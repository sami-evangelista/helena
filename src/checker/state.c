#include "state.h"

#ifdef ACTION_CHECK_LTL

state_t state_initial_mem
(heap_t heap) {
  state_t result;
  result = mem_alloc (heap, sizeof (struct_state_t));
  result->m = mstate_initial_mem (heap);
  result->b = bstate_initial ();
  result->heap = heap;
  return result;
}

state_t state_initial
() {
  return state_initial_mem (SYSTEM_HEAP);
}

bool_t state_equal
(state_t s,
 state_t t) {
  return mstate_equal (s->m, t->m) && (s->b == t->b);
}

bool_t state_accepting
(state_t s) {
  return bstate_accepting (s->b);
}

void state_free
(state_t s) {
  mstate_free (s->m);
  mem_free (s->heap, s);
}

hash_key_t state_hash
(state_t s) {
  return mstate_hash (s->m) + s->b;
}

state_t state_copy_mem
(state_t s,
 heap_t heap) {
  state_t result;
  result = mem_alloc (heap, sizeof (struct_state_t));
  result->m = mstate_copy_mem (s->m, heap);
  result->b = s->b;
  result->heap = heap;
  return result;
}

state_t state_copy
(state_t s) {
  return state_copy_mem (s, SYSTEM_HEAP);
}

void state_print
(state_t s,
 FILE *  out) {
  mstate_print (s->m, out);
}

void state_to_xml
(state_t s,
 FILE *  out) {
  mstate_to_xml (s->m, out);
}

void state_serialise
(state_t s,
 bit_vector_t v) {
  unsigned int bsize = bstate_char_width ();
  memcpy (v, &(s->b), bsize);
  mstate_serialise (s->m, v + bsize);
}

state_t state_unserialise_mem
(bit_vector_t v,
 heap_t heap) {
  unsigned int bsize = bstate_char_width ();
  state_t result = mem_alloc (heap, sizeof (struct_state_t)); 
  result->b = 0;
  memcpy (&(result->b), v, bsize);
  result->m = mstate_unserialise (v + bsize);
  result->heap = heap;
  return result;
}

state_t state_unserialise
(bit_vector_t v) {
  return state_unserialise_mem (v, SYSTEM_HEAP);
}

bool_t state_cmp_vector
(state_t s,
 bit_vector_t v) {
  bstate_t b = 0;
  unsigned int bsize = bstate_char_width ();
  memcpy (&b, v, bsize);
  if (s->b != b) {
    return FALSE;
  }
  return mstate_cmp_vector (s->m, v + bsize);
}

unsigned int state_char_width
(state_t s) {
  return bstate_char_width () + mstate_char_width (s->m);
}

#endif
