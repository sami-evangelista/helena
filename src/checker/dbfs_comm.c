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

#define DBFS_COMM_PACKET_MIN_SIZE 10000
#define DBFS_COMM_TERM_CHECK_PERIOD_MS 100

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
  DBFS_COMM_NO_TERM = 0,
  DBFS_COMM_TERM = 1,
  DBFS_COMM_FORCE_TERM = 2,
} dbfs_comm_term_t;


#define POS_TERM 0
#define POS_TERM_DETECTION sizeof(dbfs_comm_term_t)
#define POS_LEN(pe) (POS_TERM_DETECTION + sizeof(bool_t) +	\
		     sizeof(uint32_t) * pe)
#define POS_OCCUPIED(pe) (POS_LEN(PES) + sizeof(bool_t) * pe)
#define POS_DATA POS_OCCUPIED(PES)

uint16_t dbfs_comm_state_owner
(hkey_t h) {
  return h % PES;
}

bool_t dbfs_comm_state_owned
(hkey_t h) {
  return dbfs_comm_state_owner(h) == ME;
}

bool_t dbfs_comm_do_terminate
() {
  int pe;
  dbfs_comm_term_t rterm;
  bool_t result = TRUE;
  
  for(pe = 0; pe < PES; pe ++) {
    comm_get(&rterm, POS_TERM, sizeof(dbfs_comm_term_t), pe);
    if(DBFS_COMM_NO_TERM == rterm) {
      result = FALSE;
    } else if(DBFS_COMM_FORCE_TERM == rterm) {
      return TRUE;
    }
  }
  return result;
}

void dbfs_comm_ask_for_term_detection
() {
  int pe;
  bool_t term_detection = TRUE;
  
  for(pe = 0; pe < PES; pe ++) {
    comm_put(POS_TERM_DETECTION, &term_detection, sizeof(bool_t), pe);
  }
}

bool_t dbfs_comm_term_detection_asked
() {
  bool_t result = TRUE;

  comm_get(&result, POS_TERM_DETECTION, sizeof(bool_t), ME);
  return result;
}

void dbfs_comm_set_term_state
(dbfs_comm_term_t term) {
  comm_put(POS_TERM, &term, sizeof(dbfs_comm_term_t), ME);
}

void dbfs_comm_set_term_detection
(bool_t term_detection) {
  comm_put(POS_TERM_DETECTION, &term_detection, sizeof(bool_t), ME);
}

void dbfs_comm_simulate_check_termination() {
  comm_barrier();
  dbfs_comm_set_term_detection(FALSE);
  dbfs_comm_set_term_state(DBFS_COMM_NO_TERM);
  comm_barrier();
  comm_barrier();
}

bool_t dbfs_comm_check_termination
() {
  dbfs_comm_term_t term;
  bool_t result = FALSE, loop = TRUE;
  clock_t start = clock();
  uint64_t duration;
  
  if(TERM_DETECTED) {
    return TRUE;
  }
  dbfs_comm_send_all_buffers();
  while(loop) {
    dbfs_comm_process_in_states();
    if(!bfs_queue_is_empty(Q)) {
      loop = FALSE;
    } else {
      duration = 1000 * (clock() - start) / CLOCKS_PER_SEC;
      if(duration >= DBFS_COMM_TERM_CHECK_PERIOD_MS) {
	dbfs_comm_ask_for_term_detection();
	comm_barrier();
	dbfs_comm_process_in_states();
	if(!context_keep_searching()) {
	  term = DBFS_COMM_FORCE_TERM;
	} else if(bfs_queue_is_empty(Q)) {
	  term = DBFS_COMM_TERM;
	} else {
	  term = DBFS_COMM_NO_TERM;
	}
	dbfs_comm_set_term_detection(FALSE);
	dbfs_comm_set_term_state(term);
	comm_barrier();
	if(dbfs_comm_do_terminate()) {
	  TERM_DETECTED = TRUE;
	  loop = FALSE;
	  context_stop_search();
	}
	comm_barrier();
	start = clock();
      }
    }
  }
  return result;
}

void dbfs_comm_send_buffer
(int pe,
 bool_t wait) {
  //bool_t occupied = TRUE;
  uint32_t len;
  
  dbfs_comm_debug("polls %d\n", pe);
  do {
    //comm_get(&occupied, POS_OCCUPIED(pe), sizeof(bool_t), ME);  
    comm_get(&len, POS_LEN(ME), sizeof(uint32_t), pe);
    if(len > 0) {
      if(wait) {
	dbfs_comm_check_communications();
      } else {
	return;
      }
    }
  }
  while(len > 0);
  dbfs_comm_debug("sends %d bytes to %d\n", LEN[pe], pe);
  /*
    occupied = TRUE;
    comm_put(POS_OCCUPIED(pe), &occupied, sizeof(bool_t), ME);
  */
  comm_put(REMOTE_POS[pe], BUF[pe], LEN[pe], pe);
  comm_put(POS_LEN(ME), &LEN[pe], sizeof(uint32_t), pe);
  memset(BUF[pe], 0, LEN[pe]);
  LEN[pe] = 0;
  dbfs_comm_debug("sent done\n");
}

void dbfs_comm_send_all_buffers
() {
  int pe;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME && LEN[pe] > 0) {
      dbfs_comm_send_buffer(pe, TRUE);
    }
  }
}

void dbfs_comm_process_state
(state_t s,
 hkey_t h) {
  const int pe = dbfs_comm_state_owner(h);
  uint16_t size;
  char * buf;

  if(LEN[pe] + MODEL_STATE_SIZE > DBFS_HEAP_SIZE_PE) {
    dbfs_comm_send_buffer(pe, TRUE);
  }
  buf = BUF[pe] + LEN[pe];
  state_serialise(s, buf, &size);
  LEN[pe] += MODEL_STATE_SIZE;
  if(LEN[pe] >= DBFS_COMM_PACKET_MIN_SIZE) {
    dbfs_comm_send_buffer(pe, FALSE);
  }
}

void dbfs_comm_receive_buffer
(int pe,
 uint32_t len,
 int pos) {
  uint32_t stored = 0;
  bool_t is_new;
  hkey_t h;
  char buffer[DBFS_HEAP_SIZE_PE];
  htbl_id_t sid;
  bfs_queue_item_t item;
  char * b, * b_end;
  //bool_t occupied = FALSE;
  
  dbfs_comm_debug("receives %d bytes from %d\n", len, pe);
  comm_get(buffer, pos, len, ME);
  b = buffer;
  b_end = b + len;
  len = 0;
  comm_put(POS_LEN(pe), &len, sizeof(uint32_t), ME);
  //comm_put(POS_OCCUPIED(ME), &occupied, sizeof(bool_t), pe);
  while(b != b_end) {
    heap_reset(CW_HEAP);
    stbl_insert(H, state_unserialise(b, CW_HEAP), is_new, &sid, &h);
    b += MODEL_STATE_SIZE;
    if(is_new) {
      stored ++;
      item.id = sid;
      bfs_queue_enqueue(Q, item, 0, 0);
    }
  }
  context_incr_stat(STAT_STATES_STORED, 0, stored);
  dbfs_comm_debug("stored %d states received from %d\n", stored, pe);
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
  dbfs_comm_process_in_states();
  if(dbfs_comm_term_detection_asked()) {
    dbfs_comm_simulate_check_termination();
  }
}

void dbfs_comm_start
(htbl_t h,
 bfs_queue_t q) {
  uint32_t len;
  int pe, remote_pos;
  dbfs_comm_term_t term = DBFS_COMM_NO_TERM;

  dbfs_comm_debug("dbfs_comm starting\n");
  PES = comm_pes();
  ME = comm_me();
  DBFS_HEAP_SIZE_PE = (CFG_SHMEM_HEAP_SIZE - POS_DATA) / (PES - 1);
  comm_put(POS_TERM, &term, sizeof(dbfs_comm_term_t), ME);
  Q = q;
  H = h;
  LEN = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
  BUF = mem_alloc0(SYSTEM_HEAP, sizeof(char *) * PES);
  REMOTE_POS = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
  for(pe = 0; pe < PES; pe ++) {
    len = 0;
    comm_put(POS_LEN(pe), &len, sizeof(uint32_t), ME);
    if(ME == pe) {
      REMOTE_POS[pe] = 0;
    } else {
      remote_pos = POS_DATA + ME * DBFS_HEAP_SIZE_PE;
      if(ME > pe) {
	remote_pos -= DBFS_HEAP_SIZE_PE;
      }
      REMOTE_POS[pe] = remote_pos;
      BUF[pe] = mem_alloc0(SYSTEM_HEAP, DBFS_HEAP_SIZE_PE);
    }
  }
  dbfs_comm_debug("dbfs_comm at barrier\n");
  CW_HEAP = local_heap_new();
  comm_barrier();
  dbfs_comm_debug("dbfs_comm started\n");
}

void dbfs_comm_end
() {
  int pe;

  dbfs_comm_debug("dbfs_comm terminated\n");
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
