#include "rwalk.h"
#include "context.h"
#include "prop.h"
#include "workers.h"


void * rwalk_worker
(void * arg) {
  worker_id_t w = (worker_id_t) (long) arg;
  state_t s;
  event_list_t en;
  event_t e;
  int i;
  unsigned int seed = random_seed(w);
  unsigned int en_size;
  heap_t heap;
  event_list_t trace, new_trace;
  
  heap = local_heap_new();
  while(context_keep_searching()) {
    heap_reset(heap);
    s = state_initial_mem(heap);
    trace = list_new(heap, sizeof(event_t), event_free_void);
    for(i = 0; i < CFG_RWALK_MAX_DEPTH && context_keep_searching(); i ++) {
      en = state_events_mem(s, heap);
      en_size = list_size(en);
      if(CFG_ACTION_CHECK_SAFETY && state_check_property(s, en)) {
        /*  copy the trace to the system heap  */
        new_trace = list_new(SYSTEM_HEAP, sizeof(event_t), event_free_void);
        while(!list_is_empty(trace)) {
          list_pick_first(trace, &e);
          e = event_copy(e);
          list_append(new_trace, &e);
        }
	context_faulty_state(s);
        context_set_trace(new_trace);
	break;
      }
      if(0 != en_size) {
        list_pick_random(en, &e, &seed);
	event_exec(e, s);
        list_append(trace, &e);
      }
      context_incr_stat(STAT_EVENT_EXEC, w, 1);
      context_incr_stat(STAT_STATES_PROCESSED, w, 1);
      context_incr_stat(STAT_ARCS, w, en_size);
      list_free(en);
      if(0 == en_size) {
        context_incr_stat(STAT_STATES_DEADLOCK, w, 1);
	break;
      }
    }
    list_free(trace);
    state_free(s);
  }
  heap_free(heap);
}

void rwalk
() {
  launch_and_wait_workers(&rwalk_worker);
}

void rwalk_progress_report
(uint64_t * states_stored) {
  *states_stored = 0;
}

void rwalk_finalise
() {
}
