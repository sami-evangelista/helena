/**
 * @file state.h
 * @brief State definition.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_STATE
#define LIB_STATE

#include "model.h"
#include "heap.h"
#include "list.h"
#include "prop.h"
#include "config.h"

typedef list_t state_list_t;

void mstate_free_void
(void * data);

#if CFG_ACTION_CHECK_LTL == 1

/**
 *  state definition when doing LTL model checking
 */

#include "buchi.h"

typedef struct {
  mstate_t m;  /*  state of the model  */
  bstate_t b;  /*  state of the buchi automaton  */
  heap_t heap;
} struct_state_t;
typedef struct_state_t * state_t;

bool_t state_equal(state_t s, state_t t);
bool_t state_accepting(state_t s);
state_t state_initial(heap_t heap);
void state_free(state_t s);
void state_free_void(void * s);
hkey_t state_hash(state_t s);
state_t state_copy(state_t s, heap_t heap);
void state_print(state_t s, FILE *  out);
void state_to_xml(state_t s, FILE *  out);
uint16_t state_char_size(state_t s);
void state_serialise(state_t s, char * v, uint16_t * size);
state_t state_unserialise(char * v, heap_t heap);
uint16_t state_compressed_char_size();
void state_compress(state_t s, char * v, uint16_t * size);
state_t state_uncompress(char * v, heap_t heap);
bool_t state_cmp_string(state_t s, char * v);

#else

/**
 *  state definition when not doing LTL model checking
 */

typedef mstate_t state_t;

#define state_equal mstate_equal
#define state_accepting(s) FALSE
#define state_initial mstate_initial
#define state_free mstate_free
#define state_free_void mstate_free_void
#define state_hash mstate_hash
#define state_copy mstate_copy
#define state_print mstate_print
#define state_to_xml mstate_to_xml
#define state_char_size mstate_char_size
#define state_serialise mstate_serialise
#define state_unserialise mstate_unserialise
#define state_cmp_string mstate_cmp_string
#define state_compressed_char_size mstate_compressed_char_size
#define state_compress mstate_compress
#define state_uncompress mstate_uncompress
#define state_dist_compressed_char_size mstate_dist_compressed_char_size
#define state_dist_compress mstate_dist_compress
#define state_dist_uncompress mstate_dist_uncompress

#endif

#endif
