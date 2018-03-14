#include "config.h"
#include "dbfs_comm.h"
#include "comm.h"
#include "stbl.h"
#include "debug.h"
#include "dist_compression.h"

#if CFG_ALGO_BFS == 1 || CFG_ALGO_DBFS == 1

htbl_t H;
bfs_queue_t Q;
heap_t CW_HEAP;
char ** BUF;
uint32_t * LEN;
int PES;
int ME;
uint32_t * REMOTE_POS;
bool_t TERM_DETECTED = FALSE;

typedef enum {
  DBFS_COMM_NO_TERM = 0,
  DBFS_COMM_TERM = 1,
  DBFS_COMM_FORCE_TERM = 2,
} dbfs_comm_term_t;


#define POS_TERM \
  0
#define POS_TOKEN \
  (POS_TERM + sizeof(dbfs_comm_term_t))
#define POS_TERM_DETECTION_ASKED			\
  (POS_TOKEN + sizeof(bool_t))
#define POS_LEN(pe) \
  (POS_TERM_DETECTION_ASKED + sizeof(bool_t) + sizeof(uint32_t) * pe)
#define POS_DATA \
  (POS_LEN(PES))

void dbfs_comm_send_all_buffers
();

bool_t dbfs_comm_process_in_states
();

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
  bool_t b = TRUE;
  
  for(pe = 0; pe < PES; pe ++) {
    comm_put(POS_TERM_DETECTION_ASKED, &b, sizeof(bool_t), pe);
  }
}

bool_t dbfs_comm_term_detection_asked
() {
  bool_t result = TRUE;

  comm_get(&result, POS_TERM_DETECTION_ASKED, sizeof(bool_t), ME);
  return result;
}

void dbfs_comm_set_term_state
(dbfs_comm_term_t term) {
  comm_put(POS_TERM, &term, sizeof(dbfs_comm_term_t), ME);
}

void dbfs_comm_unset_term_detection_asked
() {
  bool_t b = FALSE;
  
  comm_put(POS_TERM_DETECTION_ASKED, &b, sizeof(bool_t), ME);
}

void dbfs_comm_send_token
() {
  bool_t token = TRUE;
  
  comm_put(POS_TOKEN, &token, sizeof(bool_t), (ME + 1) % PES);
}

void dbfs_comm_clear_token
() {
  bool_t token = FALSE;
  
  comm_put(POS_TOKEN, &token, sizeof(bool_t), ME);
}

bool_t dbfs_comm_token_received
() {
  bool_t result;

  comm_get(&result, POS_TOKEN, sizeof(bool_t), ME);
  return result;
}

void dbfs_comm_check_termination
(bool_t idle) {
  dbfs_comm_term_t term;

  if(TERM_DETECTED) {
    return;
  }
  comm_barrier();
  dbfs_comm_process_in_states();
  if(!context_keep_searching()) {
    term = DBFS_COMM_FORCE_TERM;
  } else if(idle && bfs_queue_is_empty(Q)) {
    term = DBFS_COMM_TERM;
  } else {
    term = DBFS_COMM_NO_TERM;
  }
  dbfs_comm_unset_term_detection_asked();
  dbfs_comm_set_term_state(term);
  comm_barrier();
  if(dbfs_comm_do_terminate()) {
    TERM_DETECTED = TRUE;
    context_stop_search();
  }
  comm_barrier();
}

bool_t dbfs_comm_check_communications_aux
(bool_t idle) {
  bool_t result;
  
  if(TERM_DETECTED) {
    return FALSE;
  }  
  result = dbfs_comm_process_in_states();
  if(dbfs_comm_token_received()) {
    dbfs_comm_clear_token();
    if(idle && bfs_queue_is_empty(Q)) {
      if(0 == ME) {
	dbfs_comm_ask_for_term_detection();
      } else {
	dbfs_comm_send_token();
      }
    }
  }
  if(dbfs_comm_term_detection_asked()) {
    dbfs_comm_check_termination(idle);
  }
  return result;
}

bool_t dbfs_comm_check_communications
() {
  return dbfs_comm_check_communications_aux(FALSE);
}

bool_t dbfs_comm_idle
() {
  clock_t start = clock();
  uint64_t duration;
  
  if(TERM_DETECTED) {
    return TRUE;
  }
  if(!context_keep_searching()) {
    dbfs_comm_ask_for_term_detection();
    dbfs_comm_check_termination(TRUE);
    return TRUE;
  }
  dbfs_comm_send_all_buffers();
  while(TRUE) {
    dbfs_comm_check_communications_aux(TRUE);
    if(TERM_DETECTED) {
      return TRUE;
    }
    if(!bfs_queue_is_empty(Q)) {
      return FALSE;
    }
    duration = 1000 * (clock() - start) / CLOCKS_PER_SEC;
    if(duration >= CFG_DBFS_CHECK_TERM_PERIOD_MS && 0 == ME) {
      dbfs_comm_send_token();
      start = clock();
    }
  }
}

void dbfs_comm_send_buffer
(int pe) {
  uint32_t len;
  
  if(TERM_DETECTED) {
    return;
  }
  debug("polls %d\n", pe);
  do {
    comm_get(&len, POS_LEN(ME), sizeof(uint32_t), pe);
    if(len > 0) {
      dbfs_comm_check_communications_aux(FALSE);
      if(TERM_DETECTED) {
	return;
      }
    }
  }
  while(len > 0);
  debug("sends %d bytes to %d\n", LEN[pe], pe);
  comm_put(REMOTE_POS[pe], BUF[pe], LEN[pe], pe);
  comm_put(POS_LEN(ME), &LEN[pe], sizeof(uint32_t), pe);
  memset(BUF[pe], 0, LEN[pe]);
  LEN[pe] = 0;
  debug("sent done\n");
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

bool_t dbfs_comm_process_state
(htbl_meta_data_t * mdata) {
  int pe;
  uint16_t size;

  if(CFG_DISTRIBUTED_STATE_COMPRESSION) {
    state_dist_compress((state_t) mdata->item, mdata->v, &size);
    mdata->v_set = TRUE;
    mdata->v_size = size;
    mdata->h = string_hash(mdata->v, size);
    mdata->h_set = TRUE;
  } else {
    mdata->h = state_hash((state_t) mdata->item);
    mdata->h_set = TRUE;
  }
  pe = dbfs_comm_state_owner(mdata->h);
  
  /**
   *  state is not mine => exit
   */
  if(ME == pe) {
    return TRUE;
  }
  
  if(!CFG_DISTRIBUTED_STATE_COMPRESSION) {
    size = state_char_size((state_t) mdata->item);
  }
  if(LEN[pe] + sizeof(uint16_t) + sizeof(hkey_t) + size
     > CFG_SHMEM_BUFFER_SIZE) {
    dbfs_comm_send_buffer(pe);
    if(TERM_DETECTED) {
      return FALSE;
    }
  }
  memcpy(BUF[pe] + LEN[pe], &size, sizeof(uint16_t));
  LEN[pe] += sizeof(uint16_t);
  memcpy(BUF[pe] + LEN[pe], &(mdata->h), sizeof(hkey_t));
  LEN[pe] += sizeof(hkey_t);
  if(CFG_DISTRIBUTED_STATE_COMPRESSION) {
    memcpy(BUF[pe] + LEN[pe], mdata->v, size);
  } else {
    state_serialise((state_t) mdata->item, BUF[pe] + LEN[pe], &size);
  }
  LEN[pe] += size;
  return FALSE;
}

void dbfs_comm_receive_buffer
(int pe,
 uint32_t len,
 int pos) {
  uint32_t stored = 0;
  bool_t is_new;
  char buffer[CFG_SHMEM_BUFFER_SIZE];
  htbl_id_t sid;
  htbl_meta_data_t mdata;
  bfs_queue_item_t item;
  char * b, * b_end;
  uint16_t size;
  
  debug("receives %d bytes from %d\n", len, pe);
  comm_get(buffer, pos, len, ME);
  b = buffer;
  b_end = b + len;
  len = 0;
  comm_put(POS_LEN(pe), &len, sizeof(uint32_t), ME);
  while(b != b_end) {
    htbl_meta_data_init(mdata, NULL);
    memcpy(&size, b, sizeof(uint16_t));
    b += sizeof(uint16_t);
    memcpy(&(mdata.h), b, sizeof(hkey_t));
    mdata.h_set = TRUE;
    b += sizeof(hkey_t);
    if(CFG_DISTRIBUTED_STATE_COMPRESSION) {
      memcpy(&mdata.v, b, size);
      mdata.v_set = TRUE;
      mdata.v_size = size;
    } else {
      heap_reset(CW_HEAP);
      mdata.item = state_unserialise(b, CW_HEAP);
    }
    b += size;
    stbl_insert(H, mdata, is_new);
    if(is_new) {
      stored ++;
      item.id = mdata.id;
      bfs_queue_enqueue(Q, item, 0, 0);
    }
  }
  context_incr_stat(STAT_STATES_STORED, 0, stored);
  debug("stored %d states received from %d\n", stored, pe);
}

bool_t dbfs_comm_process_in_states
() {
  int pe;
  bool_t result = FALSE;
  uint32_t pos = POS_DATA, len;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME) {
      comm_get(&len, POS_LEN(pe), sizeof(uint32_t), ME);
      if(len > 0) {
        dbfs_comm_receive_buffer(pe, len, pos);
        result = TRUE;
      }
      pos += CFG_SHMEM_BUFFER_SIZE;
    }
  }
  return result;
}

void dbfs_comm_start
(htbl_t h,
 bfs_queue_t q) {
  uint32_t len;
  int pe;
  dbfs_comm_term_t term = DBFS_COMM_NO_TERM;
  size_t hs;

  debug("dbfs_comm starting\n");
  PES = comm_pes();
  ME = comm_me();
  hs = POS_DATA + CFG_SHMEM_BUFFER_SIZE * (PES - 1);
  comm_malloc(hs);
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
      REMOTE_POS[pe] = POS_DATA + ME * CFG_SHMEM_BUFFER_SIZE;
      if(ME > pe) {
	REMOTE_POS[pe] -= CFG_SHMEM_BUFFER_SIZE;
      }
      BUF[pe] = mem_alloc0(SYSTEM_HEAP, CFG_SHMEM_BUFFER_SIZE);
    }
  }
  CW_HEAP = local_heap_new();
  comm_barrier();
  dist_compression_training_run();
  debug("dbfs_comm started\n");
}

void dbfs_comm_end
() {
  int pe;

  debug("dbfs_comm terminating\n");
  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME) {
      mem_free(SYSTEM_HEAP, BUF[pe]);
    }
  }
  mem_free(SYSTEM_HEAP, LEN);
  mem_free(SYSTEM_HEAP, BUF);
  mem_free(SYSTEM_HEAP, REMOTE_POS);
  heap_free(CW_HEAP);
  debug("dbfs_comm terminated\n");
}

#endif
