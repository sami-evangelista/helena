#include "delta_ddd.h"
#include "prop.h"
#include "graph.h"
#include "workers.h"
#include "context.h"

#if defined(CFG_ALGO_DELTA_DDD)

typedef struct {
  delta_ddd_storage_id_t fst_child;
  delta_ddd_storage_id_t next;
  bool_t father;
  bool_t dd;
  bool_t dd_visit;
  bool_t recons[2];
  event_id_t e;
#if defined(CFG_ACTION_BUILD_RG)
  uint32_t num;
#endif
} delta_ddd_state_t;

typedef struct {
  unsigned char content;
  delta_ddd_storage_id_t id;
  delta_ddd_storage_id_t pred;
  event_id_t e;
  bit_vector_t s;
  hash_key_t h;
  uint16_t width;
} delta_ddd_candidate_t;

struct struct_delta_ddd_storage_t {
  delta_ddd_storage_id_t root;
  delta_ddd_state_t ST[CFG_HASH_SIZE];
  int32_t size[CFG_NO_WORKERS];
  uint64_t dd_time;
  uint64_t barrier_time[CFG_NO_WORKERS];
};

typedef struct struct_delta_ddd_storage_t struct_delta_ddd_storage_t;

delta_ddd_storage_t S;
uint32_t next_num;

/*  mail boxes used during expansion  */
delta_ddd_candidate_t * BOX[CFG_NO_WORKERS][CFG_NO_WORKERS];
uint32_t BOX_size[CFG_NO_WORKERS][CFG_NO_WORKERS];
uint32_t BOX_tot_size[CFG_NO_WORKERS];
uint32_t BOX_max_size;

/*  candidate set (obtained from boxes after merging)  */
delta_ddd_candidate_t * CS[CFG_NO_WORKERS];
uint32_t CS_size[CFG_NO_WORKERS];
uint32_t * NCS[CFG_NO_WORKERS];
uint32_t CS_max_size;

/*  state table  */
delta_ddd_state_t * ST;

/*  heaps used to store candidates, to reconstruct states and
 *  perform duplicate detection  */
heap_t candidates_heaps[CFG_NO_WORKERS];
heap_t expand_heaps[CFG_NO_WORKERS];
heap_t detect_heaps[CFG_NO_WORKERS];
heap_t expand_evts_heaps[CFG_NO_WORKERS];
heap_t detect_evts_heaps[CFG_NO_WORKERS];

/*  random seeds  */
rseed_t seeds[CFG_NO_WORKERS];

/*  synchronisation variables  */
bool_t LVL_TERMINATED[CFG_NO_WORKERS];
pthread_barrier_t BARRIER;
uint32_t NEXT_LVL;
uint32_t NEXT_LVLS[CFG_NO_WORKERS];
bool_t error_reported;

/*  alternating bit to know which states to expand  */
uint8_t RECONS_ID;

#define EXPAND_HEAP_SIZE (1024 * 1024)
#define DETECT_HEAP_SIZE (1024 * 1024)

#define DELTA_DDD_STATS

#define DELTA_DDD_CAND_NEW  1
#define DELTA_DDD_CAND_DEL  2
#define DELTA_DDD_CAND_NONE 3

#define DELTA_DDD_OWNER(h) (((h) & CFG_HASH_SIZE_M) % CFG_NO_WORKERS)

#if defined(CFG_EVENT_UNDOABLE)
#define DELTA_DDD_VISIT_PRE_HEAP_PROCESS() {    \
    if(heap_space_left(heap) <= 81920) {	\
      state_t copy = state_copy(s);		\
      heap_reset(heap);                         \
      s = state_copy_mem(copy, heap);		\
      state_free(copy);                         \
    }						\
    heap_pos = heap_get_position(heap_evts);	\
  }
#define DELTA_DDD_VISIT_POST_HEAP_PROCESS() {   \
    heap_set_position(heap_evts, heap_pos);	\
  }
#define DELTA_DDD_VISIT_HANDLE_EVENT(func) {                    \
    e = state_enabled_event_mem(s, ST[curr].e, heap_evts);	\
    event_exec(e, s);						\
    s = func(w, curr, s, depth - 1);				\
    event_undo(e, s);						\
  }
#else  /*  !defined(CFG_EVENT_UNDOABLE)  */
#define DELTA_DDD_VISIT_PRE_HEAP_PROCESS() {    \
    heap_pos = heap_get_position(heap);         \
  }
#define DELTA_DDD_VISIT_POST_HEAP_PROCESS() {   \
    heap_set_position(heap, heap_pos);		\
  }
#define DELTA_DDD_VISIT_HANDLE_EVENT(func) {    \
    e = state_enabled_event(s, ST[curr].e);     \
    t = state_succ_mem(s, e, heap);             \
    func(w, curr, t, depth - 1);                \
  }
#endif

#define DELTA_DDD_PICK_RANDOM_NODE(w, now, start)	{       \
    unsigned int rnd;						\
    delta_ddd_storage_id_t fst = ST[now].fst_child;             \
    start = fst;						\
    rnd = random_int(&seeds[w]) % (ST[now].father >> 1);	\
    while(rnd --) {						\
      if((start = ST[start].next) == now) {			\
	start = fst;						\
      }								\
    }								\
  }

void delta_ddd_barrier
(worker_id_t w) {
  lna_timer_t t;
    
#if defined(CFG_PARALLEL)
  lna_timer_init(&t);
  lna_timer_start(&t);
  pthread_barrier_wait(&BARRIER);
  lna_timer_stop(&t);
  S->barrier_time[w] += lna_timer_value(t);
#endif
}

uint64_t delta_ddd_storage_barrier_time
(delta_ddd_storage_t storage) {
  return large_sum(storage->barrier_time, CFG_NO_WORKERS) / 1000000.0;
}

uint64_t delta_ddd_storage_dd_time
(delta_ddd_storage_t storage) {
  return storage->dd_time;
}



/*****
 *
 *  Function: delta_ddd_storage_new
 *
 *****/
delta_ddd_storage_t delta_ddd_storage_new
() {
  worker_id_t w, x;
  unsigned int i, fst, last, s;
  delta_ddd_storage_t result;

  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_delta_ddd_storage_t));
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    result->size[w] = 0;
    result->barrier_time[w] = 0;
  }

  /*
   *  initialisation of the state table
   */
  for(i = 0; i < CFG_HASH_SIZE; i ++) {
    result->ST[i].fst_child = UINT_MAX;
    result->ST[i].recons[0] = FALSE;
    result->ST[i].recons[1] = FALSE;
  }

  result->dd_time = 0;
  return result;
}

void delta_ddd_storage_free
(delta_ddd_storage_t storage) {
  worker_id_t w, x;
  unsigned int i;
  mem_free(SYSTEM_HEAP, storage);
}

uint64_t delta_ddd_storage_size
(delta_ddd_storage_t storage) {
  uint64_t result = 0;
  worker_id_t w;
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    result += storage->size[w];
  }
  return result;
}

void delta_ddd_storage_output_stats
(delta_ddd_storage_t storage,
 FILE * out) {
}



/*****
 *
 *  Function: delta_ddd_create_trace
 *
 *****/
void delta_ddd_create_trace
(delta_ddd_storage_id_t id) {
  delta_ddd_storage_id_t * trace;
  delta_ddd_storage_id_t pred, curr = id;
  state_t s = state_initial();
  unsigned int i;
  uint32_t trace_len;
  event_t * trace_evts;

  trace_len = 0;
  while(curr != S->root) {
    while(!(ST[curr].father & 1)) { curr = ST[curr].next; }
    curr = ST[curr].next;
    trace_len ++;
  }
  trace_evts = mem_alloc(SYSTEM_HEAP, sizeof(event_t) * trace_len);
  trace = mem_alloc(SYSTEM_HEAP,
                    sizeof(delta_ddd_storage_id_t) * (trace_len + 1));
  i = trace_len;
  curr = id;
  trace[i --] = curr;
  while(curr != S->root) {
    while(!(ST[curr].father & 1)) { curr = ST[curr].next; }
    curr = ST[curr].next;
    trace[i --] = curr;
  }
  for(i = 1; i <= trace_len; i ++) {
    trace_evts[i - 1] = state_enabled_event(s, ST[trace[i]].e);
    event_exec(trace_evts[i - 1], s);
  }
  state_free(s);
  free(trace);
  context_set_trace(trace_len, trace_evts);
}



/*****
 *
 *  Function: delta_ddd_send_candidate
 *
 *****/
bool_t delta_ddd_send_candidate
(worker_id_t w,
 delta_ddd_storage_id_t pred,
 event_id_t e,
 state_t s) {
  delta_ddd_candidate_t c;
  worker_id_t x;
  
  c.content = DELTA_DDD_CAND_NEW;
  c.pred = pred;
  c.e = e;
  c.width = state_char_width(s);
  c.s = mem_alloc0(candidates_heaps[w], c.width);
  state_serialise(s, c.s);
  c.h = state_hash(s);
  x = DELTA_DDD_OWNER(c.h);
  BOX[w][x][BOX_size[w][x]] = c;  
  BOX_size[w][x] ++;
  BOX_tot_size[w] ++;
  return BOX_size[w][x] == BOX_max_size;
}



/*****
 *
 *  Function: delta_ddd_merge_candidate_set
 *
 *  merge the mailboxes of workers into the candidate set before
 *  performing duplicate detection
 *
 *****/
bool_t delta_ddd_cmp_vector
(uint16_t width,
 bit_vector_t v,
 bit_vector_t w) {
  uint16_t i;
  for(i = 0; i < width; i ++) {
    if(v[i] != w[i]) {
      return FALSE;
    }
  }
  return TRUE;
}

bool_t delta_ddd_merge_candidate_set
(worker_id_t w) {
  delta_ddd_candidate_t * C = CS[w];
  unsigned int i, pos, fst, slot;
  delta_ddd_storage_id_t id;
  worker_id_t x;
  bool_t loop;

  CS_size[w] = 0;
  for(x = 0; x < CFG_NO_WORKERS; x ++) {
    for(i = 0; i < BOX_size[x][w]; i ++) {
      delta_ddd_candidate_t c = BOX[x][w][i];
      fst = pos = c.h % CS_max_size;
      loop = TRUE;
      while(loop) {
	switch(C[pos].content) {
	case DELTA_DDD_CAND_NONE :
	  C[pos] = c;
	  NCS[w][CS_size[w] ++] = pos;
	  loop = FALSE;
	  slot = C[pos].h & CFG_HASH_SIZE_M;

	  /*  mark for reconstruction states in conflict with the candidate  */
	  while(ST[slot].fst_child != UINT_MAX) {
	    ST[slot].dd = TRUE;
	    id = slot;
	    while(id != S->root) {
	      while(!(ST[id].father & 1)) {
		id = ST[id].next;
	      }
	      id = ST[id].next;
	      if(ST[id].dd_visit) {
		break;
	      } else {
		ST[id].dd_visit = TRUE;
	      }
	    }
	    slot = (slot + CFG_NO_WORKERS) & CFG_HASH_SIZE_M;
	  }
	  break;
	case DELTA_DDD_CAND_NEW :
#if defined(CFG_ACTION_BUILD_RG)
	  pos = (pos + 1) % CS_max_size;
	  assert (pos != fst);
#else
	  if(c.h == C[pos].h
             && c.width == C[pos].width
             && delta_ddd_cmp_vector(c.width, c.s, C[pos].s)) {
	    loop = FALSE;
	  } else {
	    pos = (pos + 1) % CS_max_size;
	    assert (pos != fst);
	  }
#endif
	  break;
	case DELTA_DDD_CAND_DEL :
	  assert(FALSE);
	}
      }
    }
  }
}



/*****
 *
 *  Function: delta_ddd_duplicate_detection_dfs
 *
 *****/
void delta_ddd_storage_delete_candidate
(worker_id_t w,
 state_t s,
 delta_ddd_storage_id_t id) {
  hash_key_t h = state_hash(s);
  unsigned int fst, i = h % CS_max_size;
  worker_id_t x = DELTA_DDD_OWNER(h);
  
  fst = i;
  do {
    switch(CS[x][i].content) {
    case DELTA_DDD_CAND_NONE : return;
    case DELTA_DDD_CAND_NEW  :
      if(state_cmp_vector(s, CS[x][i].s)) {
	CS[x][i].content = DELTA_DDD_CAND_DEL;
#if defined(CFG_ACTION_BUILD_RG)
	CS[x][i].id = id;
	break;
#else
	return;
#endif
      }
    }
    i = (i + 1) % CS_max_size;
  } while(fst != i);
}

state_t delta_ddd_duplicate_detection_dfs
(worker_id_t w,
 delta_ddd_storage_id_t now,
 state_t s,
 unsigned int depth) {
  heap_t heap = detect_heaps[w];
  heap_t heap_evts = detect_evts_heaps[w];
  state_t t;
  event_t e;
  void * heap_pos;
  delta_ddd_storage_id_t start, curr;

  DELTA_DDD_VISIT_PRE_HEAP_PROCESS();

  /*
   *  remove state now from the candidate set
   */
  if(ST[now].dd) {
    ST[now].dd = FALSE;
    delta_ddd_storage_delete_candidate(w, s, now);
  }

  /*
   *  state now must be visited by the duplicate detection procedure
   */
  if(ST[now].dd_visit) {
    
    /*
     *  we start expanding now from a randomly picked successor
     */
    DELTA_DDD_PICK_RANDOM_NODE(w, now, start);
    curr = start;
    do {
      if(ST[curr].dd || ST[curr].dd_visit) {
        context_incr_evts_exec(w, 1);
        context_incr_evts_exec_dd(w, 1);
	DELTA_DDD_VISIT_HANDLE_EVENT(delta_ddd_duplicate_detection_dfs);
      }
      if(ST[curr].father & 1) {
	curr = ST[ST[curr].next].fst_child;
      } else {
	curr = ST[curr].next;
      }
    } while(curr != start);
  }
  ST[now].dd = FALSE;
  ST[now].dd_visit = FALSE;
  DELTA_DDD_VISIT_POST_HEAP_PROCESS();
  return s;
}


#if defined(CFG_ACTION_BUILD_RG)
void delta_ddd_remove_duplicates_around
(delta_ddd_candidate_t * C,
 unsigned int i) {
  int j, k, m, moves[2] = { 1, -1};
  for(k = 0; k < 2; k ++) {
    j = i;
    m = moves[k];
    while(TRUE) {
      j += m;
      if(j == -1) { j = CS_max_size - 1; }
      if(j == CS_max_size) { j = 0; }
      if(C[j].content == DELTA_DDD_CAND_NONE) { break; }
      if(C[j].width == C[i].width
         && delta_ddd_cmp_vector(C[j].width, C[j].s, C[i].s)) {
	C[j].content = DELTA_DDD_CAND_DEL;
	C[j].id = C[i].id;
      }
    }
  }
}

void delta_ddd_write_nodes_graph
(worker_id_t w) {
  delta_ddd_candidate_t * C = CS[w];
  unsigned int i = 0;
  uint8_t t, succs = 0;
  FILE * gf = context_graph_file();
  for(i = 0; i < CS_max_size; i ++) {
    if(DELTA_DDD_CAND_NEW == C[i].content) {
      t = GT_NODE;
      fwrite(&t, sizeof(uint8_t), 1, gf);
      fwrite(&ST[C[i].id].num, sizeof(node_t), 1, gf);
      fwrite(&succs, sizeof(uint8_t), 1, gf);
    }
  }
  for(i = 0; i < CS_max_size; i ++) {
    if(DELTA_DDD_CAND_NONE != C[i].content) {
      t = GT_EDGE;
      fwrite(&t, sizeof(uint8_t), 1, gf);
      fwrite(&ST[C[i].pred].num, sizeof(node_t), 1, gf);
      fwrite(&C[i].e, sizeof(edge_num_t), 1, gf);
      fwrite(&ST[C[i].id].num, sizeof(node_t), 1, gf);
    }
  }
}
#endif



/*****
 *
 *  Function: delta_ddd_insert_new_states
 *
 *  insert in the state tree states that are still in the candidate
 *  set after duplicate detection
 *
 *****/
delta_ddd_storage_id_t delta_ddd_insert_new_state
(worker_id_t w,
 hash_key_t h,
 delta_ddd_state_t s,
 delta_ddd_storage_id_t pred) {
  uint8_t r = (RECONS_ID + 1) & 1;
  unsigned int id, fst = h & CFG_HASH_SIZE_M, slot = fst;
  while(ST[slot].fst_child != UINT_MAX) {
    assert((slot = (slot + CFG_NO_WORKERS) & CFG_HASH_SIZE_M) != fst);
  }
  s.next = s.fst_child = slot;
#if defined(CFG_ACTION_BUILD_RG)
  s.num = next_num ++;
#endif
  ST[slot] = s;

  /*  mark the state for the next expansion step  */
  do {
    ST[pred].recons[r] = TRUE;
    while(!(ST[pred].father & 1)) {
      pred = ST[pred].next;
    }
    pred = ST[pred].next;
  } while(pred != S->root && !ST[pred].recons[r]);
  return slot;
}

void delta_ddd_insert_new_states
(worker_id_t w) {
  worker_id_t x;
  unsigned int i = 0;
  delta_ddd_candidate_t c, * C = CS[w];
  delta_ddd_state_t ns;
  unsigned int no_new = 0;

  ns.dd = ns.dd_visit = ns.recons[RECONS_ID] = FALSE;
  ns.recons[(RECONS_ID + 1) & 1] = TRUE;
  for(i = 0; i < CS_size[w]; i ++) {
    c = C[NCS[w][i]];
    if(DELTA_DDD_CAND_NEW == c.content) {
      no_new ++;
      ns.e = c.e;
      ns.father = 0;
      C[NCS[w][i]].id = delta_ddd_insert_new_state(w, c.h, ns, c.pred);
#if defined(CFG_ACTION_BUILD_RG)
      delta_ddd_remove_duplicates_around(C, NCS[w][i]);
#endif
    }
  }
  S->size[w] += no_new;
  NEXT_LVLS[w] += no_new;
#if defined(CFG_ACTION_BUILD_RG)
  delta_ddd_write_nodes_graph(w);
#endif

  delta_ddd_barrier(w);

  if(0 == w) {
    for(x = 0; x < CFG_NO_WORKERS; x ++) {
      for(i = 0; i < CS_size[x]; i ++) {
	c = CS[x][NCS[x][i]];
	if(DELTA_DDD_CAND_NEW == c.content) {
	  if(ST[c.pred].fst_child == c.pred) {
	    ST[c.id].next = c.pred;
	    ST[c.id].father += 1;
	  } else {
	    ST[c.id].next = ST[c.pred].fst_child;
	  }
	  ST[c.pred].fst_child = c.id;
	  ST[c.pred].father += 2;
	}
	CS[x][NCS[x][i]].content = DELTA_DDD_CAND_NONE;
      }
    }
  }
}



/*****
 *
 *  Function: delta_ddd_duplicate_detection
 *
 *****/
bool_t delta_ddd_duplicate_detection
(worker_id_t w) {
  state_t s;
  worker_id_t x;
  bool_t all_terminated = TRUE;
  lna_timer_t t;

  if(0 == w) {
    lna_timer_init(&t);
    lna_timer_start(&t);
  }

  /*
   *  initialize heaps for duplicate detection
   */
#if defined(CFG_EVENT_UNDOABLE)
  heap_reset(detect_evts_heaps[w]);
#endif
  heap_reset(detect_heaps[w]);
  s = state_initial_mem(detect_heaps[w]);

  /*
   *  merge the candidate set and mark states to reconstruct
   */
  delta_ddd_barrier(w);
  if(delta_ddd_storage_size(S) >= 0.9 * CFG_HASH_SIZE) {
    raise_error("state table too small (increase --hash-size and rerun)");
  }
  if(!context_keep_searching()) {
    pthread_exit(NULL);
  }
  delta_ddd_merge_candidate_set(w);

  /*
   *  reconstruct states and perform duplicate detection
   */
  delta_ddd_barrier(w);
  delta_ddd_duplicate_detection_dfs(w, S->root, s, 0);

  /*
   *  insert these new states in the tree
   */
  delta_ddd_barrier(w);
  delta_ddd_insert_new_states(w);

  /*
   *  reinitialise my mail boxes and candidate heaps
   */
  heap_reset(candidates_heaps[w]);
  BOX_tot_size[w] = 0;
  for(x = 0; x < CFG_NO_WORKERS; x ++) {
    BOX_size[w][x] = 0;
    all_terminated = all_terminated && LVL_TERMINATED[x];
  }
  if(0 == w) {
    lna_timer_stop(&t);
    S->dd_time += lna_timer_value(t);
  }
  delta_ddd_barrier(w);
  return all_terminated ? FALSE : TRUE;
}



/*****
 *
 *  Function: delta_ddd_expand_dfs
 *
 *  recursive function called by delta_ddd_expand to explore state now
 *
 *****/
state_t delta_ddd_expand_dfs
(worker_id_t w,
 delta_ddd_storage_id_t now,
 state_t s,
 unsigned int depth) {
  heap_t heap = expand_heaps[w];
  heap_t heap_evts = expand_evts_heaps[w];
  void * heap_pos;
  delta_ddd_storage_id_t start, curr;
  state_t t;
  event_t e;
  event_id_t e_id;
  event_list_t en;
  unsigned int en_size, i;
  worker_id_t x, y;
  uint32_t size;

  DELTA_DDD_VISIT_PRE_HEAP_PROCESS();

  if(0 == depth) {
    
    /*
     *  we have reached a leaf => we expand it
     */
    en = state_enabled_events_mem(s, heap);
#if defined(CFG_ACTION_CHECK_SAFETY)
    if(state_check_property(s, en)) {
      if(!error_reported) {
	error_reported = TRUE;
	context_faulty_state(s);
	delta_ddd_create_trace(now);
      }
    }
#endif
    en_size = event_list_size(en);
    if(0 == en_size) {
      context_incr_dead(w, 1);
    }
    for(i = 0; i < en_size; i ++) {
      e = event_set_nth(en, i);
      e_id = event_set_nth_id(en, i);
      t = state_succ_mem(s, e, heap);
      if(delta_ddd_send_candidate(w, now, e_id, t)) {
	delta_ddd_duplicate_detection(w);
      }
    }
    context_incr_arcs(w, en_size);
    context_incr_evts_exec(w, en_size);
    context_incr_visited(w, 1);

    /*
     *  perform duplicate detection if the candidate set is full
     */
    size = 0;
    for(x = 0; x < CFG_NO_WORKERS; x ++) {
      size += BOX_tot_size[x];
    }
    if(size >= CFG_DELTA_DDD_CAND_SET_SIZE) {
      delta_ddd_duplicate_detection(w);
    }
  } else {

    /*
     *  we start expanding now from a randomly picked successor
     */
    DELTA_DDD_PICK_RANDOM_NODE(w, now, start);
    curr = start;
    do {
      if(ST[curr].recons[RECONS_ID]) {
        context_incr_evts_exec(w, 1);
	DELTA_DDD_VISIT_HANDLE_EVENT(delta_ddd_expand_dfs);
      }
      if(ST[curr].father & 1) {
	curr = ST[ST[curr].next].fst_child;
      } else {
	curr = ST[curr].next;
      }
    } while(curr != start);
  }

  ST[now].recons[RECONS_ID] = FALSE;
  DELTA_DDD_VISIT_POST_HEAP_PROCESS();
  return s;
}



/*****
 *
 *  Function: delta_ddd_expand
 *
 *****/
void delta_ddd_expand
(worker_id_t w,
 unsigned int depth) {
  state_t s;

#if defined(CFG_EVENT_UNDOABLE)
  heap_reset(expand_evts_heaps[w]);
#endif
  heap_reset(expand_heaps[w]);
  s = state_initial_mem(expand_heaps[w]);
  delta_ddd_expand_dfs(w, S->root, s, depth);
  LVL_TERMINATED[w] = TRUE;
  while(delta_ddd_duplicate_detection(w));
}



/*****
 *
 *  Function: delta_ddd_worker
 *
 *****/
void * delta_ddd_worker
(void * arg) {
  worker_id_t x, w = (worker_id_t) (unsigned long int) arg;
  unsigned int depth = 0;
  FILE * gf;
  
  if(0 == w) {
    delta_ddd_state_t ns;
    state_t s = state_initial();
    hash_key_t h = state_hash(s);
    delta_ddd_storage_id_t slot = h & CFG_HASH_SIZE_M;
    uint8_t t = GT_NODE, succs = 0;
    ns.dd = ns.dd_visit = ns.recons[0] = FALSE;
    ns.recons[1] = ns.father = 1;
    ns.next = ns.fst_child = slot;
#if defined(CFG_ACTION_BUILD_RG)
    gf = context_graph_file();
    ns.num = next_num ++;
    fwrite(&t, sizeof(uint8_t), 1, gf);
    fwrite(&ns.num, sizeof(node_t), 1, gf);
    fwrite(&succs, sizeof(uint8_t), 1, gf);
#endif
    ST[slot] = ns;
    S->root = slot;
    S->size[0] = 1;
    state_free(s);
    RECONS_ID = 0;
    NEXT_LVL = 1;
  }
  delta_ddd_barrier(w);
  while(NEXT_LVL != 0) {

    /*
     *  initialise some data for the next level
     */
    delta_ddd_barrier(w);
    LVL_TERMINATED[w] = FALSE;
    NEXT_LVLS[w] = 0;
    if(0 == w) {
      NEXT_LVL = 0;
      RECONS_ID = (RECONS_ID + 1) & 1;
    }

    /*
     *  all workers expand the current level
     */
    delta_ddd_barrier(w);
    delta_ddd_expand(w, depth);
    depth ++;
    if(0 == w) {
      for(x = 0; x < CFG_NO_WORKERS; x ++) {
	NEXT_LVL += NEXT_LVLS[x];
      }
      context_update_bfs_levels(depth);
    }
    delta_ddd_barrier(w);
  }
  return NULL;
}



/*****
 *
 *  Function: delta_ddd
 *
 *****/
void delta_ddd
() {  
  worker_id_t w, x;
  void * dummy;
  unsigned int i, s;
  FILE * gf;

  S = (delta_ddd_storage_t) context_storage();
  ST = S->ST;
  pthread_barrier_init(&BARRIER, NULL, CFG_NO_WORKERS);
  error_reported = FALSE;
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    seeds[w] = random_seed(w);
  }
  next_num = 0;
  gf = context_open_graph_file();

  /*
   *  initialisation of the heaps
   */
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    expand_heaps[w] =
      bounded_heap_new("reconstruction", EXPAND_HEAP_SIZE);
    detect_heaps[w] =
      bounded_heap_new("duplicate detection", DETECT_HEAP_SIZE);
    candidates_heaps[w] =
      evergrowing_heap_new("candidate set", 1024 * 1024);
#if defined(CFG_EVENT_UNDOABLE)
    expand_evts_heaps[w] =
      bounded_heap_new("reconstruction events", EXPAND_HEAP_SIZE);
    detect_evts_heaps[w] =
      bounded_heap_new("duplicate detection events", DETECT_HEAP_SIZE);
#endif
  }

  /*
   *  initialisation of the mailboxes of workers
   */
  BOX_max_size = (CFG_DELTA_DDD_CAND_SET_SIZE /
                  (CFG_NO_WORKERS * CFG_NO_WORKERS)) << 2;
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    for(x = 0; x < CFG_NO_WORKERS; x ++) {
      s = BOX_max_size * sizeof(delta_ddd_candidate_t);
      BOX[w][x] = mem_alloc(SYSTEM_HEAP, s);
      for(i = 0; i < BOX_max_size; i ++) {
	BOX[w][x][i].content = DELTA_DDD_CAND_NONE;
	BOX[w][x][i].h = 0;
	BOX_size[w][x] = 0;
      }
    }
    BOX_tot_size[w] = 0;
  }

  /*
   *  initialisation of the candidate set
   */
  CS_max_size = (CFG_DELTA_DDD_CAND_SET_SIZE / CFG_NO_WORKERS) << 1;
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    CS[w] = mem_alloc(SYSTEM_HEAP, CS_max_size *
                      sizeof(delta_ddd_candidate_t));
    NCS[w] = mem_alloc(SYSTEM_HEAP, CS_max_size * sizeof(uint32_t));
    for(i = 0; i < CS_max_size; i ++) {
      CS[w][i].content = DELTA_DDD_CAND_NONE;
    }
    CS_size[w] = 0;
  }

  launch_and_wait_workers(&delta_ddd_worker);

  /*
   *  free heaps and mailboxes
   */
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    for(x = 0; x < CFG_NO_WORKERS; x ++) {
      mem_free(SYSTEM_HEAP, BOX[w][x]);
    }
    heap_free(candidates_heaps[w]);
    heap_free(expand_heaps[w]);
    heap_free(detect_heaps[w]);
#if defined(CFG_EVENT_UNDOABLE)
    heap_free(expand_evts_heaps[w]);
    heap_free(detect_evts_heaps[w]);
#endif
  }
  context_close_graph_file();
}

#endif  /*  defined(CFG_ALGO_DELTA_DDD)  */
