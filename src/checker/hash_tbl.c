#include "hash_tbl.h"
#include "math.h"
#include "vectors.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

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

#ifdef CFG_HASH_COMPACTION
#define hash_tbl_copy_encoded_state(src, dest) {                        \
    unsigned int cp_idx = 0;                                            \
    for (cp_idx = 0; cp_idx < sizeof (encoded_state_t); cp_idx ++) {    \
      dest[cp_idx] = src[cp_idx];                                       \
    }                                                                   \
  }
#else
#define hash_tbl_copy_encoded_state(src, dest) { (dest) = (src); }
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
#ifdef CFG_STATE_CACHING
  if (tbl->cache_size < CFG_STATE_CACHING_CACHE_SIZE) {
    tbl->cache[tbl->cache_size] = id;
    tbl->cache_size ++;
  } else {
    hash_tbl_id_t to_rem;
#if CFG_STATE_CACHING_CACHE_SIZE == 0
    to_rem = id;
#else
    if (0 != tbl->cache_ctr) {
      to_rem = id;
    } else {
      unsigned int rep =
        random_int (&tbl->seed) % CFG_STATE_CACHING_CACHE_SIZE;
      to_rem = tbl->cache[rep];
      tbl->cache[rep] = id;
    }
    tbl->cache_ctr = (tbl->cache_ctr + 1) % CFG_STATE_CACHING_PROP;      
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
  return hash_tbl_new (CFG_HASH_SIZE);
}



/*****
 *
 *  Function: hash_tbl_new
 *
 *****/
hash_tbl_t hash_tbl_new
(uint64_t hash_size) {
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
#ifdef CFG_STATE_CACHING
  result->cache_size = 0;
  result->cache_ctr = 0;
#endif
  for (w = 0; w < CFG_NO_WORKERS; w ++) {
    result->state_cmps[w] = 0;
  }
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
#if !defined(CFG_HASH_COMPACTION)
        mem_free (SYSTEM_HEAP, tbl->states[i][j]);
#endif
      }
      mem_free (SYSTEM_HEAP, tbl->states[i]);
    }
  }
  mem_free (SYSTEM_HEAP, tbl);
}



/*****
 *
 *  Function: hash_tbl_size
 *
 *****/
uint64_t hash_tbl_size
(hash_tbl_t tbl) {
  uint64_t result = 0;
  unsigned int i = 0;
  for (i = 0; i < tbl->hash_size; i ++) {
    result += (uint64_t) tbl->no_states[i];
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
#if defined(CFG_HASH_COMPACTION)
  hash_key_t k;
  memcpy (&k, v + CFG_ATTRIBUTES_CHAR_WIDTH, sizeof (hash_key_t));
  return (k == h) ? TRUE : FALSE;
#else
  return state_cmp_vector (s, v + CFG_ATTRIBUTES_CHAR_WIDTH);
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
 worker_id_t w,
 bool_t * is_new,
 hash_tbl_id_t * id,
 hash_key_t * h) {
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

  (*h) = id->h = state_hash (s);
  slot = id->h % tbl->hash_size;
  (*is_new) = TRUE;

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
      (*is_new) = FALSE;
      break;
    }
  }

  if (*is_new) {
    
    /*
     *  compute the size of the state vector
     */
#if !defined(CFG_HASH_COMPACTION)
    len = state_char_width (s) + CFG_ATTRIBUTES_CHAR_WIDTH;
    es = mem_alloc (SYSTEM_HEAP, len);
    for (j = 0; j < len; j ++) {
      es[j] = 0;
    }
#endif

    /*
     *  encode attributes of the state
     */
    bits.vector = &es[0];
    id->p = new_pos;
    VECTOR_start (bits);
    VECTOR_set_size8 (bits, new_pos);
#ifdef CFG_ATTRIBUTE_CYAN
    move_to_attribute (bits, CFG_ATTRIBUTE_CYAN_POS);
    VECTOR_set_size1 (bits, TRUE);
#endif
#ifdef CFG_ATTRIBUTE_TYPE
    move_to_attribute (bits, CFG_ATTRIBUTE_TYPE_POS);
    VECTOR_set_size1 (bits, t);
#endif
#ifdef ATTRIBUTE_IS_RED
    move_to_attribute (bits, ATTRIBUTE_IS_RED_POS);
    VECTOR_set_size1 (bits, FALSE);
#endif

    /*
     *  encode the state
     */
#if defined(CFG_HASH_COMPACTION)
    bits.vector = es + CFG_ATTRIBUTES_CHAR_WIDTH;
    memcpy (es + CFG_ATTRIBUTES_CHAR_WIDTH, &id->h, sizeof (hash_key_t));
#else
    state_serialise (s, es + CFG_ATTRIBUTES_CHAR_WIDTH);
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
      found = TRUE;
#if !defined(CFG_HASH_COMPACTION)
      free (tbl->states[slot][i]);
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
  
#if defined(CFG_HASH_COMPACTION)
  fatal_error ("tbl_get impossible with hash-compaction");
  return NULL;
#else
  if ((v = hash_tbl_get_vector (tbl, id)) == NULL) {
    fatal_error ("hash_tbl_get_mem: could not find state");
  }
  else {
    result = state_unserialise_mem (v + CFG_ATTRIBUTES_CHAR_WIDTH, heap);
  }
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
#ifdef CFG_ATTRIBUTE_CYAN
  bit_vector_t v;
  vector bits;
  if ((v = hash_tbl_get_vector (tbl, id)) == NULL) {
    fatal_error ("hash_tbl_set_cyan could not find state");
  }
  bits.vector = v;
  move_to_attribute (bits, CFG_ATTRIBUTE_CYAN_POS);
  VECTOR_set_size1 (bits, cyan);
#if defined(CFG_STATE_CACHING)
  if (!cyan) {
    hash_tbl_cache_state (tbl, id);
  }
#endif
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
#ifdef CFG_ATTRIBUTE_CYAN
  bool_t result;
  bit_vector_t v;
  vector bits;
  if ((v = hash_tbl_get_vector (tbl, id)) == NULL) {
    fatal_error ("hash_tbl_get_cyan: could not find state");
  }
  bits.vector = v;
  move_to_attribute (bits, CFG_ATTRIBUTE_CYAN_POS);
  VECTOR_get_size1 (bits, result);
  result = result ? TRUE : FALSE;
  return result;
#else
  return FALSE;
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
           do_large_sum (tbl->state_cmps, CFG_NO_WORKERS)); 
  fprintf (out, "</hashTableStatistics>\n");
}



void init_hash_tbl () {
  null_hash_tbl_id.h = 0;
  null_hash_tbl_id.p = 0xff;
  hash_tbl_id_char_width = sizeof (hash_tbl_id_t);
}

void free_hash_tbl () {
}
