/**
 * @file workers.h
 * @brief Several routines to handle worker threads.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_WORKERS
#define LIB_WORKERS

#include "common.h"
#include "includes.h"

/**
 * @brief a function executed by a worker thread
 */
typedef void *(* worker_func_t) (void *);

/**
 * @brief Launch the worker threads and wait for their termination.
 * @arg f - the worker code
 */
void launch_and_wait_workers
(worker_func_t f);

#endif
