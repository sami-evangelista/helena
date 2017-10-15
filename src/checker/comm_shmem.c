#include "comm_shmem.h"
#include "config.h"
#include "context.h"

#if defined(CFG_DISTRIBUTED)
#include "shmem.h"
#endif

#define COMM_SHMEM_CHUNK_SIZE 10000
#define COMM_SHMEM_DEBUG_XXX

pthread_mutex_t COMM_SHMEM_MUTEX;
bool_t COMM_SHMEM_INITIALISED;

void comm_shmem_init
() {
#if !defined(CFG_DISTRIBUTED)
  assert(0);
#else
  shmem_init();
  pthread_mutex_init(&COMM_SHMEM_MUTEX, NULL);
#endif
}

void comm_shmem_barrier
() {
#if !defined(CFG_DISTRIBUTED)
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
  
#if !defined(CFG_DISTRIBUTED)
  assert(0);
#else
  /**
   * NOTE: shmem_put fails on local PE in some cases.  we do
   * memcpy instead which seems equivalent.
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
#if !defined(CFG_DISTRIBUTED)
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

void comm_shmem_finalize
(void * heap) {
#if !defined(CFG_DISTRIBUTED)
  assert(0);
#else
  comm_shmem_barrier();
  if(heap) {
    shmem_free(heap);
  }
  shmem_finalize();
  pthread_mutex_destroy(&COMM_SHMEM_MUTEX);
#endif
}

int comm_shmem_me
() {
#if !defined(CFG_DISTRIBUTED)
  return 0;
#else
  return shmem_my_pe();
#endif
}

int comm_shmem_pes
() {
#if !defined(CFG_DISTRIBUTED)
  return 1;
#else
  return shmem_n_pes();
#endif
}

void * comm_shmem_malloc
(int size) {
#if !defined(CFG_DISTRIBUTED)
  assert(0);
#else
  return shmem_malloc(size);
#endif
}
