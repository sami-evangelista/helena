#include "config.h"
#include "observer.h"
#include "context.h"
#include "storage.h"

void * observer_start
(void * arg) {
  float time = 0;
  struct timeval now;
  float mem;
  uint64_t processed;
  uint64_t stored;
  char name[100], pref[100];
  
#if defined(CFG_DISTRIBUTED)
  gethostname(name, 1024);
  sprintf(pref, "[%s:%d] ", name, getpid());
#else
  pref[0] = 0;
#endif
  while(context_keep_searching()) {
    sleep(1);
    gettimeofday(&now, NULL);
    stored = storage_size(context_storage());
    mem = mem_usage();
    context_update_max_states_stored(stored);
    context_update_max_mem_used(mem);
    processed = context_processed();
    time = ((float) duration(context_start_time(), now)) / 1000000.0;
    printf("%sTime elapsed    :   %8.2f s.\n", pref, time);
    printf("%sStates stored   :%'11llu\n", pref, stored);
    printf("%sStates processed:%'11llu\n", pref, processed);
    printf("%sMemory usage    :   %8.1f MB.\n", pref, mem);
    printf("%sCPU usage       :   %8.2f %c\n\n",
           pref, context_cpu_usage(), '%');
        
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
    if(processed > CFG_MAX_STATE) {
      context_set_termination_state(STATE_LIMIT_REACHED);
    }
#endif
  }
  return NULL;
}
