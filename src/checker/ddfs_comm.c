#include "ddfs_comm.h"

#if defined(ALGO_DDFS)

#define SYM_HEAP_SIZE 100000
#define MAX_BOX_SIZE  10000
#define BUCKET_OK     1
#define BUCKET_WRITE  2

static const struct timespec PUBLISH_PERIOD = { 0, 999 * 1000000 };
static const struct timespec WAIT_TIME = { 0, 10 };

#include "ddfs_comm.h"
#include "shmem.h"

#define PE_MEM_SPACE(pe) (H + pe * SYM_HEAP_SIZE)

typedef struct {
  bool_t terminated;
  uint32_t size;
} heap_prefix_t;

typedef struct {
  uint8_t status[NO_WORKERS];
  uint32_t size[NO_WORKERS];
  storage_id_t box[NO_WORKERS][MAX_BOX_SIZE];
} ddfs_comm_boxes_t;

ddfs_comm_boxes_t B;
storage_t S;
report_t R;
void * H;

void ddfs_comm_process_explored_state
(worker_id_t w,
 storage_id_t id) {
  return;
  if(CAS(&B.status[w], BUCKET_OK, BUCKET_WRITE)) {
    if(B.size[w] < MAX_BOX_SIZE) {
      B.box[w][B.size[w]] = id;
      B.size[w] ++;
    }
    B.status[w] = BUCKET_OK;
  }
}

void ddfs_comm_job
() {
  const int me = shmem_my_pe();
  int i, pe;
  worker_id_t w;
  bool_t loop = TRUE;
  heap_prefix_t pref,  pref_other;

  pref.terminated = FALSE;
  while(loop) {
    nanosleep(&PUBLISH_PERIOD, NULL);

    /*
     *  put every state of the local shared box in the symmetrical
     *  heap
     */
    for(w = 0; w < NO_WORKERS; w ++) {
      printf("size=%d\n", B.size[w]);

      /*  wait for the bucket of thread w to be ready  */
      while(CAS(&B.status[w], BUCKET_OK, BUCKET_WRITE)) {
	nanosleep(&WAIT_TIME, NULL);
      }

      /*  put all states of the queue of worker w in the local heap  */
      for(i = 0; i < B.size[w]; i ++) {
      }

      /*  reinitialise the queue and make it available  */
      B.size[w] = 0;
      B.status[w] = BUCKET_OK;
    }

    /*
     *  notify others if the search has terminated
     */
    if(!R->keep_searching) {
      pref.terminated = TRUE;
    }
    pref.terminated = TRUE;
    shmem_putmem(PE_MEM_SPACE(me), &pref, sizeof(heap_prefix_t), me);

    /*
     *  wait for all remote PEs to have filled their local heap
     */
    shmem_barrier_all();

    /*
     *  read prefixes of all remote PEs 
     */
    loop = FALSE;
    for(pe = 0; pe < shmem_n_pes() ; pe ++) {
      char c;
      if(me == pe) {
	continue;
      }
      shmem_getmem(&pref_other, PE_MEM_SPACE(pe), sizeof(heap_prefix_t), pe);
      printf("me = %d, pe = %d, c = %d\n", me, pe, * ((char *) PE_MEM_SPACE(me)));
      if(!pref_other.terminated) {
	loop = TRUE;
      }
    }
  }
  printf("done\n");
}

void ddfs_comm_start
(report_t r) {
  worker_id_t w;
  pthread_t worker;
  shmem_init();
  H = shmem_malloc(SYM_HEAP_SIZE * shmem_n_pes());

  R = r;
  S = R->storage;
  for(w = 0; w < NO_WORKERS; w ++) {
    B.status[w] = BUCKET_OK;
    B.size[w] = 0;
  }
  
}

void ddfs_comm_end
() {
  shfree(H);
}

#endif
