#include "ddfs_comm.h"

#if defined(CFG_ALGO_DDFS)

#define SYM_HEAP_SIZE     1000000
#define MAX_BOX_SIZE      100000
#define PUBLISH_PERIOD_MS 10

#define BUFFER_SIZE       (SYM_HEAP_SIZE - sizeof(heap_prefix_t))
#define BUCKET_OK         1
#define BUCKET_WRITE      2

static const struct timespec PUBLISH_PERIOD =
  { 0, PUBLISH_PERIOD_MS * 1000000 };
static const struct timespec WAIT_TIME =
  { 0, 10 };

#include "ddfs_comm.h"

typedef struct {
  bool_t   terminated;  /*  has all workers of the PE terminated  */
  uint32_t size; /*  number of states published by the PE  */
  uint32_t char_len; /*  total number of characters put by the PE  */
} heap_prefix_t;

typedef struct {
  uint8_t status[CFG_NO_WORKERS];
  uint32_t size[CFG_NO_WORKERS];
  storage_id_t box[CFG_NO_WORKERS][MAX_BOX_SIZE];
  uint16_t k[CFG_NO_WORKERS];
} ddfs_comm_boxes_t;

static ddfs_comm_boxes_t B;
static storage_t S;
static report_t R;
static void * H;
static pthread_t W;

void ddfs_comm_process_explored_state
(worker_id_t w,
 storage_id_t id,
 mevent_set_t en) {

  /**
   *  if a communication strategy has been set we check if the state
   *  must be sent
   */
#if defined(CFG_DDFS_COMM_STRAT)
  bool_t process = TRUE;
#if defined(CFG_DDFS_COMM_STRAT_K)
  B.k[w] ++;
  if(B.k[w] < CFG_DDFS_COMM_STRAT_K) {
    process = FALSE;
  }
#endif
#if defined(CFG_DDFS_COMM_STRAT_MINE)
  if(storage_get_hash(S, id) % shmem_n_pes() != shmem_my_pe()) {
    process = FALSE;
  }
#endif
#if defined(CFG_DDFS_COMM_STRAT_DEGREE)
  if(mevent_set_size(en) < CFG_DDFS_COMM_STRAT_DEGREE) {
    process = FALSE;
  }
#endif
  if(!process) {
    return;
  }
  B.k[w] = 0;
#endif

  /*
   *  put the state of worker w in its box and increase its reference
   *  counter
   */
  if(CAS(&B.status[w], BUCKET_OK, BUCKET_WRITE)) {
    if(B.size[w] < MAX_BOX_SIZE) {
      B.box[w][B.size[w]] = id;
      B.size[w] ++;
      storage_ref(S, id);
    }
    B.status[w] = BUCKET_OK;
  }
}

void ddfs_comm_barrier
() {
  lna_timer_t t;
  lna_timer_init(&t);
  lna_timer_start(&t);
  shmem_barrier_all();
  lna_timer_stop(&t);
  R->distributed_barrier_time += lna_timer_value(t);
}

void * ddfs_comm_worker
(void * arg) {
  const int me = shmem_my_pe();
  const int pes = shmem_n_pes();
  int i, pe;
  worker_id_t w, my_worker_id = CFG_NO_WORKERS;
  bool_t loop = TRUE;
  heap_prefix_t pref,  pref_other[pes];
  uint32_t pos;
  uint16_t s_char_len, len;
  storage_id_t sid;
  bit_vector_t s;
  bool_t red, blue, is_new;
  char buffer[SYM_HEAP_SIZE];
  hash_key_t h;
  
  pref.terminated = FALSE;
  while(loop) {
    
    nanosleep(&PUBLISH_PERIOD, NULL);

    /**
     *  1st step: put every state of the local shared box in the
     *  symmetrical heap
     */
    ddfs_comm_barrier();
    pref.size = 0;
    pos = sizeof(heap_prefix_t);
    for(w = 0; w < CFG_NO_WORKERS; w ++) {

      /*  wait for the bucket of thread w to be ready  */
      while(!CAS(&B.status[w], BUCKET_OK, BUCKET_WRITE)) {
	nanosleep(&WAIT_TIME, NULL);
      }

      /*  put all states of the queue of worker w in the local heap  */
      pref.size += B.size[w];
      for(i = 0; i < B.size[w]; i ++) {

        /*  get the serialised state and check whether there enough
            space in the heap to put it */
        sid = B.box[w][i];
        storage_get_serialised(S, sid, &s, &s_char_len);
        len = sizeof(hash_key_t) + 2 + sizeof(uint16_t) + s_char_len;
        if(pos + len > BUFFER_SIZE) {
          break;
        }

        /*  put its hash value  */
        h = storage_get_hash(S, sid);
        shmem_putmem(H + pos, &h, sizeof(hash_key_t), me);
        pos += sizeof(hash_key_t);
          
        /*  put its blue attribute  */
        blue = storage_get_blue(S, sid);
        shmem_putmem(H + pos, &blue, 1, me);
        pos ++;
          
        /*  put its red attribute  */
        red = storage_get_red(S, sid);
        shmem_putmem(H + pos, &red, 1, me);
        pos ++;
          
        /*  put its char length  */
        shmem_putmem(H + pos, &s_char_len, sizeof(uint16_t), me);
        pos += sizeof(uint16_t);
          
        /*  put the state  */
        shmem_putmem(H + pos, s, s_char_len, me);
        pos += s_char_len;

        /*  and decrease its reference counter  */
        storage_ref(S, sid);        
      }

      /*  reinitialise the queue of worker w and make it available  */
      B.size[w] = 0;
      B.status[w] = BUCKET_OK;
    }
    pref.char_len = pos - sizeof(heap_prefix_t);

    /*  notify others if the search has terminated  */
    if(!R->keep_searching) {
      pref.terminated = TRUE;
    }

    /*  put my prefix in my local heap  */
    shmem_putmem(H, &pref, sizeof(heap_prefix_t), me);

    /**
     *  2nd step: get all the states sent py remote PEs
     */
    ddfs_comm_barrier();
    
    /*  first read the heap prefixes of all remote PEs  */
    loop = !pref.terminated;
    for(pe = 0; pe < pes ; pe ++) {
      if(me != pe) {
        shmem_getmem(&pref_other[pe], H, sizeof(heap_prefix_t), pe);
        if(!pref_other[pe].terminated) {
          loop = TRUE;
        }
      }
    }

    /*  at least one process has not finished and neither have I =>
        get states put by remote PEs in their heap and put these in my
        local storage */
    if(TRUE || loop && R->keep_searching) {
      for(pe = 0; pe < pes ; pe ++) {
        if(me != pe) {
          shmem_getmem(buffer, H + sizeof(heap_prefix_t),
                       pref_other[pe].char_len, pe);
          pos = 0;
          for(i = 0; i < pref_other[pe].size; i++) {

            /*  get hash value  */
            memcpy(&h, buffer + pos, sizeof(hash_key_t));
            pos += sizeof(hash_key_t);
            
            /*  get blue attribute  */
            memcpy(&blue, buffer + pos, 1);
            pos ++;
          
            /*  get red attribute  */
            memcpy(&red, buffer + pos, 1);
            pos ++;
          
            /*  get length  */
            memcpy(&s_char_len, buffer + pos, sizeof(uint16_t));
            pos += sizeof(uint16_t);
            
            /*  get the state  */
            storage_insert_serialised(S, buffer + pos, s_char_len,
                                      h, my_worker_id, &is_new, &sid);
            pos += s_char_len;
            
            /*  set the blue and red attribute of the state  */
            if(blue) {
              storage_set_blue(S, sid, TRUE);
            }
            if(red) {
              storage_set_red(S, sid, TRUE);
            }
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
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    B.status[w] = BUCKET_OK;
    B.size[w] = 0;
    B.k[w] = 0;
  }

  /*  launch the communicator thread  */
  pthread_create(&W, NULL, &ddfs_comm_worker, NULL);
}

void ddfs_comm_end
() {
  void * dummy;

  pthread_join(W, &dummy);
  ddfs_comm_barrier();
  shmem_free(H);
  shmem_finalize();
}

#endif
