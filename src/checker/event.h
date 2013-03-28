#ifndef LIB_EVENT
#define LIB_EVENT

#include "model.h"
#include "heap.h"
#include "prop.h"
#include "state.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

#ifdef CHECK_LTL



/*
 *  event definition when doing LTL model checking
 */

typedef struct {
  bool_t dummy;
  mevent_id_t  m;
  uint8_t b;
} event_id_t;

typedef struct {
  bool_t dummy;
  mevent_t m;
  bevent_t b;
} event_t;

typedef struct {
  mevent_set_t m;
  bevent_t * b;
  unsigned int b_size;
  heap_t heap;
} struct_event_set_t;
typedef struct_event_set_t * event_set_t;

bool_t event_is_dummy
(event_t e);

event_t event_copy
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

void event_set_free
(event_set_t en);

event_t event_set_nth
(event_set_t en,
 unsigned int n);

event_id_t event_set_nth_id
(event_set_t en,
 unsigned int n);

unsigned int event_set_size
(event_set_t en);

void event_set_serialise
(event_set_t en,
 bit_vector_t v);

event_set_t event_set_unserialise
(bit_vector_t v);

event_set_t event_set_unserialise_mem
(bit_vector_t v,
 heap_t heap);

unsigned int event_set_char_width
(event_set_t en);

event_set_t state_enabled_events
(state_t s);

event_set_t state_enabled_events_mem
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
 event_set_t en);

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

typedef mevent_id_t event_id_t;

typedef mevent_t event_t;
#define event_is_dummy(e) FALSE
#define event_copy mevent_copy
#define event_exec mevent_exec
#define event_undo mevent_undo
#define event_to_xml mevent_to_xml
#define event_char_width mevent_char_width
#define event_serialise mevent_serialise
#define event_unserialise mevent_unserialise
#define event_cmp mevent_cmp
#define event_are_independent mevent_are_independent

typedef mevent_set_t event_set_t;
#define event_set_free mevent_set_free
#define event_set_nth mevent_set_nth
#define event_set_nth_id mevent_set_nth_id
#define event_set_size mevent_set_size
#define event_set_serialise mevent_set_serialise
#define event_set_unserialise mevent_set_unserialise
#define event_set_char_width mevent_set_char_width
#define event_set_filter mevent_set_filter

#define state_enabled_events mstate_enabled_events
#define state_enabled_event mstate_enabled_event
#define state_stubborn_set mstate_stubborn_set
#define state_succ mstate_succ
#define state_pred mstate_pred

#ifdef USE_HELENA_HEAPS
#define event_unserialise_mem mevent_unserialise_mem
#define event_set_unserialise_mem mevent_set_unserialise_mem
#define state_enabled_events_mem mstate_enabled_events_mem
#define state_enabled_event_mem mstate_enabled_event_mem
#define state_succ_mem mstate_succ_mem
#define state_pred_mem mstate_pred_mem
#else
#define event_unserialise_mem(v, heap) mevent_unserialise (v)
#define event_set_unserialise_mem(v, heap) mevent_set_unserialise (v)
#define state_enabled_events_mem(s, heap) mstate_enabled_events (s)
#define state_enabled_event_mem(s, heap) mstate_enabled_event (s)
#define state_succ_mem(s, e, heap) mstate_succ (s, e)
#define state_pred_mem(s, e, heap) mstate_pred (s, e)
#endif

#endif

#endif
