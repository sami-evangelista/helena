#include "comm_gasnet.h"
#include "config.h"
#include "context.h"

#if CFG_DISTRIBUTED == 1
#define GASNET_PAR
#include "gasnet.h"
gasnet_seginfo_t * COMM_GASNET_SEG;
gasnet_node_t COMM_GASNET_ME;
int COMM_GASNET_NO;
bool_t COMM_GASNET_INITIALISED = FALSE;
#endif

#if defined(COMM_GASNET_DEBUG)
#define comm_gasnet_debug(...)   {			\
    printf("[%d:%d] ", COMM_GASNET_ME, getpid());	\
    printf(__VA_ARGS__);				\
}
#else
#define comm_gasnet_debug(...) {}
#endif

void init_comm
() {
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  gasnet_init(NULL, 0);
  gasnet_attach(NULL, 0, 1000 * GASNET_PAGESIZE, 0);
  COMM_GASNET_ME = gasnet_mynode();
  COMM_GASNET_NO = gasnet_nodes();
  COMM_GASNET_SEG = mem_alloc(SYSTEM_HEAP,
                              sizeof(gasnet_seginfo_t) * COMM_GASNET_NO);
  gasnet_getSegmentInfo(COMM_GASNET_SEG, COMM_GASNET_NO);
  COMM_GASNET_INITIALISED = TRUE;
#endif
}

void finalise_comm
() {
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  free(COMM_GASNET_SEG);
  gasnet_exit(0);
#endif
}

void comm_barrier
() {
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  assert(0);
#endif
}

void comm_put
(uint32_t pos,
 void * src,
 int size,
 int pe) {
  
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  assert(COMM_GASNET_INITIALISED);
  comm_gasnet_debug("put %d bytes at %d to %d\n", size, pos, pe);
  gasnet_put(pe, COMM_GASNET_SEG[pe].addr + pos, src, size);
  if(pe != COMM_GASNET_ME) {
    context_incr_stat(STAT_BYTES_SENT, 0, size);
  }
  comm_gasnet_debug("put done\n");
#endif
}

void comm_get
(void * dst,
 uint32_t pos,
 int size,
 int pe) {
#if CFG_DISTRIBUTED == 0
  assert(0);
#else
  assert(COMM_GASNET_INITIALISED);
  comm_gasnet_debug("get %d bytes at %d from %d\n", size, pos, pe);
  gasnet_get(dst, pe, COMM_GASNET_SEG[pe].addr + pos, size);
  if(pe != COMM_GASNET_ME) {
    context_incr_stat(STAT_BYTES_SENT, 0, size);
  }
  comm_gasnet_debug("get done\n");
#endif
}

int comm_me
() {
#if CFG_DISTRIBUTED == 0
  return 0;
#else
  assert(COMM_GASNET_INITIALISED);
  return COMM_GASNET_ME;
#endif
}

int comm_no
() {
#if CFG_DISTRIBUTED == 0
  return 1;
#else
  assert(COMM_GASNET_INITIALISED);
  return (int) COMM_GASNET_NO;
#endif
}
