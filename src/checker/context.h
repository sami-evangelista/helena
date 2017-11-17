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
#include "event.h"


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

uint64_t context_processed
();

struct timeval context_start_time
();

FILE * context_open_graph_file
();

FILE * context_graph_file
();

void context_close_graph_file
();

void context_set_comp_time
(float comp_time);

void context_update_bfs_levels
(unsigned int bfs_levels);

void context_increase_bytes_sent
(uint32_t bytes);

void context_increase_barrier_time
(float time);

void context_incr_arcs
(worker_id_t w,
 int no);

void context_incr_dead
(worker_id_t w,
 int no);

void context_incr_accepting
(worker_id_t w,
 int no);

void context_incr_processed
(worker_id_t w,
 int no);

void context_incr_reduced
(worker_id_t w,
 int no);

void context_incr_evts_exec
(worker_id_t w,
 int no);

void context_incr_evts_exec_dd
(worker_id_t w,
 int no);

void context_update_max_states_stored
(uint64_t states_stored);

void context_update_max_mem_used
(float mem);

uint32_t context_global_worker_id
(worker_id_t w);

uint32_t context_proc_id
();

float context_cpu_usage
();

void context_set_avg_cpu_usage
(float avg_cpu_usage);

void context_barrier_wait
(pthread_barrier_t * b);

void context_sleep
(struct timespec t);

termination_state_t context_termination_state
();

void context_set_storage_size
(uint64_t storage_size);

void context_set_dd_time
(uint64_t dd_time);

#endif
