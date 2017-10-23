#include "state.h"

void mstate_free_void
(void * data) {
  mstate_free(*((mstate_t *) data));
}


#if CFG_ACTION_CHECK_LTL == 1

bool_t state_equal
(state_t s,
 state_t t) {
  return mstate_equal(s->m, t->m) && (s->b == t->b);
}

bool_t state_accepting
(state_t s) {
  return bstate_accepting(s->b);
}

state_t state_initial
() {
  return state_initial_mem(SYSTEM_HEAP);
}

state_t state_initial_mem
(heap_t heap) {
  state_t result;
  result = mem_alloc(heap, sizeof(struct_state_t));
  result->m = mstate_initial_mem(heap);
  result->b = bstate_initial();
  result->heap = heap;
  return result;
}

void state_free
(state_t s) {
  mstate_free(s->m);
  mem_free(s->heap, s);
}

void state_free_void(void * s) {
  state_free(*((state_t *) s));
}

hash_key_t state_hash
(state_t s) {
  return mstate_hash(s->m) + s->b;
}

state_t state_copy
(state_t s) {
  return state_copy_mem(s, SYSTEM_HEAP);
}

state_t state_copy_mem
(state_t s,
 heap_t heap) {
  state_t result;
  
  result = mem_alloc(heap, sizeof(struct_state_t));
  result->m = mstate_copy_mem(s->m, heap);
  result->b = s->b;
  result->heap = heap;
  return result;
}

void state_print
(state_t s,
 FILE * out) {
  mstate_print(s->m, out);
}

void state_to_xml
(state_t s,
 FILE * out) {
  mstate_to_xml(s->m, out);
}

unsigned int state_char_size
(state_t s) {
  return sizeof(bstate_t) + mstate_char_size(s->m);
}

void state_serialise
(state_t s,
 bit_vector_t v) {  
  memcpy(v, &(s->b), sizeof(bstate_t));
  mstate_serialise(s->m, v + sizeof(bstate_t));
}

state_t state_unserialise
(bit_vector_t v) {
  return state_unserialise_mem(v, SYSTEM_HEAP);
}

state_t state_unserialise_mem
(bit_vector_t v,
 heap_t heap) {
  unsigned int bsize = sizeof(bstate_t);
  state_t result = mem_alloc(heap, sizeof(struct_state_t));
  
  result->b = 0;
  memcpy(&(result->b), v, bsize);
  result->m = mstate_unserialise_mem(v + bsize, heap);
  result->heap = heap;
  return result;
}

bool_t state_cmp_vector
(state_t s,
 bit_vector_t v) {
  bstate_t b = 0;

  memcpy(&b, v, sizeof(bstate_t));
  if(s->b != b) {
    return FALSE;
  }
  return mstate_cmp_vector(s->m, v + sizeof(bstate_t));
}

#endif
