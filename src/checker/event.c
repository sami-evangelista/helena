#include "event.h"

uint32_t mevent_list_char_width
(list_t l) {
  uint32_t result = sizeof(list_size_t);
  list_iter_t it;
  mevent_t e;
  
  for(it = list_get_iterator(l);
      !list_iterator_at_end(it);
      it = list_iterator_next(it)) {
    e = * ((mevent_t *) list_iterator_item(it));
    result += mevent_char_width(e);
  }
  return result;
}

void mevent_list_serialise
(list_t l,
 bit_vector_t v) {
  mevent_t e;
  list_iter_t it;
  list_size_t size = list_size(l);
  uint32_t pos = 0;

  memcpy(v, &size, sizeof(list_size_t));
  pos = sizeof(list_size_t);
  for(it = list_get_iterator(l);
      !list_iterator_at_end(it);
      it = list_iterator_next(it)) {
    e = * ((mevent_t *) list_iterator_item(it));
    mevent_serialise(e, v + pos);
    pos += mevent_char_width(e);
  }
}

list_t mevent_list_unserialise
(bit_vector_t v) {
  return mevent_list_unserialise_mem(v, SYSTEM_HEAP);
}

list_t mevent_list_unserialise_mem
(bit_vector_t v,
 heap_t heap) {
  list_t result;
  uint32_t size, pos;
  mevent_t e;

  memcpy(&size, v, sizeof(list_size_t));
  result = list_new(heap, sizeof(mevent_t), mevent_free_void);
  pos = sizeof(list_size_t);
  while(size) {
    e = mevent_unserialise_mem(v + pos, heap);
    pos += mevent_char_width(e);
    list_append(result, &e);
    size --;
  }
  return result;
}

#if defined(CFG_ACTION_CHECK_LTL)

bool_t event_is_dummy
(event_t e) {
  return e.dummy;
}

void event_free
(event_t e) {
  mevent_free(e.m);
}

void event_free_void
(void * e) {
  mevent_free(* ((event_t *) e.m));
}

event_t event_copy
(event_t e) {
  return event_copy_mem(e, SYSTEM_HEAP);
}

event_t event_copy_mem
(event_t e,
 heap_t h) {
  event_t result;
  result.dummy = e.dummy;
  result.b = e.b;
  if(!e.dummy) {
    result.m = mevent_copy_mem(e.m, h);
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
  /*  not implemented  */
  assert(0);
}

unsigned int event_char_width
(event_t e) {
  return 1 + 2 * bstate_char_width() +
   (e.dummy ? 0 : mevent_char_width(e.m));
}

void event_list_free
(event_list_t en) {
  mevent_list_free(en->m);
  mem_free(en->heap, en->b);
  mem_free(en->heap, en);
}

unsigned int event_list_size
(event_list_t en) {
  if(en->b_size == 0) {
    return 0;
  }
  if(mevent_list_size(en->m) == 0) {
    return en->b_size;
  }
  return mevent_list_size(en->m) * en->b_size;
}

event_t event_list_nth
(event_list_t en,
 unsigned int n) {
  event_t result;
  
  assert(en->b_size > 0);
  if(mevent_list_size(en->m) == 0) {
    result.dummy = TRUE;
    result.b = en->b[n];
  } else {
    result.dummy = FALSE;
    result.m = mevent_list_nth(en->m, n / en->b_size);
    result.b = en->b[n % en->b_size];
  }
  return result;
}

void event_list_serialise
(event_list_t en,
 bit_vector_t v) {
  unsigned int bs = en->b_size * sizeof(bevent_t);
  
  v[0] = en->b_size;
  if(bs) {
    memcpy(v + 1, en->b, bs);
  }
  mevent_list_serialise(en->m, v + 1 + bs);
}

event_list_t event_list_unserialise
(bit_vector_t v) {
  return event_list_unserialise_mem(v, SYSTEM_HEAP);
}

unsigned int event_list_char_width
(event_list_t en) {
  return 1 +(en->b_size * sizeof(bevent_t)) + mevent_list_char_width(en->m);
}

event_list_t state_enabled_events
(state_t s) {
  return state_enabled_events_mem(s, SYSTEM_HEAP);
}

event_t state_enabled_event
(state_t s,
 event_id_t id) {
  return state_enabled_event_mem(s, id, SYSTEM_HEAP);
}

void state_reduced_set
(state_t s,
 event_list_t en) {
  mstate_reduced_set(s->m, en->m);
}

state_t state_succ
(state_t s,
 event_t e) {
  return state_succ_mem(s, e, SYSTEM_HEAP);
}

state_t state_pred
(state_t s,
 event_t e) {
  return state_pred_mem(s, e, SYSTEM_HEAP);
}

event_t event_unserialise_mem
(bit_vector_t v,
 heap_t heap) {
  event_t result;
  unsigned int bsize = bstate_char_width();
  result.b.from = 0;
  result.b.to = 0;
  memcpy(&(result.b.from), v, bsize);
  memcpy(&(result.b.to), v + bsize, bsize);
  result.dummy = v[bsize + bsize];
  if(!result.dummy) {
    result.m = mevent_unserialise_mem(v + bsize + bsize + 1, heap);
  }
  return result;
}

event_list_t event_list_unserialise_mem
(bit_vector_t v,
 heap_t heap) {
  event_list_t result = mem_alloc(heap, sizeof(struct_event_list_t));
  unsigned int bs;
  result->heap = heap;
  result->b_size = v[0];
  bs = result->b_size * sizeof(bevent_t);
  result->b = mem_alloc(heap, sizeof(bevent_t) * result->b_size);
  memcpy(result->b, v + 1, bs);
  result->m = mevent_list_unserialise_mem(v + 1 + bs, heap);
  return result;
}

event_list_t state_enabled_events_mem
(state_t s,
 heap_t heap) {
  bstate_t succs[256];
  unsigned int i;
  event_list_t result = mem_alloc(heap, sizeof(struct_event_list_t));
  result->heap = heap;
  result->m = mstate_enabled_events_mem(s->m, heap);
  bstate_succs(s->b, s->m, &succs[0], &(result->b_size));
  result->b = mem_alloc(heap, sizeof(bevent_t) * result->b_size);
  for(i = 0; i < result->b_size; i ++) {
    result->b[i].from = s->b;
    result->b[i].to = succs[i];
  }
  return result;
}

event_t state_enabled_event_mem
(state_t s,
 event_id_t id,
 heap_t heap) {
  event_t result;
  bstate_t succs[256];
  unsigned int b_size;

  bstate_succs(s->b, s->m, &succs[0], &b_size);
  result.b.from = s->b;
  result.b.to = succs[id.b];
  result.dummy = id.dummy;
  if(!result.dummy) {
    result.m = mstate_enabled_event_mem(s->m, id.m, heap);
  }
  return result;
}

state_t state_succ_mem
(state_t s,
 event_t e,
 heap_t heap) {
  state_t result;
  result = mem_alloc(heap, sizeof(struct_state_t));
  result->heap = heap;
  result->m = mstate_succ_mem(s->m, e.m, heap);
  result->b = e.b.to;
  return result;
}

state_t state_pred_mem
(state_t s,
 event_t e,
 heap_t heap) {
  state_t result;
  result = mem_alloc(heap, sizeof(struct_state_t));
  result->heap = heap;
  result->m = mstate_pred_mem(s->m, e.m, heap);
  result->b = e.b.from;
  return result;
}

#endif
