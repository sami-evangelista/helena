#include "ddfs_comm.h"

#if defined(ALGO_DDFS)

#define SYM_HEAP_SIZE     100000
#define BUFFER_SIZE       (SYM_HEAP_SIZE - sizeof(heap_prefix_t))
#define MAX_BOX_SIZE      1000000
#define BUCKET_OK         1
#define BUCKET_WRITE      2
#define PUBLISH_PERIOD_MS 10

static const struct timespec PUBLISH_PERIOD =
  { 0, PUBLISH_PERIOD_MS * 1000000 };
static const struct timespec WAIT_TIME =
  { 0, 10 };

#include "ddfs_comm.h"

typedef struct {
  bool_t   terminated;
  uint32_t size;
  uint32_t char_len;
} heap_prefix_t;

typedef struct {
  uint8_t status[NO_WORKERS];
  uint32_t size[NO_WORKERS];
  storage_id_t box[NO_WORKERS][MAX_BOX_SIZE];
} ddfs_comm_boxes_t;

ddfs_comm_boxes_t B;
storage_t S;
report_t R;
static void * H;
pthread_t W;

void ddfs_comm_process_explored_state
(worker_id_t w,
 storage_id_t id) {
  if(CAS(&B.status[w], BUCKET_OK, BUCKET_WRITE)) {
    if(B.size[w] < MAX_BOX_SIZE) {
      B.box[w][B.size[w]] = id;
      B.size[w] ++;
    }
    B.status[w] = BUCKET_OK;
  }
}

void * ddfs_comm_worker
(void * arg) {
  const int me = shmem_my_pe();
  const int pes = shmem_n_pes();
  int i, pe;
  worker_id_t w;
  bool_t loop = TRUE;
  heap_prefix_t pref,  pref_other[pes];
  uint32_t pos;

  pref.terminated = FALSE;
  while(loop) {
    
    nanosleep(&PUBLISH_PERIOD, NULL);

    /*
     *  wait for all remote PEs before filling my own space
     */
    shmem_barrier_all();

    /*
     *  put every state of the local shared box in the symmetrical
     *  heap
     */
    pref.size = 0;
    for(w = 0; w < NO_WORKERS; w ++) {

      /*  wait for the bucket of thread w to be ready  */
      while(!CAS(&B.status[w], BUCKET_OK, BUCKET_WRITE)) {
	nanosleep(&WAIT_TIME, NULL);
      }

      /*  put all states of the queue of worker w in the local heap  */
      pref.size += B.size[w];
      pref.char_len = 0;
      for(i = 0; i < B.size[w]; i ++) {
        //  TODO
        B.box[w][i];
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
    shmem_putmem(H, &pref, sizeof(heap_prefix_t), me);

    /*
     *  wait for all remote PEs to have filled their local heap
     */
    shmem_barrier_all();

    /*
     *  read prefixes of all remote PEs 
     */
    loop = !pref.terminated;
    for(pe = 0; pe < pes ; pe ++) {
      if(me != pe) {
        shmem_getmem(&pref_other[pe], H, sizeof(heap_prefix_t), pe);
        printf("[%d <- %d] size = %d\n", me, pe, pref_other[pe].size);
        printf("[%d <- %d] term = %d\n", me, pe, pref_other[pe].terminated);
        printf("[%d <- %d] len  = %d\n", me, pe, pref_other[pe].char_len);
        if(!pref_other[pe].terminated) {
          loop = TRUE;
        }
      }
    }

    /*
     *  at least one process has not finished and neither have I =>
     *  get states put by remote PEs in their heap and put these in my
     *  local storage
     */
    if(loop && R->keep_searching) {
      for(pe = 0; pe < pes ; pe ++) {
        if(me != pe) {
          for(i = 0; i < pref_other[pe].size; i++) {
            //  TODO
          }
        }
      }
    }
  }
  return NULL;
}

void ddfs_comm_start
(report_t r) {
  worker_id_t w;
  pthread_t worker;

  /*  shmem and symmetrical heap initialisation  */
  shmem_init();
  H = shmem_malloc(SYM_HEAP_SIZE * shmem_n_pes());
  
  R = r;
  S = R->storage;
  for(w = 0; w < NO_WORKERS; w ++) {
    B.status[w] = BUCKET_OK;
    B.size[w] = 0;
  }

  /*  launch the communicator thread  */
  pthread_create(&W, NULL, &ddfs_comm_worker, NULL);
}

void ddfs_comm_end
() {
  void * dummy;

  pthread_join(W, &dummy);
  shmem_barrier_all();
  shmem_free(H);
  shmem_finalize();
}

#endif
