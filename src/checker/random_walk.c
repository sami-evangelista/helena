#include "random_walk.h"
#include "prop.h"

#if defined(ALGO_RWALK)

#define RW_MAX_DEPTH 10000
#define RW_HEAP_SIZE (RW_MAX_DEPTH * 1024)

static report_t R;

void * random_walk_worker
(void * arg) {
  worker_id_t w = (worker_id_t) (long) arg;
  state_t s;
  event_set_t en;
  event_t e;
  int i, j;
  unsigned int seed = random_seed (w);
  unsigned int en_size;
  unsigned int stack_size;
  char heap_name [100];
  event_t stack[RW_MAX_DEPTH];
  heap_t heap;
  event_t * tr;

  sprintf (heap_name, "random walk heap of worker %d", w);
  heap = bounded_heap_new (heap_name, RW_HEAP_SIZE);

  while (R->keep_searching) {
    heap_reset (heap);
    stack_size = 0;
    s = state_initial_mem (heap);
    for (i = 0; i < RW_MAX_DEPTH && R->keep_searching; i ++) {
      en = state_enabled_events_mem (s, heap);
      en_size = event_set_size (en);
#ifdef ACTION_CHECK_SAFETY
      if (state_check_property (s, en)) {
	report_faulty_state (R, s);
	tr = mem_alloc (SYSTEM_HEAP, sizeof (event_t) * stack_size);
	for (j = 0; j < stack_size; j ++) {
	  tr[j] = event_copy (stack[j]);
	}
	R->trace = tr;
	R->trace_len = stack_size;
	break;
      }
#endif
      if (0 != en_size) {
	e = event_set_nth (en, random_int (&seed) % en_size);
	event_exec (e, s);
	stack[stack_size ++] = e;
      }
      R->events_executed[w] ++;
      R->states_visited[w] ++;
      R->arcs[w] += en_size;
      event_set_free (en);
      if (0 == en_size) {
	R->states_dead[w] ++;
	break;
      }
    }
    state_free (s);
  }
  heap_free (heap);
}

void random_walk
(report_t r) {
  worker_id_t w;
  void * dummy;

  R = r;

  /*
   *  launch threads and wait for their termination
   */
  for (w = 0; w < r->no_workers; w ++)
    pthread_create (&(r->workers[w]), NULL,
		    &random_walk_worker, (void *) (long) w);
  for (w = 0; w < r->no_workers; w ++)
    pthread_join (r->workers[w], &dummy);
}

#endif  /*  defined(ALGO_RWALK)  */
