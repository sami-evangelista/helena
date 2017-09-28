#include "reduction.h"

char is_independent_and_inferior
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
  list_filter(en, is_independent_and_inferior, &e);
}
