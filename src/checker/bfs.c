#include "bfs.h"
#include "list.h"
#include "bfs_queue.h"
#include "config.h"
#include "context.h"
#include "dbfs_comm.h"
#include "stbl.h"
#include "prop.h"
#include "reduction.h"
#include "workers.h"
#include "state.h"
#include "dist_compression.h"

#if CFG_ALGO_BFS == 0 && CFG_ALGO_DBFS == 0

void bfs() { assert(0); }

#else

htbl_t H = NULL;
bfs_queue_t Q = NULL;
pthread_barrier_t BFS_BARRIER;
bool_t BFS_AT_BARRIER = FALSE;

worker_id_t bfs_thread_owner
(hkey_t h) {
  uint8_t result = 0;
  int i;

  for(i = 0; i < sizeof(hkey_t); i++) {
    result += (h >> (i * 8)) & 0xff;
  }
  return result % CFG_NO_WORKERS;
}

void bfs_init_queue
() {
  const bool_t states_in_queue = CFG_HASH_COMPACTION;

  Q = bfs_queue_new(CFG_NO_WORKERS, CFG_BFS_QUEUE_BLOCK_SIZE,
                    states_in_queue);
}

bool_t bfs_check_termination
(worker_id_t w) {
  bool_t result = FALSE;

  if(!CFG_ALGO_DBFS && !CFG_PARALLEL) {
    result = !context_keep_searching() || bfs_queue_is_empty(Q);
  } else if(CFG_ALGO_DBFS) {
    result = dbfs_comm_idle();
  } else {
    if(bfs_queue_is_empty(Q) || !context_keep_searching() || BFS_AT_BARRIER) {
      BFS_AT_BARRIER = TRUE;
      context_barrier_wait(&BFS_BARRIER);
      BFS_AT_BARRIER = FALSE;
      result = !context_keep_searching() || bfs_queue_is_empty(Q);
      context_barrier_wait(&BFS_BARRIER);
    }
  }
  return result;
}

void bfs_report_trace
(htbl_id_t id) {
  list_t trace = list_new(SYSTEM_HEAP, sizeof(event_t), event_free_void);
  list_t trace_id = stbl_get_trace(H, id);
  list_iter_t it;
  state_t s = state_initial(SYSTEM_HEAP);
  event_t e;

  for(it = list_get_iter(trace_id);
      !list_iter_at_end(it);
      it = list_iter_next(it)) {
    e = state_event(s, * ((event_id_t *) list_iter_item(it)), SYSTEM_HEAP);
    event_exec(e, s);
    list_append(trace, &e);
  }
  state_free(s);
  list_free(trace_id);
  context_set_trace(trace);
}

#if defined(MODEL_HAS_EVENT_UNDOABLE)
#define bfs_goto_succ() {event_exec(e, s); succ = s;}
#define bfs_back_to_s() {event_undo(e, s);}
#else
#define bfs_goto_succ() {succ = state_succ(s, e, heap);}
#define bfs_back_to_s() {state_free(succ);}
#endif

void * bfs_worker
(void * arg) {
  const worker_id_t w = (worker_id_t) (unsigned long int) arg;
  const bool_t states_in_queue = bfs_queue_states_stored(Q);
  const bool_t with_trace = CFG_ACTION_CHECK_SAFETY && CFG_ALGO_BFS;
  const bool_t has_safe_attr = htbl_has_attr(H, ATTR_SAFE);
  state_t s, succ;
  htbl_id_t id_succ;
  event_list_t en;
  worker_id_t x, y;
  unsigned int arcs;
  heap_t heap = local_heap_new();
  bfs_queue_item_t item, succ_item;
  event_t e;
  bool_t is_new, reduced;
  hkey_t h;
  unsigned int dbfs_ctr = CFG_DBFS_CHECK_COMM_PERIOD;
  htbl_meta_data_t mdata;
  bool_t mine;

  do {
    for(x = 0; x < bfs_queue_no_workers(Q) && context_keep_searching(); x ++) {
      while(!bfs_queue_slot_is_empty(Q, x, w) && context_keep_searching()) {

	/**
	 * in DBFS we check incomming messages every
	 * CFG_DBFS_CHECK_COMM_PERIOD^th state processed
	 */
	if(CFG_ALGO_DBFS && (0 == (-- dbfs_ctr))) {
          dbfs_comm_check_communications();
          if(!context_keep_searching()) {
            goto check_termination;
          }
          dbfs_ctr = CFG_DBFS_CHECK_COMM_PERIOD;
        }

        /**
         * get the next state sent by thread x, get its successors and
         * a valid reduced set.  if the states are not stored in the
         * queue we get it from the hash table
         */
        item = bfs_queue_next(Q, x, w);
        heap_reset(heap);
        if(states_in_queue) {
          s = state_copy(item.s, heap);
        } else {
          s = htbl_get(H, item.id, heap);
        }

        /**
         * compute enabled events and apply POR
         */
        if(!CFG_POR) {
          en = state_events(s, heap);
        } else {
          en = state_events_reduced(s, &reduced, heap);
          if(reduced) {
            context_incr_stat(STAT_STATES_REDUCED, w, 1);
          } else if(CFG_PROVISO && has_safe_attr) {
            htbl_set_attr(H, item.id, ATTR_SAFE, TRUE);
          }
        }

        /**
         * check the state property
         */
        if(CFG_ACTION_CHECK_SAFETY && state_check_property(s, en)) {
          context_faulty_state(s);
          if(with_trace) {
            bfs_report_trace(item.id);
          }
        }

        /**
         * expand the current state and put its unprocessed successors
         * in the queue
         */
      state_expansion:
        arcs = 0;
        while(!list_is_empty(en)) {
          arcs ++;
          list_pick_first(en, &e);
          bfs_goto_succ();
          htbl_meta_data_init(mdata, succ);

	  /**
	   * in DBFS we check if the successor state is ours.
	   * otherwise we go back to s to get the next successor
	   */
          if(CFG_ALGO_DBFS) {
            mine = dbfs_comm_process_state(&mdata);
            if(!context_keep_searching()) {
              goto check_termination;
            } else if(!mine) {
              bfs_back_to_s();
              continue;
            }
          }

          /**
           * try to insert the successor state in the table
           */
          stbl_insert(H, mdata, is_new);
	  id_succ = mdata.id;
	  h = mdata.h;

          /**
           * the successor state is new => enqueue it
           */
          if(is_new) {
            y = bfs_thread_owner(h);
            htbl_set_worker_attr(H, id_succ, ATTR_CYAN, y, TRUE);
            succ_item.id = id_succ;
            succ_item.s = succ;
            bfs_queue_enqueue(Q, succ_item, w, y);
            if(with_trace) {
              htbl_set_attr(H, succ_item.id, ATTR_PRED, item.id);
              htbl_set_attr(H, succ_item.id, ATTR_EVT, event_id(e));
            }
            context_incr_stat(STAT_STATES_STORED, w, 1);

	    /**
	     *  with DBFS algo we notify the id of the new state that
	     *  can be used to perform as a root of a RWALK
	     */
	    if(CFG_ALGO_DBFS) {
	      dbfs_comm_new_state_stored(succ_item.id);
	    }
          } else {

            /**
             * the successor state is not new => if the current state
             * is reduced then the successor must be in the queue
             * (i.e., cyan for some worker) or safe
             */
            if(CFG_POR && CFG_PROVISO && reduced &&
               !htbl_get_any_cyan(H, id_succ) &&
               (!has_safe_attr || !htbl_get_attr(H, id_succ, ATTR_SAFE))) {
              reduced = FALSE;
              list_free(en);
              bfs_back_to_s();
              en = state_events(s, heap);
              context_incr_stat(STAT_STATES_REDUCED, w, -1);
              if(has_safe_attr) {
                htbl_set_attr(H, item.id, ATTR_SAFE, TRUE);
              }
              goto state_expansion;
            }
          }
          bfs_back_to_s();
        }
        state_free(s);
        list_free(en);

        /**
         * update some statistics
         */
        if(0 == arcs) {
          context_incr_stat(STAT_STATES_DEADLOCK, w, 1);
        } else {
          context_incr_stat(STAT_ARCS, w, arcs);
          context_incr_stat(STAT_EVENT_EXEC, w, arcs);
        }
        context_incr_stat(STAT_STATES_PROCESSED, w, 1);

        /**
         *  the state leaves the queue => we unset its cyan bit
         */
        bfs_queue_dequeue(Q, x, w);
        htbl_set_worker_attr(H, item.id, ATTR_CYAN, w, FALSE);
      }
    }
  check_termination: {}    
  } while(!bfs_check_termination(w));
  heap_free(heap);
}

void bfs
() {
  const bool_t with_trace = CFG_ACTION_CHECK_SAFETY && CFG_ALGO_BFS;
  state_t s = state_initial(SYSTEM_HEAP);
  bool_t is_new, enqueue = TRUE;
  bfs_queue_item_t item;
  hkey_t h;
  htbl_meta_data_t mdata;

  H = stbl_default_new();
  bfs_init_queue();

  if(CFG_ALGO_DBFS) {
    dbfs_comm_start(H, Q);
  }

  pthread_barrier_init(&BFS_BARRIER, NULL, CFG_NO_WORKERS);
  
  if(CFG_ALGO_DBFS) {
    h = state_hash(s);
    enqueue = dbfs_comm_state_owned(h);
  }
  
  if(enqueue) {
    htbl_meta_data_init(mdata, s);
    stbl_insert(H, mdata, is_new);
    item.id = mdata.id;
    item.s = s;
    if(with_trace) {
      htbl_set_attr(H, mdata.id, ATTR_PRED, mdata.id);
      htbl_set_attr(H, mdata.id, ATTR_EVT, 0);
    }
    bfs_queue_enqueue(Q, item, 0, 0);
    context_incr_stat(STAT_STATES_STORED, 0, 1);
  }
  state_free(s);

  launch_and_wait_workers(&bfs_worker);

  if(CFG_ALGO_DBFS) {
    dbfs_comm_end();
  }
  htbl_free(H);
  bfs_queue_free(Q);
}

#endif
