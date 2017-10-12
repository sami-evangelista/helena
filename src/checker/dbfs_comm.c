#include "config.h"
#include "dbfs_comm.h"
#include "comm_shmem.h"

#define COMM_WAIT_TIME_MS       2
#define WORKER_WAIT_TIME_MS     1
#define WORKER_STATE_BUFFER_LEN 10000
#define MAX_PES                 100

#define DBFS_COMM_DEBUG_XXX

typedef struct {
  uint32_t no_states;
  uint32_t len;
} buffer_data_t;

typedef struct {
  bool_t empty_queue;
  uint32_t packets_sent;
  uint32_t packets_received;
} worker_data_t;

typedef struct {
  worker_data_t data[CFG_NO_WORKERS + CFG_NO_COMM_WORKERS];
} term_data_t;

typedef struct {
  heap_t * heaps[CFG_NO_WORKERS];
  hash_tbl_t * states[CFG_NO_WORKERS];
  uint32_t * len[CFG_NO_WORKERS];
  uint32_t * remote_pos[CFG_NO_WORKERS];
  hash_tbl_id_t ** ids[CFG_NO_WORKERS];
  uint32_t * no_ids[CFG_NO_WORKERS];
} worker_buffers_t;

const struct timespec COMM_WAIT_TIME = { 0, COMM_WAIT_TIME_MS * 1000 };
const struct timespec WORKER_WAIT_TIME = { 0, WORKER_WAIT_TIME_MS * 1000 };

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


/**
 * remotely accessible items
 */
static char H[CFG_SHMEM_HEAP_SIZE];
static buffer_data_t H_BUFFER_DATA[CFG_NO_WORKERS][MAX_PES];
static term_data_t H_TERM_DATA;

bool_t dbfs_comm_check_for_termination
() {
  worker_id_t w;
  int pe;
  term_data_t d;
  uint32_t sum_sent = 0;
  uint32_t sum_received = 0;  

  for(pe = 0; pe < PES; pe ++) {
    comm_shmem_get(&d, &H_TERM_DATA, sizeof(term_data_t), pe);
    for(w = 0; w < CFG_NO_WORKERS + CFG_NO_COMM_WORKERS; w ++) {
      sum_sent += d.data[w].packets_sent;
      sum_received += d.data[w].packets_received;
      if(!d.data[w].empty_queue) {
	return FALSE;
      }
    }
  }
  if(sum_sent == sum_received) {
    return TRUE;
  } else {
    return FALSE;
  }
}


void dbfs_comm_notify_queue_state
(worker_id_t w,
 bool_t empty) {
  H_TERM_DATA.data[w].empty_queue = empty;
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
    comm_shmem_get(&data, &H_BUFFER_DATA[w][ME], sizeof(buffer_data_t), pe);
    if(data.no_states > 0) {
      context_sleep(WORKER_WAIT_TIME);
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
#if defined(DBFS_COMM_DEBUG)
  printf("[%d,%d] polls %d\n", ME, w, pe);
#endif
  dbfs_comm_poll_remote_pe(w, pe);
#if defined(DBFS_COMM_DEBUG)
  printf("[%d,%d] polls %d done\n", ME, w, pe);
#endif

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
  assert(pos == BUF.len[w][pe]);
#endif
  comm_shmem_put(H + BUF.remote_pos[w][pe], buffer, pos, pe);

  /**
   * send my data to the remote PE
   */
  data.no_states = hash_tbl_size(BUF.states[w][pe]);
  data.len = pos;
  comm_shmem_put(&H_BUFFER_DATA[w][ME], &data, sizeof(buffer_data_t), pe);
#if defined(DBFS_COMM_DEBUG)
  printf("[%d,%d] sends %d states to [%d] at pos %d\n",
         ME, w, data.no_states, pe, BUF.remote_pos[w][pe]);
#endif
  
  H_TERM_DATA.data[w].packets_sent ++;
  
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
  worker_id_t x, d;
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
          if(0 == H_BUFFER_DATA[x][pe].no_states) {
            pthread_mutex_unlock(&DBFS_MUTEX);
          } else {
#if defined(DBFS_COMM_DEBUG)
            printf("[%d] received %d states from [%d,%d] at pos %d\n",
                   ME, H_BUFFER_DATA[x][pe].no_states, pe, x, pos);
#endif
	    states_received = TRUE;
            comm_shmem_get(buffer, H + pos, H_BUFFER_DATA[x][pe].len, ME);
            no_states = H_BUFFER_DATA[x][pe].no_states;
            H_BUFFER_DATA[x][pe].no_states = 0;
            H_BUFFER_DATA[x][pe].len = 0;
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
		d = h % CFG_NO_WORKERS;
#if !defined(STORAGE_STATE_RECOVERABLE)
                heap_reset(COMM_HEAPS[c]);
                s = state_unserialise_mem(buffer + tmp_pos - s_len, heap);
                item.s = s;
#endif
                bfs_queue_enqueue(Q, item, w, d);
#if !defined(STORAGE_STATE_RECOVERABLE)
                state_free(item.s);
#endif
		H_TERM_DATA.data[d].empty_queue = FALSE;
              }
            }
	    H_TERM_DATA.data[w].packets_received ++;
          }
        }
      }
    }
  }
}


void * dbfs_comm_worker
(void * arg) {
  const comm_worker_id_t c = (comm_worker_id_t) (uint64_t) arg;
  
  H_TERM_DATA.data[c + CFG_NO_WORKERS].empty_queue = TRUE;
    
  /**
   * sleep a bit and process incoming states until search finished
   */
  while(context_keep_searching()) {
    context_sleep(COMM_WAIT_TIME);
    dbfs_comm_worker_process_incoming_states(c);
  }
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
  pthread_mutex_init(&DBFS_MUTEX, NULL);
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    BUF.heaps[w] = mem_alloc(SYSTEM_HEAP, sizeof(heap_t) * PES);
    BUF.ids[w] = mem_alloc(SYSTEM_HEAP, sizeof(hash_tbl_id_t *) * PES);
    BUF.len[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.no_ids[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.remote_pos[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.states[w] = mem_alloc(SYSTEM_HEAP, sizeof(hash_tbl_t) * PES);
  }
  for(w = 0; w < CFG_NO_WORKERS + CFG_NO_COMM_WORKERS; w ++) {
    H_TERM_DATA.data[w].packets_sent = 0;
    H_TERM_DATA.data[w].packets_received = 0;
    H_TERM_DATA.data[w].empty_queue = FALSE;
  }
  for(pe = 0; pe < PES; pe ++) {
    remote_pos = ME * DBFS_HEAP_SIZE_PE;
    if(ME > pe) {
      remote_pos -= DBFS_HEAP_SIZE_PE;
    }
    for(w = 0; w < CFG_NO_WORKERS; w ++) {
      H_BUFFER_DATA[w][pe].len = 0;
      H_BUFFER_DATA[w][pe].no_states = 0;
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
