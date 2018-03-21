#include "compression.h"
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
(heap_t heap) {
  state_t result;
  result = mem_alloc(heap, sizeof(struct_state_t));
  result->m = mstate_initial(heap);
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

hkey_t state_hash
(state_t s) {
  return mstate_hash(s->m) + s->b;
}

state_t state_copy
(state_t s,
 heap_t heap) {
  state_t result;
  
  result = mem_alloc(heap, sizeof(struct_state_t));
  result->m = mstate_copy(s->m, heap);
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

uint16_t state_char_size
(state_t s) {
  return sizeof(bstate_t) + mstate_char_size(s->m);
}

void state_serialise
(state_t s,
 char * v,
 uint16_t * size) {
  memcpy(v, &(s->b), sizeof(bstate_t));
  mstate_serialise(s->m, v + sizeof(bstate_t), size);
  *size += sizeof(bstate_t);
}

state_t state_unserialise
(char * v,
 heap_t heap) {
  unsigned int bsize = sizeof(bstate_t);
  state_t result = mem_alloc(heap, sizeof(struct_state_t));
  
  result->b = 0;
  memcpy(&(result->b), v, bsize);
  result->m = mstate_unserialise(v + bsize, heap);
  result->heap = heap;
  return result;
}

uint16_t state_compressed_char_size
() {
  const uint16_t ssize = compression_char_size();

  if(0 == ssize) {
    return 0;
  } else {
    return sizeof(bstate_t) + ssize;
  }
}

void state_compress
(state_t s,
 char * v,
 uint16_t * size) {  
  memcpy(v, &(s->b), sizeof(bstate_t));
  compression_compress(s->m, v + sizeof(bstate_t), size);
  *size += sizeof(bstate_t);
}

state_t state_uncompress
(char * v,
 heap_t heap) {
  unsigned int bsize = sizeof(bstate_t);
  state_t result = mem_alloc(heap, sizeof(struct_state_t));
  
  result->b = 0;
  memcpy(&(result->b), v, bsize);
  result->m = compression_uncompress(v + bsize, heap);
  result->heap = heap;
  return result;
}

bool_t state_cmp_string
(state_t s,
 char * v) {
  bstate_t b = 0;
  
  memcpy(&b, v, sizeof(bstate_t));
  if(s->b != b) {
    return FALSE;
  }
  return mstate_cmp_string(s->m, v + sizeof(bstate_t));
}

#endif
