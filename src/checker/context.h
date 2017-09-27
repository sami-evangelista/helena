/**
 * @file context.h
 * @brief Implementation of the context produced after a search.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_CONTEXT
#define LIB_CONTEXT

#include "includes.h"
#include "model.h"
#include "event.h"
#include "storage.h"

void context_init
(unsigned int no_workers);

void context_finalise
();

bool_t context_error
(char * msg);

void context_interruption_handler
(int signal);

void context_stop_search
();

void context_faulty_state
(state_t s);

storage_t context_storage
();

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

uint64_t context_visited
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
(worker_id_t w,
 uint32_t bytes);

void context_increase_distributed_barrier_time
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

void context_incr_visited
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

#endif
