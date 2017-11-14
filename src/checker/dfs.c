#include "config.h"
#include "darray.h"
#include "dfs.h"
#include "model.h"
#include "dfs_stack.h"
#include "ddfs_comm.h"
#include "prop.h"
#include "reduction.h"
#include "workers.h"

#if CFG_ALGO_DDFS == 0 && CFG_ALGO_DFS == 0 && CFG_ALGO_TARJAN == 0

void dfs() { assert(0); }
void dfs_progress_report(uint64_t * states_stored) { assert(0); }
void dfs_finalise() { assert(0); }

#else

#define DFS_MAX_HEAP_SIZE 100000

const struct timespec DFS_WAIT_RED_SLEEP_TIME = { 0, 10 };

typedef struct {
  bool_t accepting;
  hash_tbl_id_t id;  
} red_processed_t;

hash_tbl_t H = NULL;

state_t dfs_recover_state
(dfs_stack_t stack,
 state_t now,
 worker_id_t w,
 heap_t heap) {
  hash_tbl_id_t id;

  if(CFG_EVENT_UNDOABLE) {
    dfs_stack_event_undo(stack, now);
  } else if(CFG_HASH_COMPACTION) {
    now = dfs_stack_top_state(stack, heap);
  } else {
    id = dfs_stack_top(stack);
    now = hash_tbl_get_mem(H, id, w, heap);
  }
  return now;
}

#define dfs_push_new_state(id, is_s0) {                                 \
    /*printf("-----\n");state_print(now, stdout); printf("%d\n", state_hash(now));printf("-----\n"); */ \
    dfs_stack_push(stack, id, now);                                     \
    e_ref = is_s0 && edge_lean ? &e : NULL;                             \
    en = dfs_stack_compute_events(stack, now, por, e_ref);              \
    if(blue) {                                                          \
      hash_tbl_set_worker_attr(H, id, ATTR_CYAN, w, TRUE);              \
    } else {                                                            \
      hash_tbl_set_worker_attr(H, id, ATTR_PINK, w, TRUE);              \
      red_stack_size ++;                                                \
    }                                                                   \
    if(tarjan) {                                                        \
      darray_push(scc_stack, &id);                                      \
      hash_tbl_set_attr(H, id, ATTR_INDEX, index);                      \
      hash_tbl_set_attr(H, id, ATTR_LOWLINK, index);                    \
      hash_tbl_set_attr(H, id, ATTR_LIVE, TRUE);                        \
      index ++;                                                         \
    }                                                                   \
    if(blue && (0 == list_size(en))) {                                  \
      context_incr_dead(w, 1);                                          \
    }                                                                   \
    if(check_safety && state_check_property(now, en)) {                 \
      context_faulty_state(now);                                        \
      dfs_stack_create_trace(stack);                                    \
    }                                                                   \
  }
  

void * dfs_worker
(void * arg) {
  const worker_id_t w = (worker_id_t) (unsigned long int) arg;
  const uint32_t wid = context_global_worker_id(w);
  const bool_t check_ltl = CFG_ACTION_CHECK_LTL;
  const bool_t check_safety = CFG_ACTION_CHECK_SAFETY;
  const bool_t por = CFG_POR;
  const bool_t proviso = CFG_PROVISO;
  const bool_t edge_lean = CFG_EDGE_LEAN;
  const bool_t shuffle = CFG_PARALLEL || CFG_ALGO_DDFS || CFG_RANDOM_SUCCS;
  const bool_t ddfs = CFG_ALGO_DDFS;
  const bool_t ndfs = check_ltl
    && CFG_ALGO_DFS && !CFG_PARALLEL;
  const bool_t cndfs = check_ltl
    && CFG_ALGO_DDFS || (CFG_ALGO_DFS && CFG_PARALLEL);
  const bool_t tarjan = CFG_ALGO_TARJAN;
  const bool_t states_stored = !CFG_EVENT_UNDOABLE && CFG_HASH_COMPACTION;
  uint32_t i;
  hash_key_t h;
  heap_t heap = local_heap_new();
  state_t copy, now = state_initial_mem(heap);
  dfs_stack_t stack = dfs_stack_new(wid, CFG_DFS_STACK_BLOCK_SIZE,
                                    shuffle, states_stored);
  hash_tbl_id_t id, id_seed, id_succ;
  bool_t push, blue = TRUE, is_new;
  event_t e;
  event_t * e_ref;
  event_list_t en;
  uint64_t red_stack_size = 0, index = 0, index_other, lowlink;
  int64_t lowlink_popped = -1;
  red_processed_t proc;
  darray_t red_states = cndfs ?
    darray_new(SYSTEM_HEAP, sizeof(red_processed_t)) : NULL;
  darray_t scc_stack = tarjan ?
    darray_new(SYSTEM_HEAP, sizeof(hash_tbl_id_t)) : NULL;
  uint32_t nn = 0;
  
  /*
   * insert the initial state and push it on the stack
   */
  hash_tbl_insert(H, now, w, &is_new, &id, &h);
  dfs_push_new_state(id, TRUE);

  /*
   * search loop
   */
  while(dfs_stack_size(stack) && context_keep_searching()) {
  loop_start:

    /*
     * reinitialise the heap if its current size exceeds
     * DFS_MAX_HEAP_SIZE
     */
    if(heap_size(heap) >= DFS_MAX_HEAP_SIZE) {
      copy = state_copy(now);
      heap_reset(heap);
      now = state_copy_mem(copy, heap);
      state_free(copy);
    }

    id = dfs_stack_top(stack);

    /*
     * tarjan: a state has just been popped => we update the lowlink
     * of the current state
     */
    if(tarjan && lowlink_popped >= 0) {
      if(lowlink_popped < hash_tbl_get_attr(H, id, ATTR_LOWLINK)) {
        hash_tbl_set_attr(H, id, ATTR_LOWLINK, lowlink_popped);
      }
      lowlink_popped = -1;
    }

    /**
     * 1st case: all events of the top state have been executed => the
     * state has been expanded and we must pop it
     **/
    if(dfs_stack_top_expanded(stack)) {

      /*
       * check if proviso is verified.  if not we reexpand the state
       */
      if(por && proviso) {
        if(!dfs_stack_proviso(stack)) {
          dfs_stack_compute_events(stack, now, FALSE, NULL);
          goto loop_start;
        }
      }

      /*
       * we check an ltl property => launch the red search if the
       * state is accepting
       */
      if(check_ltl && blue && state_accepting(now)) {
        context_incr_accepting(w, 1);
        id_seed = dfs_stack_top(stack);
        blue = FALSE;
        red_stack_size = 1;
        dfs_stack_compute_events(stack, now, por, NULL);
        if(cndfs) {
          darray_reset(red_states);
        }
        goto loop_start;
      }

      /* 
       * put new colors on the popped state as it leaves the stack
       */
      if(blue) {
	hash_tbl_set_worker_attr(H, id, ATTR_CYAN, w, FALSE);
        hash_tbl_set_attr(H, id, ATTR_BLUE, TRUE);
      } else {  /* nested search of ndfs or cndfs */
        
        /*
         * in cdnfs we put the popped state in red_states.  in
         * sequential ndfs we can directly mark it as red.
         */
        if(cndfs) {
          proc.accepting = state_accepting(now);
          proc.id = id;
          darray_push(red_states, &proc);
        } else {
          hash_tbl_set_attr(H, id, ATTR_RED, TRUE);
        }
        red_stack_size --;
        
        /*
         * termination of the red DFS.  in cndfs we wait for all
         * accepting states of the red_states set to become red and
         * then mark all states of this set as red
         */
        if(0 == red_stack_size) {
          blue = TRUE;
          if(cndfs) {
            for(i = 0; i < darray_size(red_states); i ++) {
              proc = * ((red_processed_t *) darray_get(red_states, i));
              if(proc.accepting && proc.id != id) {
                while(!hash_tbl_get_attr(H, proc.id, ATTR_RED)) {
                  context_sleep(DFS_WAIT_RED_SLEEP_TIME);
                }
              }
            }
            for(i = 0; i < darray_size(red_states); i ++) {
              proc = * ((red_processed_t *) darray_get(red_states, i));
              hash_tbl_set_attr(H, proc.id, ATTR_RED, TRUE);
            }
          }
        }
      }

      /*
       * in distributed DFS we process the state to be later sent
       */
      if(ddfs) {
	ddfs_comm_process_explored_state(w, id);
      }

      /*
       * in tarjan we check whether the state is the root of an SCC we
       * pop the SCC
       */
      if(tarjan) {
        if(hash_tbl_get_attr(H, id, ATTR_INDEX) ==
           hash_tbl_get_attr(H, id, ATTR_LOWLINK)) {
          do {
            id_succ = * ((hash_tbl_id_t *) darray_pop(scc_stack));
            hash_tbl_set_attr(H, id_succ, ATTR_LIVE, FALSE);
          } while (id_succ != id);
        }
      }

      /*
       * and finally pop the state
       */
      context_incr_processed(w, 1);
      dfs_stack_pop(stack);
      if(dfs_stack_size(stack)) {
        now = dfs_recover_state(stack, now, w, heap);
      }
      if(tarjan) {
        lowlink_popped = hash_tbl_get_attr(H, id, ATTR_LOWLINK);
      }
    }

    /**
     * 2nd case: some events of the top state remain to be executed =>
     * we execute the next one
     **/
    else {
      
      /*
       * get the next event to process on the top state and execute it
       */
      dfs_stack_pick_event(stack, &e);
      event_exec(e, now);
      context_incr_evts_exec(w, 1);

      /*
       * try to insert the successor
       */
      hash_tbl_insert(H, now, w, &is_new, &id_succ, &h);

      /*
       * if we check an LTL property and are in the red search, test
       * whether the state reached is the seed.  exit the loop if this
       * is the case
       */
      if(check_ltl && !blue && (id_succ == id_seed)) {
        dfs_stack_create_trace(stack);
        break;
      }
      
      /*
       * see if it must be pushed on the stack to be processed
       */
      if(blue) {
	context_incr_arcs(w, 1);
        push = is_new
          || ((!hash_tbl_get_attr(H, id_succ, ATTR_BLUE)) &&
              (!hash_tbl_get_worker_attr(H, id_succ, ATTR_CYAN, w)));
      } else {
        push = is_new
          || ((!hash_tbl_get_attr(H, id_succ, ATTR_RED)) &&
              (!hash_tbl_get_worker_attr(H, id_succ, ATTR_PINK, w)));
      }

      if(push) { /* successor state must be explored */
        dfs_push_new_state(id_succ, FALSE);
      } else {
        now = dfs_recover_state(stack, now, w, heap);

        /*
         * tarjan: we reach a live state.
         */
        if(tarjan && hash_tbl_get_attr(H, id_succ, ATTR_LIVE)) {
          index_other = hash_tbl_get_attr(H, id_succ, ATTR_INDEX);
          lowlink = hash_tbl_get_attr(H, id, ATTR_LOWLINK);
          if(lowlink > index_other) {
            hash_tbl_set_attr(H, id, ATTR_LOWLINK, index_other);
          }
        }
        
        /*
         * if the successor is on the stack the proviso is not
         * verified for the current state
         */
        if(por && proviso &&
           hash_tbl_get_worker_attr(H, id_succ, ATTR_CYAN, w)) {
          dfs_stack_unset_proviso(stack);
        }
      }
    }
  }

  /*
   * free everything
   */
  dfs_stack_free(stack);
  heap_free(heap);
  if(cndfs) {
    darray_free(red_states);
  }
  if(tarjan) {
    darray_free(scc_stack);
  }

  return NULL;
}

void dfs
() {
  H = hash_tbl_default_new();
  if(CFG_ALGO_DDFS) {
    ddfs_comm_start(H);
  }
  launch_and_wait_workers(&dfs_worker);
  if(CFG_ALGO_DDFS) {
    context_stop_search();
    ddfs_comm_end();
  }
}

void dfs_progress_report
(uint64_t * states_stored) {
  *states_stored = H ? hash_tbl_size(H) : 0;
}

void dfs_finalise
() {
  if(H) {
    context_set_storage_size(hash_tbl_size(H));
    hash_tbl_free(H);
    H = NULL;
  }
}

#endif
