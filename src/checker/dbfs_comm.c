#include "config.h"
#include "dbfs_comm.h"
#include "comm_shmem.h"

#if defined(CFG_ALGO_DBFS)

#include "shmem.h"

#define COMM_WAIT_TIME_MS       10
#define WORKER_WAIT_TIME_MS     5
#define WORKER_STATE_BUFFER_LEN 10000
#define MAX_PES                 100

#define DBFS_COMM_DEBUG_XXX

typedef struct {
  uint32_t no_states;
  uint32_t len;
} buffer_data_t;

typedef struct {
  heap_t * heaps[CFG_NO_WORKERS];
  hash_tbl_t * states[CFG_NO_WORKERS];
  uint32_t * len[CFG_NO_WORKERS];
  uint32_t * remote_pos[CFG_NO_WORKERS];
  hash_tbl_id_t ** ids[CFG_NO_WORKERS];
  uint32_t * no_ids[CFG_NO_WORKERS];
} worker_buffers_t;

const struct timespec COMM_WAIT_TIME = { 0, COMM_WAIT_TIME_MS * 1000000 };
const struct timespec WORKER_WAIT_TIME = { 0, WORKER_WAIT_TIME_MS * 1000000 };

storage_t S;
bfs_queue_t Q;
pthread_t CW[CFG_NO_COMM_WORKERS];
heap_t COMM_HEAPS[CFG_NO_COMM_WORKERS];
worker_buffers_t BUF;
uint32_t DBFS_HEAP_SIZE;
uint32_t DBFS_HEAP_SIZE_WORKER;
uint32_t DBFS_HEAP_SIZE_PE;
int PES;
int ME;

/**
 * synchronisation stuff
 */
pthread_mutex_t DBFS_MUTEX;
pthread_barrier_t DBFS_LOCAL_BARRIER;
pthread_barrier_t DBFS_COMM_BARRIER;


/**
 * termination detection data
 */
bool_t LOCAL_TERM;
bool_t GLOB_TERM;
unsigned int NO_TERM;
bool_t REMOTE_TERM[MAX_PES];


/**
 * remotely accessible items
 */
static bool_t H_TERM = FALSE;
static buffer_data_t H_DATA[CFG_NO_WORKERS][MAX_PES];
static uint64_t H_QUEUE_SIZE = 0;
static char H[CFG_SHMEM_HEAP_SIZE];


void dbfs_comm_init_term_data
() {
  int pe;
  
  LOCAL_TERM = FALSE;
  NO_TERM = 0;
  for(pe = 0; pe < PES; pe ++) {
    REMOTE_TERM[pe] = FALSE;
  }
  H_TERM = FALSE;
  H_QUEUE_SIZE = 0;
}


uint8_t dbfs_comm_state_owner
(hash_key_t h) {
  int i = 0;
  uint8_t result = 0;

  for(i = 0; i < sizeof(hash_key_t); i ++) {
    result += h >> (i * 8);
  }
  return result % PES;
}


bool_t dbfs_comm_state_owned
(hash_key_t h) {
  return dbfs_comm_state_owner(h) == ME;
}


bool_t dbfs_comm_global_termination
() {
  return GLOB_TERM;
}


void dbfs_comm_notify_level_termination
() {
  LOCAL_TERM = TRUE;
}


void dbfs_comm_local_barrier
() {
  context_barrier_wait(&DBFS_LOCAL_BARRIER);
}


void dbfs_comm_comm_barrier
() {
#if CFG_NO_COMM_WORKERS > 1
  context_barrier_wait(&DBFS_COMM_BARRIER);
#endif
}


void dbfs_comm_reinit_buffer
(worker_id_t w,
 int pe) {
  uint32_t i;

  for(i = 0; i < BUF.no_ids[w][pe]; i ++) {
    hash_tbl_erase(BUF.states[w][pe], 0, BUF.ids[w][pe][i]);
  }
  BUF.len[w][pe] = 0;
  BUF.no_ids[w][pe] = 0;
}

void dbfs_comm_poll_remote_pe
(worker_id_t w,
 int pe) {
  buffer_data_t data;
  
  do {
    comm_shmem_get(&data, &H_DATA[w][ME], sizeof(buffer_data_t), pe);
    if(data.no_states > 0) {
      nanosleep(&WORKER_WAIT_TIME, NULL);
    }
  } while(data.no_states > 0);
}


void dbfs_comm_send_buffer
(worker_id_t w,
 int pe) {
  buffer_data_t data;
  char buffer[DBFS_HEAP_SIZE_WORKER];
  uint32_t i, pos;
  bit_vector_t s;
  uint16_t size;
  hash_key_t h;

#if defined(DBFS_COMM_DEBUG)
  assert(hash_tbl_size(BUF.states[w][pe]) <= WORKER_STATE_BUFFER_LEN);
  assert(pe != ME);
  assert(BUF.len[w][pe] < DBFS_HEAP_SIZE_WORKER);
#endif
  
  /**
   * poll the remote PE to see if I can send my states
   */
  dbfs_comm_poll_remote_pe(w, pe);

  /**
   * send my states to the remote PE
   */
  memset(buffer, 0, DBFS_HEAP_SIZE_WORKER);
  pos = 0;
  for(i = 0; i < BUF.no_ids[w][pe]; i ++) {
    hash_tbl_get_serialised(BUF.states[w][pe], BUF.ids[w][pe][i],
			    &s, &size, &h);
    memcpy(buffer + pos, &h, sizeof(hash_key_t));
    memcpy(buffer + pos + sizeof(hash_key_t), &size, sizeof(uint16_t));
    memcpy(buffer + pos + sizeof(hash_key_t) + sizeof(uint16_t), s, size);
    pos += sizeof(hash_key_t) + sizeof(uint16_t) + size;
  }
#if defined(DBFS_COMM_DEBUG)
  assert(buf.pos == BUF.len[w][pe]);
#endif
  comm_shmem_put(H + BUF.remote_pos[w][pe], buffer, pos, pe);

  /**
   * send my data to the remote PE
   */
  data.no_states = hash_tbl_size(BUF.states[w][pe]);
  data.len = pos;
  comm_shmem_put(&H_DATA[w][ME], &data, sizeof(buffer_data_t), pe);
#if defined(DBFS_COMM_DEBUG)
  printf("[%d,%d] sends %d states to [%d] at pos %d\n",
         ME, w, data.no_states, pe, BUF.remote_pos[w][pe]);
#endif
  
  /**
   * reinitialise the buffer
   */
  dbfs_comm_reinit_buffer(w, pe);
}


void dbfs_comm_send_all_pending_states
(worker_id_t w) {
  int pe;
  buffer_data_t data;

  /**
   * send all buffers content
   */
#if defined(DBFS_COMM_DEBUG)
  printf("[%d,w%d] sends pending states\n", context_proc_id(), w);
#endif
  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME && hash_tbl_size(BUF.states[w][pe]) > 0) {
      dbfs_comm_send_buffer(w, pe);
    }
  }
#if defined(DBFS_COMM_DEBUG)
  printf("[%d,w%d] sends pending states done\n", context_proc_id(), w);
#endif
  
  /**
   * poll all remote PEs to see to make sure that all the states I've
   * sent have been consumed
   */
#if defined(DBFS_COMM_DEBUG)
  printf("[%d,w%d] polls\n", context_proc_id(), w);
#endif
  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME) {
      dbfs_comm_poll_remote_pe(w, pe);
    }
  }
#if defined(DBFS_COMM_DEBUG)
  printf("[%d,w%d] polls done\n", context_proc_id(), w);
#endif
}


void dbfs_comm_process_state
(worker_id_t w,
 state_t s,
 hash_key_t h) {
  const uint16_t len = state_char_size(s);
  const int pe = dbfs_comm_state_owner(h);
  storage_id_t id;
  uint32_t no;
  bool_t is_new;

#if defined(DBFS_COMM_DEBUG)
  assert(ME != pe);
  assert(hash_tbl_size(BUF.states[w][pe]) <= WORKER_STATE_BUFFER_LEN);
#endif

  /**
   * not enough space to put the state in the buffer => we first send
   * the buffer content to the remote pe
   */
  if((BUF.len[w][pe] + sizeof(hash_key_t) + sizeof(uint16_t) + len >
      DBFS_HEAP_SIZE_WORKER)
     || (BUF.no_ids[w][pe] == WORKER_STATE_BUFFER_LEN)) {
    dbfs_comm_send_buffer(w, pe);
  }

  /**
   * insert the state in table
   */
  hash_tbl_insert_hashed(BUF.states[w][pe], s, 0, h, &is_new, &id);
  if(is_new) {
    BUF.len[w][pe] += sizeof(hash_key_t) + sizeof(uint16_t) + len;
    BUF.ids[w][pe][BUF.no_ids[w][pe]] = id;
    BUF.no_ids[w][pe] ++;
  }
}


void dbfs_comm_worker_process_incoming_states
(comm_worker_id_t c) {
  const worker_id_t w = c + CFG_NO_WORKERS;
  worker_id_t x;
  uint32_t pos, tmp_pos, no_states;
  uint16_t s_len;
  bool_t states_received = TRUE, is_new;
  hash_key_t h;
  buffer_data_t data;
  char buffer[DBFS_HEAP_SIZE_WORKER];
  storage_id_t sid;
  bfs_queue_item_t item;
  state_t s;
  int pe;

  while(states_received) {
    states_received = FALSE;
    pos = 0;
    for(pe = 0; pe < PES; pe ++) {
      if(pe != ME) {
        for(x = 0; x < CFG_NO_WORKERS; x ++, pos += DBFS_HEAP_SIZE_WORKER) {
          pthread_mutex_lock(&DBFS_MUTEX);
          if(0 == H_DATA[x][pe].no_states) {
            pthread_mutex_unlock(&DBFS_MUTEX);
          } else {
#if defined(DBFS_COMM_DEBUG)
            printf("[%d] received %d states from [%d,%d] at pos %d\n",
                   ME, H_DATA[x][pe].no_states, pe, x, pos);
#endif
            states_received = TRUE;
            comm_shmem_get(buffer, H + pos, H_DATA[x][pe].len, ME);
            no_states = H_DATA[x][pe].no_states;
            H_DATA[x][pe].no_states = 0;
            H_DATA[x][pe].len = 0;
            pthread_mutex_unlock(&DBFS_MUTEX);
            tmp_pos = 0;
            while((no_states --) > 0) {

              /**
               * read the state from the buffer and insert it in the
               * storage
               */

              /* hash value */
              memcpy(&h, buffer + tmp_pos, sizeof(hash_key_t));
              tmp_pos += sizeof(hash_key_t);
          
              /* state char length */
              memcpy(&s_len, buffer + tmp_pos, sizeof(uint16_t));
              tmp_pos += sizeof(uint16_t);
          
              /* insert the state */
              storage_insert_serialised(S, buffer + tmp_pos, s_len,
                                        h, w, &is_new, &sid);
              tmp_pos += s_len;

              /**
               * state is new => put it in the queue.  if the queue
               * contains full states we have to unserialise it
               */
              if(is_new) {
                item.id = sid;
#if !defined(STORAGE_STATE_RECOVERABLE)
                heap_reset(COMM_HEAPS[c]);
                s = state_unserialise_mem(buffer + tmp_pos - s_len, heap);
                item.s = s;
#endif
                bfs_queue_enqueue(Q, item, w, h % CFG_NO_WORKERS);
#if !defined(STORAGE_STATE_RECOVERABLE)
                state_free(item.s);
#endif
              }
            }
          }
        }
      }
    }
  }
}


void * dbfs_comm_worker
(void * arg) {
  const comm_worker_id_t c = (comm_worker_id_t) (uint64_t) arg;
  const worker_id_t w = c + CFG_NO_WORKERS;
  int pe;
  uint64_t queue_size;
  bool_t term;

  while(!GLOB_TERM) {

    /**
     * sleep a bit and process incoming states
     */
    nanosleep(&COMM_WAIT_TIME, NULL);
    dbfs_comm_worker_process_incoming_states(c);
    
    /**
     * local threads have terminated the current BFS level.  set
     * H_TERM to TRUE to notify other PE.  also check whether it is
     * also the case for other PEs.  done by communicator 0 only
     */
    if(LOCAL_TERM && 0 == c) {
      if(!H_TERM) {
        H_TERM = TRUE;
        NO_TERM = 1;
      }
      for(pe = 0; pe < PES; pe ++) {
        if(pe != ME && !REMOTE_TERM[pe]) {
          comm_shmem_get(&REMOTE_TERM[pe], &H_TERM, sizeof(bool_t), pe);
          if(REMOTE_TERM[pe]) {
            NO_TERM ++;
          }
        }
      }
    }

    /**
     * all PEs have terminated the current level
     */
    if(NO_TERM == PES) {

      /**
       * every PE puts in its heap its queue size and read others's
       * to check for termination.  done by communicator 0 only
       */
      if(0 == c) {
#if defined(DBFS_COMM_DEBUG)
        printf("[%d,c%d] at barrier 0\n", ME, c);
#endif
        comm_shmem_barrier();
        H_QUEUE_SIZE = bfs_queue_size(Q);
#if defined(DBFS_COMM_DEBUG)
        printf("[%d,c%d] at barrier 1\n", ME, c);
#endif
        comm_shmem_barrier();
        if(0 == H_QUEUE_SIZE) {
          term = TRUE;
          for(pe = 0; pe < PES && term; pe ++) {
            if(pe != ME) {
              comm_shmem_get(&queue_size, &H_QUEUE_SIZE, sizeof(uint64_t), pe);
              if(0 != queue_size) {
                term = FALSE;
              }
            }
          }
          GLOB_TERM = term;
        }
#if defined(DBFS_COMM_DEBUG)
        printf("[%d,c%d] at barrier 2\n", ME, c);
#endif
        comm_shmem_barrier();
      }
      
      /**
       * all communicator threads synchronise then reinitialise
       * everything for termination detection at next level and
       * synchronise with the working threads
       */
#if defined(DBFS_COMM_DEBUG)
      printf("[%d,c%d] at barrier 3\n", ME, c);
#endif
      dbfs_comm_comm_barrier();
      dbfs_comm_init_term_data();
#if defined(DBFS_COMM_DEBUG)
      printf("[%d,c%d] at barrier 4\n", ME, c);
#endif
      dbfs_comm_local_barrier();
    }
  }
#if defined(DBFS_COMM_DEBUG)
  printf("[%d,c%d] terminated\n", ME, c);
#endif
}


void dbfs_comm_start
(bfs_queue_t q) {
  int pe, remote_pos;
  worker_id_t w;
  comm_worker_id_t c;
  
  /* shmem initialisation */
  PES = comm_shmem_pes();
  ME = comm_shmem_me();
  DBFS_HEAP_SIZE_WORKER = CFG_SHMEM_HEAP_SIZE / ((PES) * CFG_NO_WORKERS);
  DBFS_HEAP_SIZE_PE = CFG_NO_WORKERS * DBFS_HEAP_SIZE_WORKER;
  DBFS_HEAP_SIZE = DBFS_HEAP_SIZE_PE * (PES);
  assert(PES <= MAX_PES);

  /* initialise global variables */
  Q = q;
  S = context_storage();
  GLOB_TERM = FALSE;
  dbfs_comm_init_term_data();
  pthread_barrier_init(&DBFS_LOCAL_BARRIER, NULL,
		       CFG_NO_WORKERS + CFG_NO_COMM_WORKERS);
  pthread_barrier_init(&DBFS_COMM_BARRIER, NULL, CFG_NO_COMM_WORKERS);
  pthread_mutex_init(&DBFS_MUTEX, NULL);
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    BUF.heaps[w] = mem_alloc(SYSTEM_HEAP, sizeof(heap_t) * PES);
    BUF.ids[w] = mem_alloc(SYSTEM_HEAP, sizeof(hash_tbl_id_t *) * PES);
    BUF.len[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.no_ids[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.remote_pos[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.states[w] = mem_alloc(SYSTEM_HEAP, sizeof(hash_tbl_t) * PES);
  }
  for(pe = 0; pe < PES; pe ++) {
    remote_pos = ME * DBFS_HEAP_SIZE_PE;
    if(ME > pe) {
      remote_pos -= DBFS_HEAP_SIZE_PE;
    }
    for(w = 0; w < CFG_NO_WORKERS; w ++) {
      H_DATA[w][pe].len = 0;
      H_DATA[w][pe].no_states = 0;
      if(ME == pe) {
        BUF.remote_pos[w][pe] = 0;          
      } else {
        BUF.remote_pos[w][pe] = remote_pos;
        BUF.no_ids[w][pe] = 0;
        BUF.ids[w][pe] = mem_alloc(SYSTEM_HEAP, sizeof(hash_tbl_id_t)
				   * WORKER_STATE_BUFFER_LEN);
        BUF.heaps[w][pe] = local_heap_new();
        BUF.states[w][pe] = hash_tbl_new(WORKER_STATE_BUFFER_LEN * 2,
					 1, FALSE, 100, 0, 0);
	hash_tbl_set_heap(BUF.states[w][pe], BUF.heaps[w][pe]);
        dbfs_comm_reinit_buffer(w, pe);
        remote_pos += DBFS_HEAP_SIZE_WORKER;
      }
    }
  }
  
  comm_shmem_barrier();
  
  /* launch the communicator threads */
  for(c = 0; c < CFG_NO_COMM_WORKERS; c ++) {
    COMM_HEAPS[c] = local_heap_new();
    pthread_create(&CW[c], NULL, &dbfs_comm_worker, (void *) (long) c);
  }
}


void dbfs_comm_end
() {
  void * dummy;
  int pe;
  worker_id_t w;
  comm_worker_id_t c;

  for(c = 0; c < CFG_NO_COMM_WORKERS; c ++) {
    pthread_join(CW[c], &dummy);
    heap_free(COMM_HEAPS[c]);
  }
#if defined(DBFS_COMM_DEBUG)
  printf("[%d] all communicators terminated\n", ME);
#endif
  comm_shmem_finalize(NULL);
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    for(pe = 0; pe < PES; pe ++) {
      if(ME != pe) {
        hash_tbl_free(BUF.states[w][pe]);
        heap_free(BUF.heaps[w][pe]);
	mem_free(SYSTEM_HEAP, BUF.ids[w][pe]);
      }
    }
    mem_free(SYSTEM_HEAP, BUF.heaps[w]);
    mem_free(SYSTEM_HEAP, BUF.ids[w]);
    mem_free(SYSTEM_HEAP, BUF.len[w]);
    mem_free(SYSTEM_HEAP, BUF.no_ids[w]);
    mem_free(SYSTEM_HEAP, BUF.remote_pos[w]);
    mem_free(SYSTEM_HEAP, BUF.states[w]);
  }
}

#endif  /* defined(CFG_ALGO_DBFS) */
