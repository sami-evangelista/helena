#include "reduction.h"
#include "event.h"

char edge_lean_is_independent_and_inferior
(void * item,
 void * data) {
  event_t e = * ((event_t *) item);
  event_t f = * ((event_t *) data);

  if(event_are_independent(e, f) && (LESS == event_cmp(e, f))) {
    return TRUE;
  } else {
    return FALSE;
  }
}

void edge_lean_reduction
(event_list_t en,
 event_t e) {
  list_filter(en, edge_lean_is_independent_and_inferior, &e);
}

char por_is_safe_and_invisible
(void * item,
 void * data) {
   mevent_t e = * (mevent_t *) item;

   if(mevent_is_safe(e) && !mevent_is_visible(e)) {
     return TRUE;
   } else {
     return FALSE;
   }
}

char por_is_not_id
(void * item,
 void * data) {
   mevent_t e = * (mevent_t *) item;
   mevent_id_t id = * (mevent_id_t *) data;
   
   if(mevent_id(e) != id) {
     return TRUE;
   } else {
     return FALSE;
   }
}

char por_in_set_and_invisible
(void * item,
 void * data) {
   mevent_t e = * (mevent_t *) item;
   
   if(mevent_safe_set(e) > 0 && !mevent_is_visible(e)) {
     return TRUE;
   } else {
     return FALSE;
   }
}

char por_in_set_and_visible
(void * item,
 void * data) {
   mevent_t e = * (mevent_t *) item;
   unsigned int set = * (unsigned int *) data;
   if(mevent_safe_set(e) == set && mevent_is_visible(e)) {
     return TRUE;
   } else {
     return FALSE;
   }
}

char por_is_not_in_set
(void * item,
 void * data) {
   mevent_t e = * (mevent_t *) item;
   unsigned int set = * (unsigned int *) data;
   
   if(mevent_safe_set(e) != set) {
     return TRUE;
   } else {
     return FALSE;
   }
}

mevent_list_t mstate_events_reduced
(mstate_t s,
 bool_t * reduced,
 heap_t heap) {
  mevent_id_t eid;
  mevent_t e;
  void * data;
  unsigned int set;
  list_t result = mstate_events(s, heap);
  const list_size_t len = list_size(result);
   
  if(data = list_find(result, por_is_safe_and_invisible, NULL)) {
    e = * (mevent_t *) data;
    eid = mevent_id(e);
    list_filter(result, por_is_not_id, &eid);
  } else if(data = list_find(result, por_in_set_and_invisible, NULL)) {
    e = * (mevent_t *) data;
    set = mevent_safe_set(e);
    data = &set;
    if(NULL == list_find(result, por_in_set_and_visible, data)) {
      list_filter(result, por_is_not_in_set, data);
    }
  }
#if defined(MODEL_HAS_DYNAMIC_POR_REDUCTION) && CFG_DYNAMIC_POR == 1
  else {
    dynamic_por_reduction(s, result);
  }
#endif
  *reduced = (list_size(result) != len) ? TRUE : FALSE;
  return result;
}
