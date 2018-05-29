#include "config.h"
#include "dbfs_comm.h"
#include "comm.h"
#include "stbl.h"
#include "debug.h"
#include "dist_compression.h"
#include "bwalk.h"

#if CFG_ALGO_BFS == 1 || CFG_ALGO_DBFS == 1

htbl_t H;
bfs_queue_t Q;
heap_t CW_HEAP;
char ** BUF;
char * BUFC;
uint32_t * LEN;
int PES;
int ME;
uint32_t * REMOTE_POS;
bool_t TERM_DETECTED = FALSE;
uint32_t SINGLE_BUFFER_SIZE;
uint32_t * FIRSTC;
uint32_t LASTC;
uint32_t SIZEC;
bwalk_data_t EXPL_CACHE_DATA;
bool_t BWALK_INITIAL_DONE = FALSE;
bool_t IN_CACHE_EXPLORATION = FALSE;

typedef enum {
  DBFS_COMM_NO_TERM = 0,
  DBFS_COMM_TERM = 1,
  DBFS_COMM_FORCE_TERM = 2,
} dbfs_comm_term_t;

#define POS_TERM                                \
  0
#define POS_TOKEN                               \
  (POS_TERM + sizeof(dbfs_comm_term_t))
#define POS_TERM_DETECTION_ASKED                \
  (POS_TOKEN + sizeof(bool_t))
#define POS_LEN(pe)                                                     \
  (POS_TERM_DETECTION_ASKED + sizeof(bool_t) + sizeof(uint32_t) * pe)
#define POS_DATA                                \
  (POS_LEN(PES))


/**
 *  exploration cache
 */
#if CFG_DBFS_EXPLORATION_CACHE_SIZE == 0

#define DBFS_COMM_CACHE_CLEAR() {}
#define DBFS_COMM_CACHE_INSERT(id) {}
#define DBFS_COMM_CACHE_PICK(id, found) { found = FALSE; }

#else

typedef struct {
  htbl_id_t id[CFG_DBFS_EXPLORATION_CACHE_SIZE];
  uint32_t next, size;
  rseed_t rnd;
} dbfs_comm_cache_t;
dbfs_comm_cache_t DBFS_COMM_CACHE;

#define DBFS_COMM_CACHE_CLEAR() {				\
    memset(&DBFS_COMM_CACHE, 0, sizeof(DBFS_COMM_CACHE));	\
    DBFS_COMM_CACHE.rnd = random_seed(ME);			\
  }
#define DBFS_COMM_CACHE_INSERT(id) {                                    \
    DBFS_COMM_CACHE.id[DBFS_COMM_CACHE.next] = id;                      \
    DBFS_COMM_CACHE.next = (DBFS_COMM_CACHE.next + 1) %                 \
      CFG_DBFS_EXPLORATION_CACHE_SIZE;					\
    if(DBFS_COMM_CACHE.size < CFG_DBFS_EXPLORATION_CACHE_SIZE) {	\
      DBFS_COMM_CACHE.size ++;                                          \
    }                                                                   \
  }
#define DBFS_COMM_CACHE_PICK(id, found) {				\
    if(found = (DBFS_COMM_CACHE.size > 0)) {				\
      uint32_t pos = random_int(&DBFS_COMM_CACHE.rnd) %	DBFS_COMM_CACHE.size; \
      id = DBFS_COMM_CACHE.id[pos];					\
      DBFS_COMM_CACHE.id[pos] = DBFS_COMM_CACHE.id[DBFS_COMM_CACHE.size - 1]; \
      DBFS_COMM_CACHE.size --;						\
      DBFS_COMM_CACHE.next = DBFS_COMM_CACHE.size; 			\
    }									\
  }
#endif

#define DBFS_COMM_BUFFER_OVERFLOW(pe, added)    \
  (LEN[pe] + LASTC - FIRSTC[pe] + added > SINGLE_BUFFER_SIZE)


void dbfs_comm_send_all_buffers
();

bool_t dbfs_comm_process_in_states
();

bool_t dbfs_comm_process_state_aux
(htbl_meta_data_t * mdata,
 bool_t send);

uint16_t dbfs_comm_state_owner
(hkey_t h) {
  return h % PES;
}

bool_t dbfs_comm_state_owned
(hkey_t h) {
  return dbfs_comm_state_owner(h) == ME;
}

void dbfs_comm_new_state_stored
(htbl_id_t id) {
  DBFS_COMM_CACHE_INSERT(id);
}

bool_t dbfs_comm_explore_cache_hook
(state_t s,
 void * data) {
  htbl_meta_data_t mdata;
  bfs_queue_item_t qitem;
  bool_t is_new;
  
  htbl_meta_data_init(mdata, s);
  if(dbfs_comm_process_state_aux(&mdata, FALSE)) {
    stbl_insert(H, mdata, is_new);
    if(is_new) {
      htbl_set_worker_attr(H, mdata.id, ATTR_CYAN, 0, TRUE);
      qitem.id = mdata.id;
      qitem.s = s;
      bfs_queue_enqueue(Q, qitem, 0, 0);
      context_incr_stat(STAT_STATES_STORED, 0, 1);
      dbfs_comm_new_state_stored(mdata.id);
      return FALSE;
    }
  }
  return TRUE;
}

void dbfs_comm_explore_cache
() {
  htbl_id_t id;
  bool_t found;
  state_t s;

  DBFS_COMM_CACHE_PICK(id, found);
  if(found) {
    s = htbl_get(H, id, SYSTEM_HEAP);
  } else if(!BWALK_INITIAL_DONE) {
    BWALK_INITIAL_DONE = TRUE;
    s = state_initial(SYSTEM_HEAP);
  } else {
    return;
  }
  IN_CACHE_EXPLORATION = TRUE;
  bwalk_generic(0, s, EXPL_CACHE_DATA, 1, FALSE,
                &dbfs_comm_explore_cache_hook, NULL);
  IN_CACHE_EXPLORATION = FALSE;
  state_free(s);
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
  dbfs_comm_term_t term, rterm;
  int pe;
  bool_t all_term, force_term;

  /**
   * termination already detected => nothing to do
   */
  if(TERM_DETECTED) {
    return;
  }

  /**
   * wait for all PEs to be here and process incoming states
   */
  comm_barrier();
  dbfs_comm_process_in_states();

  /**
   * publish local termination result
   */
  if(!context_keep_searching()) {
    term = DBFS_COMM_FORCE_TERM;
  } else if(idle && bfs_queue_is_empty(Q)) {
    term = DBFS_COMM_TERM;
  } else {
    term = DBFS_COMM_NO_TERM;
  }
  dbfs_comm_unset_term_detection_asked();
  dbfs_comm_set_term_state(term);

  /**
   * wait for all PEs to publish their result
   */
  comm_barrier();

  /**
   * termination is detected if all PEs have terminated normally
   * (i.e., local termination state == DBFS_COMM_TERM) or if a single
   * PE has terminated earlier (i.e., local termination state ==
   * DBFS_COMM_FORCE_TERM)
   */
  all_term = TRUE;
  force_term = FALSE;
  for(pe = 0; pe < PES; pe ++) {
    comm_get(&rterm, POS_TERM, sizeof(dbfs_comm_term_t), pe);
    if(DBFS_COMM_NO_TERM == rterm) {
      all_term = FALSE;
    } else if(DBFS_COMM_FORCE_TERM == rterm) {
      force_term = TRUE;
      break;
    }
  }

  /**
   * process result by updating the context
   */
  if(all_term || force_term) {
    TERM_DETECTED = TRUE;
    context_stop_search();
    if(force_term && term != DBFS_COMM_FORCE_TERM) {
      context_set_termination_state(TERM_INTERRUPTION);
    }
  }

  /**
   *  this last barrier is perhaps not useful
   */
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
    dbfs_comm_explore_cache();
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

void dbfs_comm_poll_pe
(int pe) {
  int len;
  
  if(TERM_DETECTED) {
    return;
  }
  do {
    comm_get(&len, POS_LEN(ME), sizeof(uint32_t), pe);
    if(len > 0) {
      dbfs_comm_explore_cache();
      dbfs_comm_check_communications_aux(FALSE);
      if(TERM_DETECTED) {
        return;
      }
    }
  }
  while(len > 0);
}

void dbfs_comm_send_buffer
(int pe) {
  uint32_t len, lenc = LASTC - FIRSTC[pe];
  char buffer[SINGLE_BUFFER_SIZE];

  assert(LEN[pe] + lenc <= SINGLE_BUFFER_SIZE);
  dbfs_comm_poll_pe(pe);
  if(TERM_DETECTED) {
    return;
  }
  if(CFG_DISTRIBUTED_STATE_COMPRESSION && lenc > 0) {
    memcpy(buffer, BUFC + FIRSTC[pe], lenc);
    memcpy(buffer + lenc, BUF[pe], LEN[pe]);
    len = LEN[pe] + lenc;
    comm_put(REMOTE_POS[pe], buffer, len, pe);
    comm_put(POS_LEN(ME), &len, sizeof(uint32_t), pe);
    FIRSTC[pe] = LASTC;
  } else {
    comm_put(REMOTE_POS[pe], BUF[pe], LEN[pe], pe);
    comm_put(POS_LEN(ME), &LEN[pe], sizeof(uint32_t), pe);
  }
  memset(BUF[pe], 0, LEN[pe]);
  LEN[pe] = 0;
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

bool_t dbfs_comm_process_state_aux
(htbl_meta_data_t * mdata,
 bool_t send) {
  int pe;
  uint16_t size;
  
  if(!CFG_DISTRIBUTED_STATE_COMPRESSION) {
    mdata->h = state_hash((state_t) mdata->item);
  } else {
    state_dist_compress((state_t) mdata->item, mdata->v, &size);
    mdata->v_set = TRUE;
    mdata->v_size = size;
    mdata->h = string_hash(mdata->v, size);
  }
  mdata->h_set = TRUE;
  pe = dbfs_comm_state_owner(mdata->h);
  
  /**
   *  state is mine => exit (state is processed in the bfs main
   *  procedure)
   */
  if(ME == pe) {
    return TRUE;
  }

  /**
   *  otherwise put state in the send buffer.  first send the buffer
   *  if putting the new state in the buffer would cause it to
   *  overflow
   */
  if(send) {
    if(!CFG_DISTRIBUTED_STATE_COMPRESSION) {
      size = state_char_size((state_t) mdata->item);
    }
    if(DBFS_COMM_BUFFER_OVERFLOW(pe, 1 + sizeof(uint16_t) +
                                 sizeof(hkey_t) + size)) {
      dbfs_comm_send_buffer(pe);
      if(TERM_DETECTED) {
	return FALSE;
      }
    }
    * ((char *) (BUF[pe] + LEN[pe])) = DBFS_COMM_STATE;
    LEN[pe] += 1;
    * ((uint16_t *) (BUF[pe] + LEN[pe])) = size;
    LEN[pe] += sizeof(uint16_t);
    * ((hkey_t *) (BUF[pe] + LEN[pe])) = mdata->h;
    LEN[pe] += sizeof(hkey_t);
    if(CFG_DISTRIBUTED_STATE_COMPRESSION) {
      memcpy(BUF[pe] + LEN[pe], mdata->v, size);
    } else {
      state_serialise((state_t) mdata->item, BUF[pe] + LEN[pe], &size);
    }
    LEN[pe] += size;
  }
  return FALSE;
}

bool_t dbfs_comm_process_state
(htbl_meta_data_t * mdata) {
  return dbfs_comm_process_state_aux(mdata, TRUE);
}

void dbfs_comm_put_in_comp_buffer
(char * buffer,
 int len) {
  int pe;

  if(IN_CACHE_EXPLORATION) {
    return;
  }
  
  /**
   * send all output buffers that would overflow if adding the buffer
   */
  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME && DBFS_COMM_BUFFER_OVERFLOW(pe, len)) {
      dbfs_comm_send_buffer(pe);
    }
  }

  /**
   * reallocate the compression buffer if necessary
   */
  if(LASTC + len > SIZEC) {
    SIZEC <<= 1;
    BUFC = realloc(BUFC, SIZEC);
  }

  /**
   * and copy the buffer in the compression buffer
   */
  memcpy(BUFC + LASTC, buffer, len);
  LASTC += len;
}

void dbfs_comm_receive_buffer
(int pe,
 uint32_t len,
 int pos) {
  uint32_t stored = 0;
  bool_t is_new;
  char buffer[SINGLE_BUFFER_SIZE];
  htbl_id_t sid;
  htbl_meta_data_t mdata;
  bfs_queue_item_t item;
  char * b, * b_end;
  uint16_t size;
  char t;
  
  comm_get(buffer, pos, len, ME);
  b = buffer;
  b_end = b + len;
  len = 0;
  comm_put(POS_LEN(pe), &len, sizeof(uint32_t), ME);
  while(b != b_end) {
    t = * ((char *) b);
    b ++;
    size = * ((uint16_t *) b);
    b += sizeof(uint16_t);
    switch(t) {
    case DBFS_COMM_STATE:
      htbl_meta_data_init(mdata, NULL);
      mdata.h = * ((hkey_t *) b);
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
        dbfs_comm_new_state_stored(mdata.id);
      }
      break;
    case DBFS_COMM_COMP_DATA:
      dist_compression_process_serialised_component(b);
      b += size;
      break;
    default:
      printf("unknown element type: %d\n", t);
      assert(0);
    }
  }
  context_incr_stat(STAT_STATES_STORED, 0, stored);
}

bool_t dbfs_comm_process_in_states
() {
  int pe;
  bool_t result = FALSE;
  uint32_t pos = POS_DATA;
  uint32_t len[PES];

  comm_get(len, POS_LEN(0), sizeof(uint32_t) * PES, ME);
  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME) {
      if(len[pe] > 0) {
        dbfs_comm_receive_buffer(pe, len[pe], pos);
        result = TRUE;
      }
      pos += SINGLE_BUFFER_SIZE;
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

  PES = comm_pes();
  ME = comm_me();
  SINGLE_BUFFER_SIZE = CFG_SHMEM_BUFFER_SIZE / (PES - 1);
  hs = POS_DATA + SINGLE_BUFFER_SIZE * (PES - 1);
  comm_malloc(hs);
  comm_put(POS_TERM, &term, sizeof(dbfs_comm_term_t), ME);
  Q = q;
  H = h;
  SIZEC = SINGLE_BUFFER_SIZE;
  LEN = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
  BUF = mem_alloc0(SYSTEM_HEAP, sizeof(char *) * PES);
  REMOTE_POS = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
  FIRSTC = mem_alloc0(SYSTEM_HEAP, sizeof(uint32_t) * PES);
  LASTC = 0;
  BUFC = mem_alloc0(SYSTEM_HEAP, SINGLE_BUFFER_SIZE);
  EXPL_CACHE_DATA = bwalk_data_init(CFG_DBFS_BWALK_HASH);
  len = 0;
  for(pe = 0; pe < PES; pe ++) {
    comm_put(POS_LEN(pe), &len, sizeof(uint32_t), ME);
    if(ME == pe) {
      REMOTE_POS[pe] = 0;
    } else {
      REMOTE_POS[pe] = POS_DATA + ME * SINGLE_BUFFER_SIZE;
      if(ME > pe) {
	REMOTE_POS[pe] -= SINGLE_BUFFER_SIZE;
      }
      BUF[pe] = mem_alloc0(SYSTEM_HEAP, SINGLE_BUFFER_SIZE);
    }
    FIRSTC[pe] = 0;
  }
  CW_HEAP = local_heap_new();
  DBFS_COMM_CACHE_CLEAR();
  comm_barrier();
}

void dbfs_comm_end
() {
  int pe;

  for(pe = 0; pe < PES; pe ++) {
    if(pe != ME) {
      mem_free(SYSTEM_HEAP, BUF[pe]);
    }
  }
  mem_free(SYSTEM_HEAP, LEN);
  mem_free(SYSTEM_HEAP, BUF);
  mem_free(SYSTEM_HEAP, BUFC);
  mem_free(SYSTEM_HEAP, FIRSTC);
  mem_free(SYSTEM_HEAP, REMOTE_POS);
  bwalk_data_free(EXPL_CACHE_DATA);
  heap_free(CW_HEAP);
}

#endif
