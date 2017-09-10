#include "dbfs_comm.h"

#if defined(CFG_ALGO_DBFS)

#define SYM_HEAP_SIZE        1000000
#define SYM_HEAP_SIZE_PE     (1000000 / shmem_n_pes())
#define SYM_HEAP_SIZE_WORKER (SYM_HEAP_SIZE_PE / CFG_NO_WORKERS)

static report_t R;
static storage_t S;
static pthread_t W;
static void * H;

void dbfs_comm_send_all_pending_states
(worker_id_t w) {
}

void dbfs_comm_process_state
(worker_id_t w,
 storage_id_t id) {
}

void * dbfs_comm_worker
(void * arg) {
}

void dbfs_comm_start
(report_t r) {
  worker_id_t w;
  pthread_t worker;

  /*  shmem and symmetrical heap initialisation  */
  shmem_init();
  H = shmem_malloc(SYM_HEAP_SIZE);
  
  R = r;
  S = R->storage;

  /*  launch the communicator thread  */
  pthread_create(&W, NULL, &dbfs_comm_worker, NULL);
}

void dbfs_comm_end
() {
  void * dummy;

  pthread_join(W, &dummy);
  shmem_free(H);
  shmem_finalize();
}

#endif  /*  defined(CFG_ALGO_DBFS)  */
