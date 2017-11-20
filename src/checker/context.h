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
typedef uint8_t termination_state_t;
#define SUCCESS             0
#define ERROR               1
#define INTERRUPTION        2
#define SEARCH_TERMINATED   3
#define NO_ERROR            4
#define MEMORY_EXHAUSTED    5
#define TIME_ELAPSED        6
#define STATE_LIMIT_REACHED 7
#define FAILURE             8


/**
 * @brief available statistics
 */
#define STAT_STATES_STORED    0
#define STAT_STATES_PROCESSED 1
#define STAT_STATES_DEADLOCK  2
#define STAT_STATES_ACCEPTING 3
#define STAT_STATES_REDUCED   4
#define STAT_ARCS             5
#define STAT_BFS_LEVELS       6
#define STAT_EVENT_EXEC       7
#define STAT_EVENT_EXEC_DDD   8
#define STAT_BYTES_SENT       9
#define STAT_COMP_TIME        10
#define STAT_SEARCH_TIME      11
#define STAT_SLEEP_TIME       12
#define STAT_BARRIER_TIME     13
#define STAT_DDD_TIME         14
#define STAT_MAX_MEM_USED     15
#define STAT_AVG_CPU_USAGE    16


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
(termination_state_t state);

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

termination_state_t context_termination_state
();

void context_incr_stat
(uint8_t stat,
 worker_id_t w,
 double val);

double context_get_stat
(uint8_t stat);

void context_set_stat
(uint8_t stat,
 worker_id_t w,
 double val);

#endif
