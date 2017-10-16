/**
 * @file comm_shmem.h
 * @brief Various stuffs for shmem communication
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_COMM_SHMEM
#define LIB_COMM_SHMEM

#include "includes.h"
#include "common.h"

/**
 * @brief init_comm_shmem
 */
void init_comm_shmem
();


/**
 * @brief finalise_comm_shmem
 */
void finalise_comm_shmem
();


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
 int pe);


/**
 * @brief comm_shmem_get
 */
void comm_shmem_get
(void * dst,
 void * src,
 int size,
 int pe);


/**
 * @brief comm_shmem_me
 */
int comm_shmem_me
();


/**
 * @brief comm_shmem_pes
 */
int comm_shmem_pes
();


/**
 * @brief comm_shmem_malloc
 */
void * comm_shmem_malloc
(int size);

#endif
