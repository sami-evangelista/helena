/**
 * @file event.h
 * @brief Event definition.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_EVENT
#define LIB_EVENT

#include "model.h"
#include "heap.h"
#include "prop.h"
#include "state.h"

typedef list_t event_list_t;

void mevent_free_void
(void * data);

uint32_t mevent_list_char_size
(event_list_t l);

void mevent_list_serialise
(event_list_t l,
 bit_vector_t v);

event_list_t mevent_list_unserialise
(bit_vector_t v);

event_list_t mevent_list_unserialise_mem
(bit_vector_t v,
 heap_t heap);


#if defined(CFG_ACTION_CHECK_LTL)

/**
 *  event definition when doing LTL model checking
 */

typedef struct {
  bool_t dummy;
  uint8_t m;
  uint8_t b;
} event_id_t;

typedef struct {
  bool_t dummy;
  mevent_t m;
  bevent_t b;
} event_t;

bool_t event_is_dummy(event_t e);
void event_free(event_t e);
void event_free_void(void * e);
event_t event_copy(event_t e);
event_t event_copy_mem(event_t e, heap_t h);
event_id_t event_id(event_t e);
void event_exec(event_t e, state_t s);
void event_undo(event_t e, state_t s);
void event_to_xml(event_t e, FILE * f);
order_t event_cmp(event_t e, event_t f);
bool_t event_are_independent(event_t e, event_t f);
unsigned int event_char_size(event_t e);
void event_serialise(event_t e, bit_vector_t v);
event_t event_unserialise(bit_vector_t v);
event_t event_unserialise_mem(bit_vector_t v, heap_t heap);

event_list_t state_events(state_t s);
event_list_t state_events_mem(state_t s, heap_t heap);
event_t state_event(state_t s, event_id_t id);
event_t state_event_mem(state_t s, event_id_t id, heap_t heap);
event_list_t state_events_reduced(state_t s, bool_t * red);
event_list_t state_events_reduced_mem(state_t s, bool_t * red, heap_t heap);
state_t state_succ(state_t s, event_t e);
state_t state_succ_mem(state_t s, event_t e, heap_t heap);
state_t state_pred(state_t s, event_t e);
state_t state_pred_mem(state_t s, event_t e, heap_t heap);

unsigned int event_list_char_size(event_list_t l);
void event_list_serialise(event_list_t l, bit_vector_t v);
event_list_t event_list_unserialise(bit_vector_t v);
event_list_t event_list_unserialise_mem(bit_vector_t v, heap_t heap);

#else

/**
 *  event definition when not doing LTL model checking: an event
 *  is simply an mevent
 */


typedef mevent_t event_t;
typedef mevent_id_t event_id_t;

#define event_is_dummy(e) FALSE
#define event_free mevent_free
#define event_free_void mevent_free_void
#define event_copy mevent_copy
#define event_copy_mem mevent_copy_mem
#define event_id mevent_id
#define event_exec mevent_exec
#define event_undo mevent_undo
#define event_to_xml mevent_to_xml
#define event_cmp mevent_cmp
#define event_are_independent mevent_are_independent
#define event_char_size mevent_char_size
#define event_serialise mevent_serialise
#define event_unserialise mevent_unserialise
#define event_unserialise_mem mevent_unserialise_mem

#define state_events mstate_events
#define state_events_mem mstate_events_mem
#define state_event mstate_event
#define state_event_mem mstate_event_mem
#define state_events_reduced mstate_events_reduced
#define state_events_reduced_mem mstate_events_reduced_mem
#define state_succ mstate_succ
#define state_succ_mem mstate_succ_mem
#define state_pred mstate_pred
#define state_pred_mem mstate_pred_mem

#define event_list_char_size mevent_list_char_size
#define event_list_serialise mevent_list_serialise
#define event_list_unserialise mevent_list_unserialise
#define event_list_unserialise_mem mevent_list_unserialise_mem

#endif

#endif
