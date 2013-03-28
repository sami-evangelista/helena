#include "event.h"

#ifdef CHECK_LTL

bool_t event_is_dummy
(event_t e) {
  return e.dummy;
}

event_t event_copy
(event_t e) {
  event_t result;
  result.dummy = e.dummy;
  result.b = e.b;
  if (!e.dummy) {
    result.m = mevent_copy (e.m);
  }
  return result;
}

void event_exec
(event_t e,
 state_t s) {
  if (!e.dummy) {
    mevent_exec (e.m, s->m);
  }
  s->b = e.b.to;
}

void event_undo
(event_t e,
 state_t s) {
  if (!e.dummy) {
    mevent_undo (e.m, s->m);
  }
  s->b = e.b.from;
}

void event_to_xml
(event_t e,
 FILE * f) {
  if (!e.dummy) {
    mevent_to_xml (e.m, f);
  } else {
    fatal_error ("event_to_xml: called with dummy event");
  }
}

unsigned int event_char_width
(event_t e) {
  return 1 + 2 * bstate_char_width () +
    (e.dummy ? 0 : mevent_char_width (e.m));
}

void event_serialise
(event_t e,
 bit_vector_t v) {
  unsigned int bsize = bstate_char_width ();
  memcpy (v, &(e.b.from), bsize);
  memcpy (v + bsize, &(e.b.to), bsize);
  v[bsize + bsize] = e.dummy;
  if (!e.dummy) {
    mevent_serialise (e.m, v + bsize + bsize + 1);
  }
}

event_t event_unserialise
(bit_vector_t v) {
  return event_unserialise_mem (v, SYSTEM_HEAP);
}

order_t event_cmp
(event_t e,
 event_t f) {
  order_t cmp;
  if ((cmp = bevent_cmp (e.b, f.b)) != EQUAL) return cmp;
  else if (e.dummy && f.dummy) return EQUAL;
  else if (e.dummy) return LESS;
  else if (f.dummy) return GREATER;
  else return mevent_cmp (e.m, f.m);
}

bool_t event_are_independent
(event_t e,
 event_t f) {
  fatal_error ("event_are_independent: unimplemented feature");
}

void event_set_free
(event_set_t en) {
  mevent_set_free (en->m);
  mem_free (en->heap, en->b);
  mem_free (en->heap, en);
}

unsigned int event_set_size
(event_set_t en) {
  if (en->b_size == 0) {
    return 0;
  }
  if (mevent_set_size (en->m) == 0) {
    return en->b_size;
  }
  return mevent_set_size (en->m) * en->b_size;
}

event_t event_set_nth
(event_set_t en,
 unsigned int n) {
  event_t result;
  if (en->b_size == 0) {
    fatal_error ("event_set_nth: empty set");
  }
  if (mevent_set_size (en->m) == 0) {
    result.dummy = TRUE;
    result.b = en->b[n];
  } else {
    result.dummy = FALSE;
    result.m = mevent_set_nth (en->m, n / en->b_size);
    result.b = en->b[n % en->b_size];
  }
  return result;
}

event_id_t event_set_nth_id
(event_set_t en,
 unsigned int n) {
  event_id_t result;
  if (en->b_size == 0) {
    fatal_error ("event_set_nth_id: empty set");
  }
  if (mevent_set_size (en->m) == 0) {
    result.dummy = TRUE;
    result.b = n;
  } else {
    result.dummy = FALSE;
    result.m = mevent_set_nth_id (en->m, n / en->b_size);
    result.b = n % en->b_size;
  }
  return result;
}

void event_set_serialise
(event_set_t en,
 bit_vector_t v) {
  unsigned int bs = en->b_size * sizeof (bevent_t);
  v[0] = en->b_size;
  if (bs) {
    memcpy (v + 1, en->b, bs);
  }
  mevent_set_serialise (en->m, v + 1 + bs);
}

event_set_t event_set_unserialise
(bit_vector_t v) {
  return event_set_unserialise_mem (v, SYSTEM_HEAP);
}

unsigned int event_set_char_width
(event_set_t en) {
  return 1 + (en->b_size * sizeof (bevent_t)) + mevent_set_char_width (en->m);
}

event_set_t state_enabled_events
(state_t s) {
  return state_enabled_events_mem (s, SYSTEM_HEAP);
}

event_t state_enabled_event
(state_t s,
 event_id_t id) {
  return state_enabled_event_mem (s, id, SYSTEM_HEAP);
}

void state_stubborn_set
(state_t s,
 event_set_t en) {
  mstate_stubborn_set (s->m, en->m);
}

state_t state_succ
(state_t s,
 event_t e) {
  return state_succ_mem (s, e, SYSTEM_HEAP);
}

state_t state_pred
(state_t s,
 event_t e) {
  return state_pred_mem (s, e, SYSTEM_HEAP);
}

event_t event_unserialise_mem
(bit_vector_t v,
 heap_t heap) {
  event_t result;
  unsigned int bsize = bstate_char_width ();
  result.b.from = 0;
  result.b.to = 0;
  memcpy (&(result.b.from), v, bsize);
  memcpy (&(result.b.to), v + bsize, bsize);
  result.dummy = v[bsize + bsize];
  if (!result.dummy) {
    result.m = mevent_unserialise_mem (v + bsize + bsize + 1, heap);
  }
  return result;
}

event_set_t event_set_unserialise_mem
(bit_vector_t v,
 heap_t heap) {
  event_set_t result = mem_alloc (heap, sizeof (struct_event_set_t));
  unsigned int bs;
  result->heap = heap;
  result->b_size = v[0];
  bs = result->b_size * sizeof (bevent_t);
  result->b = mem_alloc (heap, sizeof(bevent_t) * result->b_size);
  memcpy (result->b, v + 1, bs);
  result->m = mevent_set_unserialise_mem (v + 1 + bs, heap);
  return result;
}

event_set_t state_enabled_events_mem
(state_t s,
 heap_t heap) {
  bstate_t succs[256];
  unsigned int i;
  event_set_t result = mem_alloc (heap, sizeof (struct_event_set_t));
  result->heap = heap;
  result->m = mstate_enabled_events_mem (s->m, heap);
  bstate_succs (s->b, s->m, &succs[0], &(result->b_size));
  result->b = mem_alloc (heap, sizeof (bevent_t) * result->b_size);
  for (i = 0; i < result->b_size; i ++) {
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

  bstate_succs (s->b, s->m, &succs[0], &b_size);
  result.b.from = s->b;
  result.b.to = succs[id.b];
  result.dummy = id.dummy;
  if (!result.dummy) {
    result.m = mstate_enabled_event_mem (s->m, id.m, heap);
  }
  return result;
}

state_t state_succ_mem
(state_t s,
 event_t e,
 heap_t heap) {
  state_t result;
  result = mem_alloc (heap, sizeof (struct_state_t));
  result->heap = heap;
  result->m = mstate_succ_mem (s->m, e.m, heap);
  result->b = e.b.to;
  return result;
}

state_t state_pred_mem
(state_t s,
 event_t e,
 heap_t heap) {
  state_t result;
  result = mem_alloc (heap, sizeof (struct_state_t));
  result->heap = heap;
  result->m = mstate_pred_mem (s->m, e.m, heap);
  result->b = e.b.from;
  return result;
}

#endif
