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

typedef void *(* worker_func_t) (void *);

void launch_and_wait_workers
(worker_func_t f);

#endif
