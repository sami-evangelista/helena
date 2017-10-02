#include "observer.h"
#include "context.h"
#include "storage.h"

void * observer_start
(void * arg) {
  float time = 0;
  struct timeval now;
  float mem;
  uint64_t visited;
  uint64_t stored;
  char name[100];

  gethostname(name, 1024);
  while(context_keep_searching()) {
    sleep(1);
    gettimeofday(&now, NULL);
    stored = storage_size(context_storage());
    mem = mem_usage();
    context_update_max_states_stored(stored);
    context_update_max_mem_used(mem);
    visited = context_visited();
    time = ((float) duration(context_start_time(), now)) / 1000000.0;
#if defined(CFG_DISTRIBUTED)
    printf("[%s:%d] ", name, getpid());    
#endif
    printf("St.:%11llu stored,", stored);
    printf("%10llu processed. ", visited);
    printf("Mem.:%8.1f MB. ", mem);
    printf("Time:%8.2f s.\n", time);
        
    /*
     *  check for limits
     */
#if defined(CFG_MEMORY_LIMITED) && defined(CFG_MAX_MEMORY)
    if(mem > CFG_MAX_MEMORY) {
      context_set_termination_state(MEMORY_EXHAUSTED);
    }
#endif
#if defined(CFG_TIME_LIMITED) && defined(CFG_MAX_TIME)
    if(time > (float) CFG_MAX_TIME) {
      context_set_termination_state(TIME_ELAPSED);
    }
#endif
#if defined(CFG_STATE_LIMITED) && defined(CFG_MAX_STATE)
    if(visited > CFG_MAX_STATE) {
      context_set_termination_state(STATE_LIMIT_REACHED);
    }
#endif
  }
  return NULL;
}
