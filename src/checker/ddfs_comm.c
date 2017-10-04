#include "config.h"
#include "ddfs_comm.h"
#include "comm_shmem.h"

#if defined(CFG_ALGO_DDFS)

#include "shmem.h"

#define PUBLISH_PERIOD_MS  10
#define BUFFER_SIZE        (CFG_SYM_HEAP_SIZE - sizeof(heap_prefix_t))
#define BUFFER_WORKER_SIZE (BUFFER_SIZE / CFG_NO_WORKERS)
#define BUCKET_OK          1
#define BUCKET_WRITE       2

#include "ddfs_comm.h"

typedef struct {
  bool_t   terminated;  /*  has all workers of the PE terminated  */
  uint32_t size; /*  number of states published by the PE  */
  uint32_t char_len; /*  total number of characters put by the PE  */
} heap_prefix_t;

typedef struct {
  uint8_t status[CFG_NO_WORKERS];
  uint32_t size[CFG_NO_WORKERS];
  uint32_t char_len[CFG_NO_WORKERS];
  bool_t full[CFG_NO_WORKERS];
  char buffer[CFG_NO_WORKERS][BUFFER_WORKER_SIZE];
  uint16_t k[CFG_NO_WORKERS];
} ddfs_comm_buffers_t;

const struct timespec PUBLISH_PERIOD = { 0, PUBLISH_PERIOD_MS * 1000000 };
const struct timespec WAIT_TIME = { 0, 10 };

ddfs_comm_buffers_t BUF;
storage_t S;
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
 event_list_t en) {
  uint16_t s_char_len, len;
  bit_vector_t s;
  bool_t red = FALSE, blue = FALSE;
  hash_key_t h;
  void * pos;

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
  if(list_size(en) < CFG_DDFS_COMM_STRAT_DEGREE) {
    assert(0);
    return;
  }
#endif
#if defined(CFG_DDFS_COMM_STRAT_K)
  BUF.k[w] ++;
  if(BUF.k[w] < CFG_DDFS_COMM_STRAT_K) {
    assert(0);
    return;
  }
#endif
  BUF.k[w] = 0;
#endif

  /*
   *  put the state of worker w in its buffer
   */
  if(!BUF.full[w] && CAS(&BUF.status[w], BUCKET_OK, BUCKET_WRITE)) {
    storage_get_serialised(S, id, &s, &s_char_len);
    len = sizeof(hash_key_t)
      + (storage_has_attr(S, ATTR_BLUE) ? sizeof(bool_t) : 0)
      + (storage_has_attr(S, ATTR_RED) ? sizeof(bool_t) : 0)
      + sizeof(uint16_t)
      + s_char_len;
    if(len + BUF.char_len[w] > BUFFER_WORKER_SIZE) {
      BUF.full[w] = TRUE;
    } else {
      if(BUF.size[w] == 0) {
        memset(BUF.buffer[w], 0, BUFFER_WORKER_SIZE);
      }
      BUF.size[w] ++;
      pos = BUF.buffer[w] + BUF.char_len[w];
      BUF.char_len[w] += len;
      
      /*  hash value  */
      h = storage_get_hash(S, id);
      memcpy(pos, &h, sizeof(hash_key_t));
      pos += sizeof(hash_key_t);
     
      /*  blue attribute  */
      if(storage_has_attr(S, ATTR_BLUE)) {
        blue = storage_get_blue(S, id);
        memcpy(pos, &blue, sizeof(bool_t));
        pos += sizeof(bool_t);
      }
          
      /*  red attribute  */
      if(storage_has_attr(S, ATTR_RED)) {
        red = storage_get_red(S, id);
        memcpy(pos, &red, sizeof(bool_t));
        pos += sizeof(bool_t);
      }
          
      /*  char length  */
      memcpy(pos, &s_char_len, sizeof(uint16_t));
      pos += sizeof(uint16_t);
          
      /*  state vector  */
      memcpy(pos, s, s_char_len);
      pos += s_char_len;
    }    
    BUF.status[w] = BUCKET_OK;
  }
}

void * ddfs_comm_worker
(void * arg) {
  const worker_id_t my_worker_id = CFG_NO_WORKERS;
  int i, pe;
  worker_id_t w;
  bool_t loop = TRUE;
  heap_prefix_t pref,  pref_other[PES];
  void * pos;
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
     *  1st step: put every state of the local buffers in the
     *  symmetrical heap
     */
    comm_shmem_barrier();
    pref.size = 0;
    pref.char_len = sizeof(heap_prefix_t);
    pref.terminated = !context_keep_searching();
    for(w = 0; w < CFG_NO_WORKERS; w ++) {
      
      /*  wait for the bucket of thread w to be ready  */
      while(!CAS(&BUF.status[w], BUCKET_OK, BUCKET_WRITE)) {
	nanosleep(&WAIT_TIME, NULL);
      }
      comm_shmem_put(H + pref.char_len, BUF.buffer[w], BUF.char_len[w], ME,
                     my_worker_id);
      pref.char_len += BUF.char_len[w];
      pref.size += BUF.size[w];
      BUF.char_len[w] = 0;
      BUF.size[w] = 0;
      BUF.full[w] = FALSE;
      BUF.status[w] = BUCKET_OK;
    }
    pref.char_len -= sizeof(heap_prefix_t);
    
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

    /*  get states put by remote PEs in their heap and put these in my
        local storage */
    for(pe = 0; pe < PES ; pe ++) {
      if(ME == pe) continue;

      comm_shmem_get(buffer, H + sizeof(heap_prefix_t),
                     pref_other[pe].char_len, pe, my_worker_id);
      pos = buffer;
      for(i = 0; i < pref_other[pe].size; i++) {

        /*  get hash value  */
        memcpy(&h, pos, sizeof(hash_key_t));
        pos += sizeof(hash_key_t);
                    
        /*  get blue attribute  */
        if(storage_has_attr(S, ATTR_BLUE)) {
          memcpy(&blue, pos, sizeof(bool_t));
          pos += sizeof(bool_t);
        }
          
        /*  get red attribute  */
        if(storage_has_attr(S, ATTR_RED)) {
          memcpy(&red, pos, sizeof(bool_t));
          pos += sizeof(bool_t);
        }
          
        /*  get length  */
        memcpy(&s_char_len, pos, sizeof(uint16_t));
        pos += sizeof(uint16_t);
            
        /*  get the state  */
        storage_insert_serialised(S, pos, s_char_len,
                                  h, my_worker_id, &is_new, &sid);
        pos += s_char_len;
          
        /*  set the blue and red attribute of the state  */
        if(blue && storage_has_attr(S, ATTR_BLUE)) {
          storage_set_blue(S, sid, TRUE);
        }
        if(red && storage_has_attr(S, ATTR_RED)) {
          storage_set_red(S, sid, TRUE);
        }

        /*  if the state is new it may be garbage collected  */
        if(is_new && storage_has_attr(S, ATTR_GARBAGE)) {
          storage_set_garbage(S, my_worker_id, sid, TRUE);
        }
      }
    }
  }
  return NULL;
}

void ddfs_comm_start
() {
  worker_id_t w;
  pthread_t worker;

  /*  shmem and symmetrical heap initialisation  */
  comm_shmem_init();
  H = shmem_malloc(CFG_SYM_HEAP_SIZE * shmem_n_pes());
  PES = shmem_n_pes();
  ME = shmem_my_pe();
  
  S = context_storage();
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    BUF.status[w] = BUCKET_OK;
    BUF.size[w] = 0;
    BUF.char_len[w] = 0;
    BUF.full[w] = FALSE;
    BUF.k[w] = 0;
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
