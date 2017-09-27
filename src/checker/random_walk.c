#include "random_walk.h"
#include "context.h"
#include "prop.h"
#include "workers.h"

#if defined(CFG_ALGO_RWALK)

#define RW_HEAP_SIZE (CFG_RWALK_MAX_DEPTH * 1024)

void * random_walk_worker
(void * arg) {
  worker_id_t w = (worker_id_t) (long) arg;
  state_t s;
  event_list_t en;
  event_t e;
  int i;
  unsigned int seed = random_seed(w);
  unsigned int en_size;
  char heap_name [100];
  heap_t heap;
  event_list_t trace, new_trace;

  sprintf(heap_name, "random walk heap of worker %d", w);
  heap = bounded_heap_new(heap_name, RW_HEAP_SIZE);

  while(context_keep_searching()) {
    heap_reset(heap);
    s = state_initial_mem(heap);
    trace = list_new(heap, sizeof(event_t), event_free_void);
    for(i = 0; i < CFG_RWALK_MAX_DEPTH && context_keep_searching(); i ++) {
      en = state_enabled_events_mem(s, heap);
      en_size = list_size(en);
#if defined(CFG_ACTION_CHECK_SAFETY)
      if(state_check_property(s, en)) {
        
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
#endif
      if(0 != en_size) {
        list_pick_random(en, &e, &seed);
	event_exec(e, s);
        list_append(trace, &e);
      }
      context_incr_evts_exec(w, 1);
      context_incr_visited(w, 1);
      context_incr_arcs(w, en_size);
      list_free(en);
      if(0 == en_size) {
        context_incr_dead(w, 1);
	break;
      }
    }
    list_free(trace);
    state_free(s);
  }
  heap_free(heap);
}

void random_walk
() {
  launch_and_wait_workers(&random_walk_worker);
}

#endif  /*  defined(CFG_ALGO_RWALK)  */
