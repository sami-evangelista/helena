#include "dbfs_comm.h"
#include "comm_shmem.h"

#if defined(CFG_ALGO_DBFS)

#define COMM_WAIT_TIME_MS       5
#define WORKER_WAIT_TIME_MS     2
#define WORKER_STATE_BUFFER_LEN 10000

typedef struct {
  uint32_t no_states;
  uint32_t len;
} buffer_prefix_t;

typedef struct {
  hash_key_t h;
  uint16_t len;
  bit_vector_t s;
} packet_t;

typedef struct {
  bit_vector_t * buffers[CFG_NO_WORKERS];
  packet_t ** states[CFG_NO_WORKERS];
  uint32_t * pos[CFG_NO_WORKERS];
  uint32_t * len[CFG_NO_WORKERS];
  uint32_t * no_states[CFG_NO_WORKERS];
  uint32_t * remote_pos[CFG_NO_WORKERS];
} worker_buffers_t;

const struct timespec COMM_WAIT_TIME = { 0, COMM_WAIT_TIME_MS * 1000000 };
const struct timespec WORKER_WAIT_TIME = { 0, WORKER_WAIT_TIME_MS * 1000000 };

report_t R;
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
 *  remotely accesible items
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
 * @fn dbfs_comm_init_buffer
 */
void dbfs_comm_init_buffer
(worker_id_t w,
 int pe) {
  memset(BUF.buffers[w][pe], 0,
         SYM_HEAP_SIZE_WORKER - sizeof(buffer_prefix_t));
}


/**
 * @fn dbfs_comm_sort_buffer
 */
void dbfs_comm_sort_buffer
(worker_id_t w,
 int pe) {
}


/**
 * @fn dbfs_comm_send_buffer
 */
void dbfs_comm_send_buffer
(worker_id_t w,
 int pe) {
  uint32_t no;
  uint32_t i, len;
  buffer_prefix_t pref;
  char buffer[SYM_HEAP_SIZE_WORKER];

#if defined(DBFS_COMM_DEBUG)
  assert(no <= WORKER_STATE_BUFFER_LEN);
  assert(pe != ME);
  assert(BUF.len[w][pe] + sizeof(buffer_prefix_t) < SYM_HEAP_SIZE_WORKER);
#endif

  /**
   *  first sort the buffer to remove duplicate states
   */  
  dbfs_comm_sort_buffer(w, pe);
  
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
   *  send my states to the remote PE.  first send the states then the
   *  prefix
   */
  len = 0;
  no = BUF.no_states[w][pe];
  for(i = 0; i < no; i ++) {
    memcpy(buffer + len, &(BUF.states[w][pe][i].h), sizeof(hash_key_t));
    len += sizeof(hash_key_t);
    memcpy(buffer + len, &(BUF.states[w][pe][i].len), sizeof(uint16_t));
    len += sizeof(uint16_t);
    memcpy(buffer + len, BUF.states[w][pe][i].s, BUF.states[w][pe][i].len);
    len += BUF.states[w][pe][i].len;  
  }
#if defined(DBFS_COMM_DEBUG)
  assert(len == BUF.len[w][pe]);
#endif
  comm_shmem_put(H + BUF.remote_pos[w][pe] + sizeof(buffer_prefix_t),
                 buffer, len, pe, w);
  pref.no_states = no;
  pref.len = BUF.len[w][pe];
  comm_shmem_put(H + BUF.remote_pos[w][pe], &pref,
                 sizeof(buffer_prefix_t), pe, w);

  /**
   *  reinitialise the buffer
   */
  BUF.no_states[w][pe] = 0;
  BUF.pos[w][pe] = 0;
  BUF.len[w][pe] = 0;
  dbfs_comm_init_buffer(w, pe);
}


/**
 * @fn dbfs_comm_send_all_pending_states
 */
void dbfs_comm_send_all_pending_states
(worker_id_t w) {
  int pe;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME && BUF.no_states[w][pe] > 0) {
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
  uint32_t no;

#if defined(DBFS_COMM_DEBUG)
  assert(ME != pe);
  assert(BUF.no_states[w][pe] <= WORKER_STATE_BUFFER_LEN);
#endif

  /**
   *  not enough space to put the state in the buffer => we first send
   *  the buffer content to the remote pe
   */
  if((BUF.len[w][pe] + sizeof(hash_key_t) + sizeof(uint16_t) + len >
      SYM_HEAP_SIZE_WORKER - sizeof(buffer_prefix_t))
     || (BUF.no_states[w][pe] == WORKER_STATE_BUFFER_LEN)) {
    dbfs_comm_send_buffer(w, pe);
  }

  /**
   *  put the state in the buffer
   */
  no = BUF.no_states[w][pe];
  state_serialise(s, BUF.buffers[w][pe] + BUF.pos[w][pe]);
  BUF.states[w][pe][no].h = h;
  BUF.states[w][pe][no].len = len;
  BUF.states[w][pe][no].s = BUF.buffers[w][pe] + BUF.pos[w][pe];
  BUF.pos[w][pe] += len;
  BUF.len[w][pe] += sizeof(hash_key_t) + sizeof(uint16_t) + len;
  BUF.no_states[w][pe] ++; 
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
#if defined(BFS_QUEUE_STATE_IN_QUEUE)
            heap_reset(heap);
            s = state_unserialise_mem(buffer + tmp_pos - s_len, heap);
            item.s = s;
#endif
            bfs_queue_enqueue(Q, item, my_worker_id, h % CFG_NO_WORKERS);
#if defined(BFS_QUEUE_STATE_IN_QUEUE)
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
(report_t r,
 bfs_queue_t q) {
  int pe, remote_pos;
  worker_id_t w;
  
  /*  shmem and symmetrical heap initialisation  */
  comm_shmem_init(r);
  PES = shmem_n_pes();
  ME = shmem_my_pe();
  SYM_HEAP_SIZE_WORKER = CFG_SYM_HEAP_SIZE / ((PES - 1) * CFG_NO_WORKERS);
  SYM_HEAP_SIZE_PE = CFG_NO_WORKERS * SYM_HEAP_SIZE_WORKER;
  SYM_HEAP_SIZE = SYM_HEAP_SIZE_PE * (PES - 1);
  H = shmem_malloc(SYM_HEAP_SIZE);

  /*  initialise global variables  */
  Q = q;
  R = r;
  S = R->storage;
  LOCAL_TERM = FALSE;
  GLOB_TERM = FALSE;
  pthread_barrier_init(&LB, NULL, CFG_NO_WORKERS + 1);
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    BUF.buffers[w] = mem_alloc(SYSTEM_HEAP, sizeof(bit_vector_t) * PES);
    BUF.pos[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.remote_pos[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.no_states[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.len[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.states[w] = mem_alloc(SYSTEM_HEAP, sizeof(packet_t *) * PES);
    for(pe = 0; pe < PES; pe ++) {
      if(ME != pe) {
        BUF.states[w][pe] =
          mem_alloc(SYSTEM_HEAP, sizeof(packet_t) * WORKER_STATE_BUFFER_LEN);
      }
    }
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
        BUF.no_states[w][pe] = 0;
        BUF.pos[w][pe] = 0;
        BUF.len[w][pe] = 0;
        BUF.buffers[w][pe] = mem_alloc(SYSTEM_HEAP,
                                       SYM_HEAP_SIZE_WORKER -
                                       sizeof(buffer_prefix_t));
        BUF.remote_pos[w][pe] = remote_pos;
        remote_pos += SYM_HEAP_SIZE_WORKER;
        dbfs_comm_init_buffer(w, pe);
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
        mem_free(SYSTEM_HEAP, BUF.buffers[w][pe]);
        mem_free(SYSTEM_HEAP, BUF.states[w][pe]);
      }
    }
    mem_free(SYSTEM_HEAP, BUF.no_states[w]);
    mem_free(SYSTEM_HEAP, BUF.buffers[w]);
    mem_free(SYSTEM_HEAP, BUF.pos[w]);
    mem_free(SYSTEM_HEAP, BUF.remote_pos[w]);
  }
}

#endif  /*  defined(CFG_ALGO_DBFS)  */
