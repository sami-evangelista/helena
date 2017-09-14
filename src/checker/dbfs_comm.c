#include "dbfs_comm.h"

#if defined(CFG_ALGO_DBFS)

#define SYM_HEAP_PREFIX_SIZE (sizeof(bool_t) + sizeof(uint64_t))
#define COMM_WAIT_TIME_MS    0
#define WORKER_WAIT_TIME_MS  0

typedef struct {
  uint32_t no_states;
  uint32_t char_len;
} buffer_prefix_t;

typedef struct {
  bit_vector_t * buffers[CFG_NO_WORKERS];
  uint32_t * states[CFG_NO_WORKERS];
  uint32_t * pos[CFG_NO_WORKERS];
  uint32_t * remote_pos[CFG_NO_WORKERS];
} worker_buffers_t;

const struct timespec COMM_WAIT_TIME = { 0, COMM_WAIT_TIME_MS * 1000000 };
const struct timespec WORKER_WAIT_TIME = { 0, WORKER_WAIT_TIME_MS * 1000000 };

report_t R;
storage_t S;
bfs_queue_t Q;
pthread_t W;
void * H;
pthread_barrier_t B;
worker_buffers_t BUF;
bool_t LOCAL_TERM;
bool_t GLOB_TERM;
uint32_t SYM_HEAP_SIZE;
uint32_t SYM_HEAP_SIZE_WORKER;
uint32_t SYM_HEAP_SIZE_PE;
int PES;
int ME;


/**
 *
 *  Function: dbfs_comm_state_owner
 *
 */
bool_t dbfs_comm_state_owner
(hash_key_t h) {
  h = (h >> 24) + (h >> 16 && 0xff) + (h >> 8 & 0xff) + h & 0xff;
  return h % PES;
}


/**
 *
 *  Function: dbfs_comm_state_owned
 *
 */
bool_t dbfs_comm_state_owned
(hash_key_t h) {
  return dbfs_comm_state_owner(h) == ME;
}


/**
 *
 *  Function: dbfs_comm_global_termination
 *
 */
bool_t dbfs_comm_global_termination
() {
  return GLOB_TERM;
}


/**
 *
 *  Function: dbfs_comm_notify_level_termination
 *
 */
void dbfs_comm_notify_level_termination
() {
  LOCAL_TERM = TRUE;
}


/**
 *
 *  Function: dbfs_comm_local_barrier
 *
 */
void dbfs_comm_local_barrier
() {
  pthread_barrier_wait(&B);
}


/**
 *
 *  Function: dbfs_comm_send_buffer
 *
 */
void dbfs_comm_send_buffer
(worker_id_t w,
 int pe) {
  buffer_prefix_t pref;
  
  /**
   *  periodically poll the remote PE to see if I can send my
   *  states
   */
  do {
    shmem_getmem(&pref, H + BUF.remote_pos[w][pe],
                 sizeof(buffer_prefix_t), pe);
    if(pref.no_states > 0) {
      nanosleep(&WORKER_WAIT_TIME, NULL);
    }
  } while(pref.no_states > 0);

  /**
   *  send my states to the remote PE.  first send the states then the
   *  prefix
   */
  pref.no_states = BUF.states[w][pe];
  pref.char_len = BUF.pos[w][pe];
  shmem_putmem(H + BUF.remote_pos[w][pe] + sizeof(buffer_prefix_t),
               BUF.buffers[w][pe], BUF.pos[w][pe], pe);
  shmem_putmem(H + BUF.remote_pos[w][pe], &pref, sizeof(buffer_prefix_t), pe);

  /**
   *  reinitialise the buffer
   */
  BUF.states[w][pe] = 0;
  BUF.pos[w][pe] = 0;
}


/**
 *
 *  Function: dbfs_comm_send_all_pending_states
 *
 */
void dbfs_comm_send_all_pending_states
(worker_id_t w) {
  int pe;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME && BUF.states[w][pe] > 0) {
      dbfs_comm_send_buffer(w, pe);
    }
  }
}


/**
 *
 *  Function: dbfs_comm_process_state
 *
 */
void dbfs_comm_process_state
(worker_id_t w,
 state_t s,
 hash_key_t h) {
  uint16_t s_char_len = state_char_width(s);
  const int pe = dbfs_comm_state_owner(h);

  /**
   *  not enough space to put the state in the buffer => we first send
   *  the buffer content to the remote pe
   */
  if(BUF.pos[w][pe] + sizeof(hash_key_t) + sizeof(uint16_t) + s_char_len >
     SYM_HEAP_SIZE_WORKER - sizeof(buffer_prefix_t)) {
    dbfs_comm_send_buffer(w, pe);
  }

  /**
   *  write the state in the buffer
   */
  BUF.states[w][pe] ++;
  
  /*  hash value  */
  memcpy(BUF.buffers[w][pe] + BUF.pos[w][pe], &h, sizeof(hash_key_t));
  BUF.pos[w][pe] += sizeof(hash_key_t);
  
  /*  state char length  */
  memcpy(BUF.buffers[w][pe] + BUF.pos[w][pe], &s_char_len, sizeof(uint16_t));
  BUF.pos[w][pe] += sizeof(uint16_t);
  
  /*  state serialisation  */
  memset(BUF.buffers[w][pe] + BUF.pos[w][pe], 0, s_char_len);
  state_serialise(s, BUF.buffers[w][pe] + BUF.pos[w][pe]);
  BUF.pos[w][pe] += s_char_len;
}


/**
 *
 *  Function: dbfs_comm_barrier
 *
 */
void dbfs_comm_barrier
() {
  lna_timer_t t;
  lna_timer_init(&t);
  lna_timer_start(&t);
  shmem_barrier_all();
  lna_timer_stop(&t);
  R->distributed_barrier_time += lna_timer_value(t);
}


/**
 *
 *  Function: dbfs_comm_worker_process_incoming_states
 *
 */
void dbfs_comm_worker_process_incoming_states
() {
  const worker_id_t my_worker_id = CFG_NO_WORKERS;
  uint32_t pos, tmp_pos, no_states;
  uint16_t s_char_len;
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
    for(pos = SYM_HEAP_PREFIX_SIZE;
        pos < SYM_HEAP_SIZE;
        pos += SYM_HEAP_SIZE_WORKER) {
      shmem_getmem(&pref, H + pos, sizeof(buffer_prefix_t), ME);
      if(pref.no_states > 0) {
        states_received = TRUE;
        shmem_getmem(buffer, H + pos + sizeof(buffer_prefix_t),
                     pref.char_len, ME);
        no_states = pref.no_states;
        pref.no_states = 0;
        pref.char_len = 0;
        shmem_putmem(H + pos, &pref, sizeof(buffer_prefix_t), ME);
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
          memcpy(&s_char_len, buffer + tmp_pos, sizeof(uint16_t));
          tmp_pos += sizeof(uint16_t);
          
          /*  insert the state  */
          storage_insert_serialised(S, buffer + tmp_pos, s_char_len,
                                    h, my_worker_id, &is_new, &sid);
          tmp_pos += s_char_len;

          /**
           * state is new => put it in the queue.  if the queue
           * contains full states we have to unserialise it
           */
          if(is_new) {
            item.id = sid;
#if defined(BFS_QUEUE_STATE_IN_QUEUE)
            heap_reset(heap);
            s = state_unserialise_mem(buffer + tmp_pos - s_char_len, heap);
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
 *
 *  Function: dbfs_comm_worker
 *
 */
void * dbfs_comm_worker
(void * arg) {
  int pe, term = 0;
  uint64_t queue_size;
  bool_t term_set = FALSE, remote_term[PES], states_received;
  
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
      if(!term_set) {
        remote_term[ME] = TRUE;
        term_set = TRUE;
        shmem_putmem(H, &remote_term[ME], sizeof(bool_t), ME);
        term = 1;
      }
      for(pe = 0; pe < PES; pe ++) {
        if(pe != ME && !remote_term[pe]) {
          shmem_getmem(&remote_term[pe], H, sizeof(bool_t), pe);
          if(remote_term[pe]) {
            term ++;
          }
        }
      }

      /**
       *  all PEs have terminated the current level
       */
      if(term == PES) {

        /**
         *  every PE puts in its heap its queue size and read others's
         *  to check for termination
         */
        queue_size = bfs_queue_size(Q);
        shmem_putmem(H + sizeof(bool_t), &queue_size, sizeof(uint64_t), ME);
        dbfs_comm_barrier();
        if(0 == queue_size) {
          GLOB_TERM = TRUE;
          for(pe = 0; pe < PES && GLOB_TERM; pe ++) {
            if(pe != ME) {
              shmem_getmem(&queue_size, H + sizeof(bool_t),
                           sizeof(uint64_t), pe);
              if(0 != queue_size) {
                GLOB_TERM = FALSE;
              }
            }
          }
        }
        dbfs_comm_barrier();

        /**
         *  reinitialise everything for termination detection at next
         *  level
         */
        for(pe = 0; pe < PES; pe ++) {
          remote_term[pe] = FALSE;
        }
        LOCAL_TERM = FALSE;
        term_set = FALSE;
        term = 0;
        queue_size = 0;
        shmem_putmem(H, &remote_term[ME], sizeof(bool_t), ME);
        shmem_putmem(H, &queue_size, sizeof(uint64_t), ME);

        /**
         *  synchronise with the working threads
         */
        dbfs_comm_local_barrier();
      }
    }
  }
}


/**
 *
 *  Function: dbfs_comm_start
 *
 */
void dbfs_comm_start
(report_t r,
 bfs_queue_t q) {
  int pe, remote_pos;
  worker_id_t w;
  
  /*  shmem and symmetrical heap initialisation  */
  shmem_init();
  PES = shmem_n_pes();
  ME = shmem_my_pe();
  SYM_HEAP_SIZE_WORKER = CFG_SYM_HEAP_SIZE - SYM_HEAP_PREFIX_SIZE;
  SYM_HEAP_SIZE_WORKER /= PES - 1;
  SYM_HEAP_SIZE_WORKER /= CFG_NO_WORKERS;
  SYM_HEAP_SIZE_PE = CFG_NO_WORKERS * SYM_HEAP_SIZE_WORKER;
  SYM_HEAP_SIZE = SYM_HEAP_SIZE_PE * (PES - 1) + SYM_HEAP_PREFIX_SIZE;
  H = shmem_malloc(SYM_HEAP_SIZE);

  /*  initialise global variables  */
  Q = q;
  R = r;
  S = R->storage;
  LOCAL_TERM = FALSE;
  GLOB_TERM = FALSE;
  pthread_barrier_init(&B, NULL, CFG_NO_WORKERS + 1);
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    BUF.buffers[w] = mem_alloc(SYSTEM_HEAP, sizeof(bit_vector_t) * PES);
    BUF.pos[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.remote_pos[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.states[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
  }
  for(pe = 0; pe < PES; pe ++) {
    remote_pos = SYM_HEAP_PREFIX_SIZE + ME * SYM_HEAP_SIZE_PE;
    if(ME > pe) {
      remote_pos -= SYM_HEAP_SIZE_PE;
    }
    for(w = 0; w < CFG_NO_WORKERS; w ++) {
      if(ME == pe) {
        BUF.remote_pos[w][pe] = 0;          
      } else {
        BUF.states[w][pe] = 0;
        BUF.pos[w][pe] = 0;
        BUF.buffers[w][pe] = mem_alloc(SYSTEM_HEAP,
                                       SYM_HEAP_SIZE_WORKER -
                                       sizeof(buffer_prefix_t));
        BUF.remote_pos[w][pe] = remote_pos;
        remote_pos += SYM_HEAP_SIZE_WORKER;
      }
    }
  }

  /*  launch the communicator thread  */
  pthread_create(&W, NULL, &dbfs_comm_worker, NULL);
}


/**
 *
 *  Function: dbfs_comm_end
 *
 */
void dbfs_comm_end
() {
  void * dummy;
  int pe;
  worker_id_t w;

  pthread_join(W, &dummy);
  shmem_free(H);
  shmem_finalize();
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    for(pe = 0; pe < PES; pe ++) {
      if(ME != pe) {
        mem_free(SYSTEM_HEAP, BUF.buffers[w][pe]);
      }
    }
    mem_free(SYSTEM_HEAP, BUF.states[w]);
    mem_free(SYSTEM_HEAP, BUF.buffers[w]);
    mem_free(SYSTEM_HEAP, BUF.pos[w]);
    mem_free(SYSTEM_HEAP, BUF.remote_pos[w]);
  }
}

#endif  /*  defined(CFG_ALGO_DBFS)  */
