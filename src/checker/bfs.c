#include "bfs.h"
#include "bfs_queue.h"
#include "report.h"
#include "dbfs_comm.h"
#include "prop.h"

#if defined(CFG_ALGO_BFS) || defined(CFG_ALGO_DBFS) || \
  defined(CFG_ALGO_FRONTIER)

static report_t R;
static storage_t S;
static bfs_queue_t Q;
static pthread_barrier_t B;
static bool_t TERM;

void bfs_wait_barrier
() {
#if defined(CFG_PARALLEL)
  pthread_barrier_wait(&B);
#endif
}

void bfs_terminate_level
(worker_id_t w) {
  /**
   *  all states of the current BFS level have been processed => move
   *  to the next level of the queue and check if the queue is empty
   *  in order to terminate.  this must be made by all threads
   *  simultaneously.  hence the barriers
   */
#if defined(CFG_ALGO_DBFS)
  dbfs_comm_send_all_pending_states(w);
  fatal_error("bfs_terminate_level: not implemented in distributed mode");
#else
  bfs_wait_barrier();
  bfs_queue_switch_level(Q, w);
  bfs_wait_barrier();
  if(0 == w) {
    TERM = (!R->keep_searching || bfs_queue_is_empty(Q)) ? TRUE : FALSE;
  }
  bfs_wait_barrier();
#endif
}

void bfs_set_report_trace
(report_t report,
 unsigned int len,
 unsigned char * trace,
 state_t f) {
#if !defined(CFG_WITH_TRACE)
  report_faulty_state(R, f);
#else
  event_t * tr;
  state_t s = state_initial();
  unsigned int i, num;

  report_faulty_state(R, f);
  tr = mem_alloc(SYSTEM_HEAP, sizeof(event_t) * len);
  for(i = 0; i < len; i ++) {
    event_set_t en = state_enabled_events(s);
    event_t e = event_set_nth(en, trace[i]);
    event_exec(e, s);
    tr[i] = event_copy(e);
    event_set_free(en);
  }
  report->trace = tr;
  report->trace_len = len;
  state_free(s);
#endif
}

void * bfs_worker
(void * arg) {
  uint32_t levels;
  char t;
  unsigned int l, en_size;
  state_t s, succ;
  storage_id_t id, id_new;
  event_set_t en;
  worker_id_t x;
  bfs_queue_item_t el;
  int i, k, no;
  unsigned char * tr;
  worker_id_t w = (worker_id_t) (unsigned long int) arg;
  char heap_name[100];
  bool_t fully_expanded;
  unsigned int arcs;
  heap_t heap;
  hash_key_t h;
  
  sprintf(heap_name, "bfs heap of worker %d", w);
  heap = bounded_heap_new(heap_name, 10 * 1024 * 1024);
  levels = 0;
  while(!TERM) {
    for(x = 0; x < CFG_NO_WORKERS && R->keep_searching; x ++) {
      while(!bfs_queue_slot_is_empty(Q, x, w) && R->keep_searching) {
        
        /*
         *  dequeue a state sent by thread x, get its successors and a
         *  valid stubborn set
         */
        el = bfs_queue_dequeue(Q, x, w);
#ifdef CFG_WITH_TRACE
        l = el.l;
        tr = el.trace;
#endif
        id = el.s;
        heap_reset(heap);
        s = storage_get_mem(S, id, w, heap);
        en = state_enabled_events_mem(s, heap);
        en_size = event_set_size(en);
        if(0 == en_size) {
          R->states_dead[w] ++;
        }
#if defined(CFG_POR)
        en_size = event_set_size(en);
        state_stubborn_set(s, en);
        fully_expanded = (en_size == event_set_size(en)) ? TRUE : FALSE;
#endif

        /*
         *  check the state property
         */
#ifdef CFG_ACTION_CHECK_SAFETY
        if(state_check_property(s, en)) {
          bfs_set_report_trace(R, l, tr, s);
        }
#endif
    
        /*
         *  expand the current state and put its unprocessed
         *  successors in the queue
         */
      state_expansion:
        arcs = 0;
        en_size = event_set_size(en);
        for(i = 0; i < en_size; i ++) {
          event_t e = event_set_nth(en, i);
          event_id_t e_id = event_set_nth_id(en, i);
          bool_t is_new;
          uint64_t queue_size;

          arcs ++;
          R->events_executed[w] ++;
          event_exec(e, s);
          storage_insert(S, s, w, &is_new, &id_new, &h);

          /*
           *  if new, enqueue the successor after setting its trace and
           *  level
           */
          if(is_new) {
	    storage_set_cyan(S, id_new, w, TRUE);
#ifdef CFG_WITH_TRACE
            el.l = l + 1;
            el.trace = mem_alloc(SYSTEM_HEAP, sizeof(unsigned char) * el.l);
            for(k = 0; k < el.l - 1; k ++) {
              el.trace[k] = tr[k];
            }
            el.trace[k] = i;
#endif
            el.s = id_new;
            bfs_queue_enqueue(Q, el, w, h % CFG_NO_WORKERS);
          } else {

            /*
             *  if the successor state is not new it must be in the
             *  queue for the proviso to be satisfied
             */
#if defined(CFG_POR) && defined(CFG_PROVISO)
            if(!fully_expanded && !storage_get_cyan(S, id_new, w)) {
              fully_expanded = TRUE;
              event_undo(e, s);
              event_set_free(en);
              en = state_enabled_events_mem(s, heap);
              goto state_expansion;
            }
#endif
          }
          event_undo(e, s);
        }
        state_free(s);
        event_set_free(en);
#ifdef CFG_WITH_TRACE
        if(tr) {
          free(tr);
        }
#endif

        /*
         *  the state leaves the queue
         */
        R->arcs[w] += arcs;
        R->states_visited[w] ++;
        storage_set_cyan(S, id, w, FALSE);
#ifdef CFG_ALGO_FRONTIER
        storage_remove(S, id);
#endif
      }
    }

    /*
     *  all states in the current queue has been processed => initiate
     *  level termination processing
     */
    bfs_terminate_level(w);
    levels ++;
  }
  heap_free(heap);
  report_update_bfs_levels(R, levels);
}

void bfs
(report_t r) {
  state_t s = state_initial();
  bool_t is_new;
  storage_id_t id;
  worker_id_t w;
  void * dummy;
  bfs_queue_item_t el;
  hash_key_t h;
  
  R = r;
  S = R->storage;

#if defined(CFG_ALGO_DBFS)
  dbfs_comm_start(R);
#endif

  Q = bfs_queue_new();
  TERM = FALSE;
  pthread_barrier_init(&B, NULL, CFG_NO_WORKERS);
  storage_insert(R->storage, s, 0, &is_new, &id, &h);
  el.s = id;
  state_free(s);
#ifdef CFG_WITH_TRACE
  el.l = 0;
  el.trace = NULL;
#endif
  bfs_queue_enqueue(Q, el, 0, 0);
  bfs_queue_switch_level(Q, w);

  
  /*
   *  start the threads and wait for their termination
   */
  for(w = 0; w < r->no_workers; w ++) {
    pthread_create(&(r->workers[w]), NULL, &bfs_worker, (void *) (long) w);
  }
  for(w = 0; w < r->no_workers; w ++) {
    pthread_join(r->workers[w], &dummy);
  }

  bfs_queue_free(Q);

#if defined(CFG_ALGO_DBFS)
  dbfs_comm_end();
#endif
}

#endif  /*  defined(CFG_ALGO_BFS)  || defined(CFG_ALGO_DBFS) ||
	    defined(CFG_ALGO_FRONTIER)  */
