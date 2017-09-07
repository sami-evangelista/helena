#ifndef LIB_REPORT
#define LIB_REPORT

#include "includes.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

struct struct_report_t;

typedef struct struct_report_t struct_report_t;

typedef struct_report_t * report_t;

#include "model.h"
#include "storage.h"

void init_report ();
void free_report ();

struct struct_report_t {
  unsigned int no_workers;
  char * error_msg;
  unsigned int errors;
  termination_state_t result;
  FILE * graph_file;
  storage_t storage;
  bool_t keep_searching;
  struct timeval start_time;
  struct timeval end_time;

  /*
   *  for the trace report
   */
  bool_t faulty_state_found;
  state_t faulty_state;
  event_t * trace;
  unsigned int trace_len;

  /*
   *  statistics field
   */
  uint64_t * states_accepting;
  uint64_t * states_visited;
  uint64_t * states_dead;
  uint64_t * arcs;
  uint64_t * events_executed;
  uint64_t * events_executed_dd;
  uint64_t * state_cmps;
  uint64_t exec_time;
  uint64_t max_unproc_size;
  uint64_t states_max_stored;
  unsigned int bfs_levels;
  bool_t bfs_levels_ok;
  float max_mem_used;
  float comp_time;
  uint64_t distributed_barrier_time;

  /*
   *  threads
   */
  pthread_t observer;
  pthread_t * workers;
};

report_t glob_report;

report_t report_new
(unsigned int no_workers);

void report_free
();

void report_finalise
(report_t r);

bool_t report_error
(char * msg);

void report_interruption_handler
(int signal);

void report_stop_search
();

void report_set_comp_time
(report_t r,
 float comp_time);

void report_update_bfs_levels
(report_t r,
 unsigned int bfs_levels);

void report_update_max_unproc_size
(report_t r,
 uint64_t max_unproc_size);

void report_faulty_state
(report_t r,
 state_t s);

#endif
