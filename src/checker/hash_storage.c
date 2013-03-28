#include "hash_storage.h"
#include "report.h"
#include "math.h"
#include "vectors.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

#define DELTA_STATE    0
#define EXPLICIT_STATE 1

#define move_to_attribute(bits, pos) { \
    VECTOR_start (bits);	       \
    VECTOR_move (bits, pos);	       \
  }

#define hash_storage_id_serialise_bits(id, bits) {	\
    VECTOR_set_size32 ((bits), (id).h);			\
    VECTOR_set_size8 ((bits), (id).p);			\
  }

#define hash_storage_id_unserialise_bits(bits, id) {	\
    VECTOR_get_size32 ((bits), (id).h);			\
    VECTOR_get_size8 ((bits), (id).p);			\
}

#ifdef STORAGE_HASH
#define hash_storage_copy_encoded_state(src, dest) { (dest) = (src); }
#else
#define hash_storage_copy_encoded_state(src, dest) {			\
    unsigned int cp_idx = 0;						\
    for (cp_idx = 0; cp_idx < sizeof (encoded_state_t); cp_idx ++) {	\
      dest[cp_idx] = src[cp_idx];					\
    }									\
  }
#endif



/*****
 *
 *  Function: hash_storage_id_is_null
 *
 *****/
bool_t hash_storage_id_is_null
(hash_storage_id_t id) {
  return
    ((id.h == null_hash_storage_id.h) && (id.p == null_hash_storage_id.p)) ?
    TRUE : FALSE;
}



/*****
 *
 *  Function: hash_storage_id_serialise
 *
 *****/
void hash_storage_id_serialise
(hash_storage_id_t id,
 bit_vector_t      v) {
  vector bits;
  bits.vector = v;
  VECTOR_start (bits);
  hash_storage_id_serialise_bits (id, bits);
}



/*****
 *
 *  Function: hash_storage_id_unserialise
 *
 *****/
hash_storage_id_t hash_storage_id_unserialise
(bit_vector_t v) {
  hash_storage_id_t result;
  vector bits;
  bits.vector = v;
  VECTOR_start (bits);
  hash_storage_id_unserialise_bits (bits, result);
  return result;
}



/*****
 *
 *  Function: hash_storage_id_cmp
 *
 *****/
order_t hash_storage_id_cmp
(hash_storage_id_t id1,
 hash_storage_id_t id2) {
  if (id1.h < id2.h) return LESS;
  if (id1.h > id2.h) return GREATER;
  if (id1.p < id2.p) return LESS;
  if (id1.p > id2.p) return GREATER;
  return EQUAL;
}



/*****
 *
 *  Function: hash_storage_cache_state
 *
 *****/
void hash_storage_cache_state
(hash_storage_t    storage,
 hash_storage_id_t id) {
#ifdef STATE_CACHING
  if (storage->cache_size < STATE_CACHING_CACHE_SIZE) {
    storage->cache[storage->cache_size] = id;
    storage->cache_size ++;
  } else {
    hash_storage_id_t to_rem;
#if STATE_CACHING_CACHE_SIZE == 0
    to_rem = id;
#else
    if (0 != storage->cache_ctr) {
      to_rem = id;
    } else {
      unsigned int rep =
	random_int (&storage->seed) % STATE_CACHING_CACHE_SIZE;
      to_rem = storage->cache[rep];
      storage->cache[rep] = id;
    }
    storage->cache_ctr = (storage->cache_ctr + 1) % STATE_CACHING_PROP;      
#endif
    hash_storage_remove (storage, to_rem);
  }
#endif
}



/*****
 *
 *  Function: hash_storage_default_new
 *
 *****/
hash_storage_t hash_storage_default_new
() {
  return hash_storage_new (HASH_SIZE);
}



/*****
 *
 *  Function: hash_storage_new
 *
 *****/
hash_storage_t hash_storage_new
(large_unsigned_t hash_size) {
  int i;
  hash_storage_t result;
  worker_id_t w;
  char name[100];
  
  result = mem_alloc (SYSTEM_HEAP, sizeof (struct_hash_storage_t));
  result->hash_size = hash_size;
  for (i = 0; i < result->hash_size; i ++) {
    result->no_states[i] = 0;
    result->states[i] = NULL;
  }
  result->state_next_num = 0;
  result->seed = random_seed (0);
#ifdef STATE_CACHING
  result->cache_size = 0;
  result->cache_ctr = 0;
#endif
  for (w = 0; w < NO_WORKERS; w ++) {
    result->state_cmps[w] = 0;
    result->events_executed[w] = 0;
  }
#ifdef STORAGE_DELTA
  for (w = 0; w < NO_WORKERS; w ++) {
    sprintf (name, "reconstruction heap of worker %d", w);
    result->reconstruction_heaps[w] = bounded_heap_new (name, 1024 * 1024);
  }
#endif
  return result;
}



/*****
 *
 *  Function: hash_storage_free
 *
 *****/
void hash_storage_free
(hash_storage_t storage) {
  int i, j;
  worker_id_t w;
  bit_vector_t v;
  vector bits;
  unsigned char t;

  for (i = 0; i < storage->hash_size; i ++) {
    if (storage->states[i]) {
      for (j = 0; j < storage->no_states[i]; j ++) {
#if   defined(STORAGE_HASH)
	mem_free (SYSTEM_HEAP, storage->states[i][j]);
#elif defined(STORAGE_DELTA)
	bits.vector = storage->states[i][j];
	move_to_attribute (bits, ATTRIBUTE_TYPE_POS);
	VECTOR_get_size1 (bits, t);
	if (EXPLICIT_STATE == t) {
	  memcpy (&v, &bits.vector[ATTRIBUTES_CHAR_WIDTH],
		  sizeof (bit_vector_t));
	  mem_free (SYSTEM_HEAP, v);
	}
#endif
      }
      mem_free (SYSTEM_HEAP, storage->states[i]);
    }
  }
#ifdef STORAGE_DELTA
  for (w = 0; w < NO_WORKERS; w ++) {
    heap_free (storage->reconstruction_heaps[w]);
  }
#endif
  mem_free (SYSTEM_HEAP, storage);
}



/*****
 *
 *  Function: hash_storage_size
 *
 *****/
large_unsigned_t hash_storage_size
(hash_storage_t storage) {
  large_unsigned_t result = 0;
  unsigned int i = 0;
  for (i = 0; i < storage->hash_size; i ++) {
    result += (large_unsigned_t) storage->no_states[i];
  }
  return result;
}



/*****
 *
 *  Function: hash_storage_get_vector
 *
 *****/
bit_vector_t hash_storage_get_vector
(hash_storage_t    storage,
 hash_storage_id_t id) {
  unsigned int slot = id.h % storage->hash_size, i;
  bit_vector_t result;
  vector bits;
  pos_t p;
  for (i = 0; i < storage->no_states[slot]; i ++) {
    bits.vector = storage->states[slot][i];
    VECTOR_start (bits);
    VECTOR_get_size8 (bits, p);
    if (p == id.p) {
      result = storage->states[slot][i];
      return result;
    }
  }
  return NULL;
}



/*****
 *
 *  Function: hash_storage_reconstruct_delta_state
 *
 *****/
#ifdef STORAGE_DELTA

state_t hash_storage_reconstruct_delta_state
(hash_storage_t    storage,
 hash_storage_id_t id,
 worker_id_t       w,
 heap_t            heap);

state_t hash_storage_reconstruct_delta_state_vec
(hash_storage_t storage,
 bit_vector_t   v,
 worker_id_t    w,
 heap_t         heap) {
  state_t result;
  vector bits;
  bool_t found;
  unsigned char t;
  bit_vector_t e;
  hash_storage_id_t id_pred;
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
    hash_storage_id_unserialise_bits (bits, id_pred);

    /*
     *  no predecessor => we have reached the initial state.
     *  otherwise, we reconstruct the predecessor, decode the event
     *  and execute it
     */
    if (hash_storage_id_is_null (id_pred)) {
      result = state_initial_mem (heap);
    } else {
      memcpy (&exec, v + ATTRIBUTES_CHAR_WIDTH, sizeof (event_id_t));
      result = hash_storage_reconstruct_delta_state (storage, id_pred,
						     w, heap);
      ev = state_enabled_event_mem (result, exec, heap);
      event_exec (ev, result);
      storage->events_executed[w] ++;
    }
    break;
  }
  default:
    fatal_error
      ("hash_storage_reconstruct_delta_state_vec: impossible state type");
    break;
  }
  return result;
}

state_t hash_storage_reconstruct_delta_state
(hash_storage_t    storage,
 hash_storage_id_t id,
 worker_id_t       w,
 heap_t            heap) {
  bit_vector_t v = hash_storage_get_vector (storage, id);
  if (!v) {
    fatal_error ("hash_storage_reconstruct_delta_state: could not find state");
  }
  return hash_storage_reconstruct_delta_state_vec (storage, v, w, heap);
}
#endif



/*****
 *
 *  Function: hash_storage_check_state
 *
 *  check if state s is the state encoded in vector v
 *
 *****/
bool_t hash_storage_check_state
(hash_storage_t storage,
 bit_vector_t   v,
 state_t        s,
 hash_key_t     h,
 worker_id_t    w) {
#if   defined(STORAGE_HASH)
  return state_cmp_vector (s, v + ATTRIBUTES_CHAR_WIDTH);
#elif defined(STORAGE_DELTA)
  state_t t;
  bool_t result;
  heap_reset (storage->reconstruction_heaps[w]);
  t = hash_storage_reconstruct_delta_state_vec
    (storage, v, w, storage->reconstruction_heaps[w]);
  result = state_equal (s, t);
  state_free (t);
  return result;
#elif defined(STORAGE_HASH_COMPACTION)
  hash_key_t k;
  memcpy (&k, v + ATTRIBUTES_CHAR_WIDTH, sizeof (hash_key_t));
  return (k == h) ? TRUE : FALSE;
#endif
}



/*****
 *
 *  Function: hash_storage_insert
 *
 *****/
void hash_storage_insert
(hash_storage_t      storage,
 state_t             s,
 hash_storage_id_t * id_pred,
 event_id_t *        exec,
 unsigned int        depth,
 worker_id_t         w,
 bool_t *            is_new,
 hash_storage_id_t * id) {
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
  slot = id->h % storage->hash_size;
  *is_new = TRUE;

  /*
   *  look for the state in the slot
   */
  new_pos = storage->no_states[slot];
  for (i = 0; i < storage->no_states[slot]; i ++) {
    storage->state_cmps[w] ++;
    bits.vector = storage->states[slot][i];
    VECTOR_start (bits);
    VECTOR_get_size8 (bits, pos);
    if (i != pos && (!pos_found)) {
      pos_found = TRUE;
      new_pos = i;
    }
    if (hash_storage_check_state (storage, storage->states[slot][i],
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
#if   defined(STORAGE_HASH)
    len = state_char_width (s) + ATTRIBUTES_CHAR_WIDTH;
    es = mem_alloc (SYSTEM_HEAP, len);
    for (j = 0; j < len; j ++) {
      es[j] = 0;
    }
#elif defined(STORAGE_DELTA)
    t = (depth % STORAGE_DELTA_K == 0) ? EXPLICIT_STATE : DELTA_STATE;
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
#ifdef ATTRIBUTE_NUM
    move_to_attribute (bits, ATTRIBUTE_NUM_POS);
    no = storage->state_next_num;
    storage->state_next_num ++;
    VECTOR_set_size32 (bits, no);
#endif
#ifdef ATTRIBUTE_IN_UNPROC
    move_to_attribute (bits, ATTRIBUTE_IN_UNPROC_POS);
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
      hash_storage_id_serialise_bits (null_hash_storage_id, bits);
    } else {
      hash_storage_id_serialise_bits (*id_pred, bits);
#ifdef ATTRIBUTE_REFS
      hash_storage_update_refs (storage, *id_pred, 1);
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
#if   defined(STORAGE_HASH)
    state_serialise (s, es + ATTRIBUTES_CHAR_WIDTH);
#elif defined(STORAGE_DELTA)
    if (EXPLICIT_STATE == t) {
      state_serialise (s, v);
      memcpy (es + ATTRIBUTES_CHAR_WIDTH, &v, sizeof (bit_vector_t));
    } else {
      if (id_pred != NULL) {
	memcpy (es + ATTRIBUTES_CHAR_WIDTH, exec, sizeof (event_id_t));
      }
    }
#elif defined(STORAGE_HASH_COMPACTION)
    bits.vector = es + ATTRIBUTES_CHAR_WIDTH;
    memcpy (es + ATTRIBUTES_CHAR_WIDTH, &id->h, sizeof (hash_key_t));
#endif

    /*
     *  and finally replace the slot in the hash table
     */
    new_states =
      mem_alloc (SYSTEM_HEAP,
		 sizeof (encoded_state_t) * (storage->no_states[slot] + 1));
    for (j = 0; j < new_pos; j ++) {
      hash_storage_copy_encoded_state (storage->states[slot][j],
				       new_states[j]);
    }
    hash_storage_copy_encoded_state (es, new_states[j]);
    for (; j < storage->no_states[slot]; j ++) {
      hash_storage_copy_encoded_state (storage->states[slot][j],
				       new_states[j + 1]);
    }
    if (storage->states[slot]) {
      free (storage->states[slot]);
    }
    storage->states[slot] = new_states;
    storage->no_states[slot] ++;
  }
}



/*****
 *
 *  Function: hash_storage_remove
 *
 *  removes from storage the state with specified id
 *
 *****/
void hash_storage_remove
(hash_storage_t    storage,
 hash_storage_id_t id) {
  unsigned int slot = id.h % storage->hash_size, i, j, k;
  vector bits;
  bool_t found = FALSE;
  pos_t p;
  encoded_state_t * new_states;
  hash_storage_id_t id_pred;
  unsigned char t;
  bit_vector_t v;

  for (i = 0; i < storage->no_states[slot]; i ++) {
    bits.vector = storage->states[slot][i];
    VECTOR_start (bits);
    VECTOR_get_size8 (bits, p);
    if (p == id.p) {
#if defined(ATTRIBUTE_REFS) && defined(ATTRIBUTE_PRED)
      id_pred = null_hash_storage_id;
      move_to_attribute (bits, ATTRIBUTE_PRED_POS);
      hash_storage_id_unserialise_bits (bits, id_pred);
#endif
      found = TRUE;
#if defined(STORAGE_HASH)
      free (storage->states[slot][i]);
#elif defined(STORAGE_DELTA)
      move_to_attribute (bits, ATTRIBUTE_TYPE_POS);
      VECTOR_get_size1 (bits, t);
      if (EXPLICIT_STATE == t) {
	memcpy (&v, bits.vector + ATTRIBUTES_CHAR_WIDTH,
		sizeof (bit_vector_t));
	free (v);
      }
#endif
      storage->no_states[slot] --;
      if (0 == storage->no_states[slot]) {
	new_states = NULL;
      }
      else {
	new_states =
	  mem_alloc (SYSTEM_HEAP,
		     sizeof (encoded_state_t) * storage->no_states[slot]);
	k = 0;
	for (j = 0; j <= storage->no_states[slot]; j ++) {
	  if (j != i) {
	    hash_storage_copy_encoded_state (storage->states[slot][j],
					     new_states[k]);
	    k ++;
	  }
	}
      }
      free (storage->states[slot]);
      storage->states[slot] = new_states;
#if defined(ATTRIBUTE_REFS) && defined(ATTRIBUTE_PRED)
      if (!hash_storage_id_is_null (id_pred)) {
	hash_storage_update_refs (storage, id_pred, -1);
      }
#endif
      break;
    }
  }
  if (!found) {
    fatal_error ("storage_remove could not find state");
  }
}



/*****
 *
 *  Function: hash_storage_get
 *
 *  get from storage the state with specified id
 *
 *****/
state_t hash_storage_get_mem
(hash_storage_t    storage,
 hash_storage_id_t id,
 worker_id_t       w,
 heap_t            heap) {
  state_t result;
  bit_vector_t v;
  
#if   defined(STORAGE_HASH_COMPACTION)
  fatal_error ("storage_get impossible with hash-compaction");
  return NULL;
#elif defined(STORAGE_HASH)
  if ((v = hash_storage_get_vector (storage, id)) == NULL) {
    fatal_error ("hash_storage_get_mem: could not find state");
  }
  else {
    result = state_unserialise_mem (v + ATTRIBUTES_CHAR_WIDTH, heap);
  }
#elif defined(STORAGE_DELTA)
  result = hash_storage_reconstruct_delta_state (storage, id, w, heap);
#endif
  return result;
}

state_t hash_storage_get
(hash_storage_t    storage,
 hash_storage_id_t id,
 worker_id_t       w) {
  return hash_storage_get_mem (storage, id, w, SYSTEM_HEAP);
}



/*****
 *
 *  Function: hash_storage_set_in_unproc
 *
 *****/
void hash_storage_set_in_unproc
(hash_storage_t    storage,
 hash_storage_id_t id,
 bool_t            in_unproc) {
#ifdef ATTRIBUTE_IN_UNPROC
  bit_vector_t v;
  vector bits;
  if ((v = hash_storage_get_vector (storage, id)) == NULL) {
    fatal_error ("hash_storage_set_in_unproc could not find state");
  }
  bits.vector = v;
  move_to_attribute (bits, ATTRIBUTE_IN_UNPROC_POS);
  VECTOR_set_size1 (bits, in_unproc);
  if (!in_unproc) {
#ifdef ATTRIBUTE_REFS
    hash_storage_update_refs (storage, id, -1);
#elif defined (STATE_CACHING)
    hash_storage_cache_state (storage, id);
#endif
  }
#endif
}



/*****
 *
 *  Function: hash_storage_get_in_unproc
 *
 *****/
bool_t hash_storage_get_in_unproc
(hash_storage_t    storage,
 hash_storage_id_t id) {
#ifdef ATTRIBUTE_IN_UNPROC
  bool_t result;
  bit_vector_t v;
  vector bits;
  if ((v = hash_storage_get_vector (storage, id)) == NULL) {
    fatal_error ("hash_storage_get_in_unproc: could not find state");
  }
  bits.vector = v;
  move_to_attribute (bits, ATTRIBUTE_IN_UNPROC_POS);
  VECTOR_get_size1 (bits, result);
  result = result ? TRUE : FALSE;
  return result;
#else
  return FALSE;
#endif
}



/*****
 *
 *  Function: hash_storage_get_num
 *
 *****/
state_num_t hash_storage_get_num
(hash_storage_t    storage,
 hash_storage_id_t id) {
#ifdef ATTRIBUTE_NUM
  state_num_t result;
  bit_vector_t v;
  vector bits;
  if ((v = hash_storage_get_vector (storage, id)) == NULL) {
    fatal_error ("hash_storage_get_num: could not find state");
  }
  bits.vector = v;
  move_to_attribute (bits, ATTRIBUTE_NUM_POS);
  VECTOR_get_size32 (bits, result);
  return result;
#else
  return 0;
#endif
}



/*****
 *
 *  Function: hash_storage_update_refs
 *
 *  add update to the reference counter of state with identifier id
 *
 *****/
void hash_storage_update_refs
(hash_storage_t    storage,
 hash_storage_id_t id,
 int               update) {
#ifdef ATTRIBUTE_REFS
  if (hash_storage_id_is_null (id)) {
    return;
  }
  bit_vector_t v;
  vector bits;
  int refs;
  if ((v = hash_storage_get_vector (storage, id)) == NULL) {
    fatal_error ("hash_storage_update_refs: could not find state");
  }
  bits.vector = v;
  move_to_attribute (bits, ATTRIBUTE_REFS_POS);
  VECTOR_get (bits, refs, ATTRIBUTE_REFS_WIDTH);
  refs += update;
  move_to_attribute (bits, ATTRIBUTE_REFS_POS);
  VECTOR_set (bits, refs, ATTRIBUTE_REFS_WIDTH);
  if (refs < 0) {
    fatal_error ("hash_storage_update_refs: negative reference counter");
  }
  
#ifdef STATE_CACHING
  if (refs == 0) {
    hash_storage_cache_state (storage, id);
  }
#endif
#endif
}



/*****
 *
 *  Function: hash_storage_set_is_red
 *
 *****/
void hash_storage_set_is_red
(hash_storage_t    storage,
 hash_storage_id_t id) {
#ifdef ATTRIBUTE_IS_RED
  bit_vector_t v;
  vector bits;
  if ((v = hash_storage_get_vector (storage, id)) == NULL) {
    fatal_error ("hash_storage_set_is_red could not find state");
  }
  bits.vector = v;
  move_to_attribute (bits, ATTRIBUTE_IS_RED_POS);
  VECTOR_set_size1 (bits, TRUE);
#endif
}



/*****
 *
 *  Function: hash_storage_get_attr
 *
 *  get the attributes of state with identifier id
 *
 *****/
void hash_storage_get_attr
(hash_storage_t              storage,
 state_t                     s,
 worker_id_t                 w,
 bool_t *                    found,
 hash_storage_id_t *         id,
 hash_storage_state_attr_t * attrs) {
  unsigned int i, slot;
  vector bits;

  id->h = state_hash (s);
  slot = id->h % storage->hash_size;
  *found = FALSE;

  /*
   *  look for the state in the slot
   */
  for (i = 0; i < storage->no_states[slot]; i ++) {
    storage->state_cmps[w] ++;
    if (hash_storage_check_state (storage, storage->states[slot][i],
				  s, id->h, w)) {
      bits.vector = storage->states[slot][i];
      VECTOR_start (bits);
      VECTOR_get_size8 (bits, id->p);
      *found = TRUE;
      break;
    }
  }

  if (*found) {
#ifdef ATTRIBUTE_NUM
    move_to_attribute (bits, ATTRIBUTE_NUM_POS);
    VECTOR_get_size32 (bits, attrs->num);
#endif
#ifdef ATTRIBUTE_IN_UNPROC
    move_to_attribute (bits, ATTRIBUTE_IN_UNPROC_POS);
    VECTOR_get_size1 (bits, attrs->in_unproc);
#endif
#ifdef ATTRIBUTE_REFS
    move_to_attribute (bits, ATTRIBUTE_REFS_POS);
    VECTOR_get (bits, attrs->refs, ATTRIBUTE_REFS_WIDTH);
#endif
#ifdef ATTRIBUTE_PRED
    move_to_attribute (bits, ATTRIBUTE_PRED_POS);
    hash_storage_id_unserialise_bits (bits, attrs->pred);
#endif
#ifdef ATTRIBUTE_IS_RED
    move_to_attribute (bits, ATTRIBUTE_IS_RED_POS);
    VECTOR_get_size1 (bits, attrs->is_red);
#endif
  }
}



/*****
 *
 *  Function: hash_storage_build_trace
 *
 *****/
void hash_storage_build_trace
(hash_storage_t    storage,
 worker_id_t       w,
 hash_storage_id_t id,
 event_t **        trace,
 unsigned int *    trace_len) {
#ifndef ATTRIBUTE_PRED
  fatal_error ("hash_storage_build_trace: unable to reconstruct trace");
#else
  fatal_error ("hash_storage_build_trace: unimplemented feature");
#endif
}



/*****
 *
 *  Function: hash_storage_fold
 *
 *****/
void hash_storage_fold
(hash_storage_t           storage,
 worker_id_t              w,
 hash_storage_fold_func_t f,
 void *                   data) {
  hash_storage_id_t id;
  uint32_t i, j;
  state_t s;
  heap_t heap = bounded_heap_new ("fold heap", 1048576);
  vector bits;
  for (i = 0; i < storage->hash_size; i ++) {
    id.h = i;
    for (j = 0; j < storage->no_states[i]; j ++) {
      bits.vector = storage->states[i][j];
      VECTOR_start (bits);
      VECTOR_get_size8 (bits, id.p);
      heap_reset (heap);
      s = hash_storage_get_mem (storage, id, w, heap);
      (*f) (s, id, data);
    }
  }
  heap_free (heap);
}

void hash_storage_output_stats
(hash_storage_t   storage,
 FILE           * out) {
  fprintf (out, "<hashTableStatistics>\n");
  fprintf (out, "<stateComparisons>%llu</stateComparisons>\n",
	   do_large_sum (storage->state_cmps, NO_WORKERS));
#ifdef STORAGE_DELTA
  fprintf (out, "<eventsExecutedDelta>%llu</eventsExecutedDelta>\n",
	   do_large_sum (storage->events_executed, NO_WORKERS));
#endif
  fprintf (out, "</hashTableStatistics>\n");
}



void init_hash_storage () {
  null_hash_storage_id.h = 0;
  null_hash_storage_id.p = 0xff;
  hash_storage_id_char_width = sizeof (hash_storage_id_t);
}

void free_hash_storage () {
}
