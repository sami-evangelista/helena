#include "config.h"
#include "dbfs_comm.h"
#include "comm_shmem.h"

#if CFG_ALGO_BFS == 1 || CFG_ALGO_DBFS == 1

#define COMM_WAIT_TIME_MUS   2
#define WORKER_WAIT_TIME_MUS 1

#define DBFS_COMM_DEBUG_XXX

#if defined(DBFS_COMM_DEBUG)
#define dbfs_comm_debug(...)   {		\
    printf("[%d:%d] ", ME, getpid());		\
    printf(__VA_ARGS__);			\
}
#else
#define dbfs_comm_debug(...) {}
#endif

const struct timespec COMM_WAIT_TIME = { 0, COMM_WAIT_TIME_MUS * 1000 };
const struct timespec WORKER_WAIT_TIME = { 0, WORKER_WAIT_TIME_MUS * 1000 };

htbl_t H;
bfs_queue_t Q;
pthread_t CW;
char ** BUF[CFG_NO_WORKERS][2];
uint32_t * LEN[CFG_NO_WORKERS][2];
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
  
  while(LEN[w][1][pe] > 0) {
    context_sleep(WORKER_WAIT_TIME);
  }
  dbfs_comm_debug("worker %d puts %d bytes in send buffer to %d\n",
		  w, LEN[w][0][pe], pe);
  tmp = BUF[w][1][pe];
  BUF[w][1][pe] = BUF[w][0][pe];
  LEN[w][1][pe] = LEN[w][0][pe];
  memset(tmp, 0, DBFS_HEAP_SIZE_WORKER);
  BUF[w][0][pe] = tmp;
  LEN[w][0][pe] = 0;
}


void dbfs_comm_process_state
(worker_id_t w,
 state_t s,
 hkey_t h) {
  const uint16_t len = state_char_size(s);
  const int pe = dbfs_comm_state_owner(h);
  char * buf;

  if(LEN[w][0][pe] + sizeof(hkey_t) + sizeof(uint16_t) + len >
     DBFS_HEAP_SIZE_WORKER) {
    dbfs_comm_prepare_buffer(w, pe);
  }
  buf = BUF[w][0][pe] + LEN[w][0][pe];
  memcpy(buf, &h, sizeof(hkey_t));
  memcpy(buf + sizeof(hkey_t), &len, sizeof(uint16_t));
  state_serialise(s, buf + sizeof(hkey_t) + sizeof(uint16_t));
  LEN[w][0][pe] += sizeof(hkey_t) + sizeof(uint16_t) + len;
}


void dbfs_comm_send_all_pending_states
(worker_id_t w) {
  int pe;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME && LEN[w][0][pe] > 0) {
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
    comm_shmem_get(&len, POS_LEN(w, ME), sizeof(uint32_t), pe);
    if(len > 0) {
      context_sleep(WORKER_WAIT_TIME);
    }
  } while(len > 0);  
  dbfs_comm_debug("comm. sends %d bytes to %d\n", LEN[w][1][pe], pe);
  comm_shmem_put(REMOTE_POS[w][pe], BUF[w][1][pe], LEN[w][1][pe], pe);
  comm_shmem_put(POS_LEN(w, ME), &LEN[w][1][pe], sizeof(uint32_t), pe);
  LEN[w][1][pe] = 0;
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
  
  dbfs_comm_debug("comm. receives %d bytes from %d\n", len, pe);
  comm_shmem_get(buffer, pos, len, ME);
  b = buffer;
  b_end = b + len;
  len = 0;
  comm_shmem_put(POS_LEN(w, pe), &len, sizeof(uint32_t), ME);
  while(b != b_end) {
    memcpy(&h, b, sizeof(hkey_t));
    b += sizeof(hkey_t);
    memcpy(&slen, b, sizeof(uint16_t));
    b += sizeof(uint16_t);
    htbl_insert_serialised(H, b, slen, h, &is_new, &sid);
    b += slen;
    if(is_new) {
      stored ++;
      item.id = sid;
      bfs_queue_enqueue(Q, item, CFG_NO_WORKERS, h % CFG_NO_WORKERS);
    }
  }
  context_incr_stat(STAT_STATES_STORED, CFG_NO_WORKERS, stored);
  dbfs_comm_debug("comm. stored %d states received from %d\n", stored, pe);
}


bool_t dbfs_comm_worker_process_outcoming_states
() {
  int pe;
  worker_id_t w;
  bool_t result = FALSE;
  
  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME) {
      for(w = 0; w < CFG_NO_WORKERS; w ++) {
	if(LEN[w][1][pe] > 0) {
	  dbfs_comm_send_buffer(w, pe);
	  result = TRUE;
	  SENT ++;
	}
      }
    }
  }
  return result;
}


bool_t dbfs_comm_worker_process_incoming_states
() {
  worker_id_t w;
  uint32_t pos = POS_DATA, len;
  bool_t result = FALSE;
  int pe;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME) {
      for(w = 0; w < CFG_NO_WORKERS; w ++, pos += DBFS_HEAP_SIZE_WORKER) {
	comm_shmem_get(&len, POS_LEN(w, pe), sizeof(uint32_t), ME);
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
      if(LEN[w][0][pe] + LEN[w][1][pe] != 0) {
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
    comm_shmem_get(&rterm, POS_CHECK_TERM, sizeof(bool_t), pe);
  }
  if(rterm) {
    comm_shmem_put(POS_CHANS, &chans, sizeof(int32_t), ME);
    for(pe = 0; pe < PES; pe ++) {
      comm_shmem_get(&chans, POS_CHANS, sizeof(int32_t), pe);
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
    check_term = !dbfs_comm_worker_process_outcoming_states();
    check_term = !dbfs_comm_worker_process_incoming_states() && check_term;
    check_term = check_term
      && bfs_queue_is_empty(Q) && dbfs_comm_all_buffers_empty();
    comm_shmem_put(POS_CHECK_TERM, &check_term, sizeof(bool_t), ME);
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
  
  PES = comm_shmem_pes();
  ME = comm_shmem_me();
  DBFS_HEAP_SIZE_WORKER =
    (CFG_SHMEM_HEAP_SIZE - POS_DATA) / ((PES - 1) * CFG_NO_WORKERS);
  DBFS_HEAP_SIZE_PE = CFG_NO_WORKERS * DBFS_HEAP_SIZE_WORKER;
  DBFS_HEAP_SIZE = DBFS_HEAP_SIZE_PE * (PES - 1);
  TERM = FALSE;
  comm_shmem_put(POS_CHECK_TERM, &TERM, sizeof(bool_t), ME);
  comm_shmem_put(POS_CHANS, &n, sizeof(int32_t), ME);
  Q = q;
  H = h;
  SENT = 0;
  RECV = 0;
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    LEN[w][0] = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    LEN[w][1] = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF[w][0] = mem_alloc0(SYSTEM_HEAP, sizeof(char *) * PES);
    BUF[w][1] = mem_alloc0(SYSTEM_HEAP, sizeof(char *) * PES);
    REMOTE_POS[w] = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
  }
  for(pe = 0; pe < PES; pe ++) {
    remote_pos = POS_DATA + ME * DBFS_HEAP_SIZE_PE;
    if(ME > pe) {
      remote_pos -= DBFS_HEAP_SIZE_PE;
    }
    for(w = 0; w < CFG_NO_WORKERS; w ++) {
      len = 0;
      comm_shmem_put(POS_LEN(w, pe), &len, sizeof(uint32_t), ME);
      if(ME == pe) {
        REMOTE_POS[w][pe] = 0;
      } else {
        REMOTE_POS[w][pe] = remote_pos;
        BUF[w][0][pe] = mem_alloc0(SYSTEM_HEAP, DBFS_HEAP_SIZE_WORKER);
        BUF[w][1][pe] = mem_alloc0(SYSTEM_HEAP, DBFS_HEAP_SIZE_WORKER);
	remote_pos += DBFS_HEAP_SIZE_WORKER;
      }
    }
  }
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
	mem_free(SYSTEM_HEAP, BUF[w][0][pe]);
	mem_free(SYSTEM_HEAP, BUF[w][1][pe]);
      }
    }
    mem_free(SYSTEM_HEAP, LEN[w][0]);
    mem_free(SYSTEM_HEAP, LEN[w][1]);
    mem_free(SYSTEM_HEAP, BUF[w][0]);
    mem_free(SYSTEM_HEAP, BUF[w][1]);
    mem_free(SYSTEM_HEAP, REMOTE_POS[w]);
  }
}

#endif
