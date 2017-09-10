#include "shared_hash_tbl.h"
#include "report.h"
#include "vectors.h"

/**
 *  TODO:
 *  * merge shared_hash_tbl_insert & shared_hash_tbl_insert_serialised
 */

#define BUCKET_EMPTY 1
#define BUCKET_READY 2
#define BUCKET_WRITE 3
#define BUCKET_DEL   4

#define MAX_TRIALS 100000

static const struct timespec SLEEP_TIME = { 0, 1 };

void shared_hash_tbl_id_serialise
(shared_hash_tbl_id_t id,
 bit_vector_t v) {
  vector bits;
  bits.vector = v;
  VECTOR_start(bits);
  VECTOR_set_size64(bits, id);
}

shared_hash_tbl_id_t shared_hash_tbl_id_unserialise
(bit_vector_t v) {
  shared_hash_tbl_id_t result;
  vector bits;
  bits.vector = v;
  VECTOR_start(bits);
  VECTOR_get_size64(bits, result);
  return result;
}

order_t shared_hash_tbl_id_cmp
(shared_hash_tbl_id_t id1,
 shared_hash_tbl_id_t id2) {
  return (id1 > id2) ? GREATER : ((id1 < id2) ? LESS : EQUAL);
}

shared_hash_tbl_t shared_hash_tbl_new
(uint64_t hash_size) {
  uint64_t i = 0;
  shared_hash_tbl_t result;
  worker_id_t w;
  char name[20];

  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_shared_hash_tbl_t));
  result->hash_size = hash_size;
  for(w = 0; w < NO_WORKERS_STORAGE; w ++) {
    result->size[w] = 0;
    result->state_cmps[w] = 0;
    sprintf(name, "heap of worker %d", w);
    result->heaps[w] = SYSTEM_HEAP;
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

shared_hash_tbl_t shared_hash_tbl_default_new
() {
  return shared_hash_tbl_new(CFG_HASH_SIZE);
}

void shared_hash_tbl_free
(shared_hash_tbl_t tbl) {
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

uint64_t shared_hash_tbl_size
(shared_hash_tbl_t tbl) {
  uint64_t result = 0;
  worker_id_t w;
  
  for(w = 0; w < NO_WORKERS_STORAGE; w ++) {
    result += tbl->size[w];
  }
  return result;
}

void shared_hash_tbl_insert_serialised
(shared_hash_tbl_t tbl,
 bit_vector_t s,
 uint16_t s_char_len,
 hash_key_t h,
 worker_id_t w,
 bool_t * is_new,
 shared_hash_tbl_id_t * id) {
  unsigned int trials = 0;
  vector bits;
  shared_hash_tbl_id_t pos = h % tbl->hash_size;
  hash_compact_t hc;

#ifdef CFG_HASH_COMPACTION
  s_char_len = sizeof(hash_compact_t);
#endif  
  while(TRUE) {
    if(tbl->status[pos] == BUCKET_EMPTY) {
      if(CAS(&tbl->status[pos], BUCKET_EMPTY, BUCKET_WRITE)) {
#ifdef CFG_HASH_COMPACTION
        memcpy(tbl->state[pos] + CFG_ATTRIBUTES_CHAR_WIDTH, s, s_char_len);
#else
        tbl->hash[pos] = h;
        tbl->state[pos] = mem_alloc0(tbl->heaps[w],
                                     s_char_len + CFG_ATTRIBUTES_CHAR_WIDTH);
        memcpy(tbl->state[pos] + CFG_ATTRIBUTES_CHAR_WIDTH, s, s_char_len);
        bits.vector = tbl->state[pos];
        VECTOR_start(bits);
        VECTOR_move(bits, CFG_ATTRIBUTE_CHAR_LEN_POS);
        VECTOR_set(bits, s_char_len, CFG_ATTRIBUTE_CHAR_LEN_WIDTH);
#endif
        tbl->status[pos] = BUCKET_READY;
        tbl->size[w] ++;
        (*is_new) = TRUE;
        (*id) = pos;
        return;
      }
    }
    while(tbl->status[pos] == BUCKET_WRITE) {
      nanosleep(&SLEEP_TIME, NULL);
    }
    if(tbl->status[pos] == BUCKET_READY) {
      tbl->state_cmps[w] ++;

#if !defined(CFG_HASH_COMPACTION)
      {
        unsigned int len;
        bits.vector = tbl->state[pos];
        VECTOR_start(bits);
        VECTOR_move(bits, CFG_ATTRIBUTE_CHAR_LEN_POS);
        VECTOR_get(bits, len, CFG_ATTRIBUTE_CHAR_LEN_WIDTH);
      }
#endif
      
      if(0 == memcmp(s, tbl->state[pos] + CFG_ATTRIBUTES_CHAR_WIDTH,
                     s_char_len)) {
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

void shared_hash_tbl_insert
(shared_hash_tbl_t tbl,
 state_t s,
 worker_id_t w,
 bool_t * is_new,
 shared_hash_tbl_id_t * id,
 hash_key_t * h) {
  unsigned int trials = 0;
  vector bits;
  shared_hash_tbl_id_t pos, init_pos;
  bit_vector_t es;
  hash_compact_t hc;
  uint16_t s_char_len;
  bool_t garbage;

#ifdef CFG_HASH_COMPACTION
  hash_compact(s, &hc);
  (*h) = hc.keys[0];
#else
  (*h) = state_hash(s);
#endif
  pos = (*h) % tbl->hash_size;
  init_pos = pos;
  
  while(TRUE) {
    if(tbl->status[pos] == BUCKET_EMPTY) {

      /**
       *  an empty bucket has been found => the state is new.  encode
       *  it and put it in this bucket.  if state caching is on we
       *  check if there is an empty bucket before this one in which
       *  the state could be put.  this bucket must be between the
       *  current position and the initial theoretical position (hash
       *  value % table size)
       */
      if(CAS(&tbl->status[pos], BUCKET_EMPTY, BUCKET_WRITE)) {
#if defined(CFG_STATE_CACHING)
        while(init_pos != pos) {
          if(tbl->status[init_pos] == BUCKET_DEL &&
             CAS(&tbl->status[init_pos], BUCKET_DEL, BUCKET_WRITE)) {
            tbl->status[pos] = BUCKET_EMPTY;
            pos = init_pos;
            break;
          }
          init_pos = (init_pos + 1) % tbl->hash_size;
        }
#endif        
#if defined(CFG_HASH_COMPACTION)
        memcpy(&(tbl->state[pos][CFG_ATTRIBUTES_CHAR_WIDTH]), &hc,
               sizeof(hash_compact_t));
#else
        s_char_len = state_char_width(s);
        tbl->state[pos] = mem_alloc0(tbl->heaps[w],
                                     s_char_len + CFG_ATTRIBUTES_CHAR_WIDTH);
        tbl->hash[pos] = (*h);
        state_serialise(s, tbl->state[pos] + CFG_ATTRIBUTES_CHAR_WIDTH);
#ifdef CFG_ATTRIBUTE_CHAR_LEN
        bits.vector = tbl->state[pos];
        VECTOR_start(bits);
        VECTOR_move(bits, CFG_ATTRIBUTE_CHAR_LEN_POS);
        VECTOR_set(bits, s_char_len, CFG_ATTRIBUTE_CHAR_LEN_WIDTH);
#endif
#endif
        tbl->status[pos] = BUCKET_READY;
        tbl->size[w] ++;
        (*is_new) = TRUE;
        (*id) = pos;
        return;
      }
    }
    while(tbl->status[pos] == BUCKET_WRITE) {
      nanosleep(&SLEEP_TIME, NULL);
    }
    if(tbl->status[pos] == BUCKET_READY) {
      tbl->state_cmps[w] ++;
      es = tbl->state[pos] + CFG_ATTRIBUTES_CHAR_WIDTH;
#if defined(CFG_HASH_COMPACTION)
      (*is_new) = (0 != memcmp(s, es, sizeof(hash_compact_t))) ?
        FALSE : TRUE;
#else
      (*is_new) = (tbl->hash[pos] == (*h) && state_cmp_vector(s, es)) ?
        FALSE : TRUE;
#endif
      if(!(*is_new)) {
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

void shared_hash_tbl_remove
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id) {
  fatal_error("shared_hash_tbl_remove: not implemented");
}

void shared_hash_tbl_lookup
(shared_hash_tbl_t tbl,
 state_t s,
 worker_id_t w,
 bool_t * found,
 shared_hash_tbl_id_t * id) {
  fatal_error("shared_hash_tbl_lookup: not implemented");
}

state_t shared_hash_tbl_get
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 worker_id_t w) {
  return shared_hash_tbl_get_mem(tbl, id, w, SYSTEM_HEAP);
}

state_t shared_hash_tbl_get_mem
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 worker_id_t w,
 heap_t heap) {
  state_t result;
#if defined(CFG_HASH_COMPACTION)
  fatal_error("shared_hash_tbl_get_mem disabled by hash compaction");
#else
  result = state_unserialise_mem(tbl->state[id] + CFG_ATTRIBUTES_CHAR_WIDTH,
                                 heap);
#endif
  return result;
}

hash_key_t shared_hash_tbl_get_hash
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id) {
  hash_key_t result;
  
#if defined(CFG_HASH_COMPACTION)
  hash_compact_t h;
  memcpy(&h, &(tbl->state[id][CFG_ATTRIBUTES_CHAR_WIDTH]),
         sizeof(hash_compact_t));
  result = h.keys[0];
#else
  result = tbl->hash[id];
#endif
  return result;
}

void shared_hash_tbl_set_attribute
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 uint32_t pos,
 uint32_t size,
 uint64_t val) {
  vector bits;
  
  bits.vector = tbl->state[id];
  VECTOR_start(bits);
  VECTOR_move(bits, pos);
#if defined(CFG_PARALLEL)
  while(!CAS(&tbl->update_status[id], BUCKET_READY, BUCKET_WRITE)) {}
#endif
  VECTOR_set(bits, val, size);
  tbl->update_status[id] = BUCKET_READY;
}

uint64_t shared_hash_tbl_get_attribute
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 uint32_t pos,
 uint32_t size) {
  uint64_t result;
  vector bits;
  bits.vector = tbl->state[id];
  VECTOR_start(bits);
  VECTOR_move(bits, pos);
  VECTOR_get(bits, result, size);
  return result;
}

bool_t shared_hash_tbl_get_cyan
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 worker_id_t w) {
  return (bool_t)
#if defined(CFG_ATTRIBUTE_CYAN)
    shared_hash_tbl_get_attribute(tbl, id, CFG_ATTRIBUTE_CYAN_POS + w, 1)
#else
    FALSE
#endif
    ;
}

bool_t shared_hash_tbl_get_blue
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id) {
  return (bool_t)
#if defined(CFG_ATTRIBUTE_BLUE)
    shared_hash_tbl_get_attribute(tbl, id, CFG_ATTRIBUTE_BLUE_POS, 1)
#else
    FALSE
#endif
    ;
}

bool_t shared_hash_tbl_get_pink
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 worker_id_t w) {
  return (bool_t)
#if defined(CFG_ATTRIBUTE_PINK)
    shared_hash_tbl_get_attribute(tbl, id, CFG_ATTRIBUTE_PINK_POS + w, 1)
#else
    FALSE
#endif
    ;
}

bool_t shared_hash_tbl_get_red
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id) {
  return (bool_t)
#if defined(CFG_ATTRIBUTE_RED)
    shared_hash_tbl_get_attribute(tbl, id, CFG_ATTRIBUTE_RED_POS, 1)
#else
    FALSE
#endif
    ;
}

void shared_hash_tbl_set_cyan
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 worker_id_t w,
 bool_t cyan) {
#if defined(CFG_ATTRIBUTE_CYAN)
  shared_hash_tbl_set_attribute(tbl, id, CFG_ATTRIBUTE_CYAN_POS + w,
                                1, (uint64_t) cyan);
#endif
}

void shared_hash_tbl_set_blue
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 bool_t blue) {
#if defined(CFG_ATTRIBUTE_BLUE)
  shared_hash_tbl_set_attribute(tbl, id, CFG_ATTRIBUTE_BLUE_POS,
                                1, (uint64_t) blue);
#endif
}

void shared_hash_tbl_set_pink
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 worker_id_t w,
 bool_t pink) {
#if defined(CFG_ATTRIBUTE_PINK)
  shared_hash_tbl_set_attribute(tbl, id, CFG_ATTRIBUTE_PINK_POS + w,
                                1, (uint64_t) pink);
#endif
}

void shared_hash_tbl_set_red
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 bool_t red) {
#if defined(CFG_ATTRIBUTE_RED)
  shared_hash_tbl_set_attribute(tbl, id, CFG_ATTRIBUTE_RED_POS,
                                1, (uint64_t) red);
#endif
}

void shared_hash_tbl_get_serialised
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 bit_vector_t * s,
 uint16_t * size) {
#if defined(CFG_HASH_COMPACTION)
  (*s) = &(tbl->state[id][CFG_ATTRIBUTES_CHAR_WIDTH]);
  (*size) = sizeof(hash_compact_t);
#else
  (*s) = tbl->state[id] + CFG_ATTRIBUTES_CHAR_WIDTH;
  (*size) = (uint16_t)
    shared_hash_tbl_get_attribute(tbl, id,
                                  CFG_ATTRIBUTE_CHAR_LEN_POS,
                                  CFG_ATTRIBUTE_CHAR_LEN_WIDTH);
#endif
}

void shared_hash_tbl_change_refs
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 int update) {
#if defined(CFG_ATTRIBUTE_REFS)
  vector bits;
  uint8_t refs;
  
  bits.vector = tbl->state[id];
  VECTOR_start(bits);
  VECTOR_move(bits, CFG_ATTRIBUTE_REFS_POS);
#if defined(CFG_PARALLEL)
  while(!CAS(&tbl->update_status[id], BUCKET_READY, BUCKET_WRITE)) {}
#endif
  
  /*  read the reference counter  */
  VECTOR_get(bits, refs, CFG_ATTRIBUTE_REFS_WIDTH);
  if(((int) refs + update) < 0) {
    fatal_error("shared_hash_tbl_change_refs: unreferenced state found");
  }
  
  /*  and write it back after update */
  refs += update;
  VECTOR_start(bits);
  VECTOR_move(bits, CFG_ATTRIBUTE_REFS_POS);
  VECTOR_set(bits, refs, CFG_ATTRIBUTE_REFS_WIDTH);
  
  /*  the garbage flag */
#if defined(CFG_ATTRIBUTE_GARBAGE)
  VECTOR_start(bits);
  VECTOR_move(bits, CFG_ATTRIBUTE_GARBAGE_POS);
  VECTOR_set(bits, (0 == refs) ? 1 : 0, CFG_ATTRIBUTE_GARBAGE_WIDTH);
#endif
  tbl->update_status[id] = BUCKET_READY;
#endif
}

void shared_hash_tbl_ref
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id) {
  shared_hash_tbl_change_refs(tbl, id, 1);
}

void shared_hash_tbl_unref
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id) {
  shared_hash_tbl_change_refs(tbl, id, - 1);
}

bool_t shared_hash_tbl_do_gc
(shared_hash_tbl_t tbl,
 worker_id_t w) {
  bool_t result = FALSE;
  
#if defined(CFG_STATE_CACHING)
  result =
    (tbl->size[w] * CFG_NO_WORKERS) >=
    ((tbl->hash_size * CFG_STATE_CACHING_GC_THRESHOLD) / 100);
#endif
  return result;
}
    
void shared_hash_tbl_gc
(shared_hash_tbl_t tbl,
 worker_id_t w) {
  uint64_t i, k, rpos, pos;
  bool_t gc;

#if defined(CFG_ATTRIBUTE_GARBAGE)
  /*
   *  delete state which have the gc flag set on.  a worker with id w
   *  deletes each STATE_CACHING_GC_RATIOth state within state[w],
   *  state[w + CFG_NO_WORKERS], state[w + 2 * CFG_NO_WORKERS], ...
   */
#if defined(CFG_PARALLEL)
  shared_hash_tbl_wait_barrier(tbl);
#endif
  k = CFG_STATE_CACHING_GC_RATIO;
  for(pos = w; pos < tbl->hash_size; pos += CFG_NO_WORKERS) {
    if(tbl->status[pos] == BUCKET_READY) {
      gc = shared_hash_tbl_get_attribute(tbl, pos, CFG_ATTRIBUTE_GARBAGE_POS,
                                         CFG_ATTRIBUTE_GARBAGE_WIDTH);
      if(gc) {
        k --;
        if(0 == k) {
          k = CFG_STATE_CACHING_GC_RATIO;
          tbl->size[w] --;
          tbl->status[pos] = BUCKET_DEL;
#if !defined(CFG_HASH_COMPACTION)
          mem_free(tbl->heaps[w], tbl->state[pos]);
          tbl->state[pos] = NULL;
#endif
        }
      }
    }
  }
#if defined(CFG_PARALLEL)
  shared_hash_tbl_wait_barrier(tbl);
#endif
#endif
}

void shared_hash_tbl_wait_barrier
(shared_hash_tbl_t tbl) {
  pthread_barrier_wait(&tbl->barrier);
}

void shared_hash_tbl_output_stats
(shared_hash_tbl_t tbl,
 FILE * out) {
  fprintf(out, "<hashTableStatistics>\n");
  fprintf(out, "<stateComparisons>%llu</stateComparisons>\n",
          do_large_sum(tbl->state_cmps, NO_WORKERS_STORAGE));
  fprintf(out, "</hashTableStatistics>\n");
}
   

void init_shared_hash_tbl
() {
  shared_hash_tbl_id_char_width = sizeof(shared_hash_tbl_id_t);
}

void free_shared_hash_tbl
() {
}
