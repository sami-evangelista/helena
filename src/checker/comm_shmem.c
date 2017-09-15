#include "comm_shmem.h"

#if defined(CFG_DISTRIBUTED)

report_t R;

/**
 * @fn comm_shmem_init
 */
void comm_shmem_init
(report_t r) {
  R = r;
  shmem_init();
}

/**
 * @fn dbfs_comm_barrier
 */
void comm_shmem_barrier
() {
  lna_timer_t t;
  lna_timer_init(&t);
  lna_timer_start(&t);
  shmem_barrier_all();
  lna_timer_stop(&t);
  report_increase_distributed_barrier_time(R, lna_timer_value(t));
}

/**
 * @fn comm_shmem_shmem_put
 */
void comm_shmem_put
(void * dst,
 void * src,
 int size,
 int pe,
 worker_id_t w) {
  report_increase_bytes_sent(R, w, size);
  shmem_putmem(dst, src, size, pe);
}


/**
 * @fn comm_shmem_shmem_get
 */
void comm_shmem_get
(void * dst,
 void * src,
 int size,
 int pe,
 worker_id_t w) {
  report_increase_bytes_sent(R, w, size);
  shmem_getmem(dst, src, size, pe);
}


/**
 * @fn comm_shmem_finalize
 */
void comm_shmem_finalize
(void * heap) {
  comm_shmem_barrier();
  if(heap) {
    shmem_free(heap);
  }
  shmem_finalize();
}

#endif
