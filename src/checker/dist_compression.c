#include "dist_compression.h"
#include "bit_stream.h"
#include "comm.h"
#include "context.h"
#include "bwalk.h"

#if CFG_DISTRIBUTED_STATE_COMPRESSION && defined(MODEL_HAS_STATE_COMPRESSION)
#define DIST_COMPRESSION_ENABLED
#include "shmem.h"
#endif

#define DIST_COMPRESSION_EMPTY   0
#define DIST_COMPRESSION_WRITING 1
#define DIST_COMPRESSION_READY   2

#define DIST_COMPRESSION_MAX_INSERT_TRIALS 1000
#define DIST_COMPRESSION_TRAINING_RUN_HASH 24
#define DIST_COMPRESSION_TRAINING_RUN_TIME 2

struct timespec dist_compression_sleep_time = { 0, 10000 }; /*  10 mus  */
htbl_compress_func_t * dist_compression_comp_funcs;
uint32_t dist_compression_pes;
uint32_t dist_compression_slots_per_pe;
size_t * dist_compression_comp_size;
char ** dist_compression_tbls;
char * dist_compression_tbl_full_msg =
  "compression table too small (increase --compression-bits and rerun)";
uint16_t dist_compression_compressed_char_size;
int dist_compression_me;

#define dist_compression_slot_owner(slot, owner)        {       \
  if((owner = slot / dist_compression_slots_per_pe) ==          \
     dist_compression_pes) {                                    \
  owner = 
  }

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


void dist_compression_training_run_state_hook
(state_t s,
 void * hook_data) {
#if defined(DIST_COMPRESSION_ENABLED)
  uint16_t comp_size;
  char buffer[65536];
  hkey_t h;
  uint32_t i, owner, slot, item_size;
  void * pos;
  int status;
  const uint32_t mask = (1 << CFG_STATE_COMPRESSION_BITS) - 1;
  
  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    dist_compression_comp_funcs[i](s, buffer, &comp_size);
    h = string_hash(buffer, comp_size);
    slot = h & mask;
    item_size = sizeof(int) + dist_compression_comp_size[i];
    owner = slot % dist_compression_pes;
    if(owner == dist_compression_me) {
      pos = dist_compression_tbls[i] + slot * item_size;
      memcpy(&status, pos, sizeof(int));
      if(status == DIST_COMPRESSION_EMPTY) {
        status = DIST_COMPRESSION_READY;
        memcpy(pos, &status, sizeof(int));
        memcpy(pos + sizeof(int), buffer, comp_size);
      }
    }
  }
#endif
}


void dist_compression_training_run
() {
#if defined(DIST_COMPRESSION_ENABLED)
  bwalk_generic(0, DIST_COMPRESSION_TRAINING_RUN_HASH, FALSE,
                DIST_COMPRESSION_TRAINING_RUN_TIME * 1000,
                dist_compression_training_run_state_hook, NULL);
  shmem_barrier_all();
#endif
}


void init_dist_compression
() {
#if defined(DIST_COMPRESSION_ENABLED)
  int i;
  size_t size;
    
  dist_compression_pes = comm_pes();
  dist_compression_comp_size =
    mem_alloc(SYSTEM_HEAP, sizeof(size_t) * MODEL_NO_COMPONENTS);
  dist_compression_tbls =
    mem_alloc(SYSTEM_HEAP, sizeof(char *) * MODEL_NO_COMPONENTS);
  dist_compression_comp_funcs =
    mem_alloc(SYSTEM_HEAP, sizeof(htbl_compress_func_t) * MODEL_NO_COMPONENTS);
  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    dist_compression_comp_size[i] = model_component_size(i);
    size =
      (1 << CFG_STATE_COMPRESSION_BITS) *
      (dist_compression_comp_size[i] + sizeof(int));
    assert(dist_compression_tbls[i] = shmem_malloc(size));
    memset(dist_compression_tbls[i], 0, size);
    dist_compression_comp_funcs[i] = model_component_compress_func(i);
  }
  dist_compression_slots_per_pe = (1 << CFG_STATE_COMPRESSION_BITS) /
    dist_compression_pes;
  dist_compression_compressed_char_size = mstate_dist_compressed_char_size();
  dist_compression_me = comm_me();
  shmem_barrier_all();
#endif
}


void finalise_dist_compression
() {
#if defined(DIST_COMPRESSION_ENABLED)
  int i;

  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    shmem_free(dist_compression_tbls[i]);
  }
  free(dist_compression_tbls);
  free(dist_compression_comp_size);
  free(dist_compression_comp_funcs);
#endif
}


#define DIST_COMPRESSION_UPDATE() {                                     \
    uint32_t no = 65000 / item_size;                                    \
                                                                        \
    if(slot + no > (1 << CFG_STATE_COMPRESSION_BITS)) {                 \
      no = (1 << CFG_STATE_COMPRESSION_BITS) - slot;                    \
    }                                                                   \
    no = 1 ; shmem_getmem(pos, pos, item_size * no, owner);		\
    context_incr_stat(STAT_SHMEM_COMMS, 0, 1);				\
  }

void mstate_dist_compress
(mstate_t s,
 char * v,
 uint16_t * size) {
#if defined(DIST_COMPRESSION_ENABLED)
  uint16_t comp_size;
  char buffer[65536];
  hkey_t h;
  uint32_t i, owner, slot, item_size;
  void * pos;
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
    dist_compression_comp_funcs[i](s, buffer, &comp_size);
    h = string_hash(buffer, comp_size);
    slot = h & mask;
    item_size = sizeof(int) + dist_compression_comp_size[i];
    pos = dist_compression_tbls[i] + slot * item_size;
    loop = TRUE;
    trials = DIST_COMPRESSION_MAX_INSERT_TRIALS;
    while(loop) {
      remote = FALSE;
      memcpy(&status, pos, sizeof(int));
      owner = slot % dist_compression_pes;
      if(status == DIST_COMPRESSION_EMPTY) {
        remote = TRUE;
        if((status = shmem_int_cswap(pos, DIST_COMPRESSION_EMPTY,
                                     DIST_COMPRESSION_WRITING, owner)) ==
           DIST_COMPRESSION_EMPTY) {
          shmem_putmem(pos + sizeof(int), buffer, comp_size, owner);
          status = DIST_COMPRESSION_READY;
          shmem_putmem(pos, &status, sizeof(int), owner);
	  context_incr_stat(STAT_SHMEM_COMMS, 0, 2);
          if(owner != dist_compression_me) {
            memcpy(pos, &status, sizeof(int));
            memcpy(pos + sizeof(int), buffer, comp_size);
          }
          loop = FALSE;
        }
      }
      if(loop) {
        if(status == DIST_COMPRESSION_WRITING) {
          remote = TRUE;
          do {
            nanosleep(&dist_compression_sleep_time, NULL);
            shmem_getmem(&status, pos, sizeof(int), owner);
          } while(status == DIST_COMPRESSION_WRITING);
        }
        assert(status == DIST_COMPRESSION_READY);
        if(remote && owner != dist_compression_me) {
          status = DIST_COMPRESSION_READY;
          memcpy(pos, &status, sizeof(int));
          DIST_COMPRESSION_UPDATE();
        }
        if(!(memcmp(pos + sizeof(int), buffer, comp_size))) {
          loop = FALSE;
        }
      }
      if(loop) {
        slot = (slot + 1) & mask;
        if(slot) {
          pos += item_size;
        } else {
          pos = dist_compression_tbls[i];
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
  uint32_t owner, i, slot, item_size;
  void * pos, * data[MODEL_NO_COMPONENTS];

  bit_stream_init(bits, v);
  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    item_size = sizeof(int) + dist_compression_comp_size[i];
    bit_stream_get(bits, slot, CFG_STATE_COMPRESSION_BITS);
    pos = dist_compression_tbls[i] + slot * item_size;
    memcpy(&status, pos, sizeof(int));
    if(status != DIST_COMPRESSION_READY) {
      owner = slot % dist_compression_pes;
      pos = dist_compression_tbls[i] + slot * item_size;
      DIST_COMPRESSION_UPDATE();
    }
    data[i] = pos + sizeof(int);
  }
  return mstate_reconstruct_from_components(data, heap);
#endif
  assert(0);
}
