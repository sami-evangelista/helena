#include "shared_hash_tbl.h"
#include "report.h"
#include "vectors.h"

static const struct timespec SLEEP_TIME = { 0, 2500 };

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
(large_unsigned_t hash_size) {
  large_unsigned_t i = 0;
  shared_hash_tbl_t result;
  worker_id_t w;

  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_shared_hash_tbl_t));
  result->hash_size = hash_size;
  for(w = 0; w < NO_WORKERS; w ++) {
    result->size[w] = 0;
    result->state_cmps[w] = 0;
  }
  for(i = 0; i < result->hash_size; i++) {
    result->status[i] = BUCKET_EMPTY;
    result->state[i] = NULL;
    result->hash[i] = 0;
  }
  return result;

}

shared_hash_tbl_t shared_hash_tbl_default_new
() {
  return shared_hash_tbl_new(HASH_SIZE);
}

void shared_hash_tbl_free
(shared_hash_tbl_t tbl) {
  large_unsigned_t i = 0;
  
  for(i = 0; i < tbl->hash_size; i++) {
    if(tbl->state[i]) {
      mem_free(SYSTEM_HEAP, tbl->state[i]);
    }
  }
  mem_free(SYSTEM_HEAP, tbl);
}

large_unsigned_t shared_hash_tbl_size
(shared_hash_tbl_t tbl) {
  large_unsigned_t result = 0;
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
  hash_key_t h = state_hash(s);
  shared_hash_tbl_id_t pos = h % tbl->hash_size;
  bit_vector_t es;
  
  while(TRUE) {
    if(tbl->status[pos] == BUCKET_EMPTY) {
      if(CAS(&tbl->status[pos], BUCKET_EMPTY, BUCKET_WRITE)) {
        
        /*
         *  encode the state
         */
        len = state_char_width(s) + ATTRIBUTES_CHAR_WIDTH;
        es = mem_alloc(SYSTEM_HEAP, len);
        for(i = 0; i < len; i ++) {
          es[i] = 0;
        }
        state_serialise(s, es + ATTRIBUTES_CHAR_WIDTH);
        
        tbl->hash[pos] = h;
        tbl->state[pos] = es;
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
    if(tbl->hash[pos] == h && tbl->status[pos] == BUCKET_READY) {
      tbl->state_cmps[w] ++;
      if(state_cmp_vector(s, tbl->state[pos] + ATTRIBUTES_CHAR_WIDTH)) {
        (*is_new) = FALSE;
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
  result = state_unserialise_mem(tbl->state[id] + ATTRIBUTES_CHAR_WIDTH, heap);
  return result;
}

void shared_hash_tbl_set_in_unproc
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 bool_t in_unproc) {
  //fatal_error("shared_hash_tbl_set_in_unproc: not implemented");
}

bool_t shared_hash_tbl_get_in_unproc
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id) {
  fatal_error("shared_hash_tbl_get_in_unproc: not implemented");
}

state_num_t shared_hash_tbl_get_num
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id) {
  fatal_error("shared_hash_tbl_get_num: not implemented");
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

void shared_hash_tbl_set_is_red
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id) {
  fatal_error("shared_hash_tbl_set_is_red: not implemented");
}

void shared_hash_tbl_check
(shared_hash_tbl_t tbl) {
  int i, j;
  state_t s1, s2;
  for(i = 0; i < tbl->hash_size; i ++) {
    if(tbl->state[i]) {
      for(j = i + 1; j < tbl->hash_size; j ++) {
        if(tbl->hash[i] == tbl->hash[j]) {
          s1 = shared_hash_tbl_get(tbl, i, 0);
          s2 = shared_hash_tbl_get(tbl, j, 0);
          if(state_equal(s1, s2)) {
            printf("ca chie (%d, %d)\n", i, j);
          }
          state_free(s1);
          state_free(s2);
        }
      }
    }
  }
}

void shared_hash_tbl_output_stats
(shared_hash_tbl_t tbl,
 FILE * out) {
  fprintf(out, "<hashTableStatistics>\n");
  fprintf(out, "<stateComparisons>%llu</stateComparisons>\n",
          do_large_sum(tbl->state_cmps, NO_WORKERS));
  fprintf(out, "</hashTableStatistics>\n");
  
  //  shared_hash_tbl_check(tbl);
}

void init_shared_hash_tbl
() {
  shared_hash_tbl_id_char_width = sizeof(shared_hash_tbl_id_t);
}

void free_shared_hash_tbl
() {
}
