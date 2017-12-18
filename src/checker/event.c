#include "event.h"
#include "reduction.h"

void mevent_free_void
(void * data) {
  mevent_free(* ((mevent_t *) data));
}

uint32_t mevent_char_size_void
(void * e) {
  return mevent_char_size(* ((mevent_t *) e));
}

void mevent_serialise_void
(void * e,
 char * data) {
  return mevent_serialise(* ((mevent_t *) e), (char *) data);
}

void mevent_unserialise_void
(char * data,
 heap_t heap,
 void * item) {
  mevent_t e = mevent_unserialise(data, heap);
  memcpy(item, &e, sizeof(mevent_t));
}

uint32_t mevent_list_char_size
(mevent_list_t l) {
  return list_char_size(l, mevent_char_size_void);
}

void mevent_list_serialise
(mevent_list_t l,
 char * v) {
  list_serialise(l, v, mevent_char_size_void, mevent_serialise_void);
}

mevent_list_t mevent_list_unserialise
(char * v,
 heap_t heap) {
  return list_unserialise(heap, sizeof(mevent_t), mevent_free_void,
                          v, mevent_char_size_void, mevent_unserialise_void);
}

#if CFG_ACTION_CHECK_LTL == 1

bool_t event_is_dummy
(event_t e) {
  return e.dummy;
}

void event_free
(event_t e) {
  if(!e.dummy) {
    mevent_free(e.m);
  }
}

void event_free_void
(void * e) {
  event_free(* (event_t *) e);
}

event_t event_copy
(event_t e,
 heap_t h) {
  event_t result;
  result.dummy = e.dummy;
  result.b = e.b;
  if(!e.dummy) {
    result.m = mevent_copy(e.m, h);
  }
  return result;
}

event_id_t event_id
(event_t e) {
  /*  not implemented  */
  assert(0);
}

void event_exec
(event_t e,
 state_t s) {
  if(!e.dummy) {
    mevent_exec(e.m, s->m);
  }
  s->b = e.b.to;
}

void event_undo
(event_t e,
 state_t s) {
  if(!e.dummy) {
    mevent_undo(e.m, s->m);
  }
  s->b = e.b.from;
}

void event_to_xml
(event_t e,
 FILE * f) {
  assert(!e.dummy);
  mevent_to_xml(e.m, f);
}

order_t event_cmp
(event_t e,
 event_t f) {
  order_t cmp;
  if((cmp = bevent_cmp(e.b, f.b)) != EQUAL) return cmp;
  else if(e.dummy && f.dummy) return EQUAL;
  else if(e.dummy) return LESS;
  else if(f.dummy) return GREATER;
  else return mevent_cmp(e.m, f.m);
}

bool_t event_are_independent
(event_t e,
 event_t f) {
  return mevent_are_independent(e.m, f.m);
}

unsigned int event_char_size
(event_t e) {
  return 1 + 2 * sizeof(bstate_t) + (e.dummy ? 0 : mevent_char_size(e.m));
}

void event_serialise
(event_t e,
 char * v) {
  const unsigned int bsize = sizeof(bstate_t);
  
  memcpy(v, &e.b.from, bsize);
  memcpy(v + bsize, &e.b.to, bsize);
  memcpy(v + bsize + bsize, &e.dummy, 1);
  if(!e.dummy) {
    mevent_serialise(e.m, v + bsize + bsize + 1);
  }
}

event_t event_unserialise
(char * v,
 heap_t heap) {
  const unsigned int bsize = sizeof(bstate_t);
  event_t result;
  
  result.b.to = 0;
  result.b.from = 0;
  memcpy(&result.b.from, v, bsize);
  memcpy(&result.b.to, v + bsize, bsize);
  memcpy(&result.dummy, v + bsize + bsize, 1);
  if(!result.dummy) {
    result.m = mevent_unserialise(v + bsize + bsize + 1, heap);
  }
  return result;
}

event_list_t state_events_with_reduction
(state_t s,
 bool_t reduce,
 bool_t * reduced,
 heap_t heap) {
  event_t e;
  event_list_t result = list_new(heap, sizeof(event_t), event_free_void);
  bstate_t succs[256];
  uint32_t size;
  list_iter_t it;
  list_t m_en;
  int i, no_succs;

  if(reduce) {
    m_en = mstate_events_reduced(s->m, reduced, heap);
  } else {
    m_en = mstate_events(s->m, heap);    
  }
  bstate_succs(s->b, s->m, succs, &no_succs);

  e.b.from = s->b;
  if(succs == 0) {
    
    /**
     *  buchi state does not have enabled events => the resulting list
     *  is empty
     */
    list_free(m_en);
    
  } else if(list_size(m_en) == 0) {
    
    /**
     *  model state does not have enabled events => the resulting list
     *  is the list of buchi events
     */
    e.dummy = TRUE;
    for(i = 0; i < no_succs; i ++) {
      e.b.to = succs[i];
      list_append(result, &e);
    }
  } else {
    
    /**
     *  buchi and model states both have enabled events => the
     *  resulting list is the cartesian product of both
     */
    e.dummy = FALSE;
    for(i = 0; i < no_succs; i ++) {
      e.b.to = succs[i];
      for(it = list_get_iter(m_en);
          !list_iter_at_end(it);
          it = list_iter_next(it)) {
        e.m = * ((mevent_t *) list_iter_item(it));
        e.m = mevent_copy(e.m, heap);
        list_append(result, &e);
      }
    }
  }
  list_free(m_en);
  return result;
}

event_list_t state_events
(state_t s,
 heap_t heap) {
  return state_events_with_reduction(s, FALSE, NULL, heap);
}

event_list_t state_events_reduced
(state_t s,
 bool_t * red,
 heap_t heap) {
  return state_events_with_reduction(s, TRUE, red, heap);  
}

event_t state_event
(state_t s,
 event_id_t id,
 heap_t heap) {
  /*  not implemented  */
  assert(0);
}

state_t state_succ
(state_t s,
 event_t e,
 heap_t heap) {
  /*  not implemented  */
  assert(0);
}

state_t state_pred
(state_t s,
 event_t e,
 heap_t heap) {
  /*  not implemented  */
  assert(0);
}

uint32_t event_char_size_void
(void * e) {
  return event_char_size(* ((event_t *) e));
}

void event_serialise_void
(void * e,
 char * data) {
  return event_serialise(* ((event_t *) e), (char *) data);
}

void event_unserialise_void
(char * data,
 heap_t heap,
 void * item) {
  event_t e = event_unserialise(data, heap);
  memcpy(item, &e, sizeof(event_t));
}

unsigned int event_list_char_size
(event_list_t l) {
  return list_char_size(l, event_char_size_void);
}

void event_list_serialise
(event_list_t l,
 char * v) {
  list_serialise(l, v, event_char_size_void, event_serialise_void);
}

event_list_t event_list_unserialise
(char * v,
 heap_t heap) {
  return list_unserialise(heap, sizeof(event_t), event_free_void,
                          v, event_char_size_void, event_unserialise_void);
}

#endif
