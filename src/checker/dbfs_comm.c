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

#define DBFS_COMM_WAIT_TIME_MUS 1
const struct timespec DBFS_COMM_WAIT_TIME = {
  0, DBFS_COMM_WAIT_TIME_MUS * 1000
};

htbl_t H;
bfs_queue_t Q;
heap_t CW_HEAP;
char ** BUF;
uint32_t * LEN;
uint32_t DBFS_HEAP_SIZE_PE;
int PES;
int ME;
uint32_t * REMOTE_POS;
bool_t TERM_DETECTED = FALSE;

typedef enum {
  DBFS_COMM_NO_TERM,
  DBFS_COMM_TERM,
  DBFS_COMM_FORCE_TERM,
} dbfs_comm_term_t;

#define POS_TERM 0
#define POS_TERM_DETECTION sizeof(dbfs_comm_term_t)
#define POS_LEN(pe)							\
  (sizeof(dbfs_comm_term_t) + sizeof(bool_t) + sizeof(uint32_t) * pe)
#define POS_DATA                                                        \
  (sizeof(dbfs_comm_term_t) + sizeof(bool_t) + sizeof(uint32_t) * PES)


uint8_t dbfs_comm_state_owner
(hkey_t h) {
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
  dbfs_comm_term_t rterm;
  bool_t result = TRUE;
  
  for(pe = 0; pe < PES; pe ++) {
    comm_get(&rterm, POS_TERM, sizeof(dbfs_comm_term_t), pe);
    if(rterm == DBFS_COMM_NO_TERM) {
      result = FALSE;
    } else if(rterm == DBFS_COMM_FORCE_TERM) {
      context_stop_search();
      return TRUE;
    }
  }
  return result;
}


void dbfs_comm_set_term_detection_state
(bool_t state) {
  comm_put(POS_TERM_DETECTION, &state, sizeof(bool_t), ME);
}


bool_t dbfs_comm_check_termination_aux
(bool_t term_val) {
  dbfs_comm_term_t term;
  bool_t result = FALSE;

  if(TERM_DETECTED) {
    result = TRUE;
  } else if(dbfs_comm_all_pes_waiting()) {
    comm_barrier();
    dbfs_comm_process_in_states();
    if(!context_keep_searching()) {
      term = DBFS_COMM_FORCE_TERM;
    } else if(term_val && bfs_queue_is_empty(Q)) {
      term = DBFS_COMM_TERM;
    } else {
      term = DBFS_COMM_NO_TERM;
    }
    comm_put(POS_TERM, &term, sizeof(dbfs_comm_term_t), ME);
    comm_barrier();
    if(result = dbfs_comm_all_pes_term()) {
      TERM_DETECTED = TRUE;
    }
    comm_barrier();
  }
  return result;
}


bool_t dbfs_comm_check_termination
() {
  return dbfs_comm_check_termination_aux(TRUE);
}


void dbfs_comm_send_buffer
(int pe) {
  uint32_t len;

  dbfs_comm_debug("comm. polls %d\n", pe);
  do {
    comm_get(&len, POS_LEN(ME), sizeof(uint32_t), pe);
    if(len > 0) {
      dbfs_comm_process_in_states();
      if(dbfs_comm_some_pe_waiting()) {
        dbfs_comm_set_term_detection_state(TRUE);
        if(dbfs_comm_check_termination_aux(FALSE)) {
	  return;
	}
      }
      nanosleep(&DBFS_COMM_WAIT_TIME, NULL);
    }
  } while(len > 0); 
  dbfs_comm_set_term_detection_state(FALSE);
  dbfs_comm_debug("comm. sends %d bytes to %d\n", LEN[pe], pe);
  comm_put(REMOTE_POS[pe], BUF[pe], LEN[pe], pe);
  comm_put(POS_LEN(ME), &LEN[pe], sizeof(uint32_t), pe);
  memset(BUF[pe], 0, LEN[pe]);
  LEN[pe] = 0;
  dbfs_comm_debug("comm. sent done\n");
}


void dbfs_comm_send_all_buffers
() {
  int pe;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME && LEN[pe] > 0) {
      dbfs_comm_send_buffer(pe);
    }
  }
}


void dbfs_comm_process_state
(state_t s,
 hkey_t h) {
  const int pe = dbfs_comm_state_owner(h);
  uint16_t size = state_char_size(s);;
  char * buf;

  if(LEN[pe] + sizeof(uint16_t) + size > DBFS_HEAP_SIZE_PE) {
    dbfs_comm_send_buffer(pe);
  }
  buf = BUF[pe] + LEN[pe];
  memcpy(buf, &size, sizeof(uint16_t));
  state_serialise(s, buf + sizeof(uint16_t), &size);
  LEN[pe] += sizeof(uint16_t) + size;
}


void dbfs_comm_receive_buffer
(int pe,
 uint32_t len,
 int pos) {
  uint32_t stored = 0;
  uint16_t slen;
  bool_t is_new;
  hkey_t h;
  char buffer[DBFS_HEAP_SIZE_PE];
  htbl_id_t sid;
  bfs_queue_item_t item;
  char * b, * b_end;
  state_t s;
  
  dbfs_comm_debug("comm. receives %d bytes from %d\n", len, pe);
  comm_get(buffer, pos, len, ME);
  b = buffer;
  b_end = b + len;
  len = 0;
  comm_put(POS_LEN(pe), &len, sizeof(uint32_t), ME);
  while(b != b_end) {
    memcpy(&slen, b, sizeof(uint16_t));
    heap_reset(CW_HEAP);
    s = state_unserialise(b +sizeof(uint16_t), CW_HEAP);
    stbl_insert(H, s, is_new, &sid, &h);
    b += sizeof(uint16_t) + slen;
    if(is_new) {
      stored ++;
      item.id = sid;
      bfs_queue_enqueue(Q, item, 0, 0);
    }
  }
  context_incr_stat(STAT_STATES_STORED, 0, stored);
  dbfs_comm_debug("comm. stored %d states received from %d\n", stored, pe);
}


bool_t dbfs_comm_process_in_states
() {
  int pe;
  bool_t result = FALSE;
  uint32_t pos = POS_DATA, len;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME) {
      comm_get(&len, POS_LEN(pe), sizeof(uint32_t), ME);
      if(0 != len) {
        dbfs_comm_receive_buffer(pe, len, pos);
        result = TRUE;
      }
      pos += DBFS_HEAP_SIZE_PE;
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
  bool_t term = FALSE;
  
  PES = comm_pes();
  ME = comm_me();
  DBFS_HEAP_SIZE_PE = (CFG_SHMEM_HEAP_SIZE - POS_DATA) / (PES - 1);
  comm_put(POS_TERM, &term, sizeof(bool_t), ME);
  Q = q;
  H = h;
  LEN = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
  BUF = mem_alloc0(SYSTEM_HEAP, sizeof(char *) * PES);
  REMOTE_POS = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
  for(pe = 0; pe < PES; pe ++) {
    remote_pos = POS_DATA + ME * DBFS_HEAP_SIZE_PE;
    if(ME > pe) {
      remote_pos -= DBFS_HEAP_SIZE_PE;
    }
    len = 0;
    comm_put(POS_LEN(pe), &len, sizeof(uint32_t), ME);
    if(ME == pe) {
      REMOTE_POS[pe] = 0;
    } else {
      REMOTE_POS[pe] = remote_pos;
      BUF[pe] = mem_alloc0(SYSTEM_HEAP, DBFS_HEAP_SIZE_PE);
      remote_pos += DBFS_HEAP_SIZE_PE;
    }
  }
  CW_HEAP = local_heap_new();
  comm_barrier();
}


void dbfs_comm_end
() {
  int pe;

  dbfs_comm_debug("comm. terminated\n");
  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME) {
      mem_free(SYSTEM_HEAP, BUF[pe]);
    }
  }
  mem_free(SYSTEM_HEAP, LEN);
  mem_free(SYSTEM_HEAP, BUF);
  mem_free(SYSTEM_HEAP, REMOTE_POS);
  heap_free(CW_HEAP);
}

#endif
