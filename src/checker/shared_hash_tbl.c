#include "shared_hash_tbl.h"
#include "report.h"
#include "vectors.h"

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
  for(w = 0; w < NO_WORKERS; w ++) {
    result->size[w] = 0;
    result->state_cmps[w] = 0;
    sprintf(name, "heap of worker %d", w);
    result->heaps[w] = evergrowing_heap_new(name, 100000);
  }
  for(i = 0; i < result->hash_size; i++) {
    result->update_status[i] = BUCKET_READY;
    result->status[i] = BUCKET_EMPTY;
#ifndef HASH_COMPACTION
    result->state[i] = NULL;
#endif
  }
  return result;

}

shared_hash_tbl_t shared_hash_tbl_default_new
() {
  return shared_hash_tbl_new(HASH_SIZE);
}

void shared_hash_tbl_free
(shared_hash_tbl_t tbl) {
  uint64_t i = 0;
  worker_id_t w;
  
#ifndef HASH_COMPACTION
  for(i = 0; i < tbl->hash_size; i++) {
    if(tbl->state[i]) {
      mem_free(tbl->heaps[w], tbl->state[i]);
    }
  }
#endif
  for(w = 0; w < NO_WORKERS; w ++) {
    heap_free(tbl->heaps[w]);
  }
  mem_free(SYSTEM_HEAP, tbl);
}

uint64_t shared_hash_tbl_size
(shared_hash_tbl_t tbl) {
  uint64_t result = 0;
  worker_id_t w;
  
  for(w = 0; w < NO_WORKERS; w ++) {
    result += tbl->size[w];
  }
  return result;
}

void shared_hash_tbl_insert
(shared_hash_tbl_t tbl,
 state_t s,
 shared_hash_tbl_id_t * pred,
 event_id_t * exec,
 unsigned int depth,
 worker_id_t w,
 bool_t * is_new,
 shared_hash_tbl_id_t * id) {
  unsigned int trials = 0;
  vector bits;
  unsigned int i, len;
  hash_key_t h;
  shared_hash_tbl_id_t pos;
  bit_vector_t es;
  hash_compact_t hc, hc_other;

#ifdef HASH_COMPACTION
  hash_compact(s, &hc);
  h = hc.keys[0];
#else
  h = state_hash(s);
#endif
  pos = h % tbl->hash_size;
  
  while(TRUE) {
    if(tbl->status[pos] == BUCKET_EMPTY) {
      if(CAS(&tbl->status[pos], BUCKET_EMPTY, BUCKET_WRITE)) {
        
        /*
         *  encode the state
         */
#ifdef HASH_COMPACTION
        memcpy(&(tbl->state[pos][ATTRIBUTES_CHAR_WIDTH]), &hc,
               sizeof(hash_compact_t));
#else
        len = state_char_width(s) + ATTRIBUTES_CHAR_WIDTH;
        es = mem_alloc(tbl->heaps[w], len);
        for(i = 0; i < len; i ++) {
          es[i] = 0;
        }
        state_serialise(s, es + ATTRIBUTES_CHAR_WIDTH);
        tbl->state[pos] = es;
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
#ifdef HASH_COMPACTION
      memcpy(&hc_other, &(tbl->state[pos][ATTRIBUTES_CHAR_WIDTH]),
             sizeof(hash_compact_t));
      (*is_new) = hash_compact_equal(hc, hc_other)
        ? FALSE : TRUE;
#else
      (*is_new) = state_cmp_vector(s, tbl->state[pos] + ATTRIBUTES_CHAR_WIDTH)
        ? FALSE : TRUE;
#endif
      if(!(*is_new)) {
        (*id) = pos;
        return;
      }
    }
    pos = (pos + 1) % tbl->hash_size;
    if((++ trials) == MAX_TRIALS) {
      raise_error("state table too small (increase --hash-size and rerun)");
      (*is_new) = FALSE;
      return;
    }
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
#ifdef HASH_COMPACTION
  fatal_error("shared_hash_tbl_get_mem disabled by hash compaction");
#else
  result = state_unserialise_mem(tbl->state[id] + ATTRIBUTES_CHAR_WIDTH, heap);
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
  while(!CAS(&tbl->update_status[id], BUCKET_READY, BUCKET_WRITE)) {}
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
#ifdef ATTRIBUTE_CYAN
    shared_hash_tbl_get_attribute(tbl, id, ATTRIBUTE_CYAN_POS + w, 1)
#else
    FALSE
#endif
    ;
}

bool_t shared_hash_tbl_get_blue
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id) {
  return (bool_t)
#ifdef ATTRIBUTE_BLUE
    shared_hash_tbl_get_attribute(tbl, id, ATTRIBUTE_BLUE_POS, 1)
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
#ifdef ATTRIBUTE_PINK
    shared_hash_tbl_get_attribute(tbl, id, ATTRIBUTE_PINK_POS + w, 1)
#else
    FALSE
#endif
    ;
}

bool_t shared_hash_tbl_get_red
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id) {
  return (bool_t)
#ifdef ATTRIBUTE_RED
    shared_hash_tbl_get_attribute(tbl, id, ATTRIBUTE_RED_POS, 1)
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
#ifdef ATTRIBUTE_CYAN
  shared_hash_tbl_set_attribute(tbl, id, ATTRIBUTE_CYAN_POS + w,
                                1, (uint64_t) cyan);
#endif
}

void shared_hash_tbl_set_blue
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 bool_t blue) {
#ifdef ATTRIBUTE_BLUE
  shared_hash_tbl_set_attribute(tbl, id, ATTRIBUTE_BLUE_POS,
                                1, (uint64_t) blue);
#endif
}

void shared_hash_tbl_set_pink
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 worker_id_t w,
 bool_t pink) {
#ifdef ATTRIBUTE_PINK
  shared_hash_tbl_set_attribute(tbl, id, ATTRIBUTE_PINK_POS + w,
                                1, (uint64_t) pink);
#endif
}

void shared_hash_tbl_set_red
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 bool_t red) {
#ifdef ATTRIBUTE_RED
  shared_hash_tbl_set_attribute(tbl, id, ATTRIBUTE_RED_POS,
                                1, (uint64_t) red);
#endif
}

void shared_hash_tbl_update_refs
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 int update) {
  fatal_error("shared_hash_tbl_update_refs: not implemented");
}

void shared_hash_tbl_build_trace
(shared_hash_tbl_t tbl,
 worker_id_t w,
 shared_hash_tbl_id_t id,
 event_t ** trace,
 unsigned int * trace_len) {
  fatal_error("shared_hash_tbl_build_trace: not implemented");
}

void shared_hash_tbl_output_stats
(shared_hash_tbl_t tbl,
 FILE * out) {
  fprintf(out, "<hashTableStatistics>\n");
  fprintf(out, "<stateComparisons>%llu</stateComparisons>\n",
          do_large_sum(tbl->state_cmps, NO_WORKERS));
  fprintf(out, "</hashTableStatistics>\n");
}

void init_shared_hash_tbl
() {
  shared_hash_tbl_id_char_width = sizeof(shared_hash_tbl_id_t);
}

void free_shared_hash_tbl
() {
}
