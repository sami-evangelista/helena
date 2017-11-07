/**
 * @file ddfs_comm.h
 * @brief Communication library used by the DDFS algorithm
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_DDFS_COMM
#define LIB_DDFS_COMM

#include "includes.h"
#include "context.h"
#include "storage.h"


/**
 * @brief ddfs_comm_start
 */
void ddfs_comm_start
();


/**
 * @brief ddfs_comm_end
 */
void ddfs_comm_end
();


/**
 * @brief ddfs_comm_process_explored_state
 */
void ddfs_comm_process_explored_state
(worker_id_t w,
 storage_id_t id);

#endif
