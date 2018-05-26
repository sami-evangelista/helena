/**
 * @file comm.h
 * @brief Various stuffs for SHMEM communications.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_COMM
#define LIB_COMM

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
 * @brief comm_malloc
 */
void * comm_malloc
(size_t heap_size);


/**
 * @brief comm_me
 */
int comm_me
();


/**
 * @brief comm_pes
 */
int comm_pes
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
 int pe);


/**
 * @brief comm_get
 */
void comm_get
(void * dst,
 uint32_t pos, 
 int size,
 int pe);

#endif
