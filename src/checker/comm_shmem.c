#include "comm_shmem.h"
#include "config.h"
#include "context.h"

#if CFG_DISTRIBUTED == 1
#include "shmem.h"
#endif

#define COMM_SHMEM_CHUNK_SIZE 10000
#define COMM_SHMEM_DEBUG_XXX

pthread_mutex_t COMM_SHMEM_MUTEX;
void * COMM_SHMEM_HEAP;

void init_comm_shmem
() {
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  shmem_init();
  COMM_SHMEM_HEAP = shmem_malloc(CFG_SHMEM_HEAP_SIZE);
  pthread_mutex_init(&COMM_SHMEM_MUTEX, NULL);
#endif
}

void finalise_comm_shmem
() {
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  shmem_free(COMM_SHMEM_HEAP);
  shmem_finalize();
  pthread_mutex_destroy(&COMM_SHMEM_MUTEX);
#endif
}

void comm_shmem_barrier
() {
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  shmem_barrier_all();
#endif
}

void comm_shmem_put
(uint32_t pos,
 void * src,
 int size,
 int pe) {
  
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  /**
   * NOTE: shmem_put fails on local PE in some cases.  we do memcpy
   * instead which seems equivalent.
   */
  if(pe == shmem_my_pe()) {
    memcpy(COMM_SHMEM_HEAP + pos, src, size);
  } else {
#if defined(COMM_SHMEM_DEBUG)
    printf("%d put %d bytes at %d to %d\n", shmem_my_pe(), size, pos, pe);
#endif
    context_increase_bytes_sent(size);
    pthread_mutex_lock(&COMM_SHMEM_MUTEX);
    while(size) {
      if(size < COMM_SHMEM_CHUNK_SIZE) {
	shmem_putmem(COMM_SHMEM_HEAP + pos, src, size, pe);
	size = 0;
      } else {
	shmem_putmem(COMM_SHMEM_HEAP + pos, src, COMM_SHMEM_CHUNK_SIZE, pe);
	size -= COMM_SHMEM_CHUNK_SIZE;
	pos += COMM_SHMEM_CHUNK_SIZE;
	src += COMM_SHMEM_CHUNK_SIZE;
      }
    }
    pthread_mutex_unlock(&COMM_SHMEM_MUTEX);
#if defined(COMM_SHMEM_DEBUG)
    printf("%d put done\n", shmem_my_pe());
#endif
  }
#endif
}

void comm_shmem_get
(void * dst,
 uint32_t pos,
 int size,
 int pe) {
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  if(pe == shmem_my_pe()) {
    memcpy(dst, COMM_SHMEM_HEAP + pos, size);
  } else {
#if defined(COMM_SHMEM_DEBUG)
    printf("%d get %d bytes at %d from %d\n", shmem_my_pe(), size, pos, pe);
#endif
    context_increase_bytes_sent(size);
    pthread_mutex_lock(&COMM_SHMEM_MUTEX);
    shmem_getmem(dst, COMM_SHMEM_HEAP + pos, size, pe);
    pthread_mutex_unlock(&COMM_SHMEM_MUTEX);
#if defined(COMM_SHMEM_DEBUG)
    printf("%d get done\n", shmem_my_pe());
#endif
  }
#endif
}

int comm_shmem_me
() {
#if CFG_DISTRIBUTED == 0
  return 0;
#else
  return shmem_my_pe();
#endif
}

int comm_shmem_pes
() {
#if CFG_DISTRIBUTED == 0
  return 1;
#else
  return shmem_n_pes();
#endif
}

void * comm_shmem_malloc
(int size) {
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  return shmem_malloc(size);
#endif
}
