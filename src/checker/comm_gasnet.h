/**
 * @file comm_shmem.h
 * @brief Various stuffs for shmem communication.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_COMM_SHMEM
#define LIB_COMM_SHMEM

#include "includes.h"
#include "common.h"

/**
 * @brief init_comm
 */
void init_comm
();


/**
 * @brief finalise_comm
 */
void finalise_comm
();


/**
 * @brief comm_barrier
 */
void comm_barrier
();


/**
 * @brief comm_put
 */
void comm_put
(uint32_t pos,
 void * src,
 int size,
 int node);


/**
 * @brief comm_get
 */
void comm_get
(void * dst,
 uint32_t pos, 
 int size,
 int node);


/**
 * @brief comm_me
 */
int comm_me
();


/**
 * @brief comm_no
 */
int comm_no
();

#endif
