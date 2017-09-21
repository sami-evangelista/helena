/**
 * @file workers.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Several routines to handle worker threads.
 */

#ifndef LIB_WORKERS
#define LIB_WORKERS

#include "common.h"
#include "includes.h"

typedef void *(* worker_func_t) (void *);

void launch_and_wait_workers
(worker_func_t f);

#endif
