#include "compression.h"
#include "dist_compression.h"
#include "context.h"
#include "observer.h"
#include "config.h"
#include "comm.h"
#include "papi_stats.h"

#define NO_STATS 12

typedef enum {
  STAT_TYPE_TIME,
  STAT_TYPE_GRAPH,
  STAT_TYPE_OTHERS
} stat_type_t;

typedef struct {
  struct timeval start_time;
  struct timeval end_time;
  unsigned int no_workers;
  unsigned long cpu_total;
  unsigned long utime;
  unsigned long stime;
  bool_t keep_searching;
  bool_t error_raised;
  FILE * graph_file;
  char * error_msg;
  term_state_t term_state;

  /*  for the trace context  */
  bool_t faulty_state_found;
  state_t faulty_state;
  event_list_t trace;
  pthread_mutex_t ctx_mutex;

  /*  statistics field  */
  uint64_t * stat[NO_STATS];
  bool_t stat_set[NO_STATS];

  /*  threads  */
  pthread_t observer;
  pthread_t * workers;
} struct_context_t;

typedef struct_context_t * context_t;

context_t CTX;

void init_context
() {
  worker_id_t w;
  unsigned int i;
  unsigned int no_workers = CFG_NO_WORKERS;
  
  CTX = mem_alloc(SYSTEM_HEAP, sizeof(struct_context_t));
  
  CTX->error_msg = NULL;
  CTX->error_raised = FALSE;

  if(CFG_ACTION_SIMULATE) {
    return;
  }
  
  /*
   * initialisation of statistic related fields
   */
  for(i = 0; i < NO_STATS; i ++) {
    CTX->stat_set[i] = FALSE;
    CTX->stat[i] = mem_alloc(SYSTEM_HEAP, no_workers * sizeof(double));
    for(w = 0; w < no_workers; w ++) {
      CTX->stat[i][w] = 0.0;
    }
  }

  /*
   * statistics that must be outputed must be set to 0 to appear in
   * the report
   */
  context_set_stat(STAT_STATES_STORED, 0, 0);
  context_set_stat(STAT_STATES_DEADLOCK, 0, 0);
  if(CFG_ACTION_CHECK_LTL) {
    context_set_stat(STAT_STATES_ACCEPTING, 0, 0);
  }
  
  CTX->no_workers = no_workers;
  CTX->faulty_state_found = FALSE;
  CTX->trace = NULL;
  CTX->keep_searching = TRUE;
  gettimeofday(&CTX->start_time, NULL);
  CTX->graph_file = NULL;
  if(!CFG_ACTION_CHECK) {
    CTX->term_state = TERM_SEARCH_TERMINATED;
  } else {
    if(CFG_HASH_COMPACTION) {
      CTX->term_state = TERM_NO_ERROR;
    } else {
      CTX->term_state = TERM_SUCCESS;
    }
  }
  CTX->cpu_total = 0;
  CTX->utime = 0;
  CTX->stime = 0;
  cpu_usage(&CTX->cpu_total, &CTX->utime, &CTX->stime);
  
  /*
   * launch the observer thread
   */
  pthread_create(&CTX->observer, NULL, &observer_worker, (void *) CTX);
  CTX->workers = mem_alloc(SYSTEM_HEAP, sizeof(pthread_t) * CTX->no_workers);
  pthread_mutex_init(&CTX->ctx_mutex, NULL);
}

#define context_state_to_xml(s, out) {          \
    fprintf(out, "<state>\n");                  \
    state_to_xml(s, out);                       \
    fprintf(out, "</state>\n");                 \
  }

#define context_event_to_xml(e, out) {          \
    fprintf(out, "<event>\n");                  \
    event_to_xml(e, out);                       \
    fprintf(out, "</event>\n");                 \
  }

void context_output_trace
(FILE * out) {
  event_t e;
  state_t s = state_initial(SYSTEM_HEAP);
  list_iter_t it;

  if(CTX->trace) {
    if(list_size(CTX->trace) > CFG_MAX_TRACE_LENGTH) {
      fprintf(out, "<traceTooLong/>\n");
    } else {
      context_state_to_xml(s, out);
      for(it = list_get_iter(CTX->trace);
          !list_iter_at_end(it);
          it = list_iter_next(it)) {
        e = * ((event_t *) list_iter_item(it));
        if(!event_is_dummy(e)) {
          context_event_to_xml(e, out);
          event_exec(e, s);
          if(CFG_TRACE_FULL) {
            context_state_to_xml(s, out);
          }
        }
      }
      if(CFG_TRACE_EVENTS && !list_is_empty(CTX->trace) > 0) {
        context_state_to_xml(s, out);
      }
    }
  }
  state_free(s);
}

bool_t context_stat_is_list
(stat_t stat) {
  switch(stat) {
  case STAT_STATES_PROCESSED: return TRUE;
  default:                    return FALSE;
  }
}

char * context_stat_xml_name
(stat_t stat) {
  switch(stat) {
  case STAT_STATES_STORED:      return "statesStored";
  case STAT_STATES_PROCESSED:   return "statesProcessed";
  case STAT_STATES_DEADLOCK:    return "statesTerminal";
  case STAT_STATES_ACCEPTING:   return "statesAccepting";
  case STAT_STATES_REDUCED:     return "statesReduced";
  case STAT_ARCS:               return "arcs";
  case STAT_EVENT_EXEC:         return "eventsExecuted";
  case STAT_SHMEM_COMMS:        return "shmemComms";
  case STAT_AVG_CPU_USAGE:      return "avgCPUUsage";
  case STAT_TIME_SEARCH:        return "searchTime";
  case STAT_TIME_COMP:          return "compilationTime";
  case STAT_BWALK_ITERATIONS:   return "bwalkIterations";
  default:
    assert(FALSE);
  }
}

stat_type_t context_stat_type
(stat_t stat) {
  switch(stat) {
  case STAT_STATES_STORED:      return STAT_TYPE_GRAPH;
  case STAT_STATES_PROCESSED:   return STAT_TYPE_GRAPH;
  case STAT_STATES_DEADLOCK:    return STAT_TYPE_GRAPH;
  case STAT_STATES_ACCEPTING:   return STAT_TYPE_GRAPH;
  case STAT_STATES_REDUCED:     return STAT_TYPE_GRAPH;
  case STAT_ARCS:               return STAT_TYPE_GRAPH;
  case STAT_EVENT_EXEC:         return STAT_TYPE_OTHERS;
  case STAT_SHMEM_COMMS:        return STAT_TYPE_OTHERS;
  case STAT_AVG_CPU_USAGE:      return STAT_TYPE_OTHERS;
  case STAT_BWALK_ITERATIONS:   return STAT_TYPE_OTHERS;
  case STAT_TIME_SEARCH:        return STAT_TYPE_TIME;
  case STAT_TIME_COMP:          return STAT_TYPE_TIME;
  default:
    assert(FALSE);
  }
}

void context_stat_to_xml
(uint8_t stat,
 FILE * out) {
  char * name = context_stat_xml_name(stat);
  double val = context_get_stat(stat);
  worker_id_t w;
  
  fprintf(out, "<%s>", name);
  if(STAT_AVG_CPU_USAGE == stat) {
    fprintf(out, "%.2lf", val);
  } else if(STAT_TYPE_TIME == context_stat_type(stat)) {
    fprintf(out, "%.2lf", val / 1000000000.0);
  } else {
    fprintf(out, "%llu", (uint64_t) val);
  }
  fprintf(out, "</%s>", name);
}

void context_stats_to_xml
(stat_type_t stat_type,
 FILE * out) {
  int i;

  for(i = 0; i < NO_STATS; i ++) {
    if(CTX->stat_set[i] && context_stat_type(i) == stat_type) {
      context_stat_to_xml(i, out);
    }
  }
}

void finalise_context
() {
  FILE * out;
  void * dummy;
  char name[1024], file_name[1024];
  char * buf = NULL;
  size_t n = 0;
  int i;

  /**
   *  context already finalised
   */
  if(!CTX) {
    return;
  }

  if(!CFG_ACTION_SIMULATE) {
    gettimeofday(&CTX->end_time, NULL);
    context_set_stat(STAT_TIME_SEARCH, 0,
                     duration(CTX->start_time, CTX->end_time));
    CTX->keep_searching = FALSE;
    pthread_join(CTX->observer, &dummy);
    if(NULL != CTX->graph_file) {
      fclose(CTX->graph_file);
    }

    /**
     *  make the report
     */
    if(CFG_DISTRIBUTED) {
      sprintf(file_name, "%s.%d", CFG_REPORT_FILE, context_proc_id());
      out = fopen(file_name, "w");
    } else {
      out = fopen(CFG_REPORT_FILE, "w");
    }
    fprintf(out, "<helenaReport>\n");
    fprintf(out, "<infoReport>\n");
    fprintf(out, "<model>%s</model>\n", model_name());
#if defined(MODEL_HAS_XML_PARAMETERS)
    model_xml_parameters(out);
#endif
    fprintf(out, "<language>%s</language>\n", CFG_LANGUAGE);
    fprintf(out, "<date>%s</date>\n", CFG_DATE);
    fprintf(out, "<filePath>%s</filePath>\n", CFG_FILE_PATH);
    fprintf(out, "</infoReport>\n");
    fprintf(out, "<searchReport>\n");
    fprintf(out, "<action>");
    if(CFG_ACTION_BUILD_GRAPH) {
      fprintf(out, "buildGraph");
    } else if(CFG_ACTION_CHECK) {
      fprintf(out, "check");
    } else if(CFG_ACTION_EXPLORE) {
      fprintf(out, "explore");
    }
    fprintf(out, "</action>\n");
    if(strcmp("", CFG_PROPERTY)) {
      fprintf(out, "<property>%s</property>\n", CFG_PROPERTY);
    }
    gethostname(name, 1024);
    fprintf(out, "<host>%s (pid = %d)</host>\n", name, getpid());
    fprintf(out, "<searchResult>");
    switch(CTX->term_state) {
    case TERM_STATE_LIMIT_REACHED:
      fprintf(out, "stateLimitReached"); break;
    case TERM_TIME_ELAPSED:
      fprintf(out, "timeElapsed"); break;
    case TERM_INTERRUPTION:
      fprintf(out, "interruption"); break;
    case TERM_SEARCH_TERMINATED:
      fprintf(out, "searchTerminated"); break;
    case TERM_NO_ERROR:
      fprintf(out, "noCounterExample"); break;
    case TERM_SUCCESS:
      fprintf(out, "propertyHolds"); break;
    case TERM_FAILURE:
      fprintf(out, "propertyViolated"); break;
    case TERM_ERROR:
      fprintf(out, "error"); break;
    }
    fprintf(out, "</searchResult>\n");
    if(CTX->term_state == TERM_ERROR && CTX->error_raised && CTX->error_msg) {
      fprintf(out, "<errorMessage>%s</errorMessage>\n", CTX->error_msg);
    }
    fprintf(out, "<searchOptions>\n");
    fprintf(out, "<searchAlgorithm>");
    if(CFG_ALGO_DFS || CFG_ALGO_TARJAN) {
      fprintf(out, "DFS");
    } else if(CFG_ALGO_BFS) {
      fprintf(out, "BFS");
    } else if(CFG_ALGO_DBFS) {
      fprintf(out, "DBFS");
    } else if(CFG_ALGO_RWALK) {
      fprintf(out, "RWALK");
    } else if(CFG_ALGO_BWALK) {
      fprintf(out, "BWALK");
    } else if(CFG_ALGO_DELTA_DDD) {
      fprintf(out, "DELTA-DDD");
    }
    fprintf(out, "</searchAlgorithm>\n");
    fprintf(out,
            "<partialOrder>%s</partialOrder>\n",
            CFG_POR ? "on" : "off");
    if(CFG_POR) {
      fprintf(out,
              "<partialOrderProviso>%s</partialOrderProviso>\n",
              CFG_PROVISO ? "on" : "off");      
    }
    fprintf(out,
            "<hashCompaction>%s</hashCompaction>\n",
            CFG_HASH_COMPACTION ? "on" : "off");
    fprintf(out,
            "<stateCompression>%s</stateCompression>\n",
            CFG_STATE_COMPRESSION ? "on" : "off");
    if(CFG_DISTRIBUTED) {
      fprintf(out,
              "<distributedStateCompression>%s</distributedStateCompression>\n",
              CFG_DISTRIBUTED_STATE_COMPRESSION ? "on" : "off");
    }
    fprintf(out,
            "<randomSuccs>%s</randomSuccs>\n",
            CFG_RANDOM_SUCCS ? "on" : "off");
    if(CFG_HASH_STORAGE || CFG_DELTA_DDD_STORAGE) {
      fprintf(out, "<hashTableSize>%d</hashTableSize>\n", CFG_HASH_SIZE);
    }
    fprintf(out, "<workers>%d</workers>\n", CTX->no_workers);
    if(CFG_DISTRIBUTED) {
      fprintf(out, "<shmemBufferSize>%d</shmemBufferSize>\n",
	      CFG_SHMEM_BUFFER_SIZE);
    }
    if(CFG_ALGO_DELTA_DDD) {
      fprintf(out, "<candidateSetSize>%d</candidateSetSize>\n",
	      CFG_DELTA_DDD_CAND_SET_SIZE);
    }
    if(CFG_DISTRIBUTED_STATE_COMPRESSION || CFG_STATE_COMPRESSION) {
      fprintf(out, "<stateCompressionBits>%d</stateCompressionBits>\n",
              CFG_STATE_COMPRESSION_BITS);
    }
    fprintf(out, "</searchOptions>\n");
    fprintf(out, "</searchReport>\n");
    fprintf(out, "<statisticsReport>\n");
    fprintf(out, "<modelStatistics>\n");
    model_xml_statistics(out);
#if defined(MODEL_STATE_SIZE)
    fprintf(out, "<stateSize>%d</stateSize>\n", MODEL_STATE_SIZE);
#endif
#if CFG_STATE_COMPRESSION && defined(MODEL_HAS_STATE_COMPRESSION)
    fprintf(out, "<compressedStateSize>%d</compressedStateSize>\n",
            state_compressed_char_size());
#endif
#if CFG_DISTRIBUTED_STATE_COMPRESSION && defined(MODEL_HAS_STATE_COMPRESSION)
    fprintf(out, "<compressedStateSize>%d</compressedStateSize>\n",
            state_dist_compressed_char_size());
#endif
    fprintf(out, "</modelStatistics>\n");
    fprintf(out, "<timeStatistics>\n");
    context_stats_to_xml(STAT_TYPE_TIME, out);
    fprintf(out, "</timeStatistics>\n");
    fprintf(out, "<graphStatistics>\n");
    context_stats_to_xml(STAT_TYPE_GRAPH, out);
    fprintf(out, "</graphStatistics>\n");
    if(CFG_WITH_PAPI) {
      papi_stats_output(out);
    }
    fprintf(out, "<otherStatistics>\n");
    context_stats_to_xml(STAT_TYPE_OTHERS, out);
    compression_output_statistics(out);
    dist_compression_output_statistics(out);
    fprintf(out, "</otherStatistics>\n");
    fprintf(out, "</statisticsReport>\n");
    if(CTX->term_state == TERM_FAILURE) {
      fprintf(out, "<traceReport>\n");
      if(CFG_TRACE_STATE) {
	fprintf(out, "<traceState>\n");
	context_state_to_xml(CTX->faulty_state, out);
	fprintf(out, "</traceState>\n");
      } else if(CFG_TRACE_FULL) {
	fprintf(out, "<traceFull>\n");
	context_output_trace(out);
	fprintf(out, "</traceFull>\n");
      } else if(CFG_TRACE_EVENTS) {
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
     *  standard output so that it can be sent to the main process.
     *  we prefix each line with [xml-PID].  reports are printed one
     *  after the other to avoid mixed lines.
     */
    if(CFG_DISTRIBUTED) {
      struct timespec t = { 0, 10000000 };
      for(i = 0; i < comm_pes(); i ++) {
	comm_barrier();
	if(i == comm_me()) {
	  out = fopen(file_name, "r");
	  while(getline(&buf, &n, out) != -1) {
	    printf("[xml-%d] %s", context_proc_id(), buf);
	  }
	  free(buf);
	  fclose(out);
	}
	nanosleep(&t, NULL); 
	comm_barrier();
      }
    }

    /**
     *  free everything
     */
    free(CTX->workers);
    if(CTX->trace) {
      list_free(CTX->trace);
    }
    if(CTX->faulty_state_found) {
      state_free(CTX->faulty_state);
    }
    for(i = 0; i < NO_STATS; i ++) {
      free(CTX->stat[i]);
    }
    pthread_mutex_destroy(&CTX->ctx_mutex);
  }
  if(CTX->error_raised) {
    free(CTX->error_msg);
  }
  free(CTX);
  CTX = NULL;
}

void context_interruption_handler
(int signal) {
  CTX->term_state = TERM_INTERRUPTION;
  CTX->keep_searching = FALSE;
}

void context_stop_search
() {
  CTX->keep_searching = FALSE;
}

void context_faulty_state
(state_t s) {
  pthread_mutex_lock(&CTX->ctx_mutex);
  if(CTX->faulty_state) {
    state_free(CTX->faulty_state);
  }
  CTX->faulty_state = state_copy(s, SYSTEM_HEAP);
  CTX->keep_searching = FALSE;
  CTX->term_state = TERM_FAILURE;
  CTX->faulty_state_found = TRUE;
  pthread_mutex_unlock(&CTX->ctx_mutex);
}

void context_set_trace
(event_list_t trace) {
  pthread_mutex_lock(&CTX->ctx_mutex);
  if(CTX->trace) {
    list_free(CTX->trace);
  }
  CTX->trace = trace;
  CTX->keep_searching = FALSE;
  CTX->term_state = TERM_FAILURE;
  pthread_mutex_unlock(&CTX->ctx_mutex);
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
(term_state_t term_state) {
  CTX->term_state = term_state;
  CTX->keep_searching = FALSE;
}

struct timeval context_start_time
() {
  return CTX->start_time;
}

FILE * context_open_graph_file
() {
  FILE * result = NULL;
  if(CFG_ACTION_BUILD_GRAPH) {
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

term_state_t context_termination_state
() {
  return CTX->term_state;
}

void context_error
(char * msg) {
  pthread_mutex_lock(&CTX->ctx_mutex);
  if(CTX->error_raised) {
    free(CTX->error_msg);
  }
  CTX->error_msg = mem_alloc(SYSTEM_HEAP, sizeof(char) * strlen(msg) + 1);
  strcpy(CTX->error_msg, msg);
  if(!CFG_ACTION_SIMULATE) {
    CTX->term_state = TERM_ERROR;
    CTX->keep_searching = FALSE;
  }
  CTX->error_raised = TRUE;
  pthread_mutex_unlock(&CTX->ctx_mutex);
}

void context_flush_error
() {
  if(CFG_ACTION_SIMULATE) {
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

uint32_t context_proc_id
() {
  return comm_me();
}

float context_cpu_usage
() {
  return cpu_usage(&CTX->cpu_total, &CTX->utime, &CTX->stime);
}

void context_barrier_wait
(pthread_barrier_t * b) {
  pthread_barrier_wait(b);
}

void context_sleep
(struct timespec t) {
  nanosleep(&t, NULL);
}

void context_incr_stat
(stat_t stat,
 worker_id_t w,
 double val) {
  CTX->stat[stat][w] += val;
  CTX->stat_set[stat] = TRUE;
}

void context_set_stat
(stat_t stat,
 worker_id_t w,
 double val) {
  CTX->stat[stat][w] = val;
  CTX->stat_set[stat] = TRUE;
}

double context_get_stat
(stat_t stat) {
  worker_id_t w;
  double result = 0;

  for(w = 0; w < CTX->no_workers; w ++) {
    result += CTX->stat[stat][w];
  }
  return result;
}

void context_set_max_stat
(stat_t stat,
 worker_id_t w,
 double val) {
  if(val > CTX->stat[stat][w]) {
    CTX->stat[stat][w] = val;
  }
  CTX->stat_set[stat] = TRUE;
}
