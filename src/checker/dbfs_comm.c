#include "dbfs_comm.h"
#include "comm_shmem.h"

#if defined(CFG_ALGO_DBFS)

#define COMM_WAIT_TIME_MS       2
#define WORKER_WAIT_TIME_MS     1
#define WORKER_STATE_BUFFER_LEN 10000

#define DBFS_COMM_DEBUG

typedef struct {
  uint32_t pos;
  bit_vector_t buffer;
} buffer_data_t;

typedef struct {
  uint32_t no_states;
  uint32_t len;
} buffer_prefix_t;

typedef struct {
  heap_t * heaps[CFG_NO_WORKERS];
  hash_tbl_t * states[CFG_NO_WORKERS];
  uint32_t * len[CFG_NO_WORKERS];
  uint32_t * remote_pos[CFG_NO_WORKERS];
} worker_buffers_t;

const struct timespec COMM_WAIT_TIME = { 0, COMM_WAIT_TIME_MS * 1000000 };
const struct timespec WORKER_WAIT_TIME = { 0, WORKER_WAIT_TIME_MS * 1000000 };

storage_t S;
bfs_queue_t Q;
pthread_t W;
pthread_barrier_t LB;
worker_buffers_t BUF;
bool_t LOCAL_TERM;
bool_t GLOB_TERM;
uint32_t SYM_HEAP_SIZE;
uint32_t SYM_HEAP_SIZE_WORKER;
uint32_t SYM_HEAP_SIZE_PE;
int PES;
int ME;


/**
 *  remotely accessible items
 */
static bool_t H_TERM = FALSE;
static uint64_t H_QUEUE_SIZE = 0;
void * H;


/**
 * @fn dbfs_comm_state_owner
 */
bool_t dbfs_comm_state_owner
(hash_key_t h) {
  h = (h >> 24) + (h >> 16 && 0xff) + (h >> 8 & 0xff) + h & 0xff;
  return h % PES;
}


/**
 * @fn dbfs_comm_state_owned
 */
bool_t dbfs_comm_state_owned
(hash_key_t h) {
  return dbfs_comm_state_owner(h) == ME;
}


/**
 * @fn Function: dbfs_comm_global_termination
 */
bool_t dbfs_comm_global_termination
() {
  return GLOB_TERM;
}


/**
 * @fn dbfs_comm_notify_level_termination
 */
void dbfs_comm_notify_level_termination
() {
  LOCAL_TERM = TRUE;
}


/**
 * @fn dbfs_comm_local_barrier
 */
void dbfs_comm_local_barrier
() {
  pthread_barrier_wait(&LB);
}


/**
 * @fn dbfs_comm_reinit_buffer
 */
void dbfs_comm_reinit_buffer
(worker_id_t w,
 int pe) {
  if(BUF.states[w][pe]) {
    hash_tbl_free(BUF.states[w][pe]);
  }
  BUF.states[w][pe] = hash_tbl_new(WORKER_STATE_BUFFER_LEN * 2,
                                   1, FALSE, 100, 0, ATTR_CHAR_LEN);
  heap_reset(BUF.heaps[w][pe]);
  hash_tbl_set_heap(BUF.states[w][pe], BUF.heaps[w][pe]);
  BUF.len[w][pe] = 0;
}


/**
 * @fn dbfs_comm_fill_buffer
 */
void dbfs_comm_fill_buffer
(bit_vector_t s,
 uint16_t l,
 hash_key_t h,
 void * data) {
  buffer_data_t * buf = (buffer_data_t *) data;

  memcpy(buf->buffer + buf->pos, &h, sizeof(hash_key_t));
  buf->pos += sizeof(hash_key_t);
  memcpy(buf->buffer + buf->pos, &l, sizeof(uint16_t));
  buf->pos += sizeof(uint16_t);
  memcpy(buf->buffer + buf->pos, s, l);
  buf->pos += l;
}


/**
 * @fn dbfs_comm_send_buffer
 */
void dbfs_comm_send_buffer
(worker_id_t w,
 int pe) {
  buffer_prefix_t pref;
  char buffer[SYM_HEAP_SIZE_WORKER];
  buffer_data_t buf;

#if defined(DBFS_COMM_DEBUG)
  assert(hash_tbl_size(BUF.states[w][pe]) <= WORKER_STATE_BUFFER_LEN);
  assert(pe != ME);
  assert(BUF.len[w][pe] + sizeof(buffer_prefix_t) < SYM_HEAP_SIZE_WORKER);
#endif
  
  /**
   *  periodically poll the remote PE to see if I can send my
   *  states
   */
  do {
    comm_shmem_get(&pref, H + BUF.remote_pos[w][pe],
                   sizeof(buffer_prefix_t), pe, w);
    if(pref.no_states > 0) {
      nanosleep(&WORKER_WAIT_TIME, NULL);
    }
  } while(pref.no_states > 0);

  /**
   *  send my states to the remote PE
   */
  memset(buffer, 0, SYM_HEAP_SIZE_WORKER);
  buf.pos = 0;
  buf.buffer = buffer;
  hash_tbl_fold_serialised(BUF.states[w][pe], &dbfs_comm_fill_buffer, &buf);
#if defined(DBFS_COMM_DEBUG)
  assert(buf.pos == BUF.len[w][pe]);
#endif
  comm_shmem_put(H + BUF.remote_pos[w][pe] + sizeof(buffer_prefix_t),
                 buffer, buf.pos, pe, w);

  /**
   *  send my prefix to the remote PE
   */
  pref.no_states = hash_tbl_size(BUF.states[w][pe]);
  pref.len = buf.pos;
  comm_shmem_put(H + BUF.remote_pos[w][pe], &pref,
                 sizeof(buffer_prefix_t), pe, w);

  /**
   *  reinitialise the buffer
   */
  dbfs_comm_reinit_buffer(w, pe);
}


/**
 * @fn dbfs_comm_send_all_pending_states
 */
void dbfs_comm_send_all_pending_states
(worker_id_t w) {
  int pe;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME && hash_tbl_size(BUF.states[w][pe]) > 0) {
      dbfs_comm_send_buffer(w, pe);
    }
  }
}


/**
 * @fn dbfs_comm_process_state
 */
void dbfs_comm_process_state
(worker_id_t w,
 state_t s,
 hash_key_t h) {
  const uint16_t len = state_char_width(s);
  const int pe = dbfs_comm_state_owner(h);
  storage_id_t id;
  uint32_t no;
  bool_t is_new;

#if defined(DBFS_COMM_DEBUG)
  assert(ME != pe);
  assert(hash_tbl_size(BUF.states[w][pe]) <= WORKER_STATE_BUFFER_LEN);
#endif

  /**
   *  not enough space to put the state in the buffer => we first send
   *  the buffer content to the remote pe
   */
  if((BUF.len[w][pe] + sizeof(hash_key_t) + sizeof(uint16_t) + len >
      SYM_HEAP_SIZE_WORKER - sizeof(buffer_prefix_t))
     || (hash_tbl_size(BUF.states[w][pe]) == WORKER_STATE_BUFFER_LEN)) {
    dbfs_comm_send_buffer(w, pe);
  }

  /**
   *  insert the state in table
   */
  hash_tbl_insert_hashed(BUF.states[w][pe], s, 0, h, &is_new, &id);
  if(is_new) {
    BUF.len[w][pe] += sizeof(hash_key_t) + sizeof(uint16_t) + len;
  }
}


/**
 * @fn dbfs_comm_worker_process_incoming_states
 */
void dbfs_comm_worker_process_incoming_states
() {
  const worker_id_t my_worker_id = CFG_NO_WORKERS;
  uint32_t pos, tmp_pos, no_states;
  uint16_t s_len;
  bool_t states_received = TRUE, is_new;
  hash_key_t h;
  buffer_prefix_t pref;
  char buffer[SYM_HEAP_SIZE_WORKER];
  storage_id_t sid;
  bfs_queue_item_t item;
  heap_t heap = bounded_heap_new("", 10000);
  state_t s;
  
  while(states_received) {
    states_received = FALSE;
    for(pos = 0;
        pos < SYM_HEAP_SIZE;
        pos += SYM_HEAP_SIZE_WORKER) {
      comm_shmem_get(&pref, H + pos, sizeof(buffer_prefix_t), ME,
                     my_worker_id);
      if(pref.no_states > 0) {
        states_received = TRUE;
        comm_shmem_get(buffer, H + pos + sizeof(buffer_prefix_t),
                       pref.len, ME, my_worker_id);
        no_states = pref.no_states;
        pref.no_states = 0;
        pref.len = 0;
        comm_shmem_put(H + pos, &pref, sizeof(buffer_prefix_t), ME,
                       my_worker_id);
        tmp_pos = 0;
        while(no_states > 0) {

          /**
           *  read the state from the buffer and insert it in the
           *  storage
           */

          /*  hash value  */
          memcpy(&h, buffer + tmp_pos, sizeof(hash_key_t));
          tmp_pos += sizeof(hash_key_t);
          
          /*  state char length  */
          memcpy(&s_len, buffer + tmp_pos, sizeof(uint16_t));
          tmp_pos += sizeof(uint16_t);
          
          /*  insert the state  */
          storage_insert_serialised(S, buffer + tmp_pos, s_len,
                                    h, my_worker_id, &is_new, &sid);
          tmp_pos += s_len;

          /**
           * state is new => put it in the queue.  if the queue
           * contains full states we have to unserialise it
           */
          if(is_new) {
            item.id = sid;
#if !defined(STORAGE_STATE_RECOVERABLE)
            heap_reset(heap);
            s = state_unserialise_mem(buffer + tmp_pos - s_len, heap);
            item.s = s;
#endif
            bfs_queue_enqueue(Q, item, my_worker_id, h % CFG_NO_WORKERS);
#if !defined(STORAGE_STATE_RECOVERABLE)
            state_free(item.s);
#endif
          }
          no_states --;
        }
      }
    }
  }
  heap_free(heap);
}


/**
 * @fn dbfs_comm_worker
 */
void * dbfs_comm_worker
(void * arg) {
  const worker_id_t my_worker_id = CFG_NO_WORKERS;
  int pe, no_term = 0;
  uint64_t queue_size;
  bool_t remote_term[PES];
  
  for(pe = 0; pe < PES; pe ++) {
    remote_term[pe] = FALSE;
  }    
  while(!GLOB_TERM) {

    /**
     *  sleep a bit and process incoming states
     */
    nanosleep(&COMM_WAIT_TIME, NULL);
    dbfs_comm_worker_process_incoming_states();
    
    /**
     *  local threads have terminated the current BFS level.  put TRUE
     *  at beginning of the heap to notify other PE.  also check
     *  whether it is also the case for other PEs
     */
    if(LOCAL_TERM) {
      if(!H_TERM) {
        H_TERM = TRUE;
        no_term = 1;
      }
      for(pe = 0; pe < PES; pe ++) {
        if(pe != ME && !remote_term[pe]) {
          comm_shmem_get(&remote_term[pe], &H_TERM, sizeof(bool_t), pe,
                         my_worker_id);
          if(remote_term[pe]) {
            no_term ++;
          }
        }
      }

      /**
       *  all PEs have terminated the current level
       */
      if(no_term == PES) {

        /**
         *  every PE puts in its heap its queue size and read others's
         *  to check for termination
         */
        comm_shmem_barrier();
        H_QUEUE_SIZE = bfs_queue_size(Q);
        comm_shmem_barrier();
        if(0 == H_QUEUE_SIZE) {
          GLOB_TERM = TRUE;
          for(pe = 0; pe < PES && GLOB_TERM; pe ++) {
            if(pe != ME) {
              comm_shmem_get(&queue_size, &H_QUEUE_SIZE, sizeof(uint64_t), pe,
                             my_worker_id);
              if(0 != queue_size) {
                GLOB_TERM = FALSE;
              }
            }
          }
        }
        comm_shmem_barrier();

        /**
         *  reinitialise everything for termination detection at next
         *  level
         */
        H_TERM = FALSE;
        H_QUEUE_SIZE = 0;
        LOCAL_TERM = FALSE;
        no_term = 0;
        for(pe = 0; pe < PES; pe ++) {
          remote_term[pe] = FALSE;
        }

        /**
         *  synchronise with the working threads
         */
        dbfs_comm_local_barrier();
      }
    }
  }
}


/**
 * @fn dbfs_comm_start
 */
void dbfs_comm_start
(bfs_queue_t q) {
  int pe, remote_pos;
  worker_id_t w;
  
  /*  shmem and symmetrical heap initialisation  */
  comm_shmem_init();
  PES = shmem_n_pes();
  ME = shmem_my_pe();
  SYM_HEAP_SIZE_WORKER = CFG_SYM_HEAP_SIZE / ((PES - 1) * CFG_NO_WORKERS);
  SYM_HEAP_SIZE_PE = CFG_NO_WORKERS * SYM_HEAP_SIZE_WORKER;
  SYM_HEAP_SIZE = SYM_HEAP_SIZE_PE * (PES - 1);
  H = shmem_malloc(SYM_HEAP_SIZE);

  /*  initialise global variables  */
  Q = q;
  S = context_storage();
  LOCAL_TERM = FALSE;
  GLOB_TERM = FALSE;
  pthread_barrier_init(&LB, NULL, CFG_NO_WORKERS + 1);
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    BUF.remote_pos[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.len[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.states[w] = mem_alloc(SYSTEM_HEAP, sizeof(hash_tbl_t) * PES);
    BUF.heaps[w] = mem_alloc(SYSTEM_HEAP, sizeof(heap_t) * PES);
  }
  for(pe = 0; pe < PES; pe ++) {
    remote_pos = ME * SYM_HEAP_SIZE_PE;
    if(ME > pe) {
      remote_pos -= SYM_HEAP_SIZE_PE;
    }
    for(w = 0; w < CFG_NO_WORKERS; w ++) {
      if(ME == pe) {
        BUF.remote_pos[w][pe] = 0;          
      } else {
        BUF.remote_pos[w][pe] = remote_pos;
        BUF.states[w][pe] = NULL;
        BUF.heaps[w][pe] = bounded_heap_new("dbfs_comm buffer",
                                            SYM_HEAP_SIZE_WORKER);
        dbfs_comm_reinit_buffer(w, pe);
        remote_pos += SYM_HEAP_SIZE_WORKER;
      }
    }
  }

  /*  launch the communicator thread  */
  pthread_create(&W, NULL, &dbfs_comm_worker, NULL);
}


/**
 * @fn dbfs_comm_end
 */
void dbfs_comm_end
() {
  void * dummy;
  int pe;
  worker_id_t w;

  pthread_join(W, &dummy);
  comm_shmem_finalize(H);
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    for(pe = 0; pe < PES; pe ++) {
      if(ME != pe) {
        hash_tbl_free(BUF.states[w][pe]);
        heap_free(BUF.heaps[w][pe]);
      }
    }
    mem_free(SYSTEM_HEAP, BUF.states[w]);
    mem_free(SYSTEM_HEAP, BUF.heaps[w]);
    mem_free(SYSTEM_HEAP, BUF.len[w]);
    mem_free(SYSTEM_HEAP, BUF.remote_pos[w]);
  }
}

#endif  /*  defined(CFG_ALGO_DBFS)  */
