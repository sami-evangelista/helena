#include "comm_shmem.h"
#include "config.h"
#include "context.h"

#if CFG_DISTRIBUTED == 1
#include "shmem.h"
#endif

#define COMM_SHMEM_CHUNK_SIZE 10000
#define COMM_SHMEM_DEBUG

pthread_mutex_t COMM_SHMEM_MUTEX;
bool_t COMM_SHMEM_INITIALISED;

void init_comm_shmem
() {
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  shmem_init();
  pthread_mutex_init(&COMM_SHMEM_MUTEX, NULL);
#endif
}

void finalise_comm_shmem
() {
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  comm_shmem_barrier();
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
(void * dst,
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
    memcpy(dst, src, size);
  } else {
#if defined(COMM_SHMEM_DEBUG)
    printf("%d put %d bytes at %p to %d\n",
	   shmem_my_pe(), size , dst, pe);
#endif
    context_increase_bytes_sent(size);
    pthread_mutex_lock(&COMM_SHMEM_MUTEX);
    while(size) {
      if(size < COMM_SHMEM_CHUNK_SIZE) {
	shmem_putmem(dst, src, size, pe);
	size = 0;
      } else {
	shmem_putmem(dst, src, COMM_SHMEM_CHUNK_SIZE, pe);
	size -= COMM_SHMEM_CHUNK_SIZE;
	dst += COMM_SHMEM_CHUNK_SIZE;
	src += COMM_SHMEM_CHUNK_SIZE;
      }
    }
    pthread_mutex_unlock(&COMM_SHMEM_MUTEX);
#if defined(COMM_SHMEM_DEBUG)
    printf("%d put %d bytes at %p to %d done\n",
	   shmem_my_pe(), size , dst, pe);
#endif
  }
#endif
}

void comm_shmem_get
(void * dst,
 void * src,
 int size,
 int pe) {
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  if(pe == shmem_my_pe()) {
    memcpy(dst, src, size);
  } else {
#if defined(COMM_SHMEM_DEBUG)
    printf("%d get %d bytes at %p from %d\n",
	   shmem_my_pe(), size , dst, pe);
#endif
    context_increase_bytes_sent(size);
    pthread_mutex_lock(&COMM_SHMEM_MUTEX);
    shmem_getmem(dst, src, size, pe);
    pthread_mutex_unlock(&COMM_SHMEM_MUTEX);
#if defined(COMM_SHMEM_DEBUG)
    printf("%d get %d bytes at %p from %d done\n",
	   shmem_my_pe(), size , dst, pe);
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
