/**
 * @file dbfs_comm.h
 * @brief Communication library used by the DBFS algorithm
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_DBFS_COMM
#define LIB_DBFS_COMM

#include "includes.h"
#include "bfs_queue.h"
#include "htbl.h"


/**
 * @brief dbfs_comm_start
 */
void dbfs_comm_start
(htbl_t h,
 bfs_queue_t q);


/**
 * @brief dbfs_comm_end
 */
void dbfs_comm_end
();


/**
 * @brief dbfs_comm_process_state
 */
void dbfs_comm_process_state
(worker_id_t w,
 state_t s,
 hkey_t h);


/**
 *  @brief dbfs_comm_termination
 */
bool_t dbfs_comm_termination
();


/**
 * @brief dbfs_comm_send_all_pending_states
 */
void dbfs_comm_send_all_pending_states
(worker_id_t w);


/**
 * @brief dbfs_comm_state_owned
 */
bool_t dbfs_comm_state_owned
(hkey_t h);

#endif
