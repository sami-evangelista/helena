#include "context.h"
#include "observer.h"
#include "config.h"
#include "comm_shmem.h"

typedef struct {
  unsigned int no_workers;
  char * error_msg;
  termination_state_t term_state;
  FILE * graph_file;
  storage_t storage;
  bool_t keep_searching;
  bool_t error_raised;
  struct timeval start_time;
  struct timeval end_time;

  /*  for the trace context  */
  bool_t faulty_state_found;
  state_t faulty_state;
  event_list_t trace;
  pthread_mutex_t ctx_mutex;

  /*  statistics field  */
  uint64_t * states_accepting;
  uint64_t * states_visited;
  uint64_t * states_dead;
  uint64_t * arcs;
  uint64_t * evts_exec;
  uint64_t * evts_exec_dd;
  uint64_t * state_cmps;
  uint64_t * bytes_sent;
  uint64_t exec_time;
  uint64_t states_max_stored;
  unsigned int bfs_levels;
  bool_t bfs_levels_ok;
  float max_mem_used;
  float comp_time;
  uint64_t distributed_barrier_time;

  /*  threads  */
  pthread_t observer;
  pthread_t * workers;
} struct_context_t;

typedef struct_context_t * context_t;

context_t CTX;

void context_init
(unsigned int no_workers) {
  unsigned int i;

  CTX = mem_alloc(SYSTEM_HEAP, sizeof(struct_context_t));
  
  CTX->error_msg = NULL;
  CTX->error_raised = FALSE;

#if !defined(CFG_ACTION_SIMULATE)
  
  /*
   *  initialisation of statistic related fields
   */
  CTX->states_visited =
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
  CTX->state_cmps =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  CTX->bytes_sent =
    mem_alloc(SYSTEM_HEAP, (no_workers + 1) * sizeof(uint64_t));
  for(i = 0; i < no_workers; i ++) {
    CTX->states_visited[i] = 0;
    CTX->states_accepting[i] = 0;
    CTX->states_dead[i] = 0;
    CTX->arcs[i] = 0;
    CTX->evts_exec[i] = 0;
    CTX->evts_exec_dd[i] = 0;
    CTX->state_cmps[i] = 0;
  }
  for(i = 0; i < no_workers + 1; i ++) {
    CTX->bytes_sent[i] = 0;
  }
  CTX->bfs_levels = 0;
  CTX->bfs_levels_ok = FALSE;
  CTX->max_mem_used = 0.0;
  CTX->states_max_stored = 0;
  CTX->comp_time = 0.0;
  CTX->distributed_barrier_time = 0;

  CTX->no_workers = no_workers;
  CTX->storage = storage_new();
  CTX->faulty_state_found = FALSE;
  CTX->trace = NULL;
  CTX->keep_searching = TRUE;
  gettimeofday(&CTX->start_time, NULL);
  CTX->graph_file = NULL;
#if defined(CFG_PROPERTY)
#if defined(CFG_HASH_COMPACTION)
  CTX->term_state = NO_ERROR;
#else
  CTX->term_state = SUCCESS;
#endif
#else
  CTX->term_state = SEARCH_TERMINATED;
#endif

  /*
   *  launch the observer thread
   */
  pthread_create(&CTX->observer, NULL, &observer_start, (void *) CTX);
  CTX->workers = mem_alloc(SYSTEM_HEAP, sizeof(pthread_t) * CTX->no_workers);
  pthread_mutex_init(&CTX->ctx_mutex, NULL);
#endif
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
#if defined(CFG_TRACE_FULL)
        state_to_xml(s, out);
#endif
      }
      event_free(e);
    }
#if defined(CFG_TRACE_EVENTS)
    if(l > 0) {
      state_to_xml(s, out);
    }
#endif
  }
  state_free(s);
}


void context_finalise
() {
  FILE * out;
  void * dummy;
  uint64_t ssize;
  uint64_t sum_visited;
  uint64_t min_visited;
  uint64_t max_visited;
  uint64_t avg_visited;
  uint64_t dev_visited;
  worker_id_t w;
  char name[1024], file_name[1024];
  char * buf = NULL;
  size_t n = 0;
  int i;
  
#if !defined(CFG_ACTION_SIMULATE)
  if(NULL != CTX->graph_file) {
    fclose(CTX->graph_file);
  }
  CTX->keep_searching = FALSE;
  gettimeofday(&CTX->end_time, NULL);
  CTX->exec_time = duration(CTX->start_time, CTX->end_time);
  pthread_join(CTX->observer, &dummy);
#if defined(CFG_DISTRIBUTED)
  sprintf(file_name, "%s.%d", CFG_REPORT_FILE, proc_id());
  out = fopen(file_name, "w");
#else
  out = fopen(CFG_REPORT_FILE, "w");
#endif
  fprintf(out, "<helenaReport>\n");

  /**
   *  info context
   ***/
  fprintf(out, "<infoReport>\n");
  fprintf(out, "<model>%s</model>\n", model_name());
  model_xml_parameters(out);
#if defined(CFG_LANGUAGE)
  fprintf(out, "<language>%s</language>\n", CFG_LANGUAGE);
#endif
#if defined(CFG_DATE)
  fprintf(out, "<date>%s</date>\n", CFG_DATE);
#endif
#if defined(CFG_FILE_PATH)
  fprintf(out, "<filePath>%s</filePath>\n", CFG_FILE_PATH);
#endif
  gethostname(name, 1024);
  fprintf(out, "<host>%s (pid = %d)</host>\n", name, getpid());
  fprintf(out, "</infoReport>\n");

  /**
   *  search context
   ***/
  fprintf(out, "<searchReport>\n");
#if defined(CFG_PROPERTY)
  fprintf(out, "<property>%s</property>\n", CFG_PROPERTY);
#endif
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
#if defined(CFG_ALGO_DFS)
  fprintf(out, "<depthSearch/>\n");
#elif defined(CFG_ALGO_DDFS)
  fprintf(out, "<distributedDepthSearch/>\n");
#elif defined(CFG_ALGO_BFS)
  fprintf(out, "<breadthSearch/>\n");
#elif defined(CFG_ALGO_FRONTIER)
  fprintf(out, "<frontierSearch/>\n");
#elif defined(CFG_ALGO_RWALK)
  fprintf(out, "<randomWalk/>\n");
#elif defined(CFG_ALGO_DELTA_DDD)
  fprintf(out, "<parallelDDDD/>\n");
#endif
#if defined(CFG_NO_WORKERS)
  fprintf(out, "<workers>%d</workers>\n", CFG_NO_WORKERS);
#endif
  fprintf(out, "<searchOptions>\n");
#if defined(CFG_HASH_STORAGE) || defined(CFG_DELTA_DDD_STORAGE)
  fprintf(out, "<hashTableSlots>%d</hashTableSlots>\n", CFG_HASH_SIZE);
#endif
#if defined(CFG_HASH_COMPACTION)
  fprintf(out, "<hashCompact/>\n");
#endif
#if defined(CFG_POR)
  fprintf(out, "<partialOrder/>\n");
#endif
#if defined(CFG_STATE_CACHING)
  fprintf(out, "<stateCaching/>\n");
#endif
#if defined(CFG_ALGO_DELTA_DDD)
  fprintf(out, "<candidateSetSize>%d</candidateSetSize>\n",
          CFG_DELTA_DDD_CAND_SET_SIZE);
#endif
  fprintf(out, "</searchOptions>\n");
  fprintf(out, "</searchReport>\n");

  /**
   *  statistics context
   ***/
  fprintf(out, "<statisticsReport>\n");
  
  /*  model */
  model_xml_statistics(out);
  
  /*  time  */
  fprintf(out, "<timeStatistics>\n");
  if(CTX->comp_time > 0) {
    fprintf(out, "<compilationTime>%.2f</compilationTime>\n", CTX->comp_time);
  }
  fprintf(out, "<searchTime>%.2f</searchTime>\n", CTX->exec_time / 1000000.0);
#if defined(CFG_ALGO_DELTA_DDD)
  fprintf(out, "<duplicateDetectionTime>%.2f</duplicateDetectionTime>\n",
          storage_dd_time(CTX->storage) / 1000000.0);
  fprintf(out, "<barrierTime>%.2f</barrierTime>\n",
          storage_barrier_time(CTX->storage) / 1000000.0);
#endif
#if defined(CFG_DISTRIBUTED)
  fprintf(out, "<distributedBarrierTime>");
  fprintf(out, "%.2f</distributedBarrierTime>\n",
	  CTX->distributed_barrier_time / 1000000.0);
#endif
#if defined(CFG_STATE_CACHING)
  fprintf(out, "<garbageCollectionTime>");
  fprintf(out, "%.2f</garbageCollectionTime>\n",
	  storage_gc_time(CTX->storage) / 1000000.0);
#endif
  fprintf(out, "</timeStatistics>\n");
  
  /*  reachability graph  */
  fprintf(out, "<graphStatistics>\n");
  ssize = storage_size(CTX->storage);
  fprintf(out, "<statesStored>%llu</statesStored>\n", ssize);
  fprintf(out, "<statesMaxStored>%llu</statesMaxStored>\n",
	  (ssize > CTX->states_max_stored) ? ssize : CTX->states_max_stored);
  sum_visited = large_sum(CTX->states_visited, CTX->no_workers);
  fprintf(out, "<statesExpanded>%llu</statesExpanded>\n", sum_visited);
#if defined(CFG_PARALLEL)
  min_visited = CTX->states_visited[0];
  max_visited = CTX->states_visited[0];
  avg_visited = sum_visited / CFG_NO_WORKERS;
  dev_visited = 0;
  for(w = 1; w < CFG_NO_WORKERS; w ++) {
    if(CTX->states_visited[w] > max_visited) {
      max_visited = CTX->states_visited[w];
    } else if(CTX->states_visited[w] < min_visited) {
      min_visited = CTX->states_visited[w];
    }
    dev_visited += (CTX->states_visited[w] - avg_visited)
      * (CTX->states_visited[w] - avg_visited);
  }
  dev_visited = sqrt(dev_visited / CFG_NO_WORKERS);
  fprintf(out, "<statesExpandedMin>%llu</statesExpandedMin>\n", min_visited);
  fprintf(out, "<statesExpandedMax>%llu</statesExpandedMax>\n", max_visited);
  fprintf(out, "<statesExpandedDev>%llu</statesExpandedDev>\n", dev_visited);
#endif
#if defined(CFG_ACTION_CHECK_LTL)
  fprintf(out, "<statesAccepting>%llu</statesAccepting>\n",
          large_sum(CTX->states_accepting, CTX->no_workers));
#endif
  fprintf(out, "<statesTerminal>%llu</statesTerminal>\n",
          large_sum(CTX->states_dead, CTX->no_workers));
  fprintf(out, "<arcs>%llu</arcs>\n",
          large_sum(CTX->arcs, CTX->no_workers));
  if(CTX->bfs_levels_ok) {
    fprintf(out, "<bfsLevels>%u</bfsLevels>\n", CTX->bfs_levels);
  }
  fprintf(out, "</graphStatistics>\n");
  
  /*  storage statistics  */
#if defined(CFG_HASH_STORAGE) || defined(CFG_DELTA_DDD_STORAGE)
  storage_output_stats(CTX->storage, out);
#endif
  
  /*  others  */
  fprintf(out, "<otherStatistics>\n");
  fprintf(out, "<maxMemoryUsed>%.1f</maxMemoryUsed>\n",
          CTX->max_mem_used);
  fprintf(out, "<eventsExecuted>%llu</eventsExecuted>\n",
          large_sum(CTX->evts_exec, CTX->no_workers));
#if defined(CFG_ALGO_DELTA_DDD)
  fprintf(out, "<eventsExecutedDDD>%llu</eventsExecutedDDD>\n",
          large_sum(CTX->evts_exec_dd, CTX->no_workers));
  fprintf(out, "<eventsExecutedExpansion>%llu</eventsExecutedExpansion>\n",
          large_sum(CTX->evts_exec, CTX->no_workers) -
          large_sum(CTX->evts_exec_dd, CTX->no_workers));
#endif
#if defined(CFG_ALGO_RWALK)
  fprintf(out, "<eventExecPerSecond>%d</eventExecPerSecond>\n",
	  (unsigned int)(1.0 * sum_visited / (CTX->exec_time / 1000000.0)));
#endif
#if defined(CFG_DISTRIBUTED)
  fprintf(out, "<bytesSend>%llu</bytesSend>\n",
	  large_sum(CTX->bytes_sent, CTX->no_workers + 1));
#endif
  fprintf(out, "</otherStatistics>\n");
  fprintf(out, "</statisticsReport>\n");

  /**
   *  trace context
   ***/
  if(CTX->term_state == FAILURE) {
    fprintf(out, "<traceReport>\n");
#if defined(CFG_TRACE_STATE)
    fprintf(out, "<traceState>\n");
    state_to_xml(CTX->faulty_state, out);
    fprintf(out, "</traceState>\n");
#elif defined(CFG_TRACE_FULL)
    fprintf(out, "<traceFull>\n");
    context_output_trace(out);
    fprintf(out, "</traceFull>\n");
#elif defined(CFG_TRACE_EVENTS)
    fprintf(out, "<traceEvents>\n");
    context_output_trace(out);
    fprintf(out, "</traceEvents>\n");
#endif
    fprintf(out, "</traceReport>\n");  
  }
  fprintf(out, "</helenaReport>\n");
  fclose(out);

  /**
   *  in distributed mode the context file must be printed to the
   *  standard output so that it can be sent to the main process.  we
   *  prefix each line with [xml-PID]
   */
#if defined(CFG_DISTRIBUTED)
  out = fopen(file_name, "r");
  while(getline(&buf, &n, out) != -1) {
    printf("[xml-%d] %s", proc_id(), buf);
  }
  free(buf);
  fclose(out);
#endif

  /**
   *  free everything
   */
  free(CTX->states_visited);
  free(CTX->states_dead);
  free(CTX->states_accepting);
  free(CTX->arcs);
  free(CTX->evts_exec);
  free(CTX->evts_exec_dd);
  free(CTX->state_cmps);
  free(CTX->bytes_sent);
  storage_free(CTX->storage);
  free(CTX->workers);
  if(CTX->trace) {
    list_free(CTX->trace);
  }
  if(CTX->faulty_state_found) {
    state_free(CTX->faulty_state);
  }
  pthread_mutex_destroy(&CTX->ctx_mutex);  
#endif /*  !defined(CFG_ACTION_SIMULATE) */
  
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

uint64_t context_visited
() {
  return large_sum(CTX->states_visited, CTX->no_workers);
}

struct timeval context_start_time
() {
  return CTX->start_time;
}

FILE * context_open_graph_file
() {
  FILE * result = NULL;
#if defined(CFG_ACTION_BUILD_GRAPH)
  CTX->graph_file = fopen(CFG_GRAPH_FILE, "w");
  result = CTX->graph_file;
#endif
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
(worker_id_t w,
 uint32_t bytes) {
  CTX->bytes_sent[w] += bytes;
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

void context_incr_visited
(worker_id_t w,
 int no) {
  CTX->states_visited[w] += no;
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
#if !defined(CFG_ACTION_SIMULATE)
  CTX->term_state = ERROR;
  CTX->keep_searching = FALSE;
#endif
  CTX->error_raised = TRUE;
}

void context_flush_error
() {
#if defined(CFG_ACTION_SIMULATE)
  if(CTX->error_raised) {
    mem_free(SYSTEM_HEAP, CTX->error_msg);
  }
  CTX->error_msg = NULL;
#endif
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
  return context_proc_id() * CFG_NO_WORKERS + w;
}

uint32_t context_proc_id
() {
  uint32_t result;
  
#if defined(CFG_DISTRIBUTED)
  result = comm_shmem_me();
#else
  result = 0;
#endif
  return result;
}
