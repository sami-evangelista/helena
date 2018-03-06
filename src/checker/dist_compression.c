#include "dist_compression.h"
#include "bit_stream.h"
#include "comm.h"
#include "context.h"

#if CFG_DISTRIBUTED_STATE_COMPRESSION && defined(MODEL_HAS_STATE_COMPRESSION)
#define DIST_COMPRESSION_ENABLED
#endif

#define DIST_COMPRESSION_EMPTY   0
#define DIST_COMPRESSION_WRITING 1
#define DIST_COMPRESSION_READY   2

#define DIST_COMPRESSION_MAX_INSERT_TRIALS 1000

struct timespec dist_compression_sleep_time = { 0, 10000 }; /*  10 mus  */
htbl_compress_func_t * dist_compression_comp_funcs;
uint32_t dist_compression_pes;
uint32_t dist_compression_data_pos;
size_t * dist_compression_comp_size;
size_t * dist_compression_tbl_size;
size_t * dist_compression_tbl_start_pos;
int * dist_compression_comp_owner;
char ** dist_compression_tbls;
char * dist_compression_tbl_full_msg =
  "compression table too small (increase --compression-bits and rerun)";
uint16_t dist_compression_compressed_char_size;


uint16_t mstate_dist_compressed_char_size
() {
#if defined(DIST_COMPRESSION_ENABLED)
  uint32_t bits = CFG_STATE_COMPRESSION_BITS * MODEL_NO_COMPONENTS;
  uint16_t result = bits / CHAR_BIT;

  if(bits % CHAR_BIT) {
    result ++;
  }
  return result;
#else
#if defined(MODEL_STATE_SIZE)
  return MODEL_STATE_SIZE;
#else
  return 0;
#endif  
#endif
  assert(0);
}


void init_dist_compression
() {
#if defined(DIST_COMPRESSION_ENABLED)
  int i, owner;
  size_t start_pos[comm_pes()];

  memset(start_pos, 0, sizeof(start_pos));
  dist_compression_pes = comm_pes();
  dist_compression_comp_size =
    mem_alloc(SYSTEM_HEAP, sizeof(size_t) * MODEL_NO_COMPONENTS);
  dist_compression_tbl_size =
    mem_alloc(SYSTEM_HEAP, sizeof(size_t) * MODEL_NO_COMPONENTS);
  dist_compression_tbl_start_pos =
    mem_alloc(SYSTEM_HEAP, sizeof(size_t) * MODEL_NO_COMPONENTS);
  dist_compression_tbls =
    mem_alloc(SYSTEM_HEAP, sizeof(char *) * MODEL_NO_COMPONENTS);
  dist_compression_comp_owner =
    mem_alloc(SYSTEM_HEAP, sizeof(int) * MODEL_NO_COMPONENTS);
  dist_compression_comp_funcs =
    mem_alloc(SYSTEM_HEAP, sizeof(htbl_compress_func_t) * MODEL_NO_COMPONENTS);
  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    dist_compression_comp_size[i] = model_component_size(i);
    dist_compression_tbl_size[i] =
      (1 << CFG_STATE_COMPRESSION_BITS) *
      (dist_compression_comp_size[i] + sizeof(int));
    dist_compression_tbls[i] =
      mem_alloc0(SYSTEM_HEAP, sizeof(char) * dist_compression_tbl_size[i]);
    owner = i % dist_compression_pes;
    dist_compression_comp_owner[i] = owner;
    dist_compression_comp_funcs[i] = model_component_compress_func(i);
    dist_compression_tbl_start_pos[i] = start_pos[owner];
    start_pos[owner] += dist_compression_tbl_size[i];
  }
  dist_compression_compressed_char_size = mstate_dist_compressed_char_size();
#endif
}


void finalise_dist_compression
() {
#if defined(DIST_COMPRESSION_ENABLED)
  int i;

  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    free(dist_compression_tbls[i]);
  }
  free(dist_compression_tbls);
  free(dist_compression_comp_owner);
  free(dist_compression_comp_size);
  free(dist_compression_comp_funcs);
  free(dist_compression_tbl_size);
  free(dist_compression_tbl_start_pos);
#endif
}


void dist_compression_set_heap_pos
(uint32_t pos) {
#if defined(DIST_COMPRESSION_ENABLED)
  int i;
  
  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    dist_compression_tbl_start_pos[i] += pos;
  }
#endif
}


#define DIST_COMPRESSION_UPDATE() {                                     \
    uint32_t no = 65000 / item_size;                                    \
                                                                        \
    if(slot + no > (1 << CFG_STATE_COMPRESSION_BITS)) {                 \
      no = (1 << CFG_STATE_COMPRESSION_BITS) - slot;                    \
    }                                                                   \
    comm_get(lpos, rpos, item_size * no, owner);                        \
  }

void mstate_dist_compress
(mstate_t s,
 char * v,
 uint16_t * size) {
#if defined(DIST_COMPRESSION_ENABLED)
  uint16_t comp_size;
  char buffer[65536];
  hkey_t h;
  uint32_t i, owner, slot, rpos, item_size;
  void * lpos;
  int status;
  bool_t loop;
  const uint32_t mask = (1 << CFG_STATE_COMPRESSION_BITS) - 1;
  bit_stream_t bits;
  uint32_t trials;
  bool_t remote;
  
  *size = dist_compression_compressed_char_size;
  memset(v, 0, *size);
  bit_stream_init(bits, v);
  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    owner = dist_compression_comp_owner[i];
    dist_compression_comp_funcs[i](s, buffer, &comp_size);
    h = string_hash(buffer, comp_size);
    slot = h & mask;
    item_size = sizeof(int) + dist_compression_comp_size[i];
    lpos = dist_compression_tbls[i] + slot * item_size;
    rpos = dist_compression_tbl_start_pos[i] + slot * item_size;
    loop = TRUE;
    trials = DIST_COMPRESSION_MAX_INSERT_TRIALS;
    while(loop) {
      remote = FALSE;
      memcpy(&status, lpos, sizeof(int));
      if(status == DIST_COMPRESSION_EMPTY) {
        remote = TRUE;
        if((status = comm_int_cswap(rpos, DIST_COMPRESSION_EMPTY,
                                    DIST_COMPRESSION_WRITING, owner)) ==
           DIST_COMPRESSION_EMPTY) {
          comm_put(rpos + sizeof(int), buffer, comp_size, owner);
          assert(DIST_COMPRESSION_WRITING ==
                 comm_int_cswap(rpos, DIST_COMPRESSION_WRITING,
                                DIST_COMPRESSION_READY, owner));
          status = DIST_COMPRESSION_READY;
          memcpy(lpos, &status, sizeof(int));
          memcpy(lpos + sizeof(int), buffer, comp_size);
          loop = FALSE;
        }
      }
      if(loop) {
        if(status == DIST_COMPRESSION_WRITING) {
          remote = TRUE;
          do {
            nanosleep(&dist_compression_sleep_time, NULL);
            comm_get(&status, rpos, sizeof(int), owner);
          } while(status == DIST_COMPRESSION_WRITING);
        }
        assert(status == DIST_COMPRESSION_READY);
        if(remote) {
          status = DIST_COMPRESSION_READY;
          memcpy(lpos, &status, sizeof(int));
          DIST_COMPRESSION_UPDATE();
        }
        if(!(memcmp(lpos + sizeof(int), buffer, comp_size))) {
          loop = FALSE;
        }
      }
      if(loop) {
        slot = (slot + 1) & mask;
        if(slot) {
          lpos += item_size;
          rpos += item_size;
        } else {
          lpos = dist_compression_tbls[i];
          rpos = dist_compression_tbl_start_pos[i];
        }
        if(!(-- trials)) {
          context_error(dist_compression_tbl_full_msg);
          return;
        }
      }
    }
    bit_stream_set(bits, slot, CFG_STATE_COMPRESSION_BITS);
  }
#endif
}


void * mstate_dist_uncompress
(char * v,
 heap_t heap) {
#if defined(DIST_COMPRESSION_ENABLED)
  bit_stream_t bits;
  int status;
  uint32_t owner, i, slot, rpos, item_size;
  void *lpos, *data[MODEL_NO_COMPONENTS];

  bit_stream_init(bits, v);
  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    item_size = sizeof(int) + dist_compression_comp_size[i];
    bit_stream_get(bits, slot, CFG_STATE_COMPRESSION_BITS);
    lpos = dist_compression_tbls[i] + slot * item_size;
    memcpy(&status, lpos, sizeof(int));
    if(status != DIST_COMPRESSION_READY) {
      owner = dist_compression_comp_owner[i];
      rpos = dist_compression_tbl_start_pos[i] + slot * item_size;
      DIST_COMPRESSION_UPDATE();
    }
    data[i] = lpos + sizeof(int);
  }
  return mstate_reconstruct_from_components(data, heap);
#endif
  assert(0);  
}


size_t dist_compression_heap_size
() {
  size_t result = 0;
  int i;
  size_t sizes[dist_compression_pes];
  
#if defined(DIST_COMPRESSION_ENABLED)
  memset(sizes, 0, sizeof(sizes));
  for(i = 0; i < dist_compression_pes; i ++) {
    sizes[i] = 0;
  }
  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    sizes[dist_compression_comp_owner[i]] += dist_compression_tbl_size[i];
    if(sizes[dist_compression_comp_owner[i]] > result) {
      result = sizes[dist_compression_comp_owner[i]];
    }
  }
#endif

  return result;
}
