/**
 * @file context.h
 * @brief Implementation of the context of a search.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_CONTEXT
#define LIB_CONTEXT

#include "includes.h"
#include "model.h"
#include "state.h"
#include "event.h"


/**
 * @typedef termination_state_t
 * @brief possible termination states of helena
 */
typedef enum {
  TERM_SUCCESS,
  TERM_ERROR,
  TERM_INTERRUPTION,
  TERM_SEARCH_TERMINATED,
  TERM_NO_ERROR,
  TERM_TIME_ELAPSED,
  TERM_STATE_LIMIT_REACHED,
  TERM_FAILURE
} term_state_t;


/**
 * @typedef stat_t
 * @brief available statistics
 */
typedef enum {
  STAT_STATES_STORED,
  STAT_STATES_ACCEPTING,
  STAT_STATES_DEADLOCK,
  STAT_STATES_PROCESSED,
  STAT_STATES_REDUCED,
  STAT_ARCS,
  STAT_AVG_CPU_USAGE,
  STAT_SHMEM_COMMS,
  STAT_EVENT_EXEC,
  STAT_TIME_COMP,
  STAT_TIME_SEARCH,
  STAT_TIME_SLEEP,
  STAT_TIME_BARRIER,  
  STAT_BWALK_ITERATIONS
} stat_t;


/**
 * @brief Context initialisation.
 */
void init_context
();


/**
 * @brief Context finalisation.
 */
void finalise_context
();


/**
 * @brief Raise an error: stop the search and set the termination
 *        state.  This does not apply for simulation mode.  No effect
 *        if an error has already been raised.
 */
void context_error
(char * msg);


/**
 * @brief Check if an error has been raised.
 */
bool_t context_error_raised
();


/**
 * @brief Return the error message of the error raised, NULL if no
 *        error raised.
 */
char * context_error_msg
();


/**
 * @brief Cancel the last error raised.
 */
void context_flush_error
();

void context_interruption_handler
(int signal);

void context_stop_search
();

void context_faulty_state
(state_t s);

bool_t context_keep_searching
();

uint16_t context_no_workers
();

pthread_t * context_workers
();

void context_set_termination_state
(term_state_t state);

void context_set_trace
(event_list_t trace);

float context_cpu_usage
();

struct timeval context_start_time
();

FILE * context_open_graph_file
();

FILE * context_graph_file
();

void context_close_graph_file
();

uint32_t context_global_worker_id
(worker_id_t w);

uint32_t context_proc_id
();

void context_barrier_wait
(pthread_barrier_t * b);

void context_sleep
(struct timespec t);

term_state_t context_termination_state
();

void context_incr_stat
(stat_t stat,
 worker_id_t w,
 double val);

void context_set_max_stat
(stat_t stat,
 worker_id_t w,
 double val);

double context_get_stat
(stat_t stat);

void context_set_stat
(stat_t stat,
 worker_id_t w,
 double val);

#endif
