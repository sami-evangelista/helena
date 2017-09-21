/**
 * @file report.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Implementation of the report produced after a search.
 */

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

void report_increase_bytes_sent
(report_t r,
 worker_id_t w,
 uint32_t bytes);

void report_increase_distributed_barrier_time
(report_t r,
 float time);

void report_faulty_state
(report_t r,
 state_t s);

#define report_storage(r) (r->storage)
#define report_set_result(r, result) {r->result = result;}
#define report_keep_searching(r) (r->keep_searching)
#define report_incr_arcs(r, w, no) {r->arcs[w] += no;}
#define report_incr_dead(r, w, no) {r->states_dead[w] += no;}
#define report_incr_accepting(r, w, no) {r->states_accepting[w] += no;}
#define report_incr_visited(r, w, no) {r->states_visited[w] += no;}
#define report_incr_evts_exec(r, w, no) {r->evts_exec[w] += no;}
#define report_incr_evts_exec_dd(r, w, no) {r->evts_exec[w] += no;}

#endif
