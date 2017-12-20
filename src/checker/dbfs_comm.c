#include "config.h"
#include "dbfs_comm.h"
#include "comm_gasnet.h"
#include "stbl.h"

#if CFG_ALGO_BFS == 1 || CFG_ALGO_DBFS == 1

#define COMM_WAIT_TIME_MUS   2
#define WORKER_WAIT_TIME_MUS 1

#define DBFS_COMM_DEBUG_XXX

#if defined(DBFS_COMM_DEBUG)
#define dbfs_comm_debug(...)   {                        \
    printf("[pe=%d:pid=%d] ", ME, getpid());		\
    printf(__VA_ARGS__);                                \
}
#else
#define dbfs_comm_debug(...) {}
#endif

const struct timespec COMM_WAIT_TIME = { 0, COMM_WAIT_TIME_MUS * 1000 };
const struct timespec WORKER_WAIT_TIME = { 0, WORKER_WAIT_TIME_MUS * 1000 };

htbl_t H;
bfs_queue_t Q;
pthread_t CW;
heap_t CW_HEAP;
char ** BUF0[CFG_NO_WORKERS];
char ** BUF1[CFG_NO_WORKERS];
uint32_t * LEN0[CFG_NO_WORKERS];
uint32_t * LEN1[CFG_NO_WORKERS];
uint32_t DBFS_HEAP_SIZE;
uint32_t DBFS_HEAP_SIZE_WORKER;
uint32_t DBFS_HEAP_SIZE_PE;
uint32_t SENT;
uint32_t RECV;
int PES;
int ME;
uint32_t * REMOTE_POS[CFG_NO_WORKERS];
bool_t TERM = FALSE;

#define POS_CHECK_TERM				\
  0
#define POS_CHANS				\
  (sizeof(bool_t))
#define POS_LEN(w, pe)						\
  (sizeof(bool_t) + sizeof(int32_t) +				\
   sizeof(uint32_t) * (w + pe * CFG_NO_WORKERS))
#define POS_DATA							\
  (sizeof(bool_t) + sizeof(int32_t) +					\
   sizeof(uint32_t) * CFG_NO_WORKERS * PES)


bool_t dbfs_comm_termination
() {
  return TERM;
}


uint8_t dbfs_comm_state_owner
(hkey_t h) {
  int i = 0;
  uint8_t result = 0;

  for(i = 0; i < sizeof(hkey_t); i ++) {
    result ^= h >> (i * 8);
  }
  return result % PES;
}


bool_t dbfs_comm_state_owned
(hkey_t h) {
  return dbfs_comm_state_owner(h) == ME;
}


void dbfs_comm_prepare_buffer
(worker_id_t w,
 int pe) {
  char * tmp;
  
  while(LEN1[w][pe] > 0) {
    context_sleep(WORKER_WAIT_TIME);
  }
  dbfs_comm_debug("worker %d puts %d bytes in send buffer to %d\n",
                  w, LEN0[w][pe], pe);
  tmp = BUF1[w][pe];
  BUF1[w][pe] = BUF0[w][pe];
  LEN1[w][pe] = LEN0[w][pe];
  memset(tmp, 0, DBFS_HEAP_SIZE_WORKER);
  BUF0[w][pe] = tmp;
  LEN0[w][pe] = 0;
}


void dbfs_comm_process_state
(worker_id_t w,
 state_t s,
 hkey_t h) {
  const int pe = dbfs_comm_state_owner(h);
  uint16_t size = state_char_size(s);;
  char * buf;

  if(LEN0[w][pe] + sizeof(hkey_t) + sizeof(uint16_t) + size >
     DBFS_HEAP_SIZE_WORKER) {
    dbfs_comm_prepare_buffer(w, pe);
  }
  buf = BUF0[w][pe] + LEN0[w][pe];
  memcpy(buf, &h, sizeof(hkey_t));
  memcpy(buf + sizeof(hkey_t), &size, sizeof(uint16_t));
  state_serialise(s, buf + sizeof(hkey_t) + sizeof(uint16_t), &size);
  LEN0[w][pe] += sizeof(hkey_t) + sizeof(uint16_t) + size;
}


void dbfs_comm_send_all_pending_states
(worker_id_t w) {
  int pe;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME && LEN0[w][pe] > 0) {
      dbfs_comm_prepare_buffer(w, pe);
    }
  }
}


void dbfs_comm_send_buffer
(worker_id_t w,
 int pe) {
  uint32_t len;

  dbfs_comm_debug("comm. polls %d\n", pe);
  do {
    comm_get(&len, POS_LEN(w, ME), sizeof(uint32_t), pe);
    if(len > 0) {
      context_sleep(WORKER_WAIT_TIME);
    }
  } while(len > 0);  
  dbfs_comm_debug("comm. sends %d bytes to %d\n", LEN1[w][pe], pe);
  comm_put(REMOTE_POS[w][pe], BUF1[w][pe], LEN1[w][pe], pe);
  comm_put(POS_LEN(w, ME), &LEN1[w][pe], sizeof(uint32_t), pe);
  LEN1[w][pe] = 0;
  dbfs_comm_debug("comm. sent done\n");
}


void dbfs_comm_receive_buffer
(worker_id_t w,
 int pe,
 uint32_t len,
 int pos) {
  uint32_t stored = 0;
  uint16_t slen;
  bool_t is_new;
  hkey_t h;
  char buffer[DBFS_HEAP_SIZE_WORKER];
  htbl_id_t sid;
  bfs_queue_item_t item;
  char * b, * b_end;
  state_t s;
  
  dbfs_comm_debug("comm. receives %d bytes from %d\n", len, pe);
  comm_get(buffer, pos, len, ME);
  b = buffer;
  b_end = b + len;
  len = 0;
  comm_put(POS_LEN(w, pe), &len, sizeof(uint32_t), ME);
  while(b != b_end) {
    memcpy(&h, b, sizeof(hkey_t));
    memcpy(&slen, b + sizeof(hkey_t), sizeof(uint16_t));
    heap_reset(CW_HEAP);
    s = state_unserialise(b + sizeof(hkey_t) + sizeof(uint16_t), CW_HEAP);
    stbl_insert(H, s, is_new, &sid, &h);
    b += sizeof(hkey_t) + sizeof(uint16_t) + slen;
    if(is_new) {
      stored ++;
      item.id = sid;
      bfs_queue_enqueue(Q, item, CFG_NO_WORKERS, h % CFG_NO_WORKERS);
    }
  }
  context_incr_stat(STAT_STATES_STORED, CFG_NO_WORKERS, stored);
  dbfs_comm_debug("comm. stored %d states received from %d\n", stored, pe);
}


bool_t dbfs_comm_worker_process_out_states
() {
  int pe;
  worker_id_t w;
  bool_t result = FALSE;
  
  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME) {
      for(w = 0; w < CFG_NO_WORKERS; w ++) {
	if(LEN1[w][pe] > 0) {
	  dbfs_comm_send_buffer(w, pe);
	  result = TRUE;
	  SENT ++;
	}
      }
    }
  }
  return result;
}


bool_t dbfs_comm_worker_process_in_states
() {
  int pe;
  worker_id_t w;
  bool_t result = FALSE;
  uint32_t pos = POS_DATA, len;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME) {
      for(w = 0; w < CFG_NO_WORKERS; w ++, pos += DBFS_HEAP_SIZE_WORKER) {
	comm_get(&len, POS_LEN(w, pe), sizeof(uint32_t), ME);
	if(0 != len) {
	  dbfs_comm_receive_buffer(w, pe, len, pos);
	  result = TRUE;
	  RECV ++;
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
      if(LEN0[w][pe] + LEN1[w][pe] != 0) {
	return FALSE;
      }
    }
  }
  return TRUE;
}


void dbfs_comm_check_termination
() {
  int pe;
  bool_t rterm = TRUE;
  int32_t chans = SENT - RECV, tot = 0;

  for(pe = 0; pe < PES && rterm; pe ++) {
    comm_get(&rterm, POS_CHECK_TERM, sizeof(bool_t), pe);
  }
  if(rterm) {
    comm_put(POS_CHANS, &chans, sizeof(int32_t), ME);
    for(pe = 0; pe < PES; pe ++) {
      comm_get(&chans, POS_CHANS, sizeof(int32_t), pe);
      tot += chans;
    }
    if(tot == 0) {
      TERM = TRUE;
    }
  }
}


void * dbfs_comm_worker
(void * arg) {
  bool_t check_term;
      
  while(!TERM) {
    context_sleep(COMM_WAIT_TIME);
    check_term = !dbfs_comm_worker_process_out_states();
    check_term = !dbfs_comm_worker_process_in_states() && check_term;
    check_term = check_term
      && bfs_queue_is_empty(Q) && dbfs_comm_all_buffers_empty();
    comm_put(POS_CHECK_TERM, &check_term, sizeof(bool_t), ME);
    if(check_term) {
      dbfs_comm_check_termination();
    }
  }
}


void dbfs_comm_start
(htbl_t h,
 bfs_queue_t q) {
  uint32_t len;
  int pe, remote_pos;
  worker_id_t w;
  int32_t n = INT32_MAX;
  
  PES = comm_no();
  ME = comm_me();
  DBFS_HEAP_SIZE_WORKER =
    (CFG_SHMEM_HEAP_SIZE - POS_DATA) / ((PES - 1) * CFG_NO_WORKERS);
  DBFS_HEAP_SIZE_PE = CFG_NO_WORKERS * DBFS_HEAP_SIZE_WORKER;
  DBFS_HEAP_SIZE = DBFS_HEAP_SIZE_PE * (PES - 1);
  TERM = FALSE;
  comm_put(POS_CHECK_TERM, &TERM, sizeof(bool_t), ME);
  comm_put(POS_CHANS, &n, sizeof(int32_t), ME);
  Q = q;
  H = h;
  SENT = 0;
  RECV = 0;
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    LEN0[w] = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    LEN1[w] = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF0[w] = mem_alloc0(SYSTEM_HEAP, sizeof(char *) * PES);
    BUF1[w] = mem_alloc0(SYSTEM_HEAP, sizeof(char *) * PES);
    REMOTE_POS[w] = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
  }
  for(pe = 0; pe < PES; pe ++) {
    remote_pos = POS_DATA + ME * DBFS_HEAP_SIZE_PE;
    if(ME > pe) {
      remote_pos -= DBFS_HEAP_SIZE_PE;
    }
    for(w = 0; w < CFG_NO_WORKERS; w ++) {
      len = 0;
      comm_put(POS_LEN(w, pe), &len, sizeof(uint32_t), ME);
      if(ME == pe) {
        REMOTE_POS[w][pe] = 0;
      } else {
        REMOTE_POS[w][pe] = remote_pos;
        BUF0[w][pe] = mem_alloc0(SYSTEM_HEAP, DBFS_HEAP_SIZE_WORKER);
        BUF1[w][pe] = mem_alloc0(SYSTEM_HEAP, DBFS_HEAP_SIZE_WORKER);
	remote_pos += DBFS_HEAP_SIZE_WORKER;
      }
    }
  }
  CW_HEAP = local_heap_new();
  pthread_create(&CW, NULL, &dbfs_comm_worker, NULL);
}


void dbfs_comm_end
() {
  void * dummy;
  int pe;
  worker_id_t w;
  
  pthread_join(CW, &dummy);
  dbfs_comm_debug("comm. terminated\n");
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    for(pe = 0; pe < PES; pe ++) {
      if(pe != ME) {
	mem_free(SYSTEM_HEAP, BUF0[w][pe]);
	mem_free(SYSTEM_HEAP, BUF1[w][pe]);
      }
    }
    mem_free(SYSTEM_HEAP, LEN0[w]);
    mem_free(SYSTEM_HEAP, LEN1[w]);
    mem_free(SYSTEM_HEAP, BUF0[w]);
    mem_free(SYSTEM_HEAP, BUF1[w]);
    mem_free(SYSTEM_HEAP, REMOTE_POS[w]);
  }
  heap_free(CW_HEAP);
}

#endif
