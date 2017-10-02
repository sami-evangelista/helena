#include "bfs.h"
#include "bfs_queue.h"
#include "context.h"
#include "dbfs_comm.h"
#include "prop.h"
#include "reduction.h"
#include "workers.h"

#if defined(CFG_ALGO_BFS) || defined(CFG_ALGO_DBFS) || \
  defined(CFG_ALGO_FRONTIER)

const bool_t WITH_TRACE =
#if defined(CFG_ACTION_CHECK_SAFETY) && defined(CFG_ALGO_BFS)
  TRUE
#else
  FALSE
#endif
  ;
const bool_t POR = 
#if defined(CFG_POR)
  TRUE
#else
  FALSE
#endif
  ;
const bool_t PROVISO =
#if defined(CFG_PROVISO)
  TRUE
#else
  FALSE
#endif
  ;
const bool_t EDGE_LEAN =
#if defined(CFG_EDGE_LEAN)
  TRUE
#else
  FALSE
#endif
  ;
storage_t S;
bfs_queue_t Q;
pthread_barrier_t B;
bool_t TERM;


worker_id_t bfs_thread_owner
(hash_key_t h) {
  uint8_t result = 0;
  int i;
  
  for(i = 0; i < sizeof(hash_key_t); i++) {
    result += (h >> (i * 8)) & 0xff;
  }
  return result % CFG_NO_WORKERS;
}

void bfs_wait_barrier
() {
#if defined(CFG_PARALLEL)
  pthread_barrier_wait(&B);
#endif
}

void bfs_init_queue
() {
#if defined(CFG_ALGO_DBFS)
  uint16_t no_workers = CFG_NO_WORKERS + 1;
#else
  uint16_t no_workers = CFG_NO_WORKERS;
#endif
#if defined(STORAGE_STATE_RECOVERABLE)
  bool_t states_in_queue = FALSE;
#else
  bool_t states_in_queue = TRUE;
#endif
  bool_t events_in_queue = EDGE_LEAN;
  
  Q = bfs_queue_new(no_workers, CFG_BFS_QUEUE_BLOCK_SIZE,
                    states_in_queue, events_in_queue);
}

void bfs_terminate_level
(worker_id_t w) {
#if defined(CFG_ALGO_DBFS)
  
  /**
   *  level termination in distributed mode
   *
   *  first send pending states then wait that all threads have done
   *  so.  then wait that other threads have done so.  worker 0
   *  notifies the communicator thread that the level has been
   *  processed.  then all wait that the communicator thread has
   *  exchanged termination information with remote processes.
   *  finally move to the next level.  this is the communicator thread
   *  that tells us whether the search is finished or not.
   */
  dbfs_comm_send_all_pending_states(w);
  bfs_wait_barrier();
  if(0 == w) {
    dbfs_comm_notify_level_termination();
  }
  dbfs_comm_local_barrier();
  bfs_queue_switch_level(Q, w);
  bfs_wait_barrier();
  TERM = dbfs_comm_global_termination();
#else
  
  /**
   *  level termination in non distributed mode
   *
   *  move to the next level of the queue and check if the queue is
   *  empty in order to terminate.  this must be made by all threads
   *  simultaneously.  hence the barriers
   */
  bfs_wait_barrier();
  bfs_queue_switch_level(Q, w);
  bfs_wait_barrier();
  if(0 == w) {
    TERM = !context_keep_searching() || bfs_queue_is_empty(Q);
  }
  bfs_wait_barrier();
#endif

  /**
   *  with FRONTIER algorithm we delete all states of the previous
   *  level that were marked as garbage by the storage_remove calls
   */
#if defined(CFG_ALGO_FRONTIER)
  storage_gc_all(S, w);
#endif
}

void bfs_report_trace
(storage_id_t id) {
  list_t trace = list_new(SYSTEM_HEAP, sizeof(event_t), event_free_void);
  list_t trace_id = storage_get_trace(S, id);
  list_iter_t it;
  state_t s = state_initial();
  event_t e;
  
  for(it = list_get_iter(trace_id);
      !list_iter_at_end(it);
      it = list_iter_next(it)) {
    e = state_event(s, * ((event_id_t *) list_iter_item(it)));
    event_exec(e, s);
    list_append(trace, &e);
  }
  state_free(s);
  list_free(trace_id);
  context_set_trace(trace);
}

#if defined(CFG_EVENT_UNDOABLE)
#define bfs_back_to_s() {event_undo(e, s);}
#else
#define bfs_back_to_s() {state_free(succ);}
#endif

void * bfs_worker
(void * arg) {
  const worker_id_t w = (worker_id_t) (unsigned long int) arg;
  const bool_t states_in_queue = bfs_queue_states_stored(Q);
  uint32_t levels = 0;
  state_t s, succ;
  storage_id_t id_succ;
  event_list_t en;
  worker_id_t x, y;
  unsigned int arcs;
  heap_t heap = local_heap_new();
  hash_key_t h;
  bfs_queue_item_t item, succ_item;
  event_t e;
  bool_t is_new, reduced;
  
  while(!TERM) {
    for(x = 0;
        x < bfs_queue_no_workers(Q) && context_keep_searching();
        x ++) {
      while(!bfs_queue_slot_is_empty(Q, x, w) && context_keep_searching()) {
        
        /**
         *  dequeue a state sent by thread x, get its successors and a
         *  valid reduced set.  if the states are not stored in the
         *  queue we get it from the storage
         */
        item = bfs_queue_dequeue(Q, x, w);
        heap_reset(heap);
        if(states_in_queue) {
          s = item.s;
        } else {
          s = storage_get_mem(S, item.id, w, heap);
        }

        /**
         *  compute enabled events and apply POR
         */
        if(POR) {
          en = state_events_reduced_mem(s, &reduced, heap);
        } else {
          en = state_events_mem(s, heap);
        }


        /**
         *  check the state property
         */
#if defined(CFG_ACTION_CHECK_SAFETY)
        if(state_check_property(s, en)) {
          if(WITH_TRACE) {
            bfs_report_trace(item.id);
          } else {
            context_faulty_state(s);
          }
        }
#endif
        
        /**
         *  apply edge lean reduction after checking state property
         *  (EDGE-LEAN may remove all enabled events)
         */
        if(EDGE_LEAN && item.e_set) {
          edge_lean_reduction(en, item.e);
        }

        /**
         *  expand the current state and put its unprocessed
         *  successors in the queue
         */
      state_expansion:
        arcs = 0;
        while(!list_is_empty(en)) {
          list_pick_first(en, &e);
          arcs ++;
#if defined(CFG_EVENT_UNDOABLE)
          event_exec(e, s);
          succ = s;
#else
          succ = state_succ_mem(s, e, heap);
#endif
#if defined(CFG_ALGO_DBFS)
          h = state_hash(succ);
          if(!dbfs_comm_state_owned(h)) {
            dbfs_comm_process_state(w, succ, h);
            bfs_back_to_s();
            continue;
          }
          storage_insert_hashed(S, succ, w, h, &is_new, &id_succ);
#else
          storage_insert(S, succ, w, &is_new, &id_succ, &h);
#endif

          /**
           *  if new, enqueue the successor
           */
          if(is_new) {
            y = bfs_thread_owner(h);
	    storage_set_cyan(S, id_succ, y, TRUE);
            succ_item.id = id_succ;
            succ_item.s = succ;
            succ_item.e_set = TRUE;
            succ_item.e = e;
            bfs_queue_enqueue(Q, succ_item, w, y);
            if(WITH_TRACE) {
              storage_set_pred(S, succ_item.id, item.id, event_id(e));
            }
          } else {

            /**
             *  if the successor state is not new and if the current
             *  state is reduced then the successor must be in the
             *  queue (i.e., cyan for some worker)
             */
            if(POR && PROVISO && reduced &&
               !storage_get_any_cyan(S, id_succ)) {
              reduced = FALSE;
              list_free(en);
              bfs_back_to_s();
              en = state_events_mem(s, heap);
              goto state_expansion;
            }
          }
          bfs_back_to_s();
        }
        state_free(s);
        list_free(en);

        /**
         *  update some statistics
         */
        if(0 == arcs) {
          context_incr_dead(w, 1);
        }
	context_incr_arcs(w, arcs);
	context_incr_visited(w, 1);
        context_incr_evts_exec(w, arcs);

        /**
         *  the state leaves the queue => we unset its cyan bit and
         *  delete it from storage if algo is FRONTIER.
         */
        storage_set_cyan(S, item.id, w, FALSE);
#if defined(CFG_ALGO_FRONTIER)
        storage_remove(S, w, item.id);
#endif
      }
    }

    /**
     *  all states in the current queue has been processed => initiate
     *  level termination processing
     */
    bfs_terminate_level(w);
    levels ++;
  }
  heap_free(heap);
  context_update_bfs_levels(levels);
}

void bfs
() {
  state_t s = state_initial();
  bool_t is_new;
  storage_id_t id;
  worker_id_t w;
  hash_key_t h;
  bool_t enqueue = TRUE;
  bfs_queue_item_t item;
  
  S = context_storage();
  bfs_init_queue();

#if defined(CFG_ALGO_DBFS)
  dbfs_comm_start(Q);
#endif

  TERM = FALSE;
  pthread_barrier_init(&B, NULL, CFG_NO_WORKERS);
  
#if defined(CFG_ALGO_DBFS)
  h = state_hash(s);
  enqueue = dbfs_comm_state_owned(h);
#endif
  
  if(enqueue) {
    storage_insert(S, s, 0, &is_new, &id, &h);
    w = h % CFG_NO_WORKERS;
    item.id = id;
    item.s = s;
    item.e_set = FALSE;
    if(WITH_TRACE) {
      storage_set_pred(S, id, id, 0);
    }
    bfs_queue_enqueue(Q, item, w, w);
    bfs_queue_switch_level(Q, w);
  }
  state_free(s);

  launch_and_wait_workers(&bfs_worker);

  bfs_queue_free(Q);

#if defined(CFG_ALGO_DBFS)
  dbfs_comm_end();
#endif
}

#endif  /*  defined(CFG_ALGO_BFS)  || defined(CFG_ALGO_DBFS) ||
	    defined(CFG_ALGO_FRONTIER)  */
