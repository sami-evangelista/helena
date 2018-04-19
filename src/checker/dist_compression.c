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

#define DIST_COMPRESSION_MAX_INSERT_TRIALS 100000
#define DIST_COMPRESSION_TRAINING_RUNS     1
#define DIST_COMPRESSION_TRAINING_RUN_HASH 20
#define DIST_COMPRESSION_BLOCK_SIZE        65000

struct timespec dist_compression_sleep_time = { 0, 10000 }; /*  10 mus  */
htbl_compress_func_t * dist_compression_comp_funcs;
uint32_t dist_compression_me;
uint32_t dist_compression_pes;
uint32_t dist_compression_slots_per_pe;
uint32_t * dist_compression_last_slot;
size_t * dist_compression_comp_size;
char ** dist_compression_tbls;
char * dist_compression_tbl_full_msg =
  "compression table too small (increase --compression-bits and rerun)";
uint16_t dist_compression_compressed_char_size;

#define dist_compression_slot_owner(slot, owner)        {       \
    if((owner = slot / dist_compression_slots_per_pe) >=        \
       dist_compression_pes) {                                  \
      owner = dist_compression_pes - 1;                         \
    }                                                           \
  }

#define CHUNK_SIZE 65000

void dist_compression_putmem
(void * target,
 void * source,
 int size,
 int pe) {
#if defined(DIST_COMPRESSION_ENABLED)
  while(size) {
    if(size <= CHUNK_SIZE) {
      shmem_putmem(target, source, size, pe);
      size = 0;
    } else {
      shmem_putmem(target, source, CHUNK_SIZE, pe);
      size -= CHUNK_SIZE;
      target += CHUNK_SIZE;
      source += CHUNK_SIZE;
    }
  }
#endif
}

void dist_compression_getmem
(void * target,
 void * source,
 int size,
 int pe) {
#if defined(DIST_COMPRESSION_ENABLED)
  while(size) {
    if(size <= CHUNK_SIZE) {
      shmem_getmem(target, source, size, pe);
      size = 0;
    } else {
      shmem_getmem(target, source, CHUNK_SIZE, pe);
      size -= CHUNK_SIZE;
      target += CHUNK_SIZE;
      source += CHUNK_SIZE;
    }
  }
#endif
}

uint32_t NN = 0;

#define dist_compression_table_size(i)                  \
  (1 << CFG_STATE_COMPRESSION_BITS) *                   \
  (dist_compression_comp_size[i] + sizeof(int));

bool_t dist_compression_training_run_state_hook
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
    dist_compression_slot_owner(slot, owner);
    comp_size = dist_compression_comp_size[i];
    pos = dist_compression_tbls[i] + slot * (comp_size + sizeof(int));
    memcpy(&status, pos + comp_size, sizeof(int));
    if(status == DIST_COMPRESSION_EMPTY) {
      status = DIST_COMPRESSION_READY;
      memcpy(pos + comp_size, &status, sizeof(int));
      memcpy(pos, buffer, comp_size);
      NN ++;
    }
  }
#endif
  return TRUE;
}


void dist_compression_merge_training_run_results
() {
#if defined(DIST_COMPRESSION_ENABLED)
  uint32_t n, i, pe, comp_size, shift, tbl_size;
  void * pos;
  const uint32_t no_items = 1 << CFG_STATE_COMPRESSION_BITS;
  int status;
  char * buffer;
  /*
  for(pe = 1; pe < dist_compression_pes; pe ++) {
    if(pe == dist_compression_me) {
      for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
        tbl_size = dist_compression_table_size(i);
        buffer = mem_alloc(SYSTEM_HEAP, tbl_size);
        pos = dist_compression_tbls[i];
        comp_size = dist_compression_comp_size[i];
        dist_compression_getmem(buffer, pos, tbl_size, 0);
        for(n = 0, shift = 0;
            n < no_items;
            n ++, shift += comp_size + sizeof(int)) {
          memcpy(&status, buffer + shift + comp_size, sizeof(int));
          if(status == DIST_COMPRESSION_READY) {
            memcpy(pos + shift, buffer + shift, comp_size + sizeof(int));
          }
        }
        dist_compression_putmem(pos, buffer, tbl_size, 0);
        mem_free(SYSTEM_HEAP, buffer);
      }
    }
    shmem_barrier_all();
  }
  */
  if(0 != dist_compression_me) {
    for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
      tbl_size = dist_compression_table_size(i);
      pos = dist_compression_tbls[i];
      dist_compression_getmem(pos, pos, tbl_size, 0);
    }
  }
#endif
}


void dist_compression_training_run
() {
#if defined(DIST_COMPRESSION_ENABLED)
  state_t s;

  return;
  if(0 == dist_compression_me) {
    s = state_initial(SYSTEM_HEAP);
    bwalk_generic(0, s,
                  DIST_COMPRESSION_TRAINING_RUN_HASH,
                  DIST_COMPRESSION_TRAINING_RUNS, FALSE,
                  dist_compression_training_run_state_hook, NULL);
    state_free(s);
  }
  shmem_barrier_all();
  dist_compression_merge_training_run_results();
  shmem_barrier_all();
#endif
}


void init_dist_compression
() {
#if defined(DIST_COMPRESSION_ENABLED)
  int i, pe;
  size_t size, s;
  
  dist_compression_me = comm_me();
  dist_compression_pes = comm_pes();
  dist_compression_comp_size =
    mem_alloc(SYSTEM_HEAP, sizeof(size_t) * MODEL_NO_COMPONENTS);
  dist_compression_tbls =
    mem_alloc(SYSTEM_HEAP, sizeof(char *) * MODEL_NO_COMPONENTS);
  dist_compression_comp_funcs =
    mem_alloc(SYSTEM_HEAP,
              sizeof(htbl_compress_func_t) * MODEL_NO_COMPONENTS);
  dist_compression_last_slot =
    mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * dist_compression_pes);
  dist_compression_slots_per_pe = (1 << CFG_STATE_COMPRESSION_BITS) /
    dist_compression_pes;
  dist_compression_compressed_char_size = dist_compression_char_size();
  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    dist_compression_comp_size[i] = model_component_size(i);
    size = dist_compression_table_size(i);
    assert(dist_compression_tbls[i] = shmem_malloc(size));
    memset(dist_compression_tbls[i], 0, size);
    dist_compression_comp_funcs[i] = model_component_compress_func(i);
  }
  s = 0;
  for(pe = 0; pe < dist_compression_pes; pe ++) {
    s += dist_compression_slots_per_pe;
    if(pe < dist_compression_pes - 1) {
      dist_compression_last_slot[pe] = s - 1;
    } else {
      dist_compression_last_slot[pe] = (1 << CFG_STATE_COMPRESSION_BITS) - 1;
    }
  }
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
  free(dist_compression_last_slot);
#endif
}


uint16_t dist_compression_char_size
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


#define DIST_COMPRESSION_UPDATE() {                                     \
    uint32_t no = DIST_COMPRESSION_BLOCK_SIZE / item_size;              \
    if(0 == no) {                                                       \
      no = 1;                                                           \
    }                                                                   \
    if(slot + no - 1 > dist_compression_last_slot[owner]) {             \
      no = dist_compression_last_slot[owner] - slot + 1;                \
    }                                                                   \
    shmem_getmem(pos, pos, no * item_size, owner);                      \
    context_incr_stat(STAT_SHMEM_COMMS, 0, 1);                          \
  }

void dist_compression_compress
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
    assert(item_size == sizeof(int) + comp_size);
    pos = dist_compression_tbls[i] + slot * item_size;
    loop = TRUE;
    trials = DIST_COMPRESSION_MAX_INSERT_TRIALS;
    while(loop) {
      remote = FALSE;
      memcpy(&status, pos + comp_size, sizeof(int));
      dist_compression_slot_owner(slot, owner);
      if(status == DIST_COMPRESSION_EMPTY) {
        remote = TRUE;
        if((status = shmem_int_cswap(pos + comp_size, DIST_COMPRESSION_EMPTY,
                                     DIST_COMPRESSION_WRITING, owner)) ==
           DIST_COMPRESSION_EMPTY) {
          status = DIST_COMPRESSION_READY;
          memcpy(buffer + comp_size, &status, sizeof(int));
          shmem_putmem(pos, buffer, item_size, owner);
          if(owner != dist_compression_me) {
            memcpy(pos, buffer, item_size);
            context_incr_stat(STAT_SHMEM_COMMS, 0, 1);
          }
          loop = FALSE;
        }
      }
      if(loop) {
        if(status == DIST_COMPRESSION_WRITING) {
          remote = TRUE;
          do {
            nanosleep(&dist_compression_sleep_time, NULL);
            shmem_getmem(&status, pos + comp_size, sizeof(int), owner);
            context_incr_stat(STAT_SHMEM_COMMS, 0, 1);
          } while(status == DIST_COMPRESSION_WRITING);
        }
        assert(status == DIST_COMPRESSION_READY);
        if(remote && owner != dist_compression_me) {
          DIST_COMPRESSION_UPDATE();
        }
        if(!(memcmp(pos, buffer, comp_size))) {
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
          assert(0);
          context_error(dist_compression_tbl_full_msg);
          return;
        }
      }
    }
    bit_stream_set(bits, slot, CFG_STATE_COMPRESSION_BITS);
  }
#endif
}


void * dist_compression_uncompress
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
    memcpy(&status, pos + dist_compression_comp_size[i], sizeof(int));
    if(status != DIST_COMPRESSION_READY) {
      dist_compression_slot_owner(slot, owner);
      pos = dist_compression_tbls[i] + slot * item_size;
      DIST_COMPRESSION_UPDATE();
    }
    data[i] = pos;
  }
  return mstate_reconstruct_from_components(data, heap);
#endif
  assert(0);
}

void dist_compression_output_statistics
(FILE * f) {
#if defined(DIST_COMPRESSION_ENABLED)
  int i, j, status;
  uint64_t tot;
  uint16_t comp_size;
  void * pos;

  if(0 == dist_compression_me) {
    fprintf(f, "<compressionTemplates><list>");
    for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
      comp_size = dist_compression_comp_size[i];
      for(tot = 0, j = 0, pos = dist_compression_tbls[i];
          j < 1 << CFG_STATE_COMPRESSION_BITS;
          j ++, pos += sizeof(int) + comp_size) {
        memcpy(&status, pos + comp_size, sizeof(int));
        if(status != DIST_COMPRESSION_EMPTY) {
          tot ++;
        }
      }
      fprintf(f, "<item>%llu</item>", tot);
    }
    fprintf(f, "</list></compressionTemplates>");
  }
#endif
}
