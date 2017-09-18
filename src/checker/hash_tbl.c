#include "hash_tbl.h"
#include "report.h"
#include "bit_stream.h"

typedef uint8_t bucket_status_t;

struct struct_hash_tbl_t {
  uint64_t hash_size;
  uint64_t gc_time;
  pthread_barrier_t barrier;
  heap_t heaps[NO_WORKERS_STORAGE];
  uint64_t size[NO_WORKERS_STORAGE];
  uint64_t state_cmps[NO_WORKERS_STORAGE];
  uint32_t seeds[NO_WORKERS_STORAGE];
  hash_key_t hash[CFG_HASH_SIZE];
  bucket_status_t update_status[CFG_HASH_SIZE];
  bucket_status_t status[CFG_HASH_SIZE];
#if defined(CFG_HASH_COMPACTION)
  char state[CFG_HASH_SIZE][CFG_ATTRS_CHAR_SIZE];
#else
  bit_vector_t state[CFG_HASH_SIZE];
#endif
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
(uint64_t hash_size) {
  uint64_t i = 0;
  hash_tbl_t result;
  worker_id_t w;
  char name[20];

  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_hash_tbl_t));
  result->hash_size = hash_size;
  for(w = 0; w < NO_WORKERS_STORAGE; w ++) {
    result->size[w] = 0;
    result->state_cmps[w] = 0;
    sprintf(name, "heap of worker %d", w);
    result->heaps[w] = SYSTEM_HEAP;
    result->seeds[w] = random_seed(w);
  }
  for(i = 0; i < result->hash_size; i++) {
    result->update_status[i] = BUCKET_READY;
    result->status[i] = BUCKET_EMPTY;
#if !defined(CFG_HASH_COMPACTION)
    result->state[i] = NULL;
#endif
  }
  pthread_barrier_init(&result->barrier, NULL, CFG_NO_WORKERS);
  return result;

}

hash_tbl_t hash_tbl_default_new
() {
  return hash_tbl_new(CFG_HASH_SIZE);
}

void hash_tbl_free
(hash_tbl_t tbl) {
  uint64_t i = 0;
  worker_id_t w;
  
#if !defined(CFG_HASH_COMPACTION)
  for(i = 0; i < tbl->hash_size; i++) {
    if(tbl->state[i]) {
      mem_free(SYSTEM_HEAP, tbl->state[i]);
    }
  }
#endif
  for(w = 0; w < NO_WORKERS_STORAGE; w ++) {
    heap_free(tbl->heaps[w]);
  }
  mem_free(SYSTEM_HEAP, tbl);
}

uint64_t hash_tbl_size
(hash_tbl_t tbl) {
  uint64_t result = 0;
  worker_id_t w;
  
  for(w = 0; w < NO_WORKERS_STORAGE; w ++) {
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
#if defined(CFG_HASH_COMPACTION)
  if(NULL == se) {
    (*h) = state_hash(*s);
  } else {
    assert(h_set);
  }
#else
  if(!h_set) {
    (*h) = state_hash(*s);
  }
#endif
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
#if !defined(CFG_HASH_COMPACTION)
        if(NULL == se) {
          se_char_len = state_char_width(*s);
        }
        tbl->state[pos] = mem_alloc0(tbl->heaps[w],
                                     se_char_len + CFG_ATTRS_CHAR_SIZE);
        if(NULL == se) {
          state_serialise(*s, tbl->state[pos] + CFG_ATTRS_CHAR_SIZE);
        } else {
          memcpy(tbl->state[pos] + CFG_ATTRS_CHAR_SIZE, se, se_char_len);
        }
        bit_stream_init(bits, tbl->state[pos]);
        bit_stream_move(bits, CFG_ATTR_CHAR_LEN_POS);
        bit_stream_set(bits, se_char_len, CFG_ATTR_CHAR_LEN_SIZE);
#endif
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
      se_other = tbl->state[pos] + CFG_ATTRS_CHAR_SIZE;
      found = (tbl->hash[pos] == (*h));
#if !defined(CFG_HASH_COMPACTION)
      if(found) {
        if(NULL == se) {
          found = state_cmp_vector(*s, se_other);
        } else {
          found = 0 == memcmp(se, se_other, se_char_len);
        }
      }
#endif
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
#if defined(CFG_HASH_COMPACTION)
  fatal_error("hash_tbl_get_mem disabled by hash compaction");
#else
  result = state_unserialise_mem(tbl->state[id] + CFG_ATTRS_CHAR_SIZE, heap);
#endif
  return result;
}

hash_key_t hash_tbl_get_hash
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  return tbl->hash[id];
}

void hash_tbl_set_attribute
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 uint32_t pos,
 uint32_t size,
 uint64_t val) {
  bit_stream_t bits;
  
  bit_stream_init(bits, tbl->state[id]);
  bit_stream_move(bits, pos);
#if defined(CFG_PARALLEL)
  while(!CAS(&tbl->update_status[id], BUCKET_READY, BUCKET_WRITE)) {}
#endif
  bit_stream_set(bits, val, size);
  tbl->update_status[id] = BUCKET_READY;
}

void hash_tbl_remove
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
#if defined(CFG_ATTR_GARBAGE)
  hash_tbl_set_attribute(tbl, id, CFG_ATTR_GARBAGE_POS,
                         CFG_ATTR_GARBAGE_SIZE, 1);
#endif
}

uint64_t hash_tbl_get_attribute
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 uint32_t pos,
 uint32_t size) {
  uint64_t result;
  bit_stream_t bits;
  
  bit_stream_init(bits, tbl->state[id]);
  bit_stream_move(bits, pos);
  bit_stream_get(bits, result, size);
  return result;
}

bool_t hash_tbl_get_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w) {
  return (bool_t)
#if defined(CFG_ATTR_CYAN)
    hash_tbl_get_attribute(tbl, id, CFG_ATTR_CYAN_POS + w,
                           CFG_ATTR_CYAN_SIZE)
#else
    FALSE
#endif
    ;
}

bool_t hash_tbl_get_blue
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  return (bool_t)
#if defined(CFG_ATTR_BLUE)
    hash_tbl_get_attribute(tbl, id, CFG_ATTR_BLUE_POS,
                           CFG_ATTR_BLUE_SIZE)
#else
    FALSE
#endif
    ;
}

bool_t hash_tbl_get_pink
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w) {
  return (bool_t)
#if defined(CFG_ATTR_PINK)
    hash_tbl_get_attribute(tbl, id, CFG_ATTR_PINK_POS + w,
                           CFG_ATTR_PINK_SIZE)
#else
    FALSE
#endif
    ;
}

bool_t hash_tbl_get_red
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  return (bool_t)
#if defined(CFG_ATTR_RED)
    hash_tbl_get_attribute(tbl, id, CFG_ATTR_RED_POS,
                           CFG_ATTR_RED_SIZE)
#else
    FALSE
#endif
    ;
}

void hash_tbl_set_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 bool_t cyan) {
#if defined(CFG_ATTR_CYAN)
  hash_tbl_set_attribute(tbl, id, CFG_ATTR_CYAN_POS + w,
                         CFG_ATTR_CYAN_SIZE, (uint64_t) cyan);
#endif
}

void hash_tbl_set_blue
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t blue) {
#if defined(CFG_ATTR_BLUE)
  hash_tbl_set_attribute(tbl, id, CFG_ATTR_BLUE_POS,
                         CFG_ATTR_BLUE_SIZE, (uint64_t) blue);
#endif
}

void hash_tbl_set_pink
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 bool_t pink) {
#if defined(CFG_ATTR_PINK)
  hash_tbl_set_attribute(tbl, id, CFG_ATTR_PINK_POS + w,
                         CFG_ATTR_PINK_SIZE, (uint64_t) pink);
#endif
}

void hash_tbl_set_red
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t red) {
#if defined(CFG_ATTR_RED)
  hash_tbl_set_attribute(tbl, id, CFG_ATTR_RED_POS,
                         CFG_ATTR_RED_SIZE, (uint64_t) red);
#endif
}

void hash_tbl_get_serialised
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bit_vector_t * s,
 uint16_t * size) {
#if defined(CFG_HASH_COMPACTION)
  memcpy(*s, &tbl->hash[id], sizeof(hash_key_t));
  (*size) = sizeof(hash_key_t);
#else
  (*s) = tbl->state[id] + CFG_ATTRS_CHAR_SIZE;
  (*size) = (uint16_t) hash_tbl_get_attribute(tbl, id,
                                              CFG_ATTR_CHAR_LEN_POS,
                                              CFG_ATTR_CHAR_LEN_SIZE);
#endif
}

void hash_tbl_change_refs
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 int update) {
#if defined(CFG_ATTR_REFS)
  bit_stream_t bits;
  uint8_t refs;
  
  bit_stream_init(bits, tbl->state[id]);
  bit_stream_move(bits, CFG_ATTR_REFS_POS);
#if defined(CFG_PARALLEL)
  while(!CAS(&tbl->update_status[id], BUCKET_READY, BUCKET_WRITE)) {}
#endif
  
  /*  read the reference counter  */
  bit_stream_get(bits, refs, CFG_ATTR_REFS_SIZE);
  if(((int) refs + update) < 0) {
    fatal_error("hash_tbl_change_refs: unreferenced state found");
  }
  
  /*  and write it back after update */
  refs += update;
  bit_stream_start(bits);
  bit_stream_move(bits, CFG_ATTR_REFS_POS);
  bit_stream_set(bits, refs, CFG_ATTR_REFS_SIZE);
  
  /*  update the garbage flag */
#if defined(CFG_ATTR_GARBAGE)
  bit_stream_start(bits);
  bit_stream_move(bits, CFG_ATTR_GARBAGE_POS);
  bit_stream_set(bits, (0 == refs) ? 1 : 0, CFG_ATTR_GARBAGE_SIZE);
#endif
  tbl->update_status[id] = BUCKET_READY;
#endif
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
  
#if defined(CFG_STATE_CACHING)
  result =
      (tbl->size[w] * CFG_NO_WORKERS) >=
    ((tbl->hash_size * CFG_STATE_CACHING_GC_THRESHOLD) / 100);
#endif
  return result;
}
    
void hash_tbl_empty_slot
(hash_tbl_t tbl,
 worker_id_t w,
 hash_tbl_id_t id) {
  
  tbl->size[w] --;
  tbl->status[id] = BUCKET_DEL;
#if !defined(CFG_HASH_COMPACTION)
  mem_free(tbl->heaps[w], tbl->state[id]);
  tbl->state[id] = NULL;
#endif
}

void hash_tbl_barrier
(hash_tbl_t tbl) {
#if defined(CFG_PARALLEL)
  pthread_barrier_wait(&tbl->barrier);
#endif
}
    
void hash_tbl_gc
(hash_tbl_t tbl,
 worker_id_t w) {
  uint64_t init_pos, pos;
  bool_t gc;
  lna_timer_t t;
  uint32_t to_delete;

#if defined(CFG_STATE_CACHING)
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
  pos = (random_int(&tbl->seeds[w]) % tbl->hash_size) / CFG_NO_WORKERS;
  pos = pos * CFG_NO_WORKERS + w;
  init_pos = pos;
  to_delete = (int)((float) tbl->size[w] * CFG_STATE_CACHING_GC_PERCENT) / 100;
  while(to_delete) {
    if(tbl->status[pos] == BUCKET_READY) {
      gc = hash_tbl_get_attribute(tbl, pos, CFG_ATTR_GARBAGE_POS,
				  CFG_ATTR_GARBAGE_SIZE);
      if(gc) {
	to_delete --;
        hash_tbl_empty_slot(tbl, w, pos);
      }
    }
    pos += CFG_NO_WORKERS;
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
#endif
}
    
void hash_tbl_gc_all
(hash_tbl_t tbl,
 worker_id_t w) {
  uint64_t pos;
  lna_timer_t t;

#if defined(CFG_ATTR_GARBAGE)
  if(0 == w) {
    lna_timer_init(&t);
    lna_timer_start(&t);
  }
  hash_tbl_barrier(tbl);
  for(pos = w; pos < tbl->hash_size; pos ++) {
    if(tbl->status[pos] == BUCKET_READY) {
      if(hash_tbl_get_attribute(tbl, pos, CFG_ATTR_GARBAGE_POS,
                                CFG_ATTR_GARBAGE_SIZE)) {
        hash_tbl_empty_slot(tbl, w, pos);
      }
    }
  }
  hash_tbl_barrier(tbl);
  if(0 == w) {
    lna_timer_stop(&t);
    tbl->gc_time += lna_timer_value(t);
  }
#endif
}

void hash_tbl_output_stats
(hash_tbl_t tbl,
 FILE * out) {
  fprintf(out, "<hashTableStatistics>\n");
  fprintf(out, "<stateComparisons>%llu</stateComparisons>\n",
          do_large_sum(tbl->state_cmps, NO_WORKERS_STORAGE));
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
      s = state_unserialise_mem(tbl->state[pos] + CFG_ATTRS_CHAR_SIZE, h);
      f(s, pos, data);
      state_free(s);
      heap_reset(h);
    }
  }
}

void init_hash_tbl
() {
  hash_tbl_id_char_width = sizeof(hash_tbl_id_t);
}

void free_hash_tbl
() {
}
