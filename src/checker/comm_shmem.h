/**
 * @file comm_shmem.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Various stuffs for shmem communication
 */

#ifndef LIB_COMM_SHMEM
#define LIB_COMM_SHMEM

#include "includes.h"
#include "common.h"

/**
 * @brief comm_shmem_init
 */
void comm_shmem_init
();


/**
 * @brief comm_shmem_finalize
 */
void comm_shmem_finalize
(void * heap);


/**
 * @brief comm_shmem_barrier
 */
void comm_shmem_barrier
();


/**
 * @brief comm_shmem_put
 */
void comm_shmem_put
(void * dst,
 void * src,
 int size,
 int pe,
 worker_id_t w);


/**
 * @brief comm_shmem_get
 */
void comm_shmem_get
(void * dst,
 void * src,
 int size,
 int pe,
 worker_id_t w);

#endif
