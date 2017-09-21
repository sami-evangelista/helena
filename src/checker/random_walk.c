#include "random_walk.h"
#include "prop.h"
#include "workers.h"

#if defined(CFG_ALGO_RWALK)

#define RW_MAX_DEPTH 10000
#define RW_HEAP_SIZE (RW_MAX_DEPTH * 1024)

report_t R;

void * random_walk_worker
(void * arg) {
  worker_id_t w = (worker_id_t) (long) arg;
  state_t s;
  event_set_t en;
  event_t e;
  int i, j;
  unsigned int seed = random_seed(w);
  unsigned int en_size;
  unsigned int stack_size;
  char heap_name [100];
  event_t stack[RW_MAX_DEPTH];
  heap_t heap;
  event_t * tr;

  sprintf(heap_name, "random walk heap of worker %d", w);
  heap = bounded_heap_new(heap_name, RW_HEAP_SIZE);

  while(report_keep_searching(R)) {
    heap_reset(heap);
    stack_size = 0;
    s = state_initial_mem(heap);
    for(i = 0; i < RW_MAX_DEPTH && report_keep_searching(R); i ++) {
      en = state_enabled_events_mem(s, heap);
      en_size = event_set_size(en);
#if defined(CFG_ACTION_CHECK_SAFETY)
      if(state_check_property(s, en)) {
	report_faulty_state(R, s);
	tr = mem_alloc(SYSTEM_HEAP, sizeof(event_t) * stack_size);
	for(j = 0; j < stack_size; j ++) {
	  tr[j] = event_copy(stack[j]);
	}
	R->trace = tr;
	R->trace_len = stack_size;
	break;
      }
#endif
      if(0 != en_size) {
	e = event_set_nth(en, random_int(&seed) % en_size);
	event_exec(e, s);
	stack[stack_size ++] = e;
      }
      report_incr_evts_exec(R, w, 1);
      report_incr_visited(R, w, 1);
      report_incr_arcs(R, w, en_size);
      event_set_free(en);
      if(0 == en_size) {
        report_incr_dead(R, w, 1);
	break;
      }
    }
    state_free(s);
  }
  heap_free(heap);
}

void random_walk
(report_t r) {

  R = r;
  launch_and_wait_workers(R, &random_walk_worker);
}

#endif  /*  defined(CFG_ALGO_RWALK)  */
