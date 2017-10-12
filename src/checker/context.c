#include "context.h"
#include "observer.h"
#include "config.h"
#include "comm_shmem.h"

typedef struct {
  struct timeval start_time;
  struct timeval end_time;
  unsigned int no_workers;
  unsigned int no_comm_workers;
  unsigned long cpu_total;
  unsigned long utime;
  unsigned long stime;
  bool_t keep_searching;
  bool_t error_raised;
  FILE * graph_file;
  char * error_msg;
  termination_state_t term_state;
  storage_t storage;

  /*  for the trace context  */
  bool_t faulty_state_found;
  state_t faulty_state;
  event_list_t trace;
  pthread_mutex_t ctx_mutex;

  /*  statistics field  */
  uint64_t * states_accepting;
  uint64_t * states_processed;
  uint64_t * states_dead;
  uint64_t * arcs;
  uint64_t * evts_exec;
  uint64_t * evts_exec_dd;
  uint64_t bytes_sent;
  uint64_t exec_time;
  uint64_t states_max_stored;
  uint64_t barrier_time;
  uint64_t distributed_barrier_time;
  uint64_t sleep_time;
  unsigned int bfs_levels;
  bool_t bfs_levels_ok;
  float max_mem_used;
  float comp_time;
  float avg_cpu_usage;

  /*  threads  */
  pthread_t observer;
  pthread_t * workers;
} struct_context_t;

typedef struct_context_t * context_t;

context_t CTX;

void context_init
() {
  unsigned int i;
  unsigned int no_workers = CFG_NO_WORKERS;
  unsigned int no_comm_workers = CFG_NO_COMM_WORKERS;
  
  CTX = mem_alloc(SYSTEM_HEAP, sizeof(struct_context_t));
  
  CTX->error_msg = NULL;
  CTX->error_raised = FALSE;

  if(cfg_action_simulate()) {
    return;
  }
  
  /*
   *  initialisation of statistic related fields
   */
  CTX->states_processed =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  CTX->states_dead =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  CTX->states_accepting =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  CTX->arcs =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  CTX->evts_exec =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  CTX->evts_exec_dd =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  for(i = 0; i < no_workers; i ++) {
    CTX->states_processed[i] = 0;
    CTX->states_accepting[i] = 0;
    CTX->states_dead[i] = 0;
    CTX->arcs[i] = 0;
    CTX->evts_exec[i] = 0;
    CTX->evts_exec_dd[i] = 0;
  }
  CTX->bytes_sent = 0;
  CTX->bfs_levels = 0;
  CTX->bfs_levels_ok = FALSE;
  CTX->max_mem_used = 0.0;
  CTX->states_max_stored = 0;
  CTX->comp_time = 0.0;
  CTX->barrier_time = 0;
  CTX->distributed_barrier_time = 0;
  CTX->sleep_time = 0;
  CTX->avg_cpu_usage = 0.0;
  CTX->no_workers = no_workers;
  CTX->no_comm_workers = no_comm_workers;
  CTX->storage = storage_new();
  CTX->faulty_state_found = FALSE;
  CTX->trace = NULL;
  CTX->keep_searching = TRUE;
  gettimeofday(&CTX->start_time, NULL);
  CTX->graph_file = NULL;
  if(!cfg_action_check()) {
    CTX->term_state = SEARCH_TERMINATED;
  } else {
    if(cfg_hash_compaction()) {
      CTX->term_state = NO_ERROR;
    } else {
      CTX->term_state = SUCCESS;
    }
  }
  CTX->cpu_total = 0;
  CTX->utime = 0;
  CTX->stime = 0;
  cpu_usage(&CTX->cpu_total, &CTX->utime, &CTX->stime);
  
  /*
   *  launch the observer thread
   */
  pthread_create(&CTX->observer, NULL, &observer_worker, (void *) CTX);
  CTX->workers = mem_alloc(SYSTEM_HEAP, sizeof(pthread_t) * CTX->no_workers);
  pthread_mutex_init(&CTX->ctx_mutex, NULL);
}


void context_output_trace
(FILE * out) {
  event_t e;
  state_t s = state_initial();
  list_size_t l;

  state_to_xml(s, out);
  if(CTX->trace) {
    l = list_size(CTX->trace);
    while(!list_is_empty(CTX->trace)) {
      list_pick_first(CTX->trace, &e);
      if(!event_is_dummy(e)) {
        event_to_xml(e, out);
        event_exec(e, s);
	if(cfg_trace_full()) {
	  state_to_xml(s, out);
	}
      }
      event_free(e);
    }
    if(cfg_trace_events()) {
      if(l > 0) {
	state_to_xml(s, out);
      }
    }
  }
  state_free(s);
}


void context_finalise
() {
  FILE * out;
  void * dummy;
  uint64_t ssize;
  uint64_t sum_processed;
  uint64_t min_processed;
  uint64_t max_processed;
  uint64_t avg_processed;
  uint64_t dev_processed;
  worker_id_t w;
  char name[1024], file_name[1024];
  char * buf = NULL;
  size_t n = 0;
  int i;

  if(!cfg_action_simulate()) {
    gettimeofday(&CTX->end_time, NULL);
    CTX->exec_time = duration(CTX->start_time, CTX->end_time);
    CTX->keep_searching = FALSE;
    pthread_join(CTX->observer, &dummy);
    if(NULL != CTX->graph_file) {
      fclose(CTX->graph_file);
    }

    /**
     *  make the report
     */
    if(cfg_distributed()) {
      sprintf(file_name, "%s.%d", CFG_REPORT_FILE, context_proc_id());
      out = fopen(file_name, "w");
    } else {
      out = fopen(CFG_REPORT_FILE, "w");
    }
    fprintf(out, "<helenaReport>\n");
    fprintf(out, "<infoReport>\n");
    fprintf(out, "<model>%s</model>\n", model_name());
    model_xml_parameters(out);
    fprintf(out, "<language>%s</language>\n", CFG_LANGUAGE);
    fprintf(out, "<date>%s</date>\n", CFG_DATE);
    fprintf(out, "<filePath>%s</filePath>\n", CFG_FILE_PATH);
    gethostname(name, 1024);
    fprintf(out, "<host>%s (pid = %d)</host>\n", name, getpid());
    fprintf(out, "</infoReport>\n");
    fprintf(out, "<searchReport>\n");
    if(cfg_property()) {
      fprintf(out, "<property>%s</property>\n", CFG_PROPERTY);
    }
    fprintf(out, "<searchResult>");
    switch(CTX->term_state) {
    case STATE_LIMIT_REACHED:
      fprintf(out, "stateLimitReached"); break;
    case MEMORY_EXHAUSTED:
      fprintf(out, "memoryExhausted"); break;
    case TIME_ELAPSED:
      fprintf(out, "timeElapsed"); break;
    case INTERRUPTION:
      fprintf(out, "interruption"); break;
    case SEARCH_TERMINATED:
      fprintf(out, "searchTerminated"); break;
    case NO_ERROR:
      fprintf(out, "noCounterExample"); break;
    case SUCCESS:
      fprintf(out, "propertyHolds"); break;
    case FAILURE:
      fprintf(out, "propertyViolated"); break;
    case ERROR:
      fprintf(out, "error"); break;
    }
    fprintf(out, "</searchResult>\n");
    if(CTX->term_state == ERROR && CTX->error_raised) {
      fprintf(out, "<errorMessage>%s</errorMessage>\n", CTX->error_msg);
    }
    fprintf(out, "<searchOptions>\n");
    fprintf(out, "<searchAlgorithm>");
    if(cfg_algo_dfs()) {
      fprintf(out, "depthSearch");
    } else if(cfg_algo_bfs()) {
      fprintf(out, "breadthSearch");
    } else if(cfg_algo_ddfs()) {
      fprintf(out, "distributedDepthSearch");
    } else if(cfg_algo_dbfs()) {
      fprintf(out, "distributedBreadthSearch");
    } else if(cfg_algo_frontier()) {
      fprintf(out, "frontierSearch");
    } else if(cfg_algo_rwalk()) {
      fprintf(out, "randomWalk");
    } else if(cfg_algo_delta_ddd()) {
      fprintf(out, "deltaDDD");
    }
    fprintf(out, "</searchAlgorithm>\n");
    fprintf(out, "<workers>%d</workers>\n", CTX->no_workers);
    if(cfg_distributed()) {
      fprintf(out, "<commWorkers>%d</commWorkers>\n", CTX->no_comm_workers);
    }
    if(cfg_hash_storage() || cfg_delta_ddd_storage()) {
      fprintf(out, "<hashTableSlots>%d</hashTableSlots>\n", cfg_hash_size());
    }
    if(cfg_hash_compaction()) {
      fprintf(out, "<hashCompact/>\n");
    }
    if(cfg_por()) {
      fprintf(out, "<partialOrder/>\n");
    }
    if(cfg_state_caching()) {
      fprintf(out, "<stateCaching/>\n");
    }
    if(cfg_algo_delta_ddd()) {
      fprintf(out, "<candidateSetSize>%d</candidateSetSize>\n",
	      cfg_delta_ddd_cand_set_size());
    }
    fprintf(out, "</searchOptions>\n");
    fprintf(out, "</searchReport>\n");
    fprintf(out, "<statisticsReport>\n");
    model_xml_statistics(out);
    fprintf(out, "<timeStatistics>\n");
    if(CTX->comp_time > 0) {
      fprintf(out, "<compilationTime>%.3f</compilationTime>\n",
	      CTX->comp_time);
    }
    fprintf(out, "<searchTime>%.3f</searchTime>\n",
	    CTX->exec_time / 1000000.0);
    if(CTX->sleep_time > 0) {
      fprintf(out, "<sleepTime>%.3f</sleepTime>\n",
	      CTX->sleep_time / 1000000000.0);
    }
    if(CTX->barrier_time > 0) {
      fprintf(out, "<barrierTime>%.3f</barrierTime>\n",
	      CTX->barrier_time / 1000000.0);
    }
    if(cfg_algo_delta_ddd()) {
      fprintf(out, "<duplicateDetectionTime>%.3f</duplicateDetectionTime>\n",
	      storage_dd_time(CTX->storage) / 1000000.0);
    }
    if(cfg_distributed()) {
      fprintf(out, "<distributedBarrierTime>");
      fprintf(out, "%.3f</distributedBarrierTime>\n",
	      CTX->distributed_barrier_time / 1000000.0);
    }
    if(cfg_state_caching()) {
      fprintf(out, "<garbageCollectionTime>");
      fprintf(out, "%.3f</garbageCollectionTime>\n",
	      storage_gc_time(CTX->storage) / 1000000.0);
    }
    fprintf(out, "</timeStatistics>\n");
    fprintf(out, "<graphStatistics>\n");
    ssize = storage_size(CTX->storage);
    fprintf(out, "<statesStored>%llu</statesStored>\n", ssize);
    fprintf(out, "<statesMaxStored>%llu</statesMaxStored>\n",
	    (ssize > CTX->states_max_stored) ? ssize : CTX->states_max_stored);
    sum_processed = large_sum(CTX->states_processed, CTX->no_workers);
    fprintf(out, "<statesProcessed>%llu</statesProcessed>\n", sum_processed);
    if(cfg_parallel()) {
      min_processed = CTX->states_processed[0];
      max_processed = CTX->states_processed[0];
      avg_processed = sum_processed / CFG_NO_WORKERS;
      dev_processed = 0;
      for(w = 1; w < CFG_NO_WORKERS; w ++) {
	if(CTX->states_processed[w] > max_processed) {
	  max_processed = CTX->states_processed[w];
	} else if(CTX->states_processed[w] < min_processed) {
	  min_processed = CTX->states_processed[w];
	}
	dev_processed += (CTX->states_processed[w] - avg_processed)
	  * (CTX->states_processed[w] - avg_processed);
      }
      dev_processed = sqrt(dev_processed / CTX->no_workers);
      fprintf(out, "<statesProcessedMin>%llu</statesProcessedMin>\n",
	      min_processed);
      fprintf(out, "<statesProcessedMax>%llu</statesProcessedMax>\n",
	      max_processed);
      fprintf(out, "<statesProcessedDev>%llu</statesProcessedDev>\n",
	      dev_processed);
    }
    if(cfg_action_check_ltl()) {
      fprintf(out, "<statesAccepting>%llu</statesAccepting>\n",
	      large_sum(CTX->states_accepting, CTX->no_workers));
    }
    fprintf(out, "<statesTerminal>%llu</statesTerminal>\n",
	    large_sum(CTX->states_dead, CTX->no_workers));
    fprintf(out, "<arcs>%llu</arcs>\n",
	    large_sum(CTX->arcs, CTX->no_workers));
    if(CTX->bfs_levels_ok) {
      fprintf(out, "<bfsLevels>%u</bfsLevels>\n", CTX->bfs_levels);
    }
    fprintf(out, "</graphStatistics>\n");
    fprintf(out, "<otherStatistics>\n");
    fprintf(out, "<maxMemoryUsed>%.1f</maxMemoryUsed>\n",
	    CTX->max_mem_used);
    if(CTX->avg_cpu_usage > 0) {
      fprintf(out, "<avgCPUUsage>%.2f</avgCPUUsage>\n", CTX->avg_cpu_usage);
    }
    fprintf(out, "<eventsExecuted>%llu</eventsExecuted>\n",
	    large_sum(CTX->evts_exec, CTX->no_workers));
    if(cfg_algo_delta_ddd()) {
      fprintf(out, "<eventsExecutedDDD>%llu</eventsExecutedDDD>\n",
	      large_sum(CTX->evts_exec_dd, CTX->no_workers));
      fprintf(out, "<eventsExecutedExpansion>%llu</eventsExecutedExpansion>\n",
	      large_sum(CTX->evts_exec, CTX->no_workers) -
	      large_sum(CTX->evts_exec_dd, CTX->no_workers));
    }
    if(cfg_algo_rwalk()) {
      fprintf(out, "<eventExecPerSecond>%d</eventExecPerSecond>\n",
	      (unsigned int) (1.0 * sum_processed /
			      (CTX->exec_time / 1000000.0)));
    }
    if(cfg_distributed()) {
      fprintf(out, "<bytesSent>%llu</bytesSent>\n", CTX->bytes_sent);
    }
    fprintf(out, "</otherStatistics>\n");
    fprintf(out, "</statisticsReport>\n");
    if(CTX->term_state == FAILURE) {
      fprintf(out, "<traceReport>\n");
      if(cfg_trace_state()) {
	fprintf(out, "<traceState>\n");
	state_to_xml(CTX->faulty_state, out);
	fprintf(out, "</traceState>\n");
      } else if(cfg_trace_full()) {
	fprintf(out, "<traceFull>\n");
	context_output_trace(out);
	fprintf(out, "</traceFull>\n");
      } else if(cfg_trace_events()) {
	fprintf(out, "<traceEvents>\n");
	context_output_trace(out);
	fprintf(out, "</traceEvents>\n");
      }
      fprintf(out, "</traceReport>\n");  
    }
    fprintf(out, "</helenaReport>\n");
    fclose(out);

    /**
     *  in distributed mode the report file must be printed to the
     *  standard output so that it can be sent to the main process.  we
     *  prefix each line with [xml-PID]
     */
    if(cfg_distributed()) {
      out = fopen(file_name, "r");
      while(getline(&buf, &n, out) != -1) {
	printf("[xml-%d] %s", context_proc_id(), buf);
      }
      free(buf);
      fclose(out);
    }

    /**
     *  free everything
     */
    free(CTX->states_processed);
    free(CTX->states_dead);
    free(CTX->states_accepting);
    free(CTX->arcs);
    free(CTX->evts_exec);
    free(CTX->evts_exec_dd);
    storage_free(CTX->storage);
    free(CTX->workers);
    if(CTX->trace) {
      list_free(CTX->trace);
    }
    if(CTX->faulty_state_found) {
      state_free(CTX->faulty_state);
    }
    pthread_mutex_destroy(&CTX->ctx_mutex);
  }
  
  if(CTX->error_raised) {
    free(CTX->error_msg);
  }
  free(CTX);
}

void context_interruption_handler
(int signal) {
  CTX->term_state = INTERRUPTION;
  CTX->keep_searching = FALSE;
}

void context_stop_search
() {
  CTX->keep_searching = FALSE;
}

void context_faulty_state
(state_t s) {
  pthread_mutex_lock(&CTX->ctx_mutex);
  if(CTX->keep_searching) {
    CTX->faulty_state = state_copy(s);
    CTX->keep_searching = FALSE;
    CTX->term_state = FAILURE;
    CTX->faulty_state_found = TRUE;
  }
  pthread_mutex_unlock(&CTX->ctx_mutex);
}

void context_set_trace
(event_list_t trace) {
  pthread_mutex_lock(&CTX->ctx_mutex);
  if(CTX->keep_searching) {
    CTX->trace = trace;
    CTX->keep_searching = FALSE;
    CTX->term_state = FAILURE;
  }
  pthread_mutex_unlock(&CTX->ctx_mutex);
}

storage_t context_storage
() {
  return CTX->storage;
}

bool_t context_keep_searching
() {
  return CTX->keep_searching;
}

uint16_t context_no_workers
() {
  return CTX->no_workers;
}

pthread_t * context_workers
() {
  return CTX->workers;
}

void context_set_termination_state
(termination_state_t term_state) {
  CTX->term_state = term_state;
  CTX->keep_searching = FALSE;
}

uint64_t context_processed
() {
  return large_sum(CTX->states_processed, CTX->no_workers);
}

struct timeval context_start_time
() {
  return CTX->start_time;
}

FILE * context_open_graph_file
() {
  FILE * result = NULL;
  if(cfg_action_build_graph()) {
    CTX->graph_file = fopen(CFG_GRAPH_FILE, "w");
    result = CTX->graph_file;
  }
  return result;
}

FILE * context_graph_file
() {
  return CTX->graph_file;
}

void context_close_graph_file
() {
  if(CTX->graph_file) {
    fclose(CTX->graph_file);
    CTX->graph_file = NULL;
  }
}

void context_set_comp_time
(float comp_time) {
  CTX->comp_time = comp_time;
}

void context_update_bfs_levels
(unsigned int bfs_levels) {
  CTX->bfs_levels_ok = TRUE;
  if(bfs_levels > CTX->bfs_levels) {
    CTX->bfs_levels = bfs_levels;
  }
}

void context_increase_bytes_sent
(uint32_t bytes) {
  CTX->bytes_sent += bytes;
}

void context_increase_barrier_time
(float time) {
  CTX->barrier_time += time;
}

void context_increase_distributed_barrier_time
(float time) {
  CTX->distributed_barrier_time += time;
}

void context_update_max_states_stored
(uint64_t states_stored) {
  if(CTX->states_max_stored < states_stored) {
    CTX->states_max_stored = states_stored;
  }
}

void context_update_max_mem_used
(float mem) {
  if(CTX->max_mem_used < mem) {
    CTX->max_mem_used = mem;
  }
}

void context_incr_arcs
(worker_id_t w,
 int no) {
  CTX->arcs[w] += no;
}

void context_incr_dead
(worker_id_t w,
 int no) {
  CTX->states_dead[w] += no;
}

void context_incr_accepting
(worker_id_t w,
 int no) {
  CTX->states_accepting[w] += no;
}

void context_incr_processed
(worker_id_t w,
 int no) {
  CTX->states_processed[w] += no;
}

void context_incr_evts_exec
(worker_id_t w,
 int no) {
  CTX->evts_exec[w] += no;
}

void context_incr_evts_exec_dd
(worker_id_t w,
 int no) {
  CTX->evts_exec_dd[w] += no;
}

void context_error
(char * msg) {
  if(CTX->error_raised) {
    free(CTX->error_msg);
  }
  CTX->error_msg = mem_alloc(SYSTEM_HEAP, sizeof(char) * strlen(msg) + 1);
  strcpy(CTX->error_msg, msg);
  if(!cfg_action_simulate()) {
    CTX->term_state = ERROR;
    CTX->keep_searching = FALSE;
  }
  CTX->error_raised = TRUE;
}

void context_flush_error
() {
  if(cfg_action_simulate()) {
    if(CTX->error_raised) {
      mem_free(SYSTEM_HEAP, CTX->error_msg);
    }
    CTX->error_msg = NULL;
  }
  CTX->error_raised = FALSE;
}

bool_t context_error_raised
() {
  return CTX->error_raised;
}

char * context_error_msg
() {
  return CTX->error_msg;
}

uint32_t context_global_worker_id
(worker_id_t w) {
  return context_proc_id() * CTX->no_workers + w;
}

uint32_t context_proc_id
() {
  return comm_shmem_me();
}

float context_cpu_usage
() {
  return cpu_usage(&CTX->cpu_total, &CTX->utime, &CTX->stime);
}

void context_set_avg_cpu_usage
(float avg_cpu_usage) {
  CTX->avg_cpu_usage = avg_cpu_usage;
}

void context_barrier_wait
(pthread_barrier_t * b) {
  lna_timer_t t;
  
  lna_timer_init(&t);
  lna_timer_start(&t);
  pthread_barrier_wait(b);
  lna_timer_stop(&t);
  context_increase_barrier_time(lna_timer_value(t));
}

void context_sleep
(struct timespec t) {
  nanosleep(&t, NULL);
  CTX->sleep_time += t.tv_nsec;
}
