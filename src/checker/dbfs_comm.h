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


#define DBFS_COMM_STATE     0
#define DBFS_COMM_COMP_DATA 1


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
bool_t dbfs_comm_process_state
(htbl_meta_data_t * mdata);


/**
 *  @brief dbfs_comm_idle
 */
bool_t dbfs_comm_idle
();


/**
 * @brief dbfs_comm_state_owned
 */
bool_t dbfs_comm_state_owned
(hkey_t h);


/**
 * @brief dbfs_comm_check_communications
 */
bool_t dbfs_comm_check_communications
();


/**
 * @brief dbfs_comm_new_state_stored
 */
void dbfs_comm_new_state_stored
(htbl_id_t id);


/**
 * @brief dbfs_comm_put_in_comp_buffer
 */
void dbfs_comm_put_in_comp_buffer
(char * buffer,
 int len);

#endif
