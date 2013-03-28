#include "dfs.h"
#include "model.h"
#include "storage.h"
#include "dfs_stack.h"
#include "prop.h"

static report_t R;

state_t dfs_main
(state_t      now,
 storage_id_t id,
 heap_t       heap,
 bool_t       red,
 dfs_stack_t  blue_stack,
 dfs_stack_t  red_stack) {
  dfs_stack_item_t item;
  storage_id_t id_seed;
  storage_t storage = R->storage;
  bool_t push;
  worker_id_t w = 0;
  storage_state_attr_t attr;
  dfs_stack_t stack = red ? red_stack : blue_stack;
  state_t copy;
  event_t e;
  event_id_t e_id;

  /*
   *  push the root state on the stack
   */
  item.id = id;
  dfs_stack_push (stack, item);
  item.en = dfs_stack_compute_events (stack, now, TRUE, NULL);
  if (red) {
    id_seed = id;
  }

#ifdef CHECK_SAFETY
  if (state_check_property (now, item.en)) {
    report_faulty_state (R, now);
    dfs_stack_create_trace (blue_stack, red_stack, R);
  }
#endif

  /*
   *  search loop
   */
  while (dfs_stack_size (stack) && R->keep_searching) {
  loop_start:
    item = dfs_stack_top (stack);

    /*
     *  reinitialise the heap if we do not have enough space
     */
    if (heap_space_left (heap) <= 1024) {
      copy = state_copy (now);
      heap_reset (heap);
      now = state_copy_mem (copy, heap);
      state_free (copy);
    }

    /*
     *  all events of the top state have been executed => the state
     *  has been expanded and we must pop it
     */
    if (item.n == event_set_size (item.en)) {

      /*
       *  check if proviso is verified.  if not we reexpand the state
       */
#if defined(POR) && defined(PROVISO)
      if ((!item.prov_ok) && (!item.fully_expanded)) {
	event_set_free (item.en);
	dfs_stack_pop (stack);
	dfs_stack_push (stack, item);
	dfs_stack_compute_events (stack, now, FALSE, NULL);
	goto loop_start;
      }
#endif

      /*
       *  we check an ltl property => launch the red search if the
       *  state is accepting
       */
#ifdef CHECK_LTL
      if (!red && state_accepting (now)) {
	R->states_accepting[w] ++;
	dfs_main (now, item.id, heap, TRUE, blue_stack, red_stack);
	if (!R->keep_searching) {
	  return now;
	}
      }
#endif

      if (!red || (EQUAL != storage_id_cmp (id_seed, item.id))) {
	storage_set_in_unproc (storage, item.id, FALSE);
      }
      R->states_visited[w] ++;
      dfs_stack_pop (stack);
      if (dfs_stack_size (stack)) {
	item = dfs_stack_top (stack);
	event_undo (event_set_nth (item.en, item.n - 1), now);
      }
    }

    /*
     *  some events of the top state remain to be executed => we
     *  execute the next one
     */
    else {
      e = event_set_nth (item.en, item.n);
      e_id = event_set_nth_id (item.en, item.n);
      item.n ++;
      dfs_stack_update_top (stack, item);
      event_exec (e, now);
      R->events_executed[w] ++;
      if (red) {
#ifdef CHECK_LTL
	storage_get_attr (storage, now, w, &push, &id, &attr);
	push = push && (!attr.is_red);
	if (push) {
	  storage_set_is_red (storage, id);
	  storage_set_in_unproc (storage, item.id, TRUE);
	}
#endif
      } else {
	R->arcs[w] ++;
	storage_insert (storage, now, &item.id, &e_id,
			dfs_stack_size (stack), w, &push, &id);
      }

      /*
       *  if the state reached is not new we undo the event used to
       *  reach it.  otherwise we push it on the stack
       */
      if (!push) {
    	event_undo (e, now);
#if defined(POR) && defined(PROVISO)
	if (storage_get_in_unproc (storage, id)) {
	  item.prov_ok = FALSE;
	  dfs_stack_update_top (stack, item);
	}
#endif
      }
      else {
    	item.id = id;
	dfs_stack_push (stack, item);
    	item.en = dfs_stack_compute_events (stack, now, TRUE, &e);
    	report_update_max_unproc_size
	  (R, dfs_stack_size (red_stack) + dfs_stack_size (blue_stack));
	if (!red && (0 == event_set_size (item.en))) {
	  R->states_dead[w] ++;
	}

	/*
	 *  check if the state property is verified and stop the
	 *  search if not after setting the trace
	 */
#ifdef CHECK_SAFETY
	if (state_check_property (now, item.en)) {
	  report_faulty_state (R, now);
	  dfs_stack_create_trace (blue_stack, red_stack, R);
	}
#endif

	/*
	 *  if we check an LTL property, test whether the state
	 *  reached is the seed
	 */
#ifdef CHECK_LTL
	if (red && (EQUAL == storage_id_cmp (id, id_seed))) {
	  R->keep_searching = FALSE;
	  R->result = FAILURE;
	  dfs_stack_create_trace (blue_stack, red_stack, R);
	}
#endif
      }
    }
  }
  if (red) {
    storage_set_is_red (storage, id_seed);
  }
  return now;
}

void * dfs_worker
(void * arg) {
  bool_t dummy;
  storage_id_t id;
  bounded_heap_t heap = bounded_heap_new ("state heap", 1024 * 100);
  state_t now = state_initial_mem (heap);
  dfs_stack_t blue_stack = dfs_stack_new (0);
#ifdef CHECK_LTL
  dfs_stack_t red_stack = dfs_stack_new (1);
#else
  dfs_stack_t red_stack = NULL;
#endif

  storage_insert (R->storage, now, NULL, NULL, 0, 0, &dummy, &id);
  now = dfs_main (now, id, heap, FALSE, blue_stack, red_stack);
  dfs_stack_free (blue_stack);
  dfs_stack_free (red_stack);
  state_free (now);
  heap_free (heap);
}

void dfs
(report_t r) {
  worker_id_t w;
  void * dummy;

  R = r;

  /*
   *  start the threads and wait for their termination
   */
  for (w = 0; w < r->no_workers; w ++) {
    pthread_create (&(r->workers[w]), NULL, &dfs_worker, (void *) (long) w);
  }
  for (w = 0; w < r->no_workers; w ++) {
    pthread_join (r->workers[w], &dummy);
  }
}
