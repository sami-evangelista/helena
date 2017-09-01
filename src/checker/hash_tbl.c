#include "hash_tbl.h"
#include "report.h"
#include "math.h"
#include "vectors.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

#define DELTA_STATE    0
#define EXPLICIT_STATE 1

#define move_to_attribute(bits, pos) {          \
    VECTOR_start (bits);                        \
    VECTOR_move (bits, pos);                    \
  }

#define hash_tbl_id_serialise_bits(id, bits) {  \
    VECTOR_set_size32 ((bits), (id).h);         \
    VECTOR_set_size8 ((bits), (id).p);          \
  }

#define hash_tbl_id_unserialise_bits(bits, id) {        \
    VECTOR_get_size32 ((bits), (id).h);                 \
    VECTOR_get_size8 ((bits), (id).p);                  \
  }

#ifdef HASH_STANDARD
#define hash_tbl_copy_encoded_state(src, dest) { (dest) = (src); }
#else
#define hash_tbl_copy_encoded_state(src, dest) {                        \
    unsigned int cp_idx = 0;                                            \
    for (cp_idx = 0; cp_idx < sizeof (encoded_state_t); cp_idx ++) {    \
      dest[cp_idx] = src[cp_idx];                                       \
    }                                                                   \
  }
#endif



/*****
 *
 *  Function: hash_tbl_id_is_null
 *
 *****/
bool_t hash_tbl_id_is_null
(hash_tbl_id_t id) {
  return
    ((id.h == null_hash_tbl_id.h) && (id.p == null_hash_tbl_id.p)) ?
    TRUE : FALSE;
}



/*****
 *
 *  Function: hash_tbl_id_serialise
 *
 *****/
void hash_tbl_id_serialise
(hash_tbl_id_t id,
 bit_vector_t v) {
  vector bits;
  bits.vector = v;
  VECTOR_start (bits);
  hash_tbl_id_serialise_bits (id, bits);
}



/*****
 *
 *  Function: hash_tbl_id_unserialise
 *
 *****/
hash_tbl_id_t hash_tbl_id_unserialise
(bit_vector_t v) {
  hash_tbl_id_t result;
  vector bits;
  bits.vector = v;
  VECTOR_start (bits);
  hash_tbl_id_unserialise_bits (bits, result);
  return result;
}



/*****
 *
 *  Function: hash_tbl_id_cmp
 *
 *****/
order_t hash_tbl_id_cmp
(hash_tbl_id_t id1,
 hash_tbl_id_t id2) {
  if (id1.h < id2.h) return LESS;
  if (id1.h > id2.h) return GREATER;
  if (id1.p < id2.p) return LESS;
  if (id1.p > id2.p) return GREATER;
  return EQUAL;
}



/*****
 *
 *  Function: hash_tbl_cache_state
 *
 *****/
void hash_tbl_cache_state
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
#ifdef STATE_CACHING
  if (tbl->cache_size < STATE_CACHING_CACHE_SIZE) {
    tbl->cache[tbl->cache_size] = id;
    tbl->cache_size ++;
  } else {
    hash_tbl_id_t to_rem;
#if STATE_CACHING_CACHE_SIZE == 0
    to_rem = id;
#else
    if (0 != tbl->cache_ctr) {
      to_rem = id;
    } else {
      unsigned int rep =
        random_int (&tbl->seed) % STATE_CACHING_CACHE_SIZE;
      to_rem = tbl->cache[rep];
      tbl->cache[rep] = id;
    }
    tbl->cache_ctr = (tbl->cache_ctr + 1) % STATE_CACHING_PROP;      
#endif
    hash_tbl_remove (tbl, to_rem);
  }
#endif
}



/*****
 *
 *  Function: hash_tbl_default_new
 *
 *****/
hash_tbl_t hash_tbl_default_new
() {
  return hash_tbl_new (HASH_SIZE);
}



/*****
 *
 *  Function: hash_tbl_new
 *
 *****/
hash_tbl_t hash_tbl_new
(large_unsigned_t hash_size) {
  int i;
  hash_tbl_t result;
  worker_id_t w;
  char name[100];
  
  result = mem_alloc (SYSTEM_HEAP, sizeof (struct_hash_tbl_t));
  result->hash_size = hash_size;
  for (i = 0; i < result->hash_size; i ++) {
    result->no_states[i] = 0;
    result->states[i] = NULL;
  }
  result->seed = random_seed (0);
#ifdef STATE_CACHING
  result->cache_size = 0;
  result->cache_ctr = 0;
#endif
  for (w = 0; w < NO_WORKERS; w ++) {
    result->state_cmps[w] = 0;
    result->events_executed[w] = 0;
  }
#ifdef HASH_DELTA
  for (w = 0; w < NO_WORKERS; w ++) {
    sprintf (name, "reconstruction heap of worker %d", w);
    result->reconstruction_heaps[w] = bounded_heap_new (name, 1024 * 1024);
  }
#endif
  return result;
}



/*****
 *
 *  Function: hash_tbl_free
 *
 *****/
void hash_tbl_free
(hash_tbl_t tbl) {
  int i, j;
  worker_id_t w;
  bit_vector_t v;
  vector bits;
  unsigned char t;

  for (i = 0; i < tbl->hash_size; i ++) {
    if (tbl->states[i]) {
      for (j = 0; j < tbl->no_states[i]; j ++) {
#if   defined(HASH_STANDARD)
        mem_free (SYSTEM_HEAP, tbl->states[i][j]);
#elif defined(HASH_DELTA)
        bits.vector = tbl->states[i][j];
        move_to_attribute (bits, ATTRIBUTE_TYPE_POS);
        VECTOR_get_size1 (bits, t);
        if (EXPLICIT_STATE == t) {
          memcpy (&v, &bits.vector[ATTRIBUTES_CHAR_WIDTH],
                  sizeof (bit_vector_t));
          mem_free (SYSTEM_HEAP, v);
        }
#endif
      }
      mem_free (SYSTEM_HEAP, tbl->states[i]);
    }
  }
#ifdef HASH_DELTA
  for (w = 0; w < NO_WORKERS; w ++) {
    heap_free (tbl->reconstruction_heaps[w]);
  }
#endif
  mem_free (SYSTEM_HEAP, tbl);
}



/*****
 *
 *  Function: hash_tbl_size
 *
 *****/
large_unsigned_t hash_tbl_size
(hash_tbl_t tbl) {
  large_unsigned_t result = 0;
  unsigned int i = 0;
  for (i = 0; i < tbl->hash_size; i ++) {
    result += (large_unsigned_t) tbl->no_states[i];
  }
  return result;
}



/*****
 *
 *  Function: hash_tbl_get_vector
 *
 *****/
bit_vector_t hash_tbl_get_vector
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  unsigned int slot = id.h % tbl->hash_size, i;
  bit_vector_t result;
  vector bits;
  pos_t p;
  for (i = 0; i < tbl->no_states[slot]; i ++) {
    bits.vector = tbl->states[slot][i];
    VECTOR_start (bits);
    VECTOR_get_size8 (bits, p);
    if (p == id.p) {
      result = tbl->states[slot][i];
      return result;
    }
  }
  return NULL;
}



/*****
 *
 *  Function: hash_tbl_reconstruct_delta_state
 *
 *****/
#ifdef HASH_DELTA

state_t hash_tbl_reconstruct_delta_state
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 heap_t heap);

state_t hash_tbl_reconstruct_delta_state_vec
(hash_tbl_t tbl,
 bit_vector_t v,
 worker_id_t w,
 heap_t heap) {
  state_t result;
  vector bits;
  bool_t found;
  unsigned char t;
  bit_vector_t e;
  hash_tbl_id_t id_pred;
  event_id_t exec;
  event_t ev;

  /*
   *  decode attributes of the state
   */
  bits.vector = v;
  move_to_attribute (bits, ATTRIBUTE_TYPE_POS);
  VECTOR_get_size1(bits, t);

  switch (t) {

    /*
     *  it is an explicit state => simply decode it
     */
  case EXPLICIT_STATE:
    memcpy (&e, v + ATTRIBUTES_CHAR_WIDTH, sizeof (bit_vector_t));
    result = state_unserialise_mem (e, heap);
    break;

    /*
     *  it is a delta state => reconstruct the predecessor and execute
     *  the event
     */
  case DELTA_STATE: {    
    move_to_attribute (bits, ATTRIBUTE_PRED_POS);
    hash_tbl_id_unserialise_bits (bits, id_pred);

    /*
     *  no predecessor => we have reached the initial state.
     *  otherwise, we reconstruct the predecessor, decode the event
     *  and execute it
     */
    if (hash_tbl_id_is_null (id_pred)) {
      result = state_initial_mem (heap);
    } else {
      memcpy (&exec, v + ATTRIBUTES_CHAR_WIDTH, sizeof (event_id_t));
      result = hash_tbl_reconstruct_delta_state (tbl, id_pred,
                                                 w, heap);
      ev = state_enabled_event_mem (result, exec, heap);
      event_exec (ev, result);
      tbl->events_executed[w] ++;
    }
    break;
  }
  default:
    fatal_error
      ("hash_tbl_reconstruct_delta_state_vec: impossible state type");
    break;
  }
  return result;
}

state_t hash_tbl_reconstruct_delta_state
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 heap_t heap) {
  bit_vector_t v = hash_tbl_get_vector (tbl, id);
  if (!v) {
    fatal_error ("hash_tbl_reconstruct_delta_state: could not find state");
  }
  return hash_tbl_reconstruct_delta_state_vec (tbl, v, w, heap);
}
#endif



/*****
 *
 *  Function: hash_tbl_check_state
 *
 *  check if state s is the state encoded in vector v
 *
 *****/
bool_t hash_tbl_check_state
(hash_tbl_t tbl,
 bit_vector_t v,
 state_t s,
 hash_key_t h,
 worker_id_t w) {
#if   defined(HASH_STANDARD)
  return state_cmp_vector (s, v + ATTRIBUTES_CHAR_WIDTH);
#elif defined(HASH_DELTA)
  state_t t;
  bool_t result;
  heap_reset (tbl->reconstruction_heaps[w]);
  t = hash_tbl_reconstruct_delta_state_vec
    (tbl, v, w, tbl->reconstruction_heaps[w]);
  result = state_equal (s, t);
  state_free (t);
  return result;
#elif defined(HASH_COMPACTION)
  hash_key_t k;
  memcpy (&k, v + ATTRIBUTES_CHAR_WIDTH, sizeof (hash_key_t));
  return (k == h) ? TRUE : FALSE;
#endif
}



/*****
 *
 *  Function: hash_tbl_insert
 *
 *****/
void hash_tbl_insert
(hash_tbl_t tbl,
 state_t s,
 hash_tbl_id_t * id_pred,
 event_id_t * exec,
 unsigned int depth,
 worker_id_t w,
 bool_t * is_new,
 hash_tbl_id_t * id) {
  vector bits;
  unsigned int slot; 
  int i, j;
  unsigned char t;
  state_num_t no;
  encoded_state_t * new_states, es;
  unsigned int len;
  bit_vector_t v;
  pos_t pos, new_pos;
  bool_t pos_found = FALSE;

  id->h = state_hash (s);
  slot = id->h % tbl->hash_size;
  *is_new = TRUE;

  /*
   *  look for the state in the slot
   */
  new_pos = tbl->no_states[slot];
  for (i = 0; i < tbl->no_states[slot]; i ++) {
    tbl->state_cmps[w] ++;
    bits.vector = tbl->states[slot][i];
    VECTOR_start (bits);
    VECTOR_get_size8 (bits, pos);
    if (i != pos && (!pos_found)) {
      pos_found = TRUE;
      new_pos = i;
    }
    if (hash_tbl_check_state (tbl, tbl->states[slot][i],
                              s, id->h, w)) {
      id->p = pos;
      *is_new = FALSE;
      break;
    }
  }

  if (*is_new) {
    
    /*
     *  compute the size of the state vector
     */
#if   defined(HASH_STANDARD)
    len = state_char_width (s) + ATTRIBUTES_CHAR_WIDTH;
    es = mem_alloc (SYSTEM_HEAP, len);
    for (j = 0; j < len; j ++) {
      es[j] = 0;
    }
#elif defined(HASH_DELTA)
    t = (depth % HASH_DELTA_K == 0) ? EXPLICIT_STATE : DELTA_STATE;
    if (EXPLICIT_STATE == t) {
      len = state_char_width (s);
      v = mem_alloc (SYSTEM_HEAP, len);
      for (j = 0; j < len; j ++) {
        v[j] = 0;
      }
    }
#endif

    /*
     *  encode attributes of the state
     */
    bits.vector = &es[0];
    id->p = new_pos;
    VECTOR_start (bits);
    VECTOR_set_size8 (bits, new_pos);
#ifdef ATTRIBUTE_CYAN
    move_to_attribute (bits, ATTRIBUTE_CYAN_POS);
    VECTOR_set_size1 (bits, TRUE);
#endif
#ifdef ATTRIBUTE_TYPE
    move_to_attribute (bits, ATTRIBUTE_TYPE_POS);
    VECTOR_set_size1 (bits, t);
#endif
#ifdef ATTRIBUTE_REFS
    move_to_attribute (bits, ATTRIBUTE_REFS_POS);
    VECTOR_set (bits, 1, ATTRIBUTE_REFS_WIDTH);
#endif
#ifdef ATTRIBUTE_PRED
    move_to_attribute (bits, ATTRIBUTE_PRED_POS);
    if (id_pred == NULL) {
      hash_tbl_id_serialise_bits (null_hash_tbl_id, bits);
    } else {
      hash_tbl_id_serialise_bits (*id_pred, bits);
#ifdef ATTRIBUTE_REFS
      hash_tbl_update_refs (tbl, *id_pred, 1);
#endif
    }
#endif
#ifdef ATTRIBUTE_IS_RED
    move_to_attribute (bits, ATTRIBUTE_IS_RED_POS);
    VECTOR_set_size1 (bits, FALSE);
#endif

    /*
     *  encode the state
     */
#if   defined(HASH_STANDARD)
    state_serialise (s, es + ATTRIBUTES_CHAR_WIDTH);
#elif defined(HASH_DELTA)
    if (EXPLICIT_STATE == t) {
      state_serialise (s, v);
      memcpy (es + ATTRIBUTES_CHAR_WIDTH, &v, sizeof (bit_vector_t));
    } else {
      if (id_pred != NULL) {
        memcpy (es + ATTRIBUTES_CHAR_WIDTH, exec, sizeof (event_id_t));
      }
    }
#elif defined(HASH_COMPACTION)
    bits.vector = es + ATTRIBUTES_CHAR_WIDTH;
    memcpy (es + ATTRIBUTES_CHAR_WIDTH, &id->h, sizeof (hash_key_t));
#endif

    /*
     *  and finally replace the slot in the hash table
     */
    new_states =
      mem_alloc (SYSTEM_HEAP,
                 sizeof (encoded_state_t) * (tbl->no_states[slot] + 1));
    for (j = 0; j < new_pos; j ++) {
      hash_tbl_copy_encoded_state (tbl->states[slot][j],
                                   new_states[j]);
    }
    hash_tbl_copy_encoded_state (es, new_states[j]);
    for (; j < tbl->no_states[slot]; j ++) {
      hash_tbl_copy_encoded_state (tbl->states[slot][j],
                                   new_states[j + 1]);
    }
    if (tbl->states[slot]) {
      free (tbl->states[slot]);
    }
    tbl->states[slot] = new_states;
    tbl->no_states[slot] ++;
  }
}



/*****
 *
 *  Function: hash_tbl_remove
 *
 *  removes from tbl the state with specified id
 *
 *****/
void hash_tbl_remove
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  unsigned int slot = id.h % tbl->hash_size, i, j, k;
  vector bits;
  bool_t found = FALSE;
  pos_t p;
  encoded_state_t * new_states;
  hash_tbl_id_t id_pred;
  unsigned char t;
  bit_vector_t v;

  for (i = 0; i < tbl->no_states[slot]; i ++) {
    bits.vector = tbl->states[slot][i];
    VECTOR_start (bits);
    VECTOR_get_size8 (bits, p);
    if (p == id.p) {
#if defined(ATTRIBUTE_REFS) && defined(ATTRIBUTE_PRED)
      id_pred = null_hash_tbl_id;
      move_to_attribute (bits, ATTRIBUTE_PRED_POS);
      hash_tbl_id_unserialise_bits (bits, id_pred);
#endif
      found = TRUE;
#if defined(HASH_STANDARD)
      free (tbl->states[slot][i]);
#elif defined(HASH_DELTA)
      move_to_attribute (bits, ATTRIBUTE_TYPE_POS);
      VECTOR_get_size1 (bits, t);
      if (EXPLICIT_STATE == t) {
        memcpy (&v, bits.vector + ATTRIBUTES_CHAR_WIDTH,
                sizeof (bit_vector_t));
        free (v);
      }
#endif
      tbl->no_states[slot] --;
      if (0 == tbl->no_states[slot]) {
        new_states = NULL;
      }
      else {
        new_states =
          mem_alloc (SYSTEM_HEAP,
                     sizeof (encoded_state_t) * tbl->no_states[slot]);
        k = 0;
        for (j = 0; j <= tbl->no_states[slot]; j ++) {
          if (j != i) {
            hash_tbl_copy_encoded_state (tbl->states[slot][j],
                                         new_states[k]);
            k ++;
          }
        }
      }
      free (tbl->states[slot]);
      tbl->states[slot] = new_states;
#if defined(ATTRIBUTE_REFS) && defined(ATTRIBUTE_PRED)
      if (!hash_tbl_id_is_null (id_pred)) {
        hash_tbl_update_refs (tbl, id_pred, -1);
      }
#endif
      break;
    }
  }
  if (!found) {
    fatal_error ("tbl_remove could not find state");
  }
}



/*****
 *
 *  Function: hash_tbl_get
 *
 *  get from tbl the state with specified id
 *
 *****/
state_t hash_tbl_get_mem
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 heap_t heap) {
  state_t result;
  bit_vector_t v;
  
#if   defined(HASH_COMPACTION)
  fatal_error ("tbl_get impossible with hash-compaction");
  return NULL;
#elif defined(HASH_STANDARD)
  if ((v = hash_tbl_get_vector (tbl, id)) == NULL) {
    fatal_error ("hash_tbl_get_mem: could not find state");
  }
  else {
    result = state_unserialise_mem (v + ATTRIBUTES_CHAR_WIDTH, heap);
  }
#elif defined(HASH_DELTA)
  result = hash_tbl_reconstruct_delta_state (tbl, id, w, heap);
#endif
  return result;
}

state_t hash_tbl_get
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w) {
  return hash_tbl_get_mem (tbl, id, w, SYSTEM_HEAP);
}



/*****
 *
 *  Function: hash_tbl_set_cyan
 *
 *****/
void hash_tbl_set_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 bool_t cyan) {
#ifdef ATTRIBUTE_CYAN
  bit_vector_t v;
  vector bits;
  if ((v = hash_tbl_get_vector (tbl, id)) == NULL) {
    fatal_error ("hash_tbl_set_cyan could not find state");
  }
  bits.vector = v;
  move_to_attribute (bits, ATTRIBUTE_CYAN_POS);
  VECTOR_set_size1 (bits, cyan);
  if (!cyan) {
#ifdef ATTRIBUTE_REFS
    hash_tbl_update_refs (tbl, id, -1);
#elif defined (STATE_CACHING)
    hash_tbl_cache_state (tbl, id);
#endif
  }
#endif
}



/*****
 *
 *  Function: hash_tbl_get_cyan
 *
 *****/
bool_t hash_tbl_get_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w) {
#ifdef ATTRIBUTE_CYAN
  bool_t result;
  bit_vector_t v;
  vector bits;
  if ((v = hash_tbl_get_vector (tbl, id)) == NULL) {
    fatal_error ("hash_tbl_get_cyan: could not find state");
  }
  bits.vector = v;
  move_to_attribute (bits, ATTRIBUTE_CYAN_POS);
  VECTOR_get_size1 (bits, result);
  result = result ? TRUE : FALSE;
  return result;
#else
  return FALSE;
#endif
}



/*****
 *
 *  Function: hash_tbl_update_refs
 *
 *  add update to the reference counter of state with identifier id
 *
 *****/
void hash_tbl_update_refs
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 int update) {
#ifdef ATTRIBUTE_REFS
  if (hash_tbl_id_is_null (id)) {
    return;
  }
  bit_vector_t v;
  vector bits;
  int refs;
  if ((v = hash_tbl_get_vector (tbl, id)) == NULL) {
    fatal_error ("hash_tbl_update_refs: could not find state");
  }
  bits.vector = v;
  move_to_attribute (bits, ATTRIBUTE_REFS_POS);
  VECTOR_get (bits, refs, ATTRIBUTE_REFS_WIDTH);
  refs += update;
  move_to_attribute (bits, ATTRIBUTE_REFS_POS);
  VECTOR_set (bits, refs, ATTRIBUTE_REFS_WIDTH);
  if (refs < 0) {
    fatal_error ("hash_tbl_update_refs: negative reference counter");
  }
  
#ifdef STATE_CACHING
  if (refs == 0) {
    hash_tbl_cache_state (tbl, id);
  }
#endif
#endif
}



/*****
 *
 *  Function: hash_tbl_get_red
 *
 *****/
bool_t hash_tbl_get_red
(hash_tbl_t tbl,
 hash_tbl_id_t id) {
  bool_t result = FALSE;
#ifdef ATTRIBUTE_IS_RED
  bit_vector_t v;
  vector bits;
  if ((v = hash_tbl_get_vector (tbl, id)) == NULL) {
    fatal_error ("hash_tbl_set_is_red could not find state");
  }
  bits.vector = v;
  move_to_attribute (bits, ATTRIBUTE_IS_RED_POS);
  VECTOR_get_size1 (bits, result);
#endif
  return result;
}



/*****
 *
 *  Function: hash_tbl_set_red
 *
 *****/
void hash_tbl_set_red
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t red) {
#ifdef ATTRIBUTE_IS_RED
  bit_vector_t v;
  vector bits;
  if ((v = hash_tbl_get_vector (tbl, id)) == NULL) {
    fatal_error ("hash_tbl_set_is_red could not find state");
  }
  bits.vector = v;
  move_to_attribute (bits, ATTRIBUTE_IS_RED_POS);
  VECTOR_set_size1 (bits, red);
#endif
}



/*****
 *
 *  Function: hash_tbl_lookup
 *
 *****/
void hash_tbl_lookup
(hash_tbl_t tbl,
 state_t s,
 worker_id_t w,
 bool_t * found,
 hash_tbl_id_t * id) {
  unsigned int i, slot;
  vector bits;

  id->h = state_hash (s);
  slot = id->h % tbl->hash_size;
  *found = FALSE;

  /*
   *  look for the state in the slot
   */
  for (i = 0; i < tbl->no_states[slot]; i ++) {
    tbl->state_cmps[w] ++;
    if (hash_tbl_check_state (tbl, tbl->states[slot][i], s, id->h, w)) {
      bits.vector = tbl->states[slot][i];
      VECTOR_start (bits);
      VECTOR_get_size8 (bits, id->p);
      *found = TRUE;
      break;
    }
  }
}



/*****
 *
 *  Function: hash_tbl_build_trace
 *
 *****/
void hash_tbl_build_trace
(hash_tbl_t tbl,
 worker_id_t w,
 hash_tbl_id_t id,
 event_t ** trace,
 unsigned int * trace_len) {
#ifndef ATTRIBUTE_PRED
  fatal_error ("hash_tbl_build_trace: unable to reconstruct trace");
#else
  fatal_error ("hash_tbl_build_trace: unimplemented feature");
#endif
}



/*****
 *
 *  Function: hash_tbl_fold
 *
 *****/
void hash_tbl_fold
(hash_tbl_t tbl,
 worker_id_t w,
 hash_tbl_fold_func_t f,
 void * data) {
  hash_tbl_id_t id;
  uint32_t i, j;
  state_t s;
  heap_t heap = bounded_heap_new ("fold heap", 1048576);
  vector bits;
  for (i = 0; i < tbl->hash_size; i ++) {
    id.h = i;
    for (j = 0; j < tbl->no_states[i]; j ++) {
      bits.vector = tbl->states[i][j];
      VECTOR_start (bits);
      VECTOR_get_size8 (bits, id.p);
      heap_reset (heap);
      s = hash_tbl_get_mem (tbl, id, w, heap);
      (*f) (s, id, data);
    }
  }
  heap_free (heap);
}

void hash_tbl_output_stats
(hash_tbl_t tbl,
 FILE * out) {
  fprintf (out, "<hashTableStatistics>\n");
  fprintf (out, "<stateComparisons>%llu</stateComparisons>\n",
           do_large_sum (tbl->state_cmps, NO_WORKERS));
#ifdef HASH_DELTA
  fprintf (out, "<eventsExecutedDelta>%llu</eventsExecutedDelta>\n",
           do_large_sum (tbl->events_executed, NO_WORKERS));
#endif
  fprintf (out, "</hashTableStatistics>\n");
}



void init_hash_tbl () {
  null_hash_tbl_id.h = 0;
  null_hash_tbl_id.p = 0xff;
  hash_tbl_id_char_width = sizeof (hash_tbl_id_t);
}

void free_hash_tbl () {
}
