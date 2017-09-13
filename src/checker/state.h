#ifndef LIB_STATE
#define LIB_STATE

#include "model.h"
#include "heap.h"
#include "prop.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

#if defined(CFG_ACTION_CHECK_LTL)



/*
 *  state definition when doing LTL model checking
 */

#include "buchi.h"

typedef struct {
  mstate_t m;  /*  state of the model  */
  bstate_t b;  /*  state of the buchi automaton  */
  heap_t heap;
} struct_state_t;
typedef struct_state_t * state_t;

bool_t state_equal
(state_t s,
 state_t t);

bool_t state_accepting
(state_t s);

state_t state_initial
();

void state_free
(state_t s);

hash_key_t state_hash
(state_t s);

state_t state_copy
(state_t s);

void state_print
(state_t s,
 FILE *  out);

void state_to_xml
(state_t s,
 FILE *  out);

void state_serialise
(state_t s,
 bit_vector_t v);

state_t state_unserialise
(bit_vector_t v);

bool_t state_cmp_vector
(state_t s,
 bit_vector_t v);

unsigned int state_char_width
(state_t s);

state_t state_initial_mem
(heap_t heap);

state_t state_copy_mem
(state_t s,
 heap_t heap);

state_t state_unserialise_mem
(bit_vector_t v,
 heap_t heap);

#else



/*
 *  state definition when not doing LTL model checking
 */

typedef mstate_t state_t;
#define state_initial mstate_initial
#define state_equal mstate_equal
#define state_free mstate_free
#define state_hash mstate_hash
#define state_copy mstate_copy
#define state_print mstate_print
#define state_to_xml mstate_to_xml
#define state_serialise mstate_serialise
#define state_unserialise mstate_unserialise
#define state_char_width mstate_char_width
#define state_cmp_vector mstate_cmp_vector

#if defined(CFG_USE_HELENA_HEAPS)
#define state_initial_mem mstate_initial_mem
#define state_copy_mem mstate_copy_mem
#define state_unserialise_mem mstate_unserialise_mem
#else
#define state_initial_mem(heap) mstate_initial ()
#define state_copy_mem(s, heap) mstate_copy (s)
#define state_unserialise_mem(v, heap) mstate_unserialise(v)
#endif

#endif

#endif
