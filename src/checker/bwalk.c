#include "bwalk.h"
#include "context.h"
#include "common.h"
#include "dfs_stack.h"
#include "workers.h"


struct struct_bwalk_data_t {
  uint32_t hash_bits;
  uint32_t hash_char_size;
  dfs_stack_t stack;
  char * tbl;
  heap_t heap;
};

bwalk_data_t bwalk_data_init
(uint32_t hash_bits) {
  bwalk_data_t result;
#if defined(MODEL_HAS_EVENT_UNDOABLE)
  const bool_t states_stored = FALSE;
#else
  const bool_t states_stored = TRUE;
#endif

  result = mem_alloc(SYSTEM_HEAP, sizeof(struct struct_bwalk_data_t));
  result->hash_bits = hash_bits;
  result->hash_char_size = 1 << (hash_bits - 3); 
  result->tbl = mem_alloc0(SYSTEM_HEAP, result->hash_char_size);
  result->stack = dfs_stack_new(CFG_DFS_STACK_BLOCK_SIZE, TRUE, states_stored);
  result->heap = local_heap_new();
  return result;
}


void bwalk_data_free
(bwalk_data_t data) {
  free(data->tbl);
  dfs_stack_free(data->stack);
  heap_free(data->heap);
  free(data);
}

#if defined(MODEL_HAS_EVENT_UNDOABLE)
#define bwalk_recover_state() {                 \
    dfs_stack_event_undo(stack, now);     \
  }
#else
#define bwalk_recover_state() {                         \
    now = dfs_stack_top_state(stack, heap); \
  }
#endif

#define bwalk_push() {                                    \
    if(hook) {                                            \
      loop = loop && hook(now, hook_data);                \
    }                                                     \
    dfs_stack_push(stack, 0, now);                  \
    dfs_stack_compute_events(stack, now, FALSE);    \
    if(update_stats) {                                    \
      context_incr_stat(STAT_STATES_STORED, w, 1);        \
    }                                                     \
  }

#define bwalk_tbl_insert(is_new) {                                    \
    const hkey_t h = state_hash(now) ^ rnd;                           \
    const uint32_t id = h & hash_size_m;                              \
    const uint32_t i = id >> 3;                                       \
    const uint8_t bit = 1 << (id & 7);                                \
    if(is_new = !(tbl[i] & bit)) {                                    \
      tbl[i] |= bit;                                                  \
    }                                                                 \
  }

void bwalk_generic
(worker_id_t w,
 state_t s,
 bwalk_data_t data,
 uint32_t iterations,
 bool_t update_stats,
 state_hook_t hook,
 void * hook_data) {
  char * tbl = data->tbl;
  const dfs_stack_t stack = data->stack;
  const heap_t heap = data->heap;
  const uint32_t hash_size_m = (1 << data->hash_bits) - 1;
  uint64_t rnd;
  rseed_t rseed = random_seed(0);
  state_t now, copy;
  bool_t is_new;
  event_t e;
  bool_t loop = TRUE;
  uint32_t iter = 0;

  while(context_keep_searching() && loop) {

    /**
     * initiate a random walk
     */
    dfs_stack_reset(stack);
    heap_reset(heap);
    memset(tbl, 0, data->hash_char_size);
    now = state_copy(s, heap);
    rnd = random_int(&rseed);
    if(update_stats) {
      context_set_stat(STAT_STATES_STORED, w, 0);
      context_incr_stat(STAT_BWALK_ITERATIONS, w, 1);
    }
    bwalk_tbl_insert(is_new);
    bwalk_push();
    
    /**
     * random walk DFS
     */
    while(dfs_stack_size(stack) && context_keep_searching() && loop) {
      if(heap_size(heap) >= 1000000) {
        copy = state_copy(now, SYSTEM_HEAP);
        heap_reset(heap);
        now = state_copy(copy, heap);
        state_free(copy);
      }
      if(dfs_stack_top_expanded(stack)) {
        dfs_stack_pop(stack);
        if(dfs_stack_size(stack)) {
          bwalk_recover_state();
        }
        if(update_stats) {
          context_incr_stat(STAT_STATES_PROCESSED, w, 1);
        }
      } else {
        dfs_stack_pick_event(stack, &e);
        event_exec(e, now);
        bwalk_tbl_insert(is_new);
        if(is_new) {
          bwalk_push();
        } else {
          bwalk_recover_state();
        }
      }
    }
    state_free(now);

    /**
     *  stop looping if we've performed enough iterations
     */
    iter ++;
    if(iterations > 0 && iter == iterations) {
      loop = FALSE;
    }
  }
}

void * bwalk_worker
(void * arg) {
  bwalk_data_t data;
  const worker_id_t w = (worker_id_t) (unsigned long int) arg;
  state_t s;

  data = bwalk_data_init(CFG_HASH_SIZE_BITS);
  s = state_initial(SYSTEM_HEAP);
  bwalk_generic(w, s, data, 0, TRUE, NULL, NULL);
  state_free(s);
  bwalk_data_free(data);
  return NULL;
}

void bwalk
() {
  launch_and_wait_workers(&bwalk_worker);
}
