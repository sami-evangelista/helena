#include "report.h"
#include "observer.h"

report_t report_new
(unsigned int no_workers) {
  report_t result;
  unsigned int i;

  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_report_t));

  /*
   *  initialisation of statistic related fields
   */
  result->states_visited =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  result->states_dead =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  result->states_accepting =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  result->arcs =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  result->events_executed =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  result->events_executed_dd =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  result->state_cmps =
    mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  for(i = 0; i < no_workers; i ++) {
    result->states_visited[i] = 0;
    result->states_accepting[i] = 0;
    result->states_dead[i] = 0;
    result->arcs[i] = 0;
    result->events_executed[i] = 0;
    result->events_executed_dd[i] = 0;
    result->state_cmps[i] = 0;
  }
  result->bfs_levels = 0;
  result->bfs_levels_ok = FALSE;
  result->max_mem_used = 0.0;
  result->states_max_stored = 0;
  result->comp_time = 0.0;
  result->distributed_barrier_time = 0;

  result->no_workers = no_workers;
  result->storage = storage_new();
  result->faulty_state_found = FALSE;
  result->trace = NULL;
  result->trace_len = 0;
  result->error_msg = NULL;
  result->errors = 0;
  result->keep_searching = TRUE;
  gettimeofday(&result->start_time, NULL);
  result->graph_file = NULL;
#if defined(CFG_PROPERTY)
#if defined(CFG_HASH_COMPACTION)
  result->result = NO_ERROR;
#else
  result->result = SUCCESS;
#endif
#else
  result->result = SEARCH_TERMINATED;
#endif

  /*
   *  launch the observer thread
   */
#if defined(CFG_WITH_OBSERVER)
  pthread_create(&result->observer, NULL, &observer_start,
		 (void *) result);
#else
  result->observer = NULL;
#endif
  
  result->workers =
    mem_alloc(SYSTEM_HEAP, sizeof(pthread_t) * result->no_workers);
  return result;
}

void report_free
(report_t report) {
  unsigned int i;
  free(report->states_visited);
  free(report->states_dead);
  free(report->states_accepting);
  free(report->arcs);
  free(report->events_executed);
  free(report->events_executed_dd);
  free(report->state_cmps);
  storage_free(report->storage);
  if(report->error_msg) {
    free(report->error_msg);
  }
  free(report->workers);
  if(report->trace) {
    free(report->trace);
  }
  if(report->faulty_state_found) {
    state_free(report->faulty_state);
  }
  free(report);
}



/*****
 *
 *  Function: report_output_trace
 *
 *****/
void report_output_trace
(report_t r,
 FILE * out) {
  unsigned int i = 0;
  state_t s = state_initial();
  
  state_to_xml(s, out);
  for(i = 0; i < r->trace_len; i ++) {
    if(!event_is_dummy(r->trace[i])) {
      event_to_xml(r->trace[i], out);
      event_exec(r->trace[i], s);
#if defined(CFG_TRACE_FULL)
      state_to_xml(s, out);
#endif
    }
  }
#if defined(CFG_TRACE_EVENTS)
  if(r->trace_len > 0) {
    state_to_xml(s, out);
  }
#endif
  state_free(s);
}



/*****
 *
 *  Function: report_finalise
 *
 *****/
void report_finalise
(report_t r) {
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
  
  if(NULL != r->graph_file) {
    fclose(r->graph_file);
  }
  r->keep_searching = FALSE;
  gettimeofday(&r->end_time, NULL);
  r->exec_time = duration(r->start_time, r->end_time);
#if defined(CFG_WITH_OBSERVER)
  pthread_join(r->observer, &dummy);
#endif
#if defined(CFG_DISTRIBUTED)
  sprintf(file_name, "%s.%d", CFG_REPORT_FILE, proc_id());
  out = fopen(file_name, "w");
#else
  out = fopen(CFG_REPORT_FILE, "w");
#endif
  fprintf(out, "<helenaReport>\n");

  /**
   *  info report
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
   *  search report
   ***/
  fprintf(out, "<searchReport>\n");
#if defined(CFG_PROPERTY)
  fprintf(out, "<property>%s</property>\n", CFG_PROPERTY);
#endif
  fprintf(out, "<searchResult>");
  switch(r->result) {
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
  if(r->result == ERROR) {
    fprintf(out, "<errorMessage>%s</errorMessage>\n", r->error_msg);
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
#if defined(CFG_ALGO_DELTA_DDD)
  fprintf(out, "<candidateSetSize>%d</candidateSetSize>\n",
          CFG_DELTA_DDD_CAND_SET_SIZE);
#endif
  fprintf(out, "</searchOptions>\n");
  fprintf(out, "</searchReport>\n");

  /**
   *  statistics report
   ***/
  fprintf(out, "<statisticsReport>\n");
  
  /*  model */
  model_xml_statistics(out);
  
  /*  time  */
  fprintf(out, "<timeStatistics>\n");
  if(r->comp_time > 0) {
    fprintf(out, "<compilationTime>%.2f</compilationTime>\n", r->comp_time);
  }
  fprintf(out, "<searchTime>%.2f</searchTime>\n", r->exec_time / 1000000.0);
#if defined(CFG_ALGO_DELTA_DDD)
  fprintf(out, "<duplicateDetectionTime>%.2f</duplicateDetectionTime>\n",
          r->storage->dd_time / 1000000.0);
  fprintf(out, "<barrierTime>%.2f</barrierTime>\n",
          do_large_sum(r->storage->barrier_time, r->no_workers) / 1000000.0);
#endif
#if defined(CFG_DISTRIBUTED)
  fprintf(out, "<distributedBarrierTime>");
  fprintf(out, "%.2f</distributedBarrierTime>\n",
	  r->distributed_barrier_time / 1000000.0);
#endif
#if defined(CFG_STATE_CACHING)
  fprintf(out, "<garbageCollectionTime>");
  fprintf(out, "%.2f</garbageCollectionTime>\n",
	  r->storage->gc_time / 1000000.0);
#endif
  fprintf(out, "</timeStatistics>\n");
  
  /*  reachability graph  */
  fprintf(out, "<graphStatistics>\n");
  ssize = storage_size(r->storage);
  fprintf(out, "<statesStored>%llu</statesStored>\n", ssize);
  fprintf(out, "<statesMaxStored>%llu</statesMaxStored>\n",
	  (ssize > r->states_max_stored) ? ssize : r->states_max_stored);
  sum_visited = do_large_sum(r->states_visited, r->no_workers);
  fprintf(out, "<statesExpanded>%llu</statesExpanded>\n", sum_visited);
#if defined(CFG_PARALLEL)
  min_visited = r->states_visited[0];
  max_visited = r->states_visited[0];
  avg_visited = sum_visited / CFG_NO_WORKERS;
  dev_visited = 0;
  for(w = 1; w < CFG_NO_WORKERS; w ++) {
    if(r->states_visited[w] > max_visited) {
      max_visited = r->states_visited[w];
    } else if(r->states_visited[w] < min_visited) {
      min_visited = r->states_visited[w];
    }
    dev_visited += (r->states_visited[w] - avg_visited)
      * (r->states_visited[w] - avg_visited);
  }
  dev_visited = sqrt(dev_visited / CFG_NO_WORKERS);
  fprintf(out, "<statesExpandedMin>%llu</statesExpandedMin>\n", min_visited);
  fprintf(out, "<statesExpandedMax>%llu</statesExpandedMax>\n", max_visited);
  fprintf(out, "<statesExpandedDev>%llu</statesExpandedDev>\n", dev_visited);
#endif
#if defined(CFG_ACTION_CHECK_LTL)
  fprintf(out, "<statesAccepting>%llu</statesAccepting>\n",
          do_large_sum(r->states_accepting, r->no_workers));
#endif
  fprintf(out, "<statesTerminal>%llu</statesTerminal>\n",
          do_large_sum(r->states_dead, r->no_workers));
  fprintf(out, "<arcs>%llu</arcs>\n",
          do_large_sum(r->arcs, r->no_workers));
  if(r->bfs_levels_ok) {
    fprintf(out, "<bfsLevels>%u</bfsLevels>\n", r->bfs_levels);
  }
  fprintf(out, "</graphStatistics>\n");
  
  /*  storage statistics  */
#if defined(CFG_HASH_STORAGE) || defined(CFG_DELTA_DDD_STORAGE)
  storage_output_stats(r->storage, out);
#endif
  
  /*  others  */
  fprintf(out, "<otherStatistics>\n");
  fprintf(out, "<maxMemoryUsed>%.1f</maxMemoryUsed>\n",
          r->max_mem_used);
  fprintf(out, "<eventsExecuted>%llu</eventsExecuted>\n",
          do_large_sum(r->events_executed, r->no_workers));
#if defined(CFG_ALGO_DELTA_DDD)
  fprintf(out, "<eventsExecutedDDD>%llu</eventsExecutedDDD>\n",
          do_large_sum(r->events_executed_dd, r->no_workers));
  fprintf(out, "<eventsExecutedExpansion>%llu</eventsExecutedExpansion>\n",
          do_large_sum(r->events_executed, r->no_workers) -
          do_large_sum(r->events_executed_dd, r->no_workers));
#endif
#if defined(CFG_ALGO_RWALK)
  fprintf(out, "<eventExecPerSecond>%d</eventExecPerSecond>\n",
	  (unsigned int)(1.0 * visited /(r->exec_time / 1000000.0)));
#endif
  fprintf(out, "</otherStatistics>\n");
  fprintf(out, "</statisticsReport>\n");

  /**
   *  trace report
   ***/
  if(r->result == FAILURE) {
    fprintf(out, "<traceReport>\n");
#if    defined(CFG_TRACE_STATE)
    fprintf(out, "<traceState>\n");
    state_to_xml(r->faulty_state, out);
    fprintf(out, "</traceState>\n");
#elif defined(CFG_TRACE_FULL)
    fprintf(out, "<traceFull>\n");
    report_output_trace(r, out);
    fprintf(out, "</traceFull>\n");
#elif defined(CFG_TRACE_EVENTS)
    fprintf(out, "<traceEvents>\n");
    report_output_trace(r, out);
    fprintf(out, "</traceEvents>\n");
#endif
    fprintf(out, "</traceReport>\n");  
  }
  fprintf(out, "</helenaReport>\n");
  fclose(out);

  /**
   *  in distributed mode the report file must be printed to the
   *  standard output so that it can be sent to the main process
   */
#if defined(CFG_DISTRIBUTED)
  out = fopen(file_name, "r");
  while(getline(&buf, &n, out) != -1) {
    printf("[xml-%d] %s", proc_id(), buf);
  }
  free(buf);
  fclose(out);
#endif
}

void report_interruption_handler
(int signal) {
  glob_report->result = INTERRUPTION;
  report_stop_search();
}

bool_t report_error
(char * msg) {
  if(glob_report->result != ERROR) {
    glob_report->result = ERROR;
    if(!glob_report->error_msg) {
      glob_report->error_msg =
	mem_alloc(SYSTEM_HEAP, sizeof(char) * strlen(msg) + 1);
      strcpy(glob_report->error_msg, msg);
    }
    glob_report->errors = 1;
    glob_report->keep_searching = FALSE;
  }
  glob_report->keep_searching = FALSE;
  return TRUE;
}

void report_stop_search
() {
  glob_report->keep_searching = FALSE;
}

void report_set_comp_time
(report_t r,
 float comp_time) {
  r->comp_time = comp_time;
}

void report_update_bfs_levels
(report_t r,
 unsigned int bfs_levels) {
  r->bfs_levels_ok = TRUE;
  if(bfs_levels > r->bfs_levels) {
    r->bfs_levels = bfs_levels;
  }
}

void report_faulty_state
(report_t r,
 state_t s) {
  r->faulty_state = state_copy(s);
  r->keep_searching = FALSE;
  r->result = FAILURE;
  r->faulty_state_found = TRUE;
}
