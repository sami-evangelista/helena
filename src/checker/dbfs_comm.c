#include "config.h"
#include "dbfs_comm.h"
#include "comm_shmem.h"

#if CFG_ALGO_BFS == 1 || CFG_ALGO_DBFS == 1

#define COMM_WAIT_TIME_MUS      2
#define WORKER_WAIT_TIME_MUS    1
#define WORKER_STATE_BUFFER_LEN 10000
#define MAX_PES                 100

#define TOKEN_NONE               0
#define TOKEN_BLACK              1
#define TOKEN_WHITE              2

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

const struct timespec COMM_WAIT_TIME = { 0, COMM_WAIT_TIME_MUS * 1000 };
const struct timespec WORKER_WAIT_TIME = { 0, WORKER_WAIT_TIME_MUS * 1000 };

hash_tbl_t H;
bfs_queue_t Q;
pthread_t CW[CFG_NO_COMM_WORKERS];
heap_t COMM_HEAPS[CFG_NO_COMM_WORKERS];
worker_buffers_t BUF;
uint32_t DBFS_HEAP_SIZE;
uint32_t DBFS_HEAP_SIZE_WORKER;
uint32_t DBFS_HEAP_SIZE_PE;
int PES;
int ME;

/* termination detection variables */
bool_t TERM = FALSE;
uint8_t TERM_COLOR = TOKEN_WHITE;
bool_t TOKEN_SENT = FALSE;

#define POS_TOKEN 0
#define POS_TERM sizeof(uint8_t)
#define POS_DATA                                        \
  (sizeof(uint8_t) + sizeof(bool_t) +                   \
   sizeof(buffer_data_t) * CFG_NO_WORKERS * PES)
#define POS_BUFFER(w, pe)                               \
  (sizeof(uint8_t) + sizeof(bool_t) +                   \
   sizeof(buffer_data_t) * (w + pe * CFG_NO_WORKERS))



bool_t dbfs_comm_termination
() {
  return TERM;
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
    comm_shmem_get(&data, POS_BUFFER(w, ME), sizeof(buffer_data_t), pe);
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
  assert(BUF.len[w][pe] <= DBFS_HEAP_SIZE_WORKER);
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
  assert(pos == BUF.len[w][pe]);
#endif
  comm_shmem_put(BUF.remote_pos[w][pe], buffer, pos, pe);

  /**
   * send my data to the remote PE
   */
  data.no_states = hash_tbl_size(BUF.states[w][pe]);
  data.len = pos;
#if defined(DBFS_COMM_DEBUG)
  assert(data.len > 0);
  assert(data.no_states > 0);
#endif  
  comm_shmem_put(POS_BUFFER(w, ME), &data, sizeof(buffer_data_t), pe);

  if(pe < ME) {
    TERM_COLOR = TOKEN_BLACK;
  }

  dbfs_comm_poll_remote_pe(w, pe);
  dbfs_comm_reinit_buffer(w, pe);
}


void dbfs_comm_send_all_pending_states
(worker_id_t w) {
  int pe;
  buffer_data_t data;

  /**
   * send all buffers content
   */
  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME && hash_tbl_size(BUF.states[w][pe]) > 0) {
      dbfs_comm_send_buffer(w, pe);
    }
  }
}


void dbfs_comm_process_state
(worker_id_t w,
 state_t s,
 hash_key_t h) {
  const uint16_t len = state_char_size(s);
  const int pe = dbfs_comm_state_owner(h);
  hash_tbl_id_t id;
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


bool_t dbfs_comm_worker_process_incoming_states
(comm_worker_id_t c) {
  const worker_id_t w = c + CFG_NO_WORKERS;
  worker_id_t x, d;
  uint32_t pos, tmp_pos, no_states;
  uint16_t s_len;
  bool_t states_received = TRUE, is_new;
  hash_key_t h;
  buffer_data_t data;
  char buffer[DBFS_HEAP_SIZE_WORKER];
  hash_tbl_id_t sid;
  bfs_queue_item_t item;
  state_t s;
  int pe;
  bool_t result = FALSE;

  while(states_received) {
    states_received = FALSE;
    pos = 0;
    for(pe = 0; pe < PES; pe ++) {
      if(pe != ME) {
        for(x = 0; x < CFG_NO_WORKERS; x ++, pos += DBFS_HEAP_SIZE_WORKER) {
          comm_shmem_get(&data, POS_BUFFER(x, pe), sizeof(buffer_data_t), ME);
	  if(0 != data.no_states) {
	    result = TRUE;
	    states_received = TRUE;
            comm_shmem_get(buffer, POS_DATA + pos, data.len, ME);
            no_states = data.no_states;
            data.no_states = 0;
            data.len = 0;
            comm_shmem_put(POS_BUFFER(x, pe), &data,
                           sizeof(buffer_data_t), ME);
	    tmp_pos = 0;
            while((no_states --) > 0) {

              /**
               * read the state from the buffer and insert it in the
               * hash table
               */

              /* hash value */
              memcpy(&h, buffer + tmp_pos, sizeof(hash_key_t));
              tmp_pos += sizeof(hash_key_t);
          
              /* state char length */
              memcpy(&s_len, buffer + tmp_pos, sizeof(uint16_t));
              tmp_pos += sizeof(uint16_t);
          
              /* insert the state */
              hash_tbl_insert_serialised(H, buffer + tmp_pos, s_len,
                                         h, w, &is_new, &sid);
              tmp_pos += s_len;

              /**
               * state is new => put it in the queue.  if the queue
               * contains full states we have to unserialise it
               */
              if(is_new) {
                item.id = sid;
		d = h % CFG_NO_WORKERS;
		if(CFG_HASH_COMPACTION) {
		  heap_reset(COMM_HEAPS[c]);
		  s = state_unserialise_mem(buffer + tmp_pos - s_len,
                                            COMM_HEAPS[c]);
		  item.s = s;
		}
                bfs_queue_enqueue(Q, item, w, d);
		if(CFG_HASH_COMPACTION) {
		  state_free(item.s);
		}
              }
            }
          }
        }
      }
    }
  }
  return result;
}


bool_t dbfs_comm_all_buffers_empty
() {
  int pe;
  worker_id_t w;

  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    for(pe = 0; pe < PES; pe ++) {
      if(BUF.len[w][pe] != 0) {
	return FALSE;
      }
    }
  }
  return TRUE;
}


void dbfs_comm_send_token
(uint8_t token,
 int pe) {
  comm_shmem_put(POS_TOKEN, &token, sizeof(uint8_t), pe);
}


void dbfs_comm_send_term
(int pe) {
  bool_t term = TRUE;
  
  comm_shmem_put(POS_TERM, &term, sizeof(bool_t), pe);
}


uint8_t dbfs_comm_recv_token
() {
  uint8_t result;
  
  comm_shmem_get(&result, POS_TOKEN, sizeof(uint8_t), ME);
  return result;
}


bool_t dbfs_comm_recv_term
() {
  bool_t result;
  
  comm_shmem_get(&result, POS_TERM, sizeof(bool_t), ME);
  return result;
}


void dbfs_comm_check_termination
() {
  int next;
  uint8_t to_send, token;
  bool_t term;

  if(bfs_queue_is_empty(Q) && dbfs_comm_all_buffers_empty()) {
    next = (ME + 1) % PES;
    token = dbfs_comm_recv_token();
    term = dbfs_comm_recv_term();
    if(0 == ME) {
      if(!TOKEN_SENT || TOKEN_BLACK == token) {
	TOKEN_SENT = TRUE;
	dbfs_comm_send_token(TOKEN_NONE, ME);
	dbfs_comm_send_token(TOKEN_WHITE, next);
      } else if(TOKEN_WHITE == token) {
	TERM = TRUE;
        dbfs_comm_send_term(next);
      }
    } else if(term) {
      TERM = TRUE;
      dbfs_comm_send_term(next);
    } else if(token != TOKEN_NONE) {
      dbfs_comm_send_token(TOKEN_NONE, ME);
      if(TOKEN_BLACK == token) {
	to_send = TOKEN_BLACK;
      } else if(TOKEN_WHITE == token) {
	to_send = TERM_COLOR;
        TERM_COLOR = TOKEN_WHITE;
      } else {
	assert(0);
      }    
      dbfs_comm_send_token(to_send, next);
    }
  }
}


void * dbfs_comm_worker
(void * arg) {
  const comm_worker_id_t c = (comm_worker_id_t) (uint64_t) arg;
      
  /**
   * sleep a bit and process incoming states.  communicator 0 checks
   * for termination if it did not receive any states
   */
  while(!TERM) {
    context_sleep(COMM_WAIT_TIME);
    if(!dbfs_comm_worker_process_incoming_states(c)) {
      if(0 == c) {
        dbfs_comm_check_termination(c);
      }
    }
  }
}


void dbfs_comm_start
(hash_tbl_t h,
 bfs_queue_t q) {
  int pe, remote_pos;
  worker_id_t w;
  comm_worker_id_t c;
  buffer_data_t data;
  uint8_t token;
  
  /* shmem initialisation */
  PES = comm_shmem_pes();
  ME = comm_shmem_me();
  DBFS_HEAP_SIZE_WORKER =
    (CFG_SHMEM_HEAP_SIZE - POS_DATA) / ((PES - 1) * CFG_NO_WORKERS);
  DBFS_HEAP_SIZE_PE = CFG_NO_WORKERS * DBFS_HEAP_SIZE_WORKER;
  DBFS_HEAP_SIZE = DBFS_HEAP_SIZE_PE * (PES - 1);
  assert(PES <= MAX_PES);
  TERM = FALSE;
  comm_shmem_put(POS_TERM, &TERM, sizeof(bool_t), ME);
  token = TOKEN_NONE;
  comm_shmem_put(POS_TOKEN, &token, sizeof(uint8_t), ME);

  /* initialise global variables */
  Q = q;
  H = h;
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    BUF.heaps[w] = mem_alloc(SYSTEM_HEAP, sizeof(heap_t) * PES);
    BUF.ids[w] = mem_alloc(SYSTEM_HEAP, sizeof(hash_tbl_id_t *) * PES);
    BUF.len[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.no_ids[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.remote_pos[w] = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF.states[w] = mem_alloc(SYSTEM_HEAP, sizeof(hash_tbl_t) * PES);
  }
  for(pe = 0; pe < PES; pe ++) {
    remote_pos = POS_DATA + ME * DBFS_HEAP_SIZE_PE;
    if(ME > pe) {
      remote_pos -= DBFS_HEAP_SIZE_PE;
    }
    for(w = 0; w < CFG_NO_WORKERS; w ++) {
      data.len = 0;
      data.no_states = 0;
      comm_shmem_put(POS_BUFFER(w, pe), &data, sizeof(buffer_data_t), ME);
      if(ME == pe) {
        BUF.remote_pos[w][pe] = 0;
	BUF.no_ids[w][pe] = 0;
	BUF.len[w][pe] = 0;
      } else {
        BUF.remote_pos[w][pe] = remote_pos;
        BUF.no_ids[w][pe] = 0;
        BUF.ids[w][pe] = mem_alloc(SYSTEM_HEAP, sizeof(hash_tbl_id_t)
				   * WORKER_STATE_BUFFER_LEN);
        BUF.heaps[w][pe] = local_heap_new();
        BUF.states[w][pe] = hash_tbl_new(WORKER_STATE_BUFFER_LEN * 2,
					 1, FALSE, 0);
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

#endif
