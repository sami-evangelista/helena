#include "config.h"
#include "observer.h"
#include "context.h"
#include "bfs.h"
#include "delta_ddd.h"
#include "dfs.h"
#include "rwalk.h"
#include "comm.h"

typedef struct {
  float time;
  uint64_t stored;
  uint64_t proc;
  uint64_t new_proc;
  float cpu;
} observer_data_t;

typedef struct {
  uint32_t size;
  uint32_t curr;
  observer_data_t * data;
} observer_history_t;

void observer_history_init
(observer_history_t * hist) {
  hist->size = 1;
  hist->curr = 0;
  hist->data = malloc(sizeof(observer_data_t) * hist->size);
}

void observer_history_push_data
(observer_history_t * hist,
 observer_data_t data) {
  hist->data[hist->curr] = data;
  hist->curr ++;
  if(hist->curr == hist->size) {
    hist->size *= 2;
    hist->data = realloc(hist->data, sizeof(observer_data_t) * hist->size);
  }
}

void observer_history_free
(observer_history_t hist) {
  free(hist.data);
}

void observer_history_write
(observer_history_t hist) {
#if defined(CFG_HISTORY_FILE)
  int i;
  FILE * f;
  char name[256];
  observer_data_t data;

  if(CFG_DISTRIBUTED) {
    sprintf(name, CFG_HISTORY_FILE, comm_me());
  } else {
    sprintf(name, CFG_HISTORY_FILE);
  }
  f = fopen(name, "w");
  fprintf(f, "# time;stored;processed;newly-processed;cpu-usage\n");
  for(i = 0; i < hist.curr; i ++) {
    data = hist.data[i];
    fprintf(f, "%.2f;%llu;%llu;%llu;%.2f\n",
            data.time, data.stored, data.proc, data.new_proc, data.cpu);
  }
  fclose(f);
#endif
}

void * observer_worker
(void * arg) {
  struct timeval now;
  float cpu_avg = 0;
  char name[100], pref[100];
  int n = 0;
  uint64_t old_processed = 0;
  observer_history_t hist;
  observer_data_t data;

  observer_history_init(&hist);

  /**
   * pref contains the hostname and the pid in distributed mode
   */
  pref[0] = 0; 
  if(CFG_DISTRIBUTED) {
    gethostname(name, 1024);
    sprintf(pref, "[%s:%d] ", name, getpid());
  }

  if(CFG_WITH_OBSERVER) {
    printf("%sRunning...\n", pref);
  }
  while(context_keep_searching()) {
    n ++;
    sleep(1);

    /**
     * collect statistics
     */
    gettimeofday(&now, NULL);
    data.time = ((float) duration(context_start_time(), now)) / 1000000000.0;
    data.stored = (uint64_t) context_get_stat(STAT_STATES_STORED);
    data.proc = (uint64_t) context_get_stat(STAT_STATES_PROCESSED);
    data.new_proc = (uint64_t) data.proc - old_processed;
    data.cpu = context_cpu_usage();
    if(context_keep_searching()) {
      cpu_avg = (data.cpu + (n - 1) * cpu_avg) / n;
    }
    old_processed = data.proc;
    observer_history_push_data(&hist, data);

    /**
     * print statistics
     */
    if(CFG_WITH_OBSERVER) {
      printf("%sTime: %.1f s.", pref, data.time);
      printf(", stored: %llu", data.stored);
      printf(", processed: %llu", data.proc);
      printf(", newly processed: %llu", data.new_proc);
      printf(", cpu: %.1f %c\n", data.cpu, '%');
    }

    /**
     *  check for limits
     */
    if(CFG_TIME_LIMITED && data.time > (float) CFG_MAX_TIME) {
      context_set_termination_state(TERM_TIME_ELAPSED);
    }
    if(CFG_STATE_LIMITED && data.proc > CFG_MAX_STATE) {
      context_set_termination_state(TERM_STATE_LIMIT_REACHED);
    }
  }
  if(cpu_avg != 0) {
    context_set_stat(STAT_AVG_CPU_USAGE, 0, cpu_avg);
  }
  if(CFG_WITH_OBSERVER) {
    printf("%sdone.\n", pref);
  }
  observer_history_write(hist);
  observer_history_free(hist);
  return NULL;
}
