#ifndef LIB_DBFS_COMM
#define LIB_DBFS_COMM

#include "includes.h"
#include "report.h"
#include "storage.h"
#include "bfs_queue.h"

void dbfs_comm_start
(report_t r,
 bfs_queue_t q);

void dbfs_comm_end
();

void dbfs_comm_process_state
(worker_id_t w,
 state_t s);

void dbfs_comm_send_all_pending_states
(worker_id_t w);

void dbfs_comm_notify_level_termination
();

void dbfs_comm_local_barrier
();

bool_t dbfs_comm_global_termination
();

bool_t dbfs_comm_state_owned
(hash_key_t h);

#endif
