#include "bfs.h"
#include "bfs_queue.h"
#include "report.h"
#include "prop.h"
#include "graph.h"

static report_t R;
static bfs_queue_t Q;

void set_bfs_report_trace
(report_t report,
 unsigned int len,
 unsigned char * trace,
 state_t f) {
#ifdef WITH_TRACE
  event_t * tr;
  state_t s = state_initial ();
  unsigned int i, num;

  report_faulty_state (R, f);
  tr = mem_alloc (SYSTEM_HEAP, sizeof(event_t) * len);
  for (i = 0; i < len; i ++) {
    event_set_t en = state_enabled_events (s);
    event_t e = event_set_nth (en, trace[i]);
    event_exec (e, s);
    tr[i] = event_copy (e);
    event_set_free (en);
  }
  report->trace = tr;
  report->trace_len = len;
  state_free (s);
#else
  report_faulty_state (R, f);
#endif
}

void * bfs_worker
(void * arg) {
  storage_t storage = R->storage;
  node_t num;
  char t;
  unsigned int l, en_size;
  state_t s, succ;
  storage_id_t id, id_new;
  event_set_t en;
  bfs_queue_item_t el;
  int i, k;
  unsigned char * tr;
  worker_id_t w = (worker_id_t) (unsigned long int) arg;
  char heap_name[100];
  bool_t fully_expanded;
  unsigned int arcs;
  
  sprintf (heap_name, "bfs heap of worker %d", w);
  heap_t heap = bounded_heap_new (heap_name, 1024 * 1024);

  while (!(bfs_queue_is_empty (Q)) && R->keep_searching) {

    /*
     *  dequeue a state, get its successors and a valid stubborn set
     */
    el = bfs_queue_dequeue (Q);
    l = el.l;
#ifdef WITH_TRACE
    tr = el.trace;
#endif
    id = el.s;
    heap_reset (heap);
    s = storage_get_mem (storage, id, w, heap);
    en = state_enabled_events_mem (s, heap);
    en_size = event_set_size (en);
    if (0 == en_size) {
      R->states_dead[w] ++;
    }
    report_update_bfs_levels (R, el.l + 1);
#ifdef POR
    en_size = event_set_size (en);
    state_stubborn_set (s, en);
    fully_expanded = (en_size == event_set_size (en)) ? TRUE : FALSE;
#endif

    /*
     *  check the state property
     */
#ifdef ACTION_CHECK_SAFETY
    if (state_check_property (s, en)) {
      set_bfs_report_trace (R, l, tr, s);
    }
#endif
    
    /*
     *  expand the current state and put its unprocessed successors in
     *  the queue
     */
  state_expansion:
    arcs = 0;
    en_size = event_set_size (en);

    for (i = 0; i < en_size; i ++) {
      event_t e = event_set_nth (en, i);
      event_id_t e_id = event_set_nth_id (en, i);
      bool_t is_new;
      uint64_t queue_size;

      arcs ++;
      R->events_executed[w] ++;
      event_exec (e, s);
      storage_insert (storage, s, &id, &e_id, l + 1, w, &is_new, &id_new);

      /*
       *  if new, enqueue the successor after setting its trace and
       *  level
       */
      if (is_new) {
	el.l = l + 1;
#ifdef WITH_TRACE
	el.trace = mem_alloc (SYSTEM_HEAP, sizeof (unsigned char) * el.l);
	for (k = 0; k < el.l - 1; k ++) { el.trace[k] = tr[k]; }
	el.trace[k] = i;
#endif
	el.s = id_new;
	queue_size = bfs_queue_enqueue (Q, el);
	report_update_max_unproc_size (R, queue_size);
      } else {

	/*
	 *  if the successor state is not new it must be in the queue
	 *  for the proviso to be satisfied
	 */
#if defined(POR) && defined(PROVISO)
	if(!fully_expanded && !storage_get_cyan(storage, id_new, w)) {
	  fully_expanded = TRUE;
	  event_undo (e, s);
	  event_set_free (en);
	  en = state_enabled_events_mem (s, heap);
	  goto state_expansion;
	}
#endif
      }
      event_undo (e, s);
    }
    state_free (s);
    event_set_free (en);
#ifdef WITH_TRACE
    if (tr) {
      free (tr);
    }
#endif

    /*
     *  the state leaves the queue
     */
    R->arcs[w] += arcs;
    R->states_visited[w] ++;
    storage_set_cyan (storage, id, w, FALSE);
#ifdef ALGO_FRONTIER
    storage_remove (storage, id);
#endif
  }
  heap_free (heap);
}

void bfs
(report_t r) {
  state_t s = state_initial ();
  bool_t is_new;
  storage_id_t id;
  worker_id_t w;
  void * dummy;
  bfs_queue_item_t el;

  Q = bfs_queue_init ();
  R = r;
  storage_insert (R->storage, s, NULL, NULL, 0, 0, &is_new, &id);
  R->graph_file = open_graph_file ();
  el.s = id;
  state_free (s);
#ifdef WITH_TRACE
  el.trace = NULL;
#endif
  el.l = 0;
  bfs_queue_enqueue (Q, el);
  
  /*
   *  start the threads and wait for their termination
   */
  for (w = 0; w < r->no_workers; w ++) {
    pthread_create (&(r->workers[w]), NULL, &bfs_worker, (void *) (long) w);
  }
  for (w = 0; w < r->no_workers; w ++) {
    pthread_join (r->workers[w], &dummy);
  }

  bfs_queue_free (Q);
}
