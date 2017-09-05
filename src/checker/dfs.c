#include "dfs.h"
#include "model.h"
#include "storage.h"
#include "dfs_stack.h"
#include "ddfs_comm.h"
#include "prop.h"

#if defined(ALGO_DDFS) || defined(ALGO_DFS)

report_t R;

state_t dfs_main
(worker_id_t w,
 state_t now,
 storage_id_t id,
 heap_t heap,
 bool_t blue,
 dfs_stack_t blue_stack,
 dfs_stack_t red_stack) {
  storage_id_t id_seed;
  storage_t storage = R->storage;
  bool_t push;
  dfs_stack_t stack = blue ? blue_stack : red_stack;
  state_t copy;
  event_t e;
  event_id_t eid;
  bool_t is_new;
  event_set_t en;
  storage_id_t id_top;
  hash_key_t h;
  
  /*
   *  push the root state on the stack
   */
  dfs_stack_push(stack, id);
  en = dfs_stack_compute_events(stack, now, TRUE);
  if(blue) {
    storage_set_cyan(storage, id, w, TRUE);
  } else {
    id_seed = id;
    storage_set_pink(storage, id, w, TRUE);
  }

#ifdef ACTION_CHECK_SAFETY
  if(state_check_property(now, en)) {
    report_faulty_state(R, now);
    dfs_stack_create_trace(blue_stack, red_stack, R);
  }
#endif

  /*
   *  search loop
   */
  while(dfs_stack_size(stack) && R->keep_searching) {
  loop_start:
    
    /*
     *  reinitialise the heap if we do not have enough space
     */
    if(heap_space_left(heap) <= 1024) {
      copy = state_copy(now);
      heap_reset(heap);
      now = state_copy_mem(copy, heap);
      state_free(copy);
    }

    /**
     *  1st case: all events of the top state have been executed => the state
     *  has been expanded and we must pop it
     **/
    if(dfs_stack_top_expanded(stack)) {

      /*
       *  check if proviso is verified.  if not we reexpand the state
       */
#if defined(POR) && defined(PROVISO)
      if(!dfs_stack_proviso(stack)) {
	dfs_stack_compute_events(stack, now, FALSE);
	goto loop_start;
      }
#endif

      /*
       *  we check an ltl property => launch the red search if the
       *  state is accepting and halt after if an accepting cycle has
       *  been found
       */
#ifdef ACTION_CHECK_LTL
      if(blue && state_accepting(now)) {
	R->states_accepting[w] ++;
	dfs_main(w, now, dfs_stack_top(stack), heap,
                 FALSE, blue_stack, red_stack);
	if(!R->keep_searching) {
	  return now;
	}
      }
#endif

      /* 
       * put new colors on the popped state as it leaves the stack
       */
      id_top = dfs_stack_top(stack);
      if(blue) {
	storage_set_cyan(storage, id_top, w, FALSE);
        storage_set_blue(storage, id_top, TRUE);
      } else {
        storage_set_red(storage, id_top, TRUE);
      }

      /*
       *  in distributed DFS we process the state to be later sent
       */
#ifdef ALGO_DDFS
      ddfs_comm_process_explored_state(w, id_top);
#endif

      /*
       *  and finally pop the state
       */
      R->states_visited[w] ++;
      dfs_stack_pop(stack);
      if(dfs_stack_size(stack)) {
	dfs_stack_event_undo(stack, now);
      }
    }

    /**
     *  2nd case: some events of the top state remain to be executed
     *  => we execute the next one
     **/
    else {
      
      /*
       *  get the next event to process on the top state and excute it
       */
      dfs_stack_pick_event(stack, &e, &eid);
      event_exec(e, now);
      R->events_executed[w] ++;

      /*
       *  try to insert the successor
       */
      id_top = dfs_stack_top(stack);
      storage_insert(storage, now, &id_top, &eid,
                     dfs_stack_size(stack), w, &is_new, &id, &h);

      /*
       *  see if it must be pushed on the stack to be processed
       */
      if(blue) {
	R->arcs[w] ++;
        push = is_new ||
          ((!storage_get_blue(storage, id)) &&
           (!storage_get_cyan(storage, id, w)));
#ifdef ACTION_CHECK_LTL
      } else {
        push = is_new ||
          ((!storage_get_red(storage, id)) &&
           (!storage_get_pink(storage, id, w)));
#endif
      }

      /*
       *  if the successor state must not be explored we undo the
       *  event used to reach it.  otherwise we push it on the stack
       */
      if(!push) {
        dfs_stack_event_undo(stack, now);
#if defined(POR) && defined(PROVISO)
	if(storage_get_cyan(storage, id, w)) {
	  dfs_stack_unset_proviso(stack);
	}
#endif
      } else {

        /*
         *  push the successor state on the stack and then set some
         *  color on it
         */
	dfs_stack_push(stack, id);
    	en = dfs_stack_compute_events(stack, now, TRUE);
        if(blue) {
          storage_set_cyan(storage, id, w, TRUE);
        } else {
          storage_set_pink(storage, id, w, TRUE);
        }

        /*
         *  update some statistics
         */
#ifndef PARALLEL
    	report_update_max_unproc_size
          (R, dfs_stack_size(red_stack) + dfs_stack_size(blue_stack));
#endif
	if(blue && (0 == event_set_size(en))) {
	  R->states_dead[w] ++;
	}

	/*
	 *  check if the state property is verified and stop the
	 *  search if not after setting the trace
	 */
#ifdef ACTION_CHECK_SAFETY
	if(state_check_property(now, en)) {
	  report_faulty_state(R, now);
	  dfs_stack_create_trace(blue_stack, red_stack, R);
	}
#endif

	/*
	 *  if we check an LTL property, test whether the state
	 *  reached is the seed
	 */
#ifdef ACTION_CHECK_LTL
	if(!blue && (EQUAL == storage_id_cmp(id, id_seed))) {
	  R->keep_searching = FALSE;
	  R->result = FAILURE;
	  dfs_stack_create_trace(blue_stack, red_stack, R);
	}
#endif
      }
    }
  }
  if(!blue) {
    storage_set_red(storage, id_seed, TRUE);
  }
  return now;
}

void * dfs_worker
(void * arg) {
  worker_id_t w = (worker_id_t) (unsigned long int) arg;
  uint32_t wid = worker_global_id(w);
  hash_key_t h;
  bool_t dummy;
  storage_id_t id;
  bounded_heap_t heap = bounded_heap_new("state heap", 1024 * 100);
  state_t now = state_initial_mem(heap);
  dfs_stack_t blue_stack = dfs_stack_new(wid * 2);
#ifdef ACTION_CHECK_LTL
  dfs_stack_t red_stack = dfs_stack_new(wid * 2 + 1);
#else
  dfs_stack_t red_stack = NULL;
#endif

  storage_insert(R->storage, now, NULL, NULL, 0, w, &dummy, &id, &h);
  now = dfs_main(w, now, id, heap, TRUE, blue_stack, red_stack);
  dfs_stack_free(blue_stack);
  dfs_stack_free(red_stack);
  state_free(now);
  heap_free(heap);
}

void dfs
(report_t r) {
  worker_id_t w;
  void * dummy;

  R = r;

#ifdef ALGO_DDFS
  ddfs_comm_start(R);
#endif

  /*
   *  start the threads and wait for their termination
   */
  for(w = 0; w < r->no_workers; w ++) {
    pthread_create(&(r->workers[w]), NULL, &dfs_worker, (void *)(long) w);
  }
  for(w = 0; w < r->no_workers; w ++) {
    pthread_join(r->workers[w], &dummy);
  }
  R->keep_searching = FALSE;

#ifdef ALGO_DDFS
  ddfs_comm_end();
#endif
}

#endif  /*  defined(ALGO_DDFS) || defined(ALGO_DFS)  */
