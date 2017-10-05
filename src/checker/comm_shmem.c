#include "comm_shmem.h"
#include "config.h"
#include "context.h"

#if defined(CFG_DISTRIBUTED)
#include "shmem.h"

void comm_shmem_init
() {
  shmem_init();
}

void comm_shmem_barrier
() {
  lna_timer_t t;
  lna_timer_init(&t);
  lna_timer_start(&t);
  shmem_barrier_all();
  lna_timer_stop(&t);
  context_increase_distributed_barrier_time(lna_timer_value(t));
}

void comm_shmem_put
(void * dst,
 void * src,
 int size,
 int pe,
 worker_id_t w) {
  
  /**
   * NOTE: shmem_put fails on local PE in some cases.  we do
   * memcpy instead which seems equivalent.
   */
  if(pe == shmem_my_pe()) {
    memcpy(dst, src, size);
  } else {
    context_increase_bytes_sent(w, size);
    shmem_putmem(dst, src, size, pe);
  }
}

void comm_shmem_get
(void * dst,
 void * src,
 int size,
 int pe,
 worker_id_t w) {
  context_increase_bytes_sent(w, size);
  shmem_getmem(dst, src, size, pe);
}

void comm_shmem_finalize
(void * heap) {
  comm_shmem_barrier();
  if(heap) {
    shmem_free(heap);
  }
  shmem_finalize();
}

int comm_shmem_me
() {
  return shmem_my_pe();
}

#endif
