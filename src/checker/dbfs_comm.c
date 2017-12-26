#include "config.h"
#include "dbfs_comm.h"
#include "comm.h"
#include "stbl.h"

#if CFG_ALGO_BFS == 1 || CFG_ALGO_DBFS == 1


#define DBFS_COMM_DEBUG_XXX

#if defined(DBFS_COMM_DEBUG)
#define dbfs_comm_debug(...)   {                \
    printf("[pe=%d:pid=%d] ", ME, getpid());    \
    printf(__VA_ARGS__);                        \
  }
#else
#define dbfs_comm_debug(...) {}
#endif

#define WORKER_WAIT_TIME_MUS 1
const struct timespec WORKER_WAIT_TIME = { 0, WORKER_WAIT_TIME_MUS * 1000 };

htbl_t H;
bfs_queue_t Q;
heap_t CW_HEAP;
char ** BUF[CFG_NO_WORKERS];
uint32_t * LEN[CFG_NO_WORKERS];
uint32_t DBFS_HEAP_SIZE;
uint32_t DBFS_HEAP_SIZE_WORKER;
uint32_t DBFS_HEAP_SIZE_PE;
int PES;
int ME;
uint32_t * REMOTE_POS[CFG_NO_WORKERS];

#define POS_TERM 0
#define POS_TERM_DETECTION sizeof(bool_t)
#define POS_LEN(w, pe)                                                  \
  (sizeof(bool_t) + sizeof(bool_t) +                                    \
   sizeof(uint32_t) * (w + pe * CFG_NO_WORKERS))
#define POS_DATA                                                        \
  (sizeof(bool_t) + sizeof(bool_t) +                                    \
   sizeof(int32_t) + sizeof(uint32_t) * CFG_NO_WORKERS * PES)


uint8_t dbfs_comm_state_owner
(hkey_t h) {
  int i = 0;
  /*
  uint8_t result = 0;

  for(i = 0; i < sizeof(hkey_t); i ++) {
    result ^= h >> (i * 8);
  }
  */
  return h % PES;
}


bool_t dbfs_comm_state_owned
(hkey_t h) {
  return dbfs_comm_state_owner(h) == ME;
}

int dbfs_comm_no_pes_waiting
() {
  int result = 0, pe;
  bool_t state;
  
  for(pe = 0; pe < PES; pe ++) {
    comm_get(&state, POS_TERM_DETECTION, sizeof(bool_t), pe);
    if(state) {
      result ++;
    }
  }
  return result;
}

bool_t dbfs_comm_some_pe_waiting
() {
  return dbfs_comm_no_pes_waiting() > 0;
}


bool_t dbfs_comm_all_pes_waiting
() {
  return dbfs_comm_no_pes_waiting() == PES;
}


bool_t dbfs_comm_all_pes_term
() {
  int pe;
  bool_t rterm;
  
  for(pe = 0; pe < PES; pe ++) {
    comm_get(&rterm, POS_TERM, sizeof(bool_t), pe);
    if(!rterm) {
      return FALSE;
    }
  }
  return TRUE;
}


void dbfs_comm_set_term_detection_state
(bool_t state) {
  comm_put(POS_TERM_DETECTION, &state, sizeof(bool_t), ME);
}


bool_t dbfs_comm_check_termination_aux
(worker_id_t w,
 bool_t term_val) {
  bool_t term, result = FALSE;
  
  if(dbfs_comm_all_pes_waiting()) {
    comm_barrier();
    dbfs_comm_process_in_states(w);
    term = term_val && bfs_queue_is_empty(Q);
    comm_put(POS_TERM, &term, sizeof(bool_t), ME);
    comm_barrier();
    result = dbfs_comm_all_pes_term();
    comm_barrier();
  }
  return result;
}


bool_t dbfs_comm_check_termination
(worker_id_t w) {
  return dbfs_comm_check_termination_aux(w, TRUE);
}


void dbfs_comm_send_buffer
(worker_id_t w,
 int pe) {
  uint32_t len;

  dbfs_comm_debug("comm. polls %d\n", pe);
  do {
    comm_get(&len, POS_LEN(w, ME), sizeof(uint32_t), pe);
    if(len > 0) {
      dbfs_comm_process_in_states(w);
      if(dbfs_comm_some_pe_waiting()) {
        dbfs_comm_set_term_detection_state(TRUE);
        dbfs_comm_check_termination_aux(w, FALSE);
      }
      nanosleep(&WORKER_WAIT_TIME, NULL);
    }
  } while(len > 0); 
  dbfs_comm_set_term_detection_state(FALSE);
  dbfs_comm_debug("comm. sends %d bytes to %d\n", LEN[w][pe], pe);
  comm_put(REMOTE_POS[w][pe], BUF[w][pe], LEN[w][pe], pe);
  comm_put(POS_LEN(w, ME), &LEN[w][pe], sizeof(uint32_t), pe);
  memset(BUF[w][pe], 0, LEN[w][pe]);
  LEN[w][pe] = 0;
  dbfs_comm_debug("comm. sent done\n");
}


void dbfs_comm_send_all_buffers
(worker_id_t w) {
  int pe;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME && LEN[w][pe] > 0) {
      dbfs_comm_send_buffer(w, pe);
    }
  }
}


void dbfs_comm_process_state
(worker_id_t w,
 state_t s,
 hkey_t h) {
  const int pe = dbfs_comm_state_owner(h);
  uint16_t size = state_char_size(s);;
  char * buf;

  if(LEN[w][pe] + sizeof(hkey_t) + sizeof(uint16_t) + size >
     DBFS_HEAP_SIZE_WORKER) {
    dbfs_comm_send_buffer(w, pe);
  }
  buf = BUF[w][pe] + LEN[w][pe];
  memcpy(buf, &h, sizeof(hkey_t));
  memcpy(buf + sizeof(hkey_t), &size, sizeof(uint16_t));
  state_serialise(s, buf + sizeof(hkey_t) + sizeof(uint16_t), &size);
  LEN[w][pe] += sizeof(hkey_t) + sizeof(uint16_t) + size;
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


bool_t dbfs_comm_process_in_states
(worker_id_t w) {
  int pe;
  bool_t result = FALSE;
  uint32_t pos = POS_DATA, len;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME) {
      comm_get(&len, POS_LEN(w, pe), sizeof(uint32_t), ME);
      if(0 != len) {
        dbfs_comm_receive_buffer(w, pe, len, pos);
        result = TRUE;
      }
      pos += DBFS_HEAP_SIZE_WORKER;
    }
  }
  return result;
}


void dbfs_comm_check_communications
() {
  dbfs_comm_process_in_states(0);
}

void dbfs_comm_start
(htbl_t h,
 bfs_queue_t q) {
  uint32_t len;
  int pe, remote_pos;
  worker_id_t w;
  bool_t term = FALSE;
  
  PES = comm_pes();
  ME = comm_me();
  DBFS_HEAP_SIZE_WORKER =
    (CFG_SHMEM_HEAP_SIZE - POS_DATA) / ((PES - 1) * CFG_NO_WORKERS);
  DBFS_HEAP_SIZE_PE = CFG_NO_WORKERS * DBFS_HEAP_SIZE_WORKER;
  DBFS_HEAP_SIZE = DBFS_HEAP_SIZE_PE * (PES - 1);
  comm_put(POS_TERM, &term, sizeof(bool_t), ME);
  Q = q;
  H = h;
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    LEN[w] = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
    BUF[w] = mem_alloc0(SYSTEM_HEAP, sizeof(char *) * PES);
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
        BUF[w][pe] = mem_alloc0(SYSTEM_HEAP, DBFS_HEAP_SIZE_WORKER);
	remote_pos += DBFS_HEAP_SIZE_WORKER;
      }
    }
  }
  CW_HEAP = local_heap_new();
  comm_barrier();
}


void dbfs_comm_end
() {
  int pe;
  worker_id_t w;

  dbfs_comm_debug("comm. terminated\n");
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    for(pe = 0; pe < PES; pe ++) {
      if(pe != ME) {
	mem_free(SYSTEM_HEAP, BUF[w][pe]);
      }
    }
    mem_free(SYSTEM_HEAP, LEN[w]);
    mem_free(SYSTEM_HEAP, BUF[w]);
    mem_free(SYSTEM_HEAP, REMOTE_POS[w]);
  }
  heap_free(CW_HEAP);
}

#endif
