#include "hash_tbl.h"
#include "report.h"
#include "bit_stream.h"

#define ATTR_CHAR_LEN_NUM   0
#define ATTR_CYAN_NUM       1
#define ATTR_BLUE_NUM       2
#define ATTR_PINK_NUM       3
#define ATTR_RED_NUM        4
#define ATTR_GARBAGE_NUM    5
#define ATTR_REFS_NUM       6

#define ATTR_CHAR_LEN_WIDTH 16
#define ATTR_CYAN_WIDTH     1
#define ATTR_BLUE_WIDTH     1
#define ATTR_PINK_WIDTH     1
#define ATTR_RED_WIDTH      1
#define ATTR_GARBAGE_WIDTH  1
#define ATTR_REFS_WIDTH     8

#define NO_ATTRS 7

typedef uint8_t bucket_status_t;

struct struct_hash_tbl_t {
  bool_t hash_compaction;
  bool_t state_caching;
  uint32_t attrs;
  uint32_t attrs_char_width;
  uint32_t attr_pos[NO_ATTRS];
  uint16_t no_workers;
  uint64_t hash_size;
  uint64_t gc_time;
  pthread_barrier_t barrier;
  heap_t heap;
  uint64_t * size;
  uint64_t * state_cmps;
  uint32_t * seeds;
  hash_key_t * hash;
  bucket_status_t * update_status;
  bucket_status_t * status;
  bit_vector_t hc_state;
  bit_vector_t * state;
};
typedef struct struct_hash_tbl_t struct_hash_tbl_t;

#define BUCKET_EMPTY 1
#define BUCKET_READY 2
#define BUCKET_WRITE 3
#define BUCKET_DEL   4

#define MAX_TRIALS 10000

const struct timespec SLEEP_TIME = { 0, 1 };

void hash_tbl_id_serialise
(hash_tbl_id_t id,
 bit_vector_t v) {
  bit_stream_t bits;
  
  bit_stream_init(bits, v);
  bit_stream_set_size64(bits, id);
}

hash_tbl_id_t hash_tbl_id_unserialise
(bit_vector_t v) {
  hash_tbl_id_t result;
  bit_stream_t bits;
  
  bit_stream_init(bits, v);
  bit_stream_get_size64(bits, result);
  return result;
}

order_t hash_tbl_id_cmp
(hash_tbl_id_t id1,
 hash_tbl_id_t id2) {
  return (id1 > id2) ? GREATER : ((id1 < id2) ? LESS : EQUAL);
}

hash_tbl_t hash_tbl_new
(uint64_t hash_size,
 uint16_t no_workers,
 uint16_t no_workers_barrier,
 bool_t hash_compaction,
 bool_t state_caching,
 uint32_t attrs) {
  const uint32_t attrs_width[NO_ATTRS] = { ATTR_CHAR_LEN_WIDTH,
                                           ATTR_CYAN_WIDTH * no_workers,
                                           ATTR_BLUE_WIDTH,
                                           ATTR_PINK_WIDTH * no_workers,
                                           ATTR_RED_WIDTH,
                                           ATTR_GARBAGE_WIDTH,
                                           ATTR_REFS_WIDTH };
  uint32_t attrs_bit_size = 0;
  uint64_t i;
  hash_tbl_t result;
  worker_id_t w;
  uint32_t pos = 0;
  
  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_hash_tbl_t));
  result->hash_compaction = hash_compaction;
  result->state_caching = state_caching;
  result->attrs = attrs;
  for(i = 0; i < NO_ATTRS; i ++) {
    if(hash_tbl_has_attr(result, 1 << i)) {
      attrs_bit_size += attrs_width[i];
      result->attr_pos[i] = pos;
      pos += attrs_width[i];
    }
  }
  result->attrs_char_width = pos / 8;
  if(pos % 8 != 0) {
    result->attrs_char_width ++;
  }
  result->no_workers = no_workers;
  result->hash_size = hash_size;
  result->heap = SYSTEM_HEAP;
  result->size = mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  result->state_cmps = mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint64_t));
  result->seeds = mem_alloc(SYSTEM_HEAP, no_workers * sizeof(uint32_t));
  result->hash = mem_alloc(SYSTEM_HEAP, hash_size * sizeof(hash_key_t));
  result->status = mem_alloc(SYSTEM_HEAP, hash_size * sizeof(bucket_status_t));
  result->update_status = mem_alloc(SYSTEM_HEAP,
                                    hash_size * sizeof(bucket_status_t));
  if(hash_compaction) {
    result->hc_state = mem_alloc(SYSTEM_HEAP,
                                 hash_size * result->attrs_char_width);
    memset(result->hc_state, 0, hash_size * result->attrs_char_width);
  } else {
    result->state = mem_alloc(SYSTEM_HEAP, hash_size * sizeof(bit_vector_t));
  }
  for(w = 0; w < result->no_workers; w ++) {
    result->size[w] = 0;
    result->state_cmps[w] = 0;
    result->seeds[w] = random_seed(w);
  }
  for(i = 0; i < result->hash_size; i++) {
    result->update_status[i] = BUCKET_READY;
    result->status[i] = BUCKET_EMPTY;
    if(!hash_compaction) {
      result->state[i] = NULL;
    }
  }
  result->gc_time = 0;
  pthread_barrier_init(&result->barrier, NULL, no_workers_barrier);
  return result;

}

hash_tbl_t hash_tbl_default_new
() {
  bool_t hash_compaction, state_caching;
  uint32_t attrs = 0;
  uint16_t no_workers, no_workers_barrier;

  attrs |= ATTR_CYAN;
  attrs |= ATTR_BLUE;
#if defined(CFG_ACTION_CHECK_LTL)
  attrs |= ATTR_PINK;
  attrs |= ATTR_RED;
#endif
#if !defined(CFG_HASH_COMPACTION)
  attrs |= ATTR_CHAR_LEN;
#endif
#if defined(CFG_STATE_CACHING) || defined(CFG_ALGO_FRONTIER)
  attrs |= ATTR_GARBAGE;
#endif
#if defined(CFG_STATE_CACHING)
  attrs |= ATTR_REFS;
#endif

#if defined(CFG_HASH_COMPACTION)
  hash_compaction = TRUE;
#else
  hash_compaction = FALSE;
#endif
#if defined(CFG_STATE_CACHING)
  state_caching = TRUE;
#else
  state_caching = FALSE;
#endif
#if defined(CFG_DISTRIBUTED)
  no_workers = CFG_NO_WORKERS + 1;
  no_workers_barrier = CFG_NO_WORKERS;
#else
  no_workers = CFG_NO_WORKERS;
  no_workers_barrier = CFG_NO_WORKERS;
#endif
  return hash_tbl_new(CFG_HASH_SIZE, no_workers, no_workers_barrier,
                      hash_compaction, state_caching, attrs);
}

void hash_tbl_free
(hash_tbl_t tbl) {
  uint64_t i = 0;
  worker_id_t w;

  mem_free(SYSTEM_HEAP, tbl->size);
  mem_free(SYSTEM_HEAP, tbl->state_cmps);
  mem_free(SYSTEM_HEAP, tbl->seeds);
  mem_free(SYSTEM_HEAP, tbl->hash);
  mem_free(SYSTEM_HEAP, tbl->status);
  mem_free(SYSTEM_HEAP, tbl->update_status);
  if(tbl->hash_compaction) {
    mem_free(SYSTEM_HEAP, tbl->hc_state);
  } else {
    for(i = 0; i < tbl->hash_size; i++) {
      if(tbl->state[i]) {
        mem_free(tbl->heap, tbl->state[i]);
      }
    }
    mem_free(SYSTEM_HEAP, tbl->state);
  }
  mem_free(SYSTEM_HEAP, tbl);
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
  uint32_t i, trials = 0;
  bit_stream_t bits;
  hash_tbl_id_t pos, init_pos;
  bit_vector_t se_other;
  bool_t found, garbage, del_found = FALSE;

  /**
   *  compute the hash value
   */
  if(tbl->hash_compaction) {
    if(NULL == se) {
      (*h) = state_hash(*s);
    } else {
      assert(h_set);
    }
  } else {
    if(!h_set) {
      (*h) = state_hash(*s);
    }
  }
  pos = (*h) % tbl->hash_size;
  
  while(TRUE) {
    if(tbl->status[pos] == BUCKET_EMPTY) {

      /**
       *  an empty bucket has been found => the state is new.
       *
       *  encode it and put it in this bucket.  before we check if
       *  there is an empty bucket (with a deleted state) before this
       *  one in which the state could be put.  this bucket must be
       *  between the current position and the first position at which
       *  a delete state has been found
       */
      if(CAS(&tbl->status[pos], BUCKET_EMPTY, BUCKET_WRITE)) {
	if(del_found) {
	  while(init_pos != pos) {
	    if(tbl->status[init_pos] == BUCKET_DEL &&
	       CAS(&tbl->status[init_pos], BUCKET_DEL, BUCKET_WRITE)) {
	      tbl->status[pos] = BUCKET_EMPTY;
	      pos = init_pos;
	      break;
	    }
	    init_pos = (init_pos + 1) % tbl->hash_size;
	  }
        }
        if(!tbl->hash_compaction) {
          if(NULL == se) {
            se_char_len = state_char_width(*s);
          }
          tbl->state[pos] = mem_alloc0(tbl->heap,
                                       se_char_len + tbl->attrs_char_width);
          if(NULL == se) {
            state_serialise(*s, tbl->state[pos] + tbl->attrs_char_width);
          } else {
            memcpy(tbl->state[pos] + tbl->attrs_char_width, se, se_char_len);
          }
          if(hash_tbl_has_attr(tbl, ATTR_CHAR_LEN)) {
            bit_stream_init(bits, tbl->state[pos]);
            bit_stream_move(bits, tbl->attr_pos[ATTR_CHAR_LEN_NUM]);
            bit_stream_set(bits, se_char_len, ATTR_CHAR_LEN_WIDTH);
          }
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
    while(tbl->status[pos] == BUCKET_WRITE) {
      nanosleep(&SLEEP_TIME, NULL);
    }

    /**
     *  the bucket is occupied and readable
     */
    if(tbl->status[pos] == BUCKET_DEL && !del_found) {
      del_found = TRUE;
      init_pos = pos;
    } else if(tbl->status[pos] == BUCKET_READY) {
      tbl->state_cmps[w] ++;
      found = (tbl->hash[pos] == (*h));
      if(found && !tbl->hash_compaction) {
        se_other = tbl->state[pos] + tbl->attrs_char_width;
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
  result = state_unserialise_mem(tbl->state[id] + tbl->attrs_char_width, heap);
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
  return tbl->attrs & attr;  
}

uint64_t hash_tbl_get_attr
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 uint32_t pos,
 uint32_t size) {
  uint64_t result;
  bit_stream_t bits;

  if(tbl->hash_compaction) {
    bit_stream_init(bits, tbl->hc_state + pos * tbl->attrs_char_width);
  } else {
    bit_stream_init(bits, tbl->state[id]);
  }
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

  if(tbl->hash_compaction) {
    bit_stream_init(bits, tbl->hc_state + pos * tbl->attrs_char_width);
  } else  {
    bit_stream_init(bits, tbl->state[id]);
  }
  bit_stream_move(bits, pos);
  if(tbl->no_workers > 0) {
    while(!CAS(&tbl->update_status[id], BUCKET_READY, BUCKET_WRITE)) {
      nanosleep(&SLEEP_TIME, NULL);
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
    hash_tbl_get_attr(tbl, id, tbl->attr_pos[ATTR_CYAN_NUM] + w,
                      ATTR_CYAN_WIDTH);
}

bool_t hash_tbl_get_blue
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  assert(hash_tbl_has_attr(tbl, ATTR_BLUE));
  return (bool_t)
    hash_tbl_get_attr(tbl, id, tbl->attr_pos[ATTR_BLUE_NUM],
                      ATTR_BLUE_WIDTH);
}

bool_t hash_tbl_get_pink
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w) {
  assert(hash_tbl_has_attr(tbl, ATTR_PINK));
  return (bool_t)
    hash_tbl_get_attr(tbl, id, tbl->attr_pos[ATTR_PINK_NUM] + w,
                      ATTR_PINK_WIDTH);
}

bool_t hash_tbl_get_red
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  assert(hash_tbl_has_attr(tbl, ATTR_RED));
  return (bool_t)
    hash_tbl_get_attr(tbl, id, tbl->attr_pos[ATTR_RED_NUM],
                      ATTR_RED_WIDTH);
}

bool_t hash_tbl_get_garbage
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  assert(hash_tbl_has_attr(tbl, ATTR_GARBAGE));
  return (bool_t)
    hash_tbl_get_attr(tbl, id, tbl->attr_pos[ATTR_GARBAGE_NUM],
                      ATTR_GARBAGE_WIDTH);
}

void hash_tbl_set_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 bool_t cyan) {
  assert(hash_tbl_has_attr(tbl, ATTR_CYAN));
  hash_tbl_set_attr(tbl, id, tbl->attr_pos[ATTR_CYAN_NUM] + w,
                    ATTR_CYAN_WIDTH, (uint64_t) cyan);
}

void hash_tbl_set_blue
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t blue) {
  assert(hash_tbl_has_attr(tbl, ATTR_BLUE));
  hash_tbl_set_attr(tbl, id, tbl->attr_pos[ATTR_BLUE_NUM],
                    ATTR_BLUE_WIDTH, (uint64_t) blue);
}

void hash_tbl_set_pink
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 bool_t pink) {
  assert(hash_tbl_has_attr(tbl, ATTR_PINK));
  hash_tbl_set_attr(tbl, id, tbl->attr_pos[ATTR_PINK_NUM] + w,
                    ATTR_PINK_WIDTH, (uint64_t) pink);
}

void hash_tbl_set_red
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t red) {
  assert(hash_tbl_has_attr(tbl, ATTR_RED));
  hash_tbl_set_attr(tbl, id, tbl->attr_pos[ATTR_RED_NUM],
                    ATTR_RED_WIDTH, (uint64_t) red);
}

void hash_tbl_set_garbage
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t garbage) {
  assert(hash_tbl_has_attr(tbl, ATTR_GARBAGE));
  hash_tbl_set_attr(tbl, id, tbl->attr_pos[ATTR_GARBAGE_NUM],
                    ATTR_GARBAGE_WIDTH, garbage);
}

void hash_tbl_remove
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  hash_tbl_set_garbage(tbl, id, TRUE);
}

void hash_tbl_get_serialised
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bit_vector_t * s,
 uint16_t * size) {
  if(tbl->hash_compaction) {
    memcpy(*s, &tbl->hash[id], sizeof(hash_key_t));
    (*size) = sizeof(hash_key_t);
  } else {
    assert(hash_tbl_has_attr(tbl, ATTR_CHAR_LEN));
    (*s) = tbl->state[id] + tbl->attrs_char_width;
    (*size) = (uint16_t) hash_tbl_get_attr(tbl, id,
                                           tbl->attr_pos[ATTR_CHAR_LEN_NUM],
                                           ATTR_CHAR_LEN_WIDTH);
  }
}

void hash_tbl_change_refs
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 int update) {
  bit_stream_t bits;
  uint8_t refs;

  if(hash_tbl_has_attr(tbl, ATTR_REFS)) {
    bit_stream_init(bits, tbl->state[id]);
    bit_stream_move(bits, tbl->attr_pos[ATTR_REFS_NUM]);
    if(tbl->no_workers > 0) {
      while(!CAS(&tbl->update_status[id], BUCKET_READY, BUCKET_WRITE)) {
        nanosleep(&SLEEP_TIME, NULL);
      }
    }
  
    /*  read the reference counter  */
    bit_stream_get(bits, refs, ATTR_REFS_WIDTH);
    if(((int) refs + update) < 0) {
      fatal_error("hash_tbl_change_refs: unreferenced state found");
    }
  
    /*  and write it back after update */
    refs += update;
    bit_stream_start(bits);
    bit_stream_move(bits, tbl->attr_pos[ATTR_REFS_NUM]);
    bit_stream_set(bits, refs, ATTR_REFS_WIDTH);
  
    /*  update the garbage flag */
    if(hash_tbl_has_attr(tbl, ATTR_GARBAGE)) {
      bit_stream_start(bits);
      bit_stream_move(bits, tbl->attr_pos[ATTR_GARBAGE_NUM]);
      bit_stream_set(bits, (0 == refs) ? 1 : 0, ATTR_GARBAGE_WIDTH);
    }
    tbl->update_status[id] = BUCKET_READY;
  }
}

void hash_tbl_ref
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  hash_tbl_change_refs(tbl, id, 1);
}

void hash_tbl_unref
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  hash_tbl_change_refs(tbl, id, - 1);
}

bool_t hash_tbl_do_gc
(hash_tbl_t tbl,
 worker_id_t w) {
  bool_t result = FALSE;

  if(tbl->state_caching) {
    result = hash_tbl_size(tbl) >=
      ((tbl->hash_size * CFG_STATE_CACHING_GC_THRESHOLD) / 100);
  }
  return result;
}
    
void hash_tbl_empty_slot
(hash_tbl_t tbl,
 worker_id_t w,
 hash_tbl_id_t id) {
  
  tbl->size[w] --;
  tbl->status[id] = BUCKET_DEL;
  tbl->update_status[id] = BUCKET_READY;
  if(tbl->hash_compaction) {
    memset(tbl->hc_state + id * tbl->attrs_char_width,
           0, tbl->attrs_char_width);
  } else {
    mem_free(tbl->heap, tbl->state[id]);
    tbl->state[id] = NULL;
  }
}

void hash_tbl_barrier
(hash_tbl_t tbl) {
  if(tbl->no_workers > 1) {
    pthread_barrier_wait(&tbl->barrier);
  }
}
    
void hash_tbl_gc
(hash_tbl_t tbl,
 worker_id_t w) {
  uint64_t init_pos, pos;
  lna_timer_t t;
  uint32_t to_delete;

  if(tbl->state_caching) {
    if(0 == w) {
      lna_timer_init(&t);
      lna_timer_start(&t);
    }

    /**
     *  delete state which have the gc flag set on.  randomly pick a
     *  slot and delete CFG_STATE_CACHING_GC_PERCENT percent of the
     *  states stored by the worker starting from this slot
     */
    hash_tbl_barrier(tbl);
    pos = (random_int(&tbl->seeds[w]) % tbl->hash_size) / tbl->no_workers;
    pos = pos * tbl->no_workers + w;
    init_pos = pos;
    to_delete =
      (uint64_t) ((double) hash_tbl_size(tbl) * CFG_STATE_CACHING_GC_PERCENT) /
      (100 * tbl->no_workers);
    while(to_delete) {
      if(tbl->status[pos] == BUCKET_READY) {
        if(hash_tbl_get_garbage(tbl, pos)) {
          to_delete --;
          hash_tbl_empty_slot(tbl, w, pos);
        }
      }
      pos += tbl->no_workers;
      if(pos  >= tbl->hash_size) {
        pos = w;
      }
      if(pos == init_pos) {
        break;
      }
    }
    hash_tbl_barrier(tbl);
    if(0 == w) {
      lna_timer_stop(&t);
      tbl->gc_time += lna_timer_value(t);
    }
  }
}
    
void hash_tbl_gc_all
(hash_tbl_t tbl,
 worker_id_t w) {
  uint64_t pos;
  lna_timer_t t;

  if(hash_tbl_has_attr(tbl, ATTR_GARBAGE)) {
    if(0 == w) {
      lna_timer_init(&t);
      lna_timer_start(&t);
    }
    hash_tbl_barrier(tbl);
    for(pos = w; pos < tbl->hash_size; pos ++) {
      if(tbl->status[pos] == BUCKET_READY) {
        if(hash_tbl_get_garbage(tbl, pos)) {
          hash_tbl_empty_slot(tbl, w, pos);
        }
      }
    }
    hash_tbl_barrier(tbl);
    if(0 == w) {
      lna_timer_stop(&t);
      tbl->gc_time += lna_timer_value(t);
    }
  }
}

void hash_tbl_output_stats
(hash_tbl_t tbl,
 FILE * out) {
  fprintf(out, "<hashTableStatistics>\n");
  fprintf(out, "<stateComparisons>%llu</stateComparisons>\n",
          do_large_sum(tbl->state_cmps, tbl->no_workers));
  fprintf(out, "</hashTableStatistics>\n");
}

uint64_t hash_tbl_gc_time
(hash_tbl_t tbl) {
  return tbl->gc_time;
}

void hash_tbl_fold
(hash_tbl_t tbl,
 hash_tbl_fold_func_t f,
 void * data) {
  state_t s;
  uint64_t pos;
  heap_t h = bounded_heap_new("", 10000);
  
  for(pos = 0; pos < tbl->hash_size; pos ++) {
    if(tbl->status[pos] == BUCKET_READY) {
      s = state_unserialise_mem(tbl->state[pos] + tbl->attrs_char_width, h);
      f(s, pos, data);
      state_free(s);
      heap_reset(h);
    }
  }
  heap_free(h);
}

void hash_tbl_fold_serialised
(hash_tbl_t tbl,
 hash_tbl_fold_serialised_func_t f,
 void * data) {
  uint16_t l;
  hash_key_t h;
  bit_vector_t s;
  uint64_t pos;
  
  for(pos = 0; pos < tbl->hash_size; pos ++) {
    if(tbl->status[pos] == BUCKET_READY) {
      s = tbl->state[pos] + tbl->attrs_char_width;
      h = tbl->hash[pos];
      l = hash_tbl_get_attr(tbl, pos, tbl->attr_pos[ATTR_CHAR_LEN_NUM],
                            ATTR_CHAR_LEN_WIDTH);
      f(s, l, h, data);
    }
  }
}

void hash_tbl_set_heap
(hash_tbl_t tbl,
 heap_t h) {
  tbl->heap = h;
}

void init_hash_tbl
() {
  hash_tbl_id_char_width = sizeof(hash_tbl_id_t);
}

void free_hash_tbl
() {
}
