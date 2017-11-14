#include "config.h"
#include "hash_tbl.h"
#include "context.h"
#include "bit_stream.h"

#define ATTR_ID(a) (1 << a)

#define NO_ATTRS 9

#define ATTR_CYAN_WIDTH     1
#define ATTR_BLUE_WIDTH     1
#define ATTR_PINK_WIDTH     1
#define ATTR_RED_WIDTH      1
#define ATTR_PRED_WIDTH     (CHAR_BIT * sizeof(hash_tbl_id_t))
#define ATTR_EVT_WIDTH      (CHAR_BIT * sizeof(mevent_id_t))
#define ATTR_INDEX_WIDTH    32
#define ATTR_LOWLINK_WIDTH  32
#define ATTR_LIVE_WIDTH     1

const uint16_t ATTR_WIDTH[] = {
  ATTR_CYAN_WIDTH,
  ATTR_BLUE_WIDTH,
  ATTR_PINK_WIDTH,
  ATTR_RED_WIDTH,
  ATTR_PRED_WIDTH,
  ATTR_EVT_WIDTH,
  ATTR_INDEX_WIDTH,
  ATTR_LOWLINK_WIDTH,
  ATTR_LIVE_WIDTH
};

const bool_t ATTR_OF_WORKER[] = {
  1,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  0
};

#define BUCKET_EMPTY 1
#define BUCKET_READY 2
#define BUCKET_WRITE 3

#define MAX_TRIALS 10000

typedef uint8_t bucket_status_t;

struct struct_hash_tbl_t {
  bool_t hash_compaction;
  uint32_t attrs;
  uint32_t attrs_char_size;
  uint32_t attr_pos[NO_ATTRS];
  uint16_t no_workers;
  uint64_t hash_size;
  pthread_barrier_t barrier;
  heap_t heap;
  int64_t * size;
  hash_key_t * hash;
  bucket_status_t * update_status;
  bucket_status_t * status;
  bit_vector_t hc_attrs;
  bit_vector_t * state;
  uint16_t * state_len;
};
typedef struct struct_hash_tbl_t struct_hash_tbl_t;

const struct timespec SLEEP_TIME = { 0, 10 };

#define BIT_STREAM_INIT_ON_ATTRS(tbl, id, bits) {                       \
    if(tbl->hash_compaction) {                                          \
      bit_stream_init(bits, tbl->hc_attrs + id * tbl->attrs_char_size); \
    } else {                                                            \
      bit_stream_init(bits, tbl->state[id]);                            \
    }                                                                   \
  }

hash_tbl_t hash_tbl_new
(bool_t use_system_heap,
 uint64_t hash_size,
 uint16_t no_workers,
 bool_t hash_compaction,
 uint32_t attrs) {
  const heap_t heap = SYSTEM_HEAP;
  uint64_t i;
  hash_tbl_t result;
  worker_id_t w;
  uint32_t pos = 0, width;
  
  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_hash_tbl_t));
  result->hash_compaction = hash_compaction;
  result->attrs = attrs;
  for(i = 0; i < NO_ATTRS; i ++) {
    if(hash_tbl_has_attr(result, i)) {
      width = ATTR_WIDTH[i];
      if(ATTR_OF_WORKER[i]) {
        width *= no_workers;
      }
      result->attr_pos[i] = pos;
      pos += width;
    }
  }
  result->attrs_char_size = pos / 8;
  if(pos % 8 != 0) {
    result->attrs_char_size ++;
  }  
  result->heap = use_system_heap ? SYSTEM_HEAP : local_heap_new();
  result->no_workers = no_workers;
  result->hash_size = hash_size;
  result->size = mem_alloc(heap, no_workers * sizeof(uint64_t));
  result->hash = mem_alloc(heap, hash_size * sizeof(hash_key_t));
  result->status = mem_alloc(heap, hash_size * sizeof(bucket_status_t));
  result->update_status = mem_alloc(heap, hash_size * sizeof(bucket_status_t));
  if(hash_compaction) {
    result->hc_attrs = mem_alloc(heap, hash_size * result->attrs_char_size);
    memset(result->hc_attrs, 0, hash_size * result->attrs_char_size);
  } else {
    result->state = mem_alloc(heap, hash_size * sizeof(bit_vector_t));
    result->state_len = mem_alloc(heap, hash_size * sizeof(uint16_t));
  }
  for(w = 0; w < result->no_workers; w ++) {
    result->size[w] = 0;
  }
  for(i = 0; i < result->hash_size; i++) {
    result->update_status[i] = BUCKET_READY;
    result->status[i] = BUCKET_EMPTY;
    if(!hash_compaction) {
      result->state[i] = NULL;
      result->state_len[i] = 0;
    }
  }
  pthread_barrier_init(&result->barrier, NULL, no_workers);
  return result;

}

hash_tbl_t hash_tbl_default_new
() {
  uint32_t attrs = 0;
  uint16_t no_workers;

  /**
   *  check which attributes are enabled according to the
   *  configuration
   */
  attrs |= ATTR_ID(ATTR_CYAN);
  attrs |= ATTR_ID(ATTR_BLUE);
  if(CFG_ACTION_CHECK_LTL) {
    attrs |= ATTR_ID(ATTR_PINK);
    attrs |= ATTR_ID(ATTR_RED);
  }
  if(CFG_ALGO_BFS) {
    attrs |= ATTR_ID(ATTR_PRED);
    attrs |= ATTR_ID(ATTR_EVT);
  }
  if(CFG_ALGO_TARJAN) {
    attrs |= ATTR_ID(ATTR_INDEX);
    attrs |= ATTR_ID(ATTR_LOWLINK);
    attrs |= ATTR_ID(ATTR_LIVE);
  }
  
  no_workers = CFG_NO_WORKERS;
  if(CFG_DISTRIBUTED) {
    no_workers += CFG_NO_COMM_WORKERS;
  }
  return hash_tbl_new(FALSE, CFG_HASH_SIZE, no_workers,
                      CFG_HASH_COMPACTION, attrs);
}

void hash_tbl_free
(hash_tbl_t tbl) {
  uint64_t i = 0;
  worker_id_t w;

  if(tbl->hash_compaction) {
    mem_free(SYSTEM_HEAP, tbl->hc_attrs);
  } else {
    for(i = 0; i < tbl->hash_size; i++) {
      if(tbl->state[i]) {
        mem_free(tbl->heap, tbl->state[i]);
      }
    }
    mem_free(SYSTEM_HEAP, tbl->state);
    mem_free(SYSTEM_HEAP, tbl->state_len);
  }
  mem_free(SYSTEM_HEAP, tbl->size);
  mem_free(SYSTEM_HEAP, tbl->hash);
  mem_free(SYSTEM_HEAP, tbl->status);
  mem_free(SYSTEM_HEAP, tbl->update_status);
  if(tbl->heap) {
    heap_free(tbl->heap);
  }
  mem_free(SYSTEM_HEAP, tbl);
}

void hash_tbl_reset
(hash_tbl_t tbl) {
  heap_reset(tbl->heap);
}

uint64_t hash_tbl_size
(hash_tbl_t tbl) {
  uint64_t result = 0;
  worker_id_t w;
  
  for(w = 0; w < tbl->no_workers; w ++) {
    result += tbl->size[w];
  }
  return result;
}

void hash_tbl_insert_real
(hash_tbl_t tbl,
 state_t * s,
 worker_id_t w,
 bit_vector_t se,
 uint16_t se_char_len,
 bool_t * is_new,
 hash_tbl_id_t * id,
 hash_key_t * h,
 bool_t h_set) {
  uint32_t trials = 0;
  bit_stream_t bits;
  hash_tbl_id_t pos, del_pos;
  bit_vector_t se_other;
  bool_t found;

  /**
   *  compute the hash value
   */
  if(tbl->hash_compaction) {
    if(NULL == se && !h_set) {
      (*h) = state_hash(*s);
    }
  } else {
    if(!h_set) {
      (*h) = state_hash(*s);
    }
  }
  pos = (*h) % tbl->hash_size;

  while(TRUE) {
      
    /**
     *  we found a bucket where to insert the state => claim it
     */
    if(CAS(&tbl->status[pos], BUCKET_EMPTY, BUCKET_WRITE)) {

      /**
       *  state insertion
       */
      if(!tbl->hash_compaction) {
        if(NULL == se) {
          se_char_len = state_char_size(*s);
        }
        tbl->state[pos] = mem_alloc0(tbl->heap,
                                     se_char_len + tbl->attrs_char_size);
        if(NULL == se) {
          state_serialise(*s, tbl->state[pos] + tbl->attrs_char_size);
        } else {
          memcpy(tbl->state[pos] + tbl->attrs_char_size, se, se_char_len);
        }
        tbl->state_len[pos] = se_char_len;
      }
      tbl->hash[pos] = *h;
      tbl->status[pos] = BUCKET_READY;
      tbl->size[w] ++;
      (*is_new) = TRUE;
      (*id) = pos;
      return;
    }
    
    /**
     *  wait for the bucket to be readable
     */
    while(BUCKET_WRITE == tbl->status[pos]) {
      context_sleep(SLEEP_TIME);
    }

    /**
     *  the bucket is occupied and readable => compare the state in
     *  the bucket to the state to insert
     */
    if(tbl->status[pos] == BUCKET_READY) {
      found = (tbl->hash[pos] == (*h));
      if(found && !tbl->hash_compaction) {
        se_other = tbl->state[pos] + tbl->attrs_char_size;
        if(NULL == se) {
          found = state_cmp_vector(*s, se_other);
        } else {
          found = 0 == memcmp(se, se_other, se_char_len);
        }
      }
      if(found) {
        (*is_new) = FALSE;
        (*id) = pos;
        return;
      }
    }

    /**
     *  give up if MAX_TRIALS buckets have been checked
     */
    if((++ trials) == MAX_TRIALS) {
      raise_error("state table too small (increase --hash-size and rerun)");
      (*is_new) = FALSE;
      return;
    }
    pos = (pos + 1) % tbl->hash_size;
  }
}

void hash_tbl_insert
(hash_tbl_t tbl,
 state_t s,
 worker_id_t w,
 bool_t * is_new,
 hash_tbl_id_t * id,
 hash_key_t * h) {
  hash_tbl_insert_real(tbl, &s, w, NULL, 0, is_new, id, h, FALSE);
}

void hash_tbl_insert_hashed
(hash_tbl_t tbl,
 state_t s,
 worker_id_t w,
 hash_key_t h,
 bool_t * is_new,
 hash_tbl_id_t * id) {
  hash_tbl_insert_real(tbl, &s, w, NULL, 0, is_new, id, &h, TRUE);
}

void hash_tbl_insert_serialised
(hash_tbl_t tbl,
 bit_vector_t s,
 uint16_t s_char_len,
 hash_key_t h,
 worker_id_t w,
 bool_t * is_new,
 hash_tbl_id_t * id) {
  hash_tbl_insert_real(tbl, NULL, w, s, s_char_len, is_new, id, &h, TRUE);
}

state_t hash_tbl_get
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w) {
  return hash_tbl_get_mem(tbl, id, w, SYSTEM_HEAP);
}

state_t hash_tbl_get_mem
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 heap_t heap) {
  state_t result;

  assert(!tbl->hash_compaction);
  result = state_unserialise_mem(tbl->state[id] + tbl->attrs_char_size, heap);
  return result;
}

hash_key_t hash_tbl_get_hash
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  return tbl->hash[id];
}

bool_t hash_tbl_has_attr
(hash_tbl_t tbl,
 uint32_t attr) {
  return (tbl->attrs & ATTR_ID(attr)) ? TRUE : FALSE;
}

#define HASH_TBL_GET_ATTR(shift) {                                      \
    const uint32_t pos = tbl->attr_pos[attr];                           \
    const uint32_t width = ATTR_WIDTH[attr];                            \
    uint64_t result;                                                    \
    bit_stream_t bits;                                                  \
                                                                        \
    BIT_STREAM_INIT_ON_ATTRS(tbl, id, bits);                            \
    bit_stream_move(bits, pos + shift);                                 \
    bit_stream_get(bits, result, width);                                \
    return result;                                                      \
}

uint64_t hash_tbl_get_attr
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 uint32_t attr) {
  assert(hash_tbl_has_attr(tbl, attr));
  HASH_TBL_GET_ATTR(0);
}

uint64_t hash_tbl_get_worker_attr
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 uint32_t attr,
 worker_id_t w) {
  assert(hash_tbl_has_attr(tbl, attr));
  HASH_TBL_GET_ATTR(w);
}

#define HASH_TBL_SET_ATTR(shift) {                                      \
    const uint32_t pos = tbl->attr_pos[attr];                           \
    const uint32_t width = ATTR_WIDTH[attr];                            \
    bit_stream_t bits;                                                  \
                                                                        \
    BIT_STREAM_INIT_ON_ATTRS(tbl, id, bits);                            \
    bit_stream_move(bits, pos + shift);                                 \
    if(tbl->no_workers > 0) {                                           \
      while(!CAS(&tbl->update_status[id], BUCKET_READY, BUCKET_WRITE)) { \
        context_sleep(SLEEP_TIME);                                      \
      }                                                                 \
    }                                                                   \
    bit_stream_set(bits, val, width);                                   \
    tbl->update_status[id] = BUCKET_READY;                              \
  }

void hash_tbl_set_attr
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 uint32_t attr,
 uint64_t val) {
  assert(hash_tbl_has_attr(tbl, attr));
  HASH_TBL_SET_ATTR(0);
}

void hash_tbl_set_worker_attr
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 uint32_t attr,
 worker_id_t w,
 uint64_t val) {
  assert(hash_tbl_has_attr(tbl, attr));
  HASH_TBL_SET_ATTR(w);
}

bool_t hash_tbl_get_any_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  worker_id_t w;
  
  for(w = 0; w < tbl->no_workers; w ++) {
    if(hash_tbl_get_worker_attr(tbl, id, ATTR_CYAN, w)) {
      return TRUE;
    }
  }
  return FALSE;
}

void hash_tbl_erase
(hash_tbl_t tbl,
 worker_id_t w,
 hash_tbl_id_t id) {
  if(tbl->hash_compaction) {
    memset(tbl->hc_attrs + id * tbl->attrs_char_size, 0, tbl->attrs_char_size);
  } else {
    mem_free(tbl->heap, tbl->state[id]);
    tbl->state[id] = NULL;
  }
  tbl->status[id] = BUCKET_EMPTY;
  tbl->update_status[id] = BUCKET_READY;
  tbl->size[w] --;
}

void hash_tbl_get_serialised
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bit_vector_t * s,
 uint16_t * size,
 hash_key_t * h) {
  assert(!tbl->hash_compaction);
  (*s) = tbl->state[id] + tbl->attrs_char_size;
  (*size) = tbl->state_len[id];
  (*h) = tbl->hash[id];
}

void hash_tbl_fold
(hash_tbl_t tbl,
 hash_tbl_fold_func_t f,
 void * data) {
  state_t s;
  uint64_t pos;
  heap_t h = local_heap_new();
  
  for(pos = 0; pos < tbl->hash_size; pos ++) {
    if(tbl->status[pos] == BUCKET_READY) {
      s = state_unserialise_mem(tbl->state[pos] + tbl->attrs_char_size, h);
      f(s, pos, data);
      state_free(s);
      heap_reset(h);
    }
  }
  heap_free(h);
}

list_t hash_tbl_get_trace
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  hash_tbl_id_t id_pred;
  mevent_id_t evt;
  list_t result = list_new(SYSTEM_HEAP, sizeof(mevent_id_t), NULL);

  assert(hash_tbl_has_attr(tbl, ATTR_PRED));
  while(id != (id_pred = hash_tbl_get_attr(tbl, id, ATTR_PRED))) {
    evt = hash_tbl_get_attr(tbl, id, ATTR_EVT);
    list_prepend(result, &evt);
    id = id_pred;
  }
  return result;
}
