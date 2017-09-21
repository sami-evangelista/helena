#include "random_walk.h"
#include "context.h"
#include "prop.h"
#include "workers.h"

#if defined(CFG_ALGO_RWALK)

#define RW_MAX_DEPTH 10000
#define RW_HEAP_SIZE (RW_MAX_DEPTH * 1024)

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

  while(context_keep_searching()) {
    heap_reset(heap);
    stack_size = 0;
    s = state_initial_mem(heap);
    for(i = 0; i < RW_MAX_DEPTH && context_keep_searching(); i ++) {
      en = state_enabled_events_mem(s, heap);
      en_size = event_set_size(en);
#if defined(CFG_ACTION_CHECK_SAFETY)
      if(state_check_property(s, en)) {
	context_faulty_state(s);
	tr = mem_alloc(SYSTEM_HEAP, sizeof(event_t) * stack_size);
	for(j = 0; j < stack_size; j ++) {
	  tr[j] = event_copy(stack[j]);
	}
        context_set_trace(stack_size, tr);
	break;
      }
#endif
      if(0 != en_size) {
	e = event_set_nth(en, random_int(&seed) % en_size);
	event_exec(e, s);
	stack[stack_size ++] = e;
      }
      context_incr_evts_exec(w, 1);
      context_incr_visited(w, 1);
      context_incr_arcs(w, en_size);
      event_set_free(en);
      if(0 == en_size) {
        context_incr_dead(w, 1);
	break;
      }
    }
    state_free(s);
  }
  heap_free(heap);
}

void random_walk
() {
  launch_and_wait_workers(&random_walk_worker);
}

#endif  /*  defined(CFG_ALGO_RWALK)  */
