#include "config.h"
#include "ddfs_comm.h"
#include "comm.h"

#if CFG_ALGO_DDFS == 1 || CFG_ALGO_DFS == 1 || CFG_ALGO_TARJAN == 1

#define MAX_PES            100
#define PRODUCE_PERIOD_MS  20
#define CONSUME_PERIOD_MS  5
#define CONSUME_WAIT_MS    1

#define BUFFER_WORKER_SIZE (CFG_SHMEM_HEAP_SIZE / CFG_NO_WORKERS)
#define BUCKET_OK          1
#define BUCKET_WRITE       2


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
htbl_t H;
uint16_t BASE_LEN;
pthread_t PROD;
pthread_t CONS;
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
 htbl_id_t id) {
  uint16_t s_char_len, len;
  char * s;
  bool_t red = FALSE, blue = FALSE;
  hkey_t h;
  void * pos;

  /**
   *  put the state of worker w in its buffer
   */
  if(!BUF.full[w] && CAS(&BUF.status[w], BUCKET_OK, BUCKET_WRITE)) {
    if(CFG_HASH_COMPACTION) {
      /*h = htbl_get_hash(H, id);*/
    } else {
      /*htbl_get_compressed(H, id, &s, &s_char_len, &h);*/
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
      memcpy(pos, &h, sizeof(hkey_t));
      pos += sizeof(hkey_t);
     
      /*  blue attribute  */
      if(htbl_has_attr(H, ATTR_BLUE)) {
        blue = htbl_get_attr(H, id, ATTR_BLUE);
        memcpy(pos, &blue, sizeof(bool_t));
        pos += sizeof(bool_t);
      }
          
      /*  red attribute  */
      if(htbl_has_attr(H, ATTR_RED)) {
        red = htbl_get_attr(H, id, ATTR_RED);
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
  
  while(context_keep_searching()) {
    context_sleep(PRODUCE_PERIOD);

    /**
     *  wait that all other pes have consumed my states
     */
  wait_for_states_consumed:
    comm_get(&data, 0, sizeof(pub_data_t), ME);
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
      comm_put(char_len, BUF.buffer[w], BUF.char_len[w], ME);
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
    comm_put(0, &data, sizeof(pub_data_t), ME);
  }
}

void * ddfs_comm_consumer
(void * arg) {
  const worker_id_t w = CFG_NO_WORKERS;
  bool_t f = FALSE;
  int pe;
  void * pos;
  uint16_t s_char_len;
  htbl_id_t sid;
  bool_t red = FALSE, blue = FALSE, is_new;
  char buffer[CFG_SHMEM_HEAP_SIZE];
  hkey_t h;
  pub_data_t remote_data;
  
  while(context_keep_searching()) {
    
    context_sleep(CONSUME_PERIOD);

    /**
     * get states put by remote PEs in their heap and put these in my
     * local hash table
     */
    for(pe = 0; pe < PES; pe ++) {
      if(ME != pe) {
	comm_get(&remote_data, 0, sizeof(pub_data_t), pe);
        if(remote_data.produced[ME]) {
          comm_get(buffer, DDFS_COMM_DATA_POS, remote_data.char_len, pe);
          comm_put(sizeof(bool_t) * ME, &f, sizeof(bool_t), pe);
          pos = buffer;
          while(remote_data.size --) {

            /*  get hash value  */
            memcpy(&h, pos, sizeof(hkey_t));
            pos += sizeof(hkey_t);
                    
            /*  get blue attribute  */
            if(htbl_has_attr(H, ATTR_BLUE)) {
              memcpy(&blue, pos, sizeof(bool_t));
              pos += sizeof(bool_t);
            }
          
            /*  get red attribute  */
            if(htbl_has_attr(H, ATTR_RED)) {
              memcpy(&red, pos, sizeof(bool_t));
              pos += sizeof(bool_t);
            }
       
	    if(CFG_HASH_COMPACTION) {
              assert(0);
	      /*
                htbl_insert_compressed(H, pos, s_char_len, h, &is_new, &sid);
              */
	    } else {
              
	      /*  get state vector char length  */
	      memcpy(&s_char_len, pos, sizeof(uint16_t));
	      pos += sizeof(uint16_t);
              
	      /*  get state vector and insert it  */
              assert(0);
	      /*
                htbl_insert_compressed(H, pos, s_char_len, h, &is_new, &sid);
              */
	      pos += s_char_len;
	    }

            if(is_new) {
              context_incr_stat(STAT_STATES_STORED, w, 1);
            }

            /*  set the blue and red attribute of the state  */
            if(blue && htbl_has_attr(H, ATTR_BLUE)) {
              htbl_set_attr(H, sid, ATTR_BLUE, TRUE);
            }
            if(red && htbl_has_attr(H, ATTR_RED)) {
              htbl_set_attr(H, sid, ATTR_BLUE, TRUE);
            }
          }
        }
      }
    }
  }
  return NULL;
}

void ddfs_comm_start
(htbl_t h) {
  worker_id_t w;
  int i = 0;
  pub_data_t data;
  
  /*  shmem and symmetrical heap initialisation  */
  PES = comm_pes();
  ME = comm_me();
  assert(PES <= MAX_PES);
  
  H = h;
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    BUF.status[w] = BUCKET_OK;
    BUF.size[w] = 0;
    BUF.char_len[w] = 0;
    BUF.full[w] = FALSE;
  }
  BASE_LEN = sizeof(hkey_t)
    + (htbl_has_attr(H, ATTR_BLUE) ? sizeof(bool_t) : 0)
    + (htbl_has_attr(H, ATTR_RED) ? sizeof(bool_t) : 0);
  for(i = 0; i < MAX_PES; i ++) {
    data.produced[i] = FALSE;
  }
  comm_put(0, &data, sizeof(pub_data_t), ME);

  /*  launch the producer and consumer threads  */
  pthread_create(&PROD, NULL, &ddfs_comm_producer, NULL);
  pthread_create(&CONS, NULL, &ddfs_comm_consumer, NULL);
}

void ddfs_comm_end
() {
  void * dummy;

  pthread_join(PROD, &dummy);
  pthread_join(CONS, &dummy);
}

#endif
