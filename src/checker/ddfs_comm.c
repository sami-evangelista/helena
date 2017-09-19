#include "ddfs_comm.h"
#include "comm_shmem.h"

#if defined(CFG_ALGO_DDFS)

#define MAX_BOX_SIZE      100000
#define PUBLISH_PERIOD_MS 10

#define BUFFER_SIZE       (CFG_SYM_HEAP_SIZE - sizeof(heap_prefix_t))
#define BUCKET_OK         1
#define BUCKET_WRITE      2

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

const struct timespec PUBLISH_PERIOD = { 0, PUBLISH_PERIOD_MS * 1000000 };
const struct timespec WAIT_TIME = { 0, 10 };

ddfs_comm_boxes_t B;
storage_t S;
report_t R;
pthread_t W;
int PES;
int ME;

/**
 *  the symmetric heap
 */
void * H;

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
#if defined(CFG_DDFS_COMM_STRAT_MINE)
  if(storage_get_hash(S, id) % PES != ME) {
    assert(0);
    return;
  }
#endif
#if defined(CFG_DDFS_COMM_STRAT_DEGREE)
  if(mevent_set_size(en) < CFG_DDFS_COMM_STRAT_DEGREE) {
    assert(0);
    return;
  }
#endif
#if defined(CFG_DDFS_COMM_STRAT_K)
  B.k[w] ++;
  if(B.k[w] < CFG_DDFS_COMM_STRAT_K) {
    assert(0);
    return;
  }
#endif
  B.k[w] = 0;
#endif

  /*
   *  put the state of worker w in its box and increase its reference
   *  counter
   */
 loop:
  if(CAS(&B.status[w], BUCKET_OK, BUCKET_WRITE)) {
    if(B.size[w] < MAX_BOX_SIZE) {
      B.box[w][B.size[w]] = id;
      B.size[w] ++;
      storage_ref(S, w, id);
    } else {
      B.status[w] = BUCKET_OK;
      goto loop;
    }
    B.status[w] = BUCKET_OK;
  } else {
    goto loop;
  }
}

void * ddfs_comm_worker
(void * arg) {
  const worker_id_t my_worker_id = CFG_NO_WORKERS;
  int i, pe;
  worker_id_t w;
  bool_t loop = TRUE;
  heap_prefix_t pref,  pref_other[PES];
  uint32_t pos;
  uint16_t s_char_len, len;
  storage_id_t sid;
  bit_vector_t s;
  bool_t red = FALSE, blue = FALSE, is_new;
  char buffer[CFG_SYM_HEAP_SIZE];
  hash_key_t h;
  
  pref.terminated = FALSE;
  while(loop) {
    
    nanosleep(&PUBLISH_PERIOD, NULL);

    /**
     *  1st step: put every state of the local shared box in the
     *  symmetrical heap
     */
    comm_shmem_barrier();
    pref.size = 0;
    pref.char_len = sizeof(heap_prefix_t);
    for(w = 0; w < CFG_NO_WORKERS; w ++) {

      /*  wait for the bucket of thread w to be ready  */
      while(!CAS(&B.status[w], BUCKET_OK, BUCKET_WRITE)) {
	nanosleep(&WAIT_TIME, NULL);
      }

      /*  put all states of the queue of worker w in the local heap  */
      for(i = 0; i < B.size[w]; i ++) {

        /*  get the serialised state and check whether there enough
            space in the heap to put it */
        sid = B.box[w][i];
        storage_get_serialised(S, sid, &s, &s_char_len);
        len = sizeof(hash_key_t) + 2 + sizeof(uint16_t) + s_char_len;
        if(pref.char_len + len > BUFFER_SIZE) {
          break;
        }

        /*  put its hash value  */
        h = storage_get_hash(S, sid);
        comm_shmem_put(H + pref.char_len, &h, sizeof(hash_key_t), ME,
                       my_worker_id);
        pref.char_len += sizeof(hash_key_t);
          
        /*  put its blue attribute  */
        if(storage_has_attr(S, ATTR_BLUE)) {
          blue = storage_get_blue(S, sid);
          comm_shmem_put(H + pref.char_len, &blue, 1, ME,
                         my_worker_id);
          pref.char_len ++;
        }
          
        /*  put its red attribute  */
        if(storage_has_attr(S, ATTR_RED)) {
          red = storage_get_red(S, sid);
          comm_shmem_put(H + pref.char_len, &red, 1, ME,
                         my_worker_id);
          pref.char_len ++;
        }
          
        /*  put its char length  */
        comm_shmem_put(H + pref.char_len, &s_char_len, sizeof(uint16_t), ME,
                       my_worker_id);
        pref.char_len += sizeof(uint16_t);
          
        /*  put the state  */
        comm_shmem_put(H + pref.char_len, s, s_char_len, ME,
                       my_worker_id);
        pref.char_len += s_char_len;

        /*  and decrease its reference counter  */
        storage_unref(S, my_worker_id, sid);
        
        pref.size ++;
      }

      /*  reinitialise the queue of worker w and make it available  */
      B.size[w] = 0;
      B.status[w] = BUCKET_OK;
    }
    pref.char_len -= sizeof(heap_prefix_t);

    /*  notify others if the search has terminated  */
    if(!R->keep_searching) {
      pref.terminated = TRUE;
    }

    /*  put my prefix in my local heap  */
    comm_shmem_put(H, &pref, sizeof(heap_prefix_t), ME, my_worker_id);

    /**
     *  2nd step: get all the states sent py remote PEs
     */
    comm_shmem_barrier();
    
    /*  first read the heap prefixes of all remote PEs  */
    loop = !pref.terminated;
    for(pe = 0; pe < PES ; pe ++) {
      if(ME != pe) {
        comm_shmem_get(&pref_other[pe], H, sizeof(heap_prefix_t), pe,
                       my_worker_id);
        if(!pref_other[pe].terminated) {
          loop = TRUE;
        }
      }
    }

    /*  at least one process has not finished and neither have I =>
        get states put by remote PEs in their heap and put these in my
        local storage */
    if(loop && R->keep_searching) {
      for(pe = 0; pe < PES ; pe ++) {
        if(ME != pe) {
          comm_shmem_get(buffer, H + sizeof(heap_prefix_t),
                         pref_other[pe].char_len, pe, my_worker_id);
          pos = 0;
          for(i = 0; i < pref_other[pe].size; i++) {

            /*  get hash value  */
            memcpy(&h, buffer + pos, sizeof(hash_key_t));
            pos += sizeof(hash_key_t);
            
            /*  get blue attribute  */
            if(storage_has_attr(S, ATTR_BLUE)) {
              memcpy(&blue, buffer + pos, 1);
              pos ++;
            }
          
            /*  get red attribute  */
            if(storage_has_attr(S, ATTR_RED)) {
              memcpy(&red, buffer + pos, 1);
              pos ++;
            }
          
            /*  get length  */
            memcpy(&s_char_len, buffer + pos, sizeof(uint16_t));
            pos += sizeof(uint16_t);
            
            /*  get the state  */
            storage_insert_serialised(S, buffer + pos, s_char_len,
                                      h, my_worker_id, &is_new, &sid);
            pos += s_char_len;
            
            /*  set the blue and red attribute of the state  */
            if(blue && storage_has_attr(S, ATTR_BLUE)) {
              storage_set_blue(S, sid, TRUE);
            }
            if(red && storage_has_attr(S, ATTR_RED)) {
              storage_set_red(S, sid, TRUE);
            }

            /*  the new state may be garbage collected  */
            if(is_new && storage_has_attr(S, ATTR_GARBAGE)) {
              storage_set_garbage(S, my_worker_id, sid, TRUE);
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
  comm_shmem_init(r);
  H = shmem_malloc(CFG_SYM_HEAP_SIZE * shmem_n_pes());
  PES = shmem_n_pes();
  ME = shmem_my_pe();
  
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
  comm_shmem_finalize(H);
}

#endif  /*  defined(CFG_ALGO_DDFS)  */
