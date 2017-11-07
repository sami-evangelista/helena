#include "config.h"
#include "hash_tbl.h"
#include "context.h"
#include "bit_stream.h"

#define ATTR_CYAN_POS(tbl)     (tbl->attr_pos[0])
#define ATTR_BLUE_POS(tbl)     (tbl->attr_pos[1])
#define ATTR_PINK_POS(tbl)     (tbl->attr_pos[2])
#define ATTR_RED_POS(tbl)      (tbl->attr_pos[3])
#define ATTR_PRED_POS(tbl)     (tbl->attr_pos[4])
#define ATTR_EVT_POS(tbl)      (tbl->attr_pos[5])

#define ATTR_CYAN_WIDTH 1
#define ATTR_BLUE_WIDTH 1
#define ATTR_PINK_WIDTH 1
#define ATTR_RED_WIDTH  1
#define ATTR_PRED_WIDTH (CHAR_BIT * sizeof(hash_tbl_id_t))
#define ATTR_EVT_WIDTH  (CHAR_BIT * sizeof(mevent_id_t))

#define NO_ATTRS 6

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
  rseed_t * seeds;
  hash_key_t * hash;
  bucket_status_t * update_status;
  bucket_status_t * status;
  bit_vector_t hc_attrs;
  bit_vector_t * state;
  uint16_t * state_len;
  bool_t * done;
};
typedef struct struct_hash_tbl_t struct_hash_tbl_t;

#define BUCKET_EMPTY 1
#define BUCKET_READY 2
#define BUCKET_WRITE 3
#define BUCKET_DEL   4

#define MAX_TRIALS 10000

const struct timespec SLEEP_TIME = { 0, 10 };

#define BIT_STREAM_INIT_ON_ATTRS(tbl, id, bits) {                       \
    if(tbl->hash_compaction) {                                          \
      bit_stream_init(bits, tbl->hc_attrs + id * tbl->attrs_char_size); \
    } else {                                                            \
      bit_stream_init(bits, tbl->state[id]);                            \
    }                                                                   \
  }

hash_tbl_t hash_tbl_new
(uint64_t hash_size,
 uint16_t no_workers,
 bool_t hash_compaction,
 uint32_t attrs) {
  const heap_t heap = SYSTEM_HEAP;
  const uint32_t attrs_width[NO_ATTRS] = { ATTR_CYAN_WIDTH * no_workers,
                                           ATTR_BLUE_WIDTH,
                                           ATTR_PINK_WIDTH * no_workers,
                                           ATTR_RED_WIDTH,
                                           ATTR_PRED_WIDTH,
                                           ATTR_EVT_WIDTH };
  uint32_t attrs_bit_size = 0;
  uint64_t i;
  hash_tbl_t result;
  worker_id_t w;
  uint32_t pos = 0;
  
  result = mem_alloc(heap, sizeof(struct_hash_tbl_t));
  result->hash_compaction = hash_compaction;
  result->attrs = attrs;
  for(i = 0; i < NO_ATTRS; i ++) {
    if(hash_tbl_has_attr(result, 1 << i)) {
      attrs_bit_size += attrs_width[i];
      result->attr_pos[i] = pos;
      pos += attrs_width[i];
    }
  }
  result->attrs_char_size = pos / 8;
  if(pos % 8 != 0) {
    result->attrs_char_size ++;
  }
  result->no_workers = no_workers;
  result->hash_size = hash_size;
  result->heap = heap;
  result->size = mem_alloc(heap, no_workers * sizeof(uint64_t));
  result->seeds = mem_alloc(heap, no_workers * sizeof(uint32_t));
  result->hash = mem_alloc(heap, hash_size * sizeof(hash_key_t));
  result->status = mem_alloc(heap, hash_size * sizeof(bucket_status_t));
  result->update_status = mem_alloc(heap, hash_size * sizeof(bucket_status_t));
  result->done = mem_alloc(heap, no_workers * sizeof(bool_t));
  if(hash_compaction) {
    result->hc_attrs = mem_alloc(heap, hash_size * result->attrs_char_size);
    memset(result->hc_attrs, 0, hash_size * result->attrs_char_size);
  } else {
    result->state = mem_alloc(heap, hash_size * sizeof(bit_vector_t));
    result->state_len = mem_alloc(heap, hash_size * sizeof(uint16_t));
  }
  for(w = 0; w < result->no_workers; w ++) {
    result->size[w] = 0;
    result->seeds[w] = random_seed(w);
    result->done[w] = FALSE;
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
  attrs |= ATTR_CYAN;
  attrs |= ATTR_BLUE;
  if(CFG_ACTION_CHECK_LTL) {
    attrs |= ATTR_PINK;
    attrs |= ATTR_RED;
  }
  if(CFG_ALGO_BFS) {
    attrs |= ATTR_PRED;
    attrs |= ATTR_EVT;
  }
  
  no_workers = CFG_NO_WORKERS;
  if(CFG_DISTRIBUTED) {
    no_workers += CFG_NO_COMM_WORKERS;
  }
  return hash_tbl_new(CFG_HASH_SIZE, no_workers, CFG_HASH_COMPACTION, attrs);
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
        mem_free(SYSTEM_HEAP, tbl->state[i]);
      }
    }
    mem_free(SYSTEM_HEAP, tbl->state);
    mem_free(SYSTEM_HEAP, tbl->state_len);
  }
  mem_free(SYSTEM_HEAP, tbl->size);
  mem_free(SYSTEM_HEAP, tbl->seeds);
  mem_free(SYSTEM_HEAP, tbl->hash);
  mem_free(SYSTEM_HEAP, tbl->status);
  mem_free(SYSTEM_HEAP, tbl->update_status);
  mem_free(SYSTEM_HEAP, tbl->done);
  mem_free(SYSTEM_HEAP, tbl);
}

void hash_tbl_set_heap
(hash_tbl_t tbl,
 heap_t h) {
  tbl->heap = h;
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
  bool_t found, del_found = FALSE;
  uint8_t b, curr = BUCKET_EMPTY;

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

 insert_loop:
  while(TRUE) {
    
  check_bucket:
    b = tbl->status[pos];
    if(BUCKET_EMPTY == b || b == curr) {
      
      /**
       *  we found a bucket where to insert the state => claim it
       */
      if(CAS(&tbl->status[pos], b, BUCKET_WRITE)) {

        /**
         *  empty bucket found but a bucket with a deleted state found
         *  before at position del_pos => we release the current
         *  bucket and try to insert the state in a bucket with a
         *  deleted state starting to from the position del_pos
         */
        if(BUCKET_EMPTY == curr && del_found) {
          tbl->status[pos] = BUCKET_EMPTY;
          curr = BUCKET_DEL;
          pos = del_pos;
          trials = 0;
          goto insert_loop;
        }

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
    }

    /**
     *  wait for the bucket to be readable
     */
    while(BUCKET_WRITE == tbl->status[pos]) {
      context_sleep(SLEEP_TIME);
    }

    /**
     *  the bucket has not been written by the thread that held it =>
     *  we check it again
     */
    if(BUCKET_EMPTY == tbl->status[pos]) {
      goto check_bucket;
    }

    /**
     *  the bucket is occupied and readable.
     *
     *  if the bucket contains a deleted state => record the current
     *  position in del_pos if this is the first loop looking for an
     *  empty bucket
     *
     *  if the bucket contains a state => compare it to the state to
     *  insert
     */
    if(tbl->status[pos] == BUCKET_DEL && !del_found && curr == BUCKET_EMPTY) {
      del_found = TRUE;
      del_pos = pos;
    } else if(tbl->status[pos] == BUCKET_READY) {
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
  return (tbl->attrs & attr) ? TRUE : FALSE;
}

uint64_t hash_tbl_get_attr
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 uint32_t pos,
 uint32_t size) {
  uint64_t result;
  bit_stream_t bits;
  
  BIT_STREAM_INIT_ON_ATTRS(tbl, id, bits);
  bit_stream_move(bits, pos);
  bit_stream_get(bits, result, size);
  return result;
}

void hash_tbl_set_attr
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 uint32_t pos,
 uint32_t size,
 uint64_t val) {
  bit_stream_t bits;

  BIT_STREAM_INIT_ON_ATTRS(tbl, id, bits);
  bit_stream_move(bits, pos);
  if(tbl->no_workers > 0) {
    while(!CAS(&tbl->update_status[id], BUCKET_READY, BUCKET_WRITE)) {
      context_sleep(SLEEP_TIME);
    }
  }
  bit_stream_set(bits, val, size);
  tbl->update_status[id] = BUCKET_READY;
}

bool_t hash_tbl_get_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w) {
  assert(hash_tbl_has_attr(tbl, ATTR_CYAN));
  return (bool_t)
    hash_tbl_get_attr(tbl, id, ATTR_CYAN_POS(tbl) + w, ATTR_CYAN_WIDTH);
}

bool_t hash_tbl_get_any_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  worker_id_t w;
  
  assert(hash_tbl_has_attr(tbl, ATTR_CYAN));
  for(w = 0; w < tbl->no_workers; w ++) {
    if(hash_tbl_get_attr(tbl, id, ATTR_CYAN_POS(tbl) + w, ATTR_CYAN_WIDTH)) {
      return TRUE;
    }
  }
  return FALSE;
}

bool_t hash_tbl_get_blue
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  assert(hash_tbl_has_attr(tbl, ATTR_BLUE));
  return (bool_t)
    hash_tbl_get_attr(tbl, id, ATTR_BLUE_POS(tbl), ATTR_BLUE_WIDTH);
}

bool_t hash_tbl_get_pink
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w) {
  assert(hash_tbl_has_attr(tbl, ATTR_PINK));
  return (bool_t)
    hash_tbl_get_attr(tbl, id, ATTR_PINK_POS(tbl) + w, ATTR_PINK_WIDTH);
}

bool_t hash_tbl_get_red
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  assert(hash_tbl_has_attr(tbl, ATTR_RED));
  return (bool_t)
    hash_tbl_get_attr(tbl, id, ATTR_RED_POS(tbl), ATTR_RED_WIDTH);
}

void hash_tbl_set_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 bool_t cyan) {
  assert(hash_tbl_has_attr(tbl, ATTR_CYAN));
  hash_tbl_set_attr(tbl, id, ATTR_CYAN_POS(tbl) + w,
                    ATTR_CYAN_WIDTH, (uint64_t) cyan);
}

void hash_tbl_set_blue
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t blue) {
  assert(hash_tbl_has_attr(tbl, ATTR_BLUE));
  hash_tbl_set_attr(tbl, id, ATTR_BLUE_POS(tbl),
                    ATTR_BLUE_WIDTH, (uint64_t) blue);
}

void hash_tbl_set_pink
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 bool_t pink) {
  assert(hash_tbl_has_attr(tbl, ATTR_PINK));
  hash_tbl_set_attr(tbl, id, ATTR_PINK_POS(tbl) + w,
                    ATTR_PINK_WIDTH, (uint64_t) pink);
}

void hash_tbl_set_red
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t red) {
  assert(hash_tbl_has_attr(tbl, ATTR_RED));
  hash_tbl_set_attr(tbl, id, ATTR_RED_POS(tbl),
                    ATTR_RED_WIDTH, (uint64_t) red);
}

void hash_tbl_set_pred
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 hash_tbl_id_t id_pred,
 mevent_id_t evt) {
  assert(hash_tbl_has_attr(tbl, ATTR_PRED) &&
         hash_tbl_has_attr(tbl, ATTR_EVT));
  hash_tbl_set_attr(tbl, id, ATTR_PRED_POS(tbl),
                    ATTR_PRED_WIDTH, (uint64_t) id_pred);
  hash_tbl_set_attr(tbl, id, ATTR_EVT_POS(tbl),
                    ATTR_EVT_WIDTH, (uint64_t) evt);
  id_pred = hash_tbl_get_attr(tbl, id, ATTR_PRED_POS(tbl),
                              ATTR_PRED_WIDTH);
}

void hash_tbl_erase_real
(hash_tbl_t tbl,
 worker_id_t w,
 hash_tbl_id_t id,
 uint8_t bucket_status) {
  if(tbl->hash_compaction) {
    memset(tbl->hc_attrs + id * tbl->attrs_char_size, 0, tbl->attrs_char_size);
  } else {
    mem_free(tbl->heap, tbl->state[id]);
    tbl->state[id] = NULL;
  }
  tbl->status[id] = bucket_status;
  tbl->update_status[id] = BUCKET_READY;
  tbl->size[w] --;
}

void hash_tbl_erase
(hash_tbl_t tbl,
 worker_id_t w,
 hash_tbl_id_t id) {
  hash_tbl_erase_real(tbl, w, id, BUCKET_EMPTY);
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
  
  while(id != (id_pred = hash_tbl_get_attr(tbl, id, ATTR_PRED_POS(tbl),
                                           ATTR_PRED_WIDTH))) {
    evt = hash_tbl_get_attr(tbl, id, ATTR_EVT_POS(tbl), ATTR_EVT_WIDTH);
    list_prepend(result, &evt);
    id = id_pred;
  }
  return result;
}
