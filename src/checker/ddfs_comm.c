#include "config.h"
#include "ddfs_comm.h"
#include "comm_shmem.h"

#if CFG_ALGO_DDFS == 1 || CFG_ALGO_DFS == 1

#define MAX_PES            100
#define PRODUCE_PERIOD_MS  20
#define CONSUME_PERIOD_MS  5
#define CONSUME_WAIT_MS    1

#define BUFFER_WORKER_SIZE (CFG_SHMEM_HEAP_SIZE / CFG_NO_WORKERS)
#define BUCKET_OK          1
#define BUCKET_WRITE       2
#define LOCK_AVAILABLE     1
#define LOCK_TAKEN         2


typedef struct {
  uint8_t status[CFG_NO_WORKERS];
  uint32_t size[CFG_NO_WORKERS];
  uint32_t char_len[CFG_NO_WORKERS];
  bool_t full[CFG_NO_WORKERS];
  char buffer[CFG_NO_WORKERS][BUFFER_WORKER_SIZE];
} ddfs_comm_buffers_t;

const struct timespec PRODUCE_PERIOD = { 0, PRODUCE_PERIOD_MS * 1000000 };
const struct timespec CONSUME_PERIOD = { 0, CONSUME_PERIOD_MS * 1000000 };
const struct timespec CONSUME_WAIT_TIME = { 0, CONSUME_WAIT_MS * 1000000 };
const struct timespec WAIT_TIME = { 0, 10 };

ddfs_comm_buffers_t BUF;
storage_t S;
uint16_t BASE_LEN;
pthread_t PROD;
pthread_t CONS[CFG_NO_COMM_WORKERS];
uint8_t LOCK;
int PES;
int ME;

typedef struct {
  bool_t produced[MAX_PES];
  uint32_t size;
  uint32_t char_len;
} pub_data_t;

#define DDFS_COMM_DATA_POS sizeof(pub_data_t)


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
   *  put the state of worker w in its buffer
   */
  if(!BUF.full[w] && CAS(&BUF.status[w], BUCKET_OK, BUCKET_WRITE)) {
    if(CFG_HASH_COMPACTION) {
      h = storage_get_hash(S, id);
    } else {
      storage_get_serialised(S, id, &s, &s_char_len, &h);
    }
    len = BASE_LEN;
    if(!CFG_HASH_COMPACTION) {
      len += sizeof(uint16_t) + s_char_len;
    }
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

      /*  char length and state vector */
      if(!CFG_HASH_COMPACTION) {
	memcpy(pos, &s_char_len, sizeof(uint16_t));
	pos += sizeof(uint16_t);
	memcpy(pos, s, s_char_len);
	pos += s_char_len;
      }
    }
    BUF.status[w] = BUCKET_OK;
  }
}

void * ddfs_comm_producer
(void * arg) {
  int pe;
  worker_id_t w;
  uint64_t size = 0, char_len = 0;
  pub_data_t data;
  const worker_id_t my_worker_id = CFG_NO_WORKERS;
  
  while(context_keep_searching()) {
    context_sleep(PRODUCE_PERIOD);

    /**
     *  wait that all other pes have consumed my states
     */
  wait_for_states_consumed:
    comm_shmem_get(&data, 0, sizeof(pub_data_t), ME);
    for(pe = 0; pe < PES && context_keep_searching(); pe ++) {
      if(pe != ME && data.produced[pe]) {
        context_sleep(CONSUME_PERIOD);
        goto wait_for_states_consumed;
      }
    }

    /**
     *  put in my local heap states produced by my workers
     */
    char_len = DDFS_COMM_DATA_POS;
    size = 0;
    for(w = 0; w < CFG_NO_WORKERS; w ++) {
      
      /*  wait for the bucket of thread w to be ready  */
      while(!CAS(&BUF.status[w], BUCKET_OK, BUCKET_WRITE)) {
	context_sleep(WAIT_TIME);
      }

      /*  copy the buffer of worker w to my local  heap  */
      comm_shmem_put(char_len, BUF.buffer[w], BUF.char_len[w], ME);
      char_len += BUF.char_len[w];
      size += BUF.size[w];

      /*  reset the buffer of worker w and make it available  */
      BUF.char_len[w] = 0;
      BUF.size[w] = 0;
      BUF.full[w] = FALSE;
      BUF.status[w] = BUCKET_OK;
    }
    
    /*  notify other PEs that I have produced some states  */
    data.size = size;
    data.char_len = char_len;
    for(pe = 0; pe < PES; pe ++) {
      if(pe != ME) {
        data.produced[pe] = TRUE;
      }
    }
    comm_shmem_put(0, &data, sizeof(pub_data_t), ME);
  }
}

void * ddfs_comm_consumer
(void * arg) {
  const comm_worker_id_t c = (comm_worker_id_t) (uint64_t) arg;
  const worker_id_t w = c + CFG_NO_WORKERS;
  bool_t f = FALSE;
  int pe;
  void * pos;
  uint16_t s_char_len, len;
  storage_id_t sid;
  bit_vector_t s;
  bool_t red = FALSE, blue = FALSE, is_new;
  char buffer[CFG_SHMEM_HEAP_SIZE];
  hash_key_t h;
  pub_data_t remote_data;
  
  while(context_keep_searching()) {
    
    context_sleep(CONSUME_PERIOD);

    /**
     * get states put by remote PEs in their heap and put these in my
     * local storage
     */
    for(pe = 0; pe < PES; pe ++) {
      if(ME != pe) {
	while(!CAS(&LOCK, LOCK_AVAILABLE, LOCK_TAKEN)) {
	  context_sleep(CONSUME_WAIT_TIME);
	}
	comm_shmem_get(&remote_data, 0, sizeof(pub_data_t), pe);
        if(!remote_data.produced[ME]) {
	  LOCK = LOCK_AVAILABLE;
	} else {
          comm_shmem_get(buffer, DDFS_COMM_DATA_POS, remote_data.char_len, pe);
          comm_shmem_put(sizeof(bool_t) * ME, &f, sizeof(bool_t), pe);
	  LOCK = LOCK_AVAILABLE;
          pos = buffer;
          while(remote_data.size --) {

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
       
	    if(CFG_HASH_COMPACTION) {
	      storage_insert_serialised(S, pos, s_char_len,
					h, w, &is_new, &sid);
	    } else {
	    
	      /*  get state vector char length  */
	      memcpy(&s_char_len, pos, sizeof(uint16_t));
	      pos += sizeof(uint16_t);
            
	      /*  get state vector and insert it  */
	      storage_insert_serialised(S, pos, s_char_len,
		h, w, &is_new, &sid);
	      pos += s_char_len;
	    }

            /*  set the blue and red attribute of the state  */
            if(blue && storage_has_attr(S, ATTR_BLUE)) {
              storage_set_blue(S, sid, TRUE);
            }
            if(red && storage_has_attr(S, ATTR_RED)) {
              storage_set_red(S, sid, TRUE);
            }

            /*  if the state is new it may be garbage collected  */
            if(is_new && storage_has_attr(S, ATTR_GARBAGE)) {
              storage_set_garbage(S, w, sid, TRUE);
            }
          }
        }
      }
    }
  }
  return NULL;
}

void ddfs_comm_start
() {
  worker_id_t w;
  comm_worker_id_t c;
  int i = 0;
  pub_data_t data;
  
  /*  shmem and symmetrical heap initialisation  */
  PES = comm_shmem_pes();
  ME = comm_shmem_me();
  assert(PES <= MAX_PES);
  
  S = context_storage();
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    BUF.status[w] = BUCKET_OK;
    BUF.size[w] = 0;
    BUF.char_len[w] = 0;
    BUF.full[w] = FALSE;
  }
  BASE_LEN = sizeof(hash_key_t)
    + (storage_has_attr(S, ATTR_BLUE) ? sizeof(bool_t) : 0)
    + (storage_has_attr(S, ATTR_RED) ? sizeof(bool_t) : 0);
  for(i = 0; i < MAX_PES; i ++) {
    LOCK = LOCK_AVAILABLE;
    data.produced[i] = FALSE;
  }
  comm_shmem_put(0, &data, sizeof(pub_data_t), ME);

  /*  launch the producer and consumer threads  */
  pthread_create(&PROD, NULL, &ddfs_comm_producer, NULL);
  for(c = 0; c < CFG_NO_COMM_WORKERS; c ++) {
    pthread_create(&CONS[c], NULL, &ddfs_comm_consumer, (void *) (long) c);
  }
}

void ddfs_comm_end
() {
  comm_worker_id_t c;
  void * dummy;

  pthread_join(PROD, &dummy);
  for(c = 0; c < CFG_NO_COMM_WORKERS; c ++) {
    pthread_join(CONS[c], &dummy);
  }
}

#endif
