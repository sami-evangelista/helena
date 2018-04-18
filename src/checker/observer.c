#include "config.h"
#include "observer.h"
#include "context.h"
#include "bfs.h"
#include "delta_ddd.h"
#include "dfs.h"
#include "rwalk.h"

void * observer_worker
(void * arg) {
  float time = 0;
  struct timeval now;
  float cpu, cpu_avg = 0;
  double processed;
  double stored;
  char name[100], pref[100];
  int n = 0;
  uint64_t old_processed = 0;

  pref[0] = 0;  
  if(CFG_WITH_OBSERVER) {
    if(CFG_DISTRIBUTED) {
      gethostname(name, 1024);
      sprintf(pref, "[%s:%d] ", name, getpid());
    }
    printf("%sRunning...\n", pref);
  }
  while(context_keep_searching()) {
    n ++;
    sleep(1);
    gettimeofday(&now, NULL);
    cpu = context_cpu_usage();
    if(context_keep_searching()) {
      cpu_avg = (cpu + (n - 1) * cpu_avg) / n;
    }
    processed = context_get_stat(STAT_STATES_PROCESSED);
    stored = context_get_stat(STAT_STATES_STORED);
    time = ((float) duration(context_start_time(), now)) / 1000000000.0;
    if(CFG_WITH_OBSERVER) {
      printf("%sTime: %.1f s.", pref, time);
      printf(", stored: %llu", (uint64_t) stored);
      printf(", processed: %llu", (uint64_t) processed);
      printf(", newly processed: %llu", (uint64_t) processed - old_processed);
      printf(", cpu: %.1f %c\n", cpu, '%');
      old_processed = processed;
    }
    
    /*
     *  check for limits
     */
    if(CFG_TIME_LIMITED && time > (float) CFG_MAX_TIME) {
      context_set_termination_state(TERM_TIME_ELAPSED);
    }
    if(CFG_STATE_LIMITED && processed > CFG_MAX_STATE) {
      context_set_termination_state(TERM_STATE_LIMIT_REACHED);
    }
  }
  if(cpu_avg != 0) {
    context_set_stat(STAT_AVG_CPU_USAGE, 0, cpu_avg);
  }
  if(CFG_WITH_OBSERVER) {
    if(context_error_msg()) {
      printf("ERROR = %s\n", context_error_msg());
    }
    printf("%sdone.\n", pref);
  }
  return NULL;
}
