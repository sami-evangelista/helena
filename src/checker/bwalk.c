#include "bwalk.h"
#include "context.h"
#include "common.h"
#include "dfs_stack.h"
#include "htbl.h"
#include "workers.h"

#if defined(MODEL_EVENT_UNDOABLE)
#define bwalk_recover_state() {                 \
    dfs_stack_event_undo(stack, now);		\
  }
#else
#define bwalk_recover_state() {                 \
    now = dfs_stack_top_state(stack, heap);     \
  }
#endif

#define bwalk_insert_now() {					\
    h = state_hash(now);                                        \
    htbl_insert_hashed(htbl, now, h ^ rnd, &is_new, &id);       \
  }

#define bwalk_push() {                                  \
    dfs_stack_push(stack, id, now);                     \
    dfs_stack_compute_events(stack, now, FALSE, NULL);  \
    context_incr_stat(STAT_STATES_STORED, w, 1);        \
  }

void * bwalk_worker
(void * arg) {
  const worker_id_t w = (worker_id_t) (unsigned long int) arg;
  const uint32_t wid = context_global_worker_id(w);
#if defined(MODEL_EVENT_UNDOABLE)
  const bool_t states_stored = FALSE;
#else
  const bool_t states_stored = TRUE;
#endif    
  htbl_id_t id;
  dfs_stack_t stack;
  uint64_t rnd;
  rseed_t rseed = random_seed(w);
  state_t now, copy;
  htbl_t htbl = htbl_default_new();  
  bool_t is_new;
  hkey_t h;
  event_t e;
  heap_t heap = local_heap_new();
  hkey_t roots[1000000];
  uint32_t i, no_roots = 0;
    
  now = state_initial_mem(heap);
  while(context_keep_searching()) {

    stack = dfs_stack_new(wid, CFG_DFS_STACK_BLOCK_SIZE,        
                          TRUE, states_stored);
    copy = state_copy(now);
    heap_reset(heap);
    htbl_reset(htbl);
    now = state_initial_mem(heap);
    state_free(copy);
    rnd = random_int(&rseed);
    context_set_stat(STAT_STATES_STORED, w, 0);
    bwalk_insert_now();
    bwalk_push();
  
    while(dfs_stack_size(stack) && context_keep_searching()) {
      if(heap_size(heap) >= 1000000) {
        copy = state_copy(now);
        heap_reset(heap);
        now = state_copy_mem(copy, heap);
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
        bwalk_insert_now();
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
  htbl_free(htbl);
  heap_free(heap);
  return NULL;
}

void bwalk
() {
  launch_and_wait_workers(&bwalk_worker);
}
