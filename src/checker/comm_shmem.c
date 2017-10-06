#include "comm_shmem.h"
#include "config.h"
#include "context.h"

#if defined(CFG_DISTRIBUTED)
#include "shmem.h"

#define COMM_SHMEM_DEBUG_XXX

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
 int pe) {
  
  /**
   * NOTE: shmem_put fails on local PE in some cases.  we do
   * memcpy instead which seems equivalent.
   */
  if(pe == shmem_my_pe()) {
    memcpy(dst, src, size);
  } else {
#if defined(COMM_SHMEM_DEBUG)
    printf("[%d,%d] put at %p to %d\n", shmem_my_pe(), w, dst, pe);
#endif
    context_increase_bytes_sent(size);
    shmem_putmem(dst, src, size, pe);
#if defined(COMM_SHMEM_DEBUG)
    printf("[%d,%d] put at %p to %d done\n", shmem_my_pe(), w, dst, pe);
#endif
  }
}

void comm_shmem_get
(void * dst,
 void * src,
 int size,
 int pe) {
  if(pe == shmem_my_pe()) {
    memcpy(dst, src, size);
  } else {
#if defined(COMM_SHMEM_DEBUG)
    printf("[%d,%d] get adr %p from %d\n", shmem_my_pe(), w, dst, pe);
#endif
    context_increase_bytes_sent(size);
    shmem_getmem(dst, src, size, pe);
#if defined(COMM_SHMEM_DEBUG)
    printf("[%d,%d] get adr %p from %d done\n", shmem_my_pe(), w, dst, pe);
#endif
  }
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

int comm_shmem_pes
() {
  return shmem_n_pes();
}

void * comm_shmem_malloc
(int size) {
  return shmem_malloc(size);
}

#endif
