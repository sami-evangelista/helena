#ifndef LIB_DBFS_COMM
#define LIB_DBFS_COMM

#include "includes.h"
#include "report.h"
#include "storage.h"

void dbfs_comm_start
(report_t r);

void dbfs_comm_end
();

void dbfs_comm_process_state
(worker_id_t w,
 storage_id_t id);

void dbfs_comm_send_all_pending_states
(worker_id_t w);

#endif
