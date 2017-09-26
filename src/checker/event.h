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
#include "mevent_list.h"


#if defined(CFG_ACTION_CHECK_LTL)

/*
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

typedef struct {
  mevent_list_t m;
  bevent_t * b;
  unsigned int b_size;
  heap_t heap;
} struct_event_list_t;

typedef struct_event_list_t * event_list_t;

bool_t event_is_dummy
(event_t e);

event_t event_copy
(event_t e);

event_t event_copy_mem
(event_t e,
 heap_t h);

void event_free
(event_t e);

void event_exec
(event_t e,
 state_t s);

void event_undo
(event_t e,
 state_t s);

void event_to_xml
(event_t e,
 FILE * f);

unsigned int event_char_width
(event_t e);

void event_serialise
(event_t e,
 bit_vector_t v);

event_t event_unserialise
(bit_vector_t v);

event_t event_unserialise_mem
(bit_vector_t v,
 heap_t heap);

order_t event_cmp
(event_t e,
 event_t f);

bool_t event_are_independent
(event_t e,
 event_t f);

void event_list_free
(event_list_t en);

event_t event_list_nth
(event_list_t en,
 unsigned int n);

unsigned int event_list_size
(event_list_t en);

void event_list_serialise
(event_list_t en,
 bit_vector_t v);

event_list_t event_list_unserialise
(bit_vector_t v);

event_list_t event_list_unserialise_mem
(bit_vector_t v,
 heap_t heap);

unsigned int event_list_char_width
(event_list_t en);

event_list_t state_enabled_events
(state_t s);

event_list_t state_enabled_events_mem
(state_t s,
 heap_t heap);

event_t state_enabled_event
(state_t s,
 event_id_t id);

event_t state_enabled_event_mem
(state_t s,
 event_id_t id,
 heap_t heap);

void state_stubborn_set
(state_t s,
 event_list_t en);

state_t state_succ
(state_t s,
 event_t e);

state_t state_succ_mem
(state_t s,
 event_t e,
 heap_t heap);

state_t state_pred
(state_t s,
 event_t e);

state_t state_pred_mem
(state_t s,
 event_t e,
 heap_t heap);

#else

/*
 *  event definition when not doing LTL model checking
 */


typedef mevent_t event_t;
typedef uint8_t event_id_t;
typedef mevent_list_t event_list_t;

#define event_is_dummy(e) FALSE
#define event_free mevent_free
#define event_copy mevent_copy
#define event_copy_mem mevent_copy_mem
#define event_exec mevent_exec
#define event_undo mevent_undo
#define event_to_xml mevent_to_xml
#define event_char_width mevent_char_width
#define event_serialise mevent_serialise
#define event_unserialise mevent_unserialise
#define event_cmp mevent_cmp
#define event_are_independent mevent_are_independent

#define event_list_size mevent_list_size
#define event_list_free mevent_list_free
#define event_list_append mevent_list_append
#define event_list_pick_random mevent_list_pick_random
#define event_list_pick_first mevent_list_pick_first
#define event_list_is_empty mevent_list_is_empty
#define event_list_char_width mevent_list_char_width
#define event_list_serialise mevent_list_serialise
#define event_list_unserialise mevent_list_unserialise
#define event_list_unserialise_mem mevent_list_unserialise_mem

#define state_enabled_events mstate_enabled_events
#define state_enabled_event mstate_enabled_event
#define state_stubborn_set mstate_stubborn_set
#define state_succ mstate_succ
#define state_pred mstate_pred

#if defined(CFG_USE_HELENA_HEAPS)
#define event_unserialise_mem mevent_unserialise_mem
#define state_enabled_events_mem mstate_enabled_events_mem
#define state_enabled_event_mem mstate_enabled_event_mem
#define state_succ_mem mstate_succ_mem
#define state_pred_mem mstate_pred_mem
#else
#define event_unserialise_mem(v, heap) mevent_unserialise (v)
#define state_enabled_events_mem(s, heap) mstate_enabled_events (s)
#define state_enabled_event_mem(s, heap) mstate_enabled_event (s)
#define state_succ_mem(s, e, heap) mstate_succ (s, e)
#define state_pred_mem(s, e, heap) mstate_pred (s, e)
#endif

#endif

#endif
