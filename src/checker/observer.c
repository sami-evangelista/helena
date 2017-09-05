#include "observer.h"

float mem_usage() {
  float result = 0.0;
  FILE * f;
  char buf[30];
  unsigned int size = 0;
  snprintf(buf, 30, "/proc/%u/statm", (unsigned) getpid());
  f = fopen(buf, "r");
  if(f) {
    fscanf(f, "%u", &size);
  }
  fclose(f);
  return (float) size / 1024.0;
}

void * observer_start
(void * arg) {
  report_t r = (report_t) arg;
  float time = 0;
  struct timeval now;
  float mem;
  int i;
  uint64_t visited;
  uint64_t stored;

  while(r->keep_searching) {
    sleep(1);
    gettimeofday(&now, NULL);
    stored = storage_size(r->storage);
    mem = mem_usage();
    if(stored > r->states_max_stored) {
      r->states_max_stored = stored;
    }
    if(mem > r->max_mem_used) {
      r->max_mem_used = mem;
    }
    visited = 0;
    for(i = 0; i < r->no_workers; i ++) {
      visited += r->states_visited[i];
    }
    time = ((float) duration(r->start_time, now)) / 1000000.0;
#if defined(DISTRIBUTED)
    printf("[%d] ", shmem_my_pe());    
#endif
    printf("St.:%11llu stored,", stored);
    printf("%10llu processed. ", visited);
    printf("Mem.:%8.1f MB. ", mem);
    printf("Time:%8.2f s.\n", time);
    /*
     *  check for limits
     */
#if defined(MEMORY_LIMITED) && defined(MAX_MEMORY)
    if(mem > MAX_MEMORY) {
      r->keep_searching = FALSE;
      r->result = MEMORY_EXHAUSTED;
    }
#endif
#if defined(TIME_LIMITED) && defined(MAX_TIME)
    if(time > (float) MAX_TIME) {
      r->keep_searching = FALSE;
      r->result = TIME_ELAPSED;
    }
#endif
#if defined(STATE_LIMITED) && defined(MAX_STATE)
    if(visited > MAX_STATE) {
      r->keep_searching = FALSE;
      r->result = STATE_LIMIT_REACHED;
    }
#endif
  }
}
