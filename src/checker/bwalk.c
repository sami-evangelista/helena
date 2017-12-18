#include "bwalk.h"
#include "context.h"
#include "common.h"
#include "dfs_stack.h"
#include "workers.h"


/**
 * TODO
 *
 * - the implementaton assumes that 1 char = 8 bits, but we should use
 *   1 char = CHAR_BIT instead
 */

#if defined(MODEL_HAS_EVENT_UNDOABLE)
#define bwalk_recover_state() {                 \
    dfs_stack_event_undo(stack, now);		\
  }
#else
#define bwalk_recover_state() {                 \
    now = dfs_stack_top_state(stack, heap);     \
  }
#endif

#define bwalk_push() {                                  \
    dfs_stack_push(stack, 0, now);                      \
    dfs_stack_compute_events(stack, now, FALSE, NULL);  \
    context_incr_stat(STAT_STATES_STORED, w, 1);        \
  }

#define bwalk_tbl_insert(is_new) {              \
    const hkey_t h = state_hash(now) ^ rnd;     \
    const uint32_t id = h & hash_size_m;        \
    const uint32_t i = id >> 3;                 \
    const uint8_t bit = 1 << (id & 7);          \
    if(is_new = !(tbl[i] & bit)) {              \
      tbl[i] |= bit;                            \
    }                                           \
  }

void * bwalk_worker
(void * arg) {
  const uint32_t hash_size = 1 << (CFG_HASH_SIZE_BITS - 3);
  const uint32_t hash_size_m = hash_size - 1;
  const worker_id_t w = (worker_id_t) (unsigned long int) arg;
  const uint32_t wid = context_global_worker_id(w);
#if defined(MODEL_HAS_EVENT_UNDOABLE)
  const bool_t states_stored = FALSE;
#else
  const bool_t states_stored = TRUE;
#endif   
  char * tbl = mem_alloc0(SYSTEM_HEAP, hash_size); 
  dfs_stack_t stack;
  uint64_t rnd;
  rseed_t rseed = random_seed(w);
  state_t now, copy;
  bool_t is_new;
  event_t e;
  heap_t heap = local_heap_new();
  
  while(context_keep_searching()) {

    /**
     * initiate a random walk
     */
    stack = dfs_stack_new(wid, CFG_DFS_STACK_BLOCK_SIZE, TRUE, states_stored);
    heap_reset(heap);
    memset(tbl, 0, hash_size);
    now = state_initial(heap);
    rnd = random_int(&rseed);
    context_set_stat(STAT_STATES_STORED, w, 0);
    context_incr_stat(STAT_BWALK_ITERATIONS, w, 1);
    bwalk_tbl_insert(is_new);
    bwalk_push();
  
    /**
     * random walk DFS
     */
    while(dfs_stack_size(stack) && context_keep_searching()) {
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
        context_incr_stat(STAT_STATES_PROCESSED, w, 1);
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
    dfs_stack_free(stack);
  }
  free(tbl);
  heap_free(heap);
  return NULL;
}

void bwalk
() {
  launch_and_wait_workers(&bwalk_worker);
}
