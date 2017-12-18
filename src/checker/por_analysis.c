#include "common.h"
#include "por_analysis.h"
#include "reduction.h"

uint64_t POR_ANALYSIS_NO_UNSAFE_STATES = 0;

uint64_t por_analysis_no_unsafe_states
() {
  return POR_ANALYSIS_NO_UNSAFE_STATES;
}

bool_t por_analysis_state_is_unsafe
(darray_t unsafe,
 htbl_id_t id) {
  int i;

  for(i = 0; i < darray_size(unsafe); i ++) {
    if(id == * ((htbl_id_t *) darray_get(unsafe, i))) {
      return TRUE;
    }
  }
  return FALSE;
}

void por_analysis_scc
(htbl_t H,
 darray_t scc) {
  uint32_t i;
  state_t s, succ;
  htbl_id_t id, id_succ;
  bool_t changes = TRUE, reduced;
  heap_t heap = local_heap_new();
  list_t en;
  event_t e;
  hkey_t h;
  bool_t all_succ_safe;
  darray_t unsafe = darray_new(SYSTEM_HEAP, sizeof(htbl_id_t));

  /*
   * initialise the set of unsafe states of the scc
   */
  for(i = 0; i < darray_size(scc); i ++) {
    id = * ((htbl_id_t *) darray_get(scc, i));
    if(!htbl_get_attr(H, id, ATTR_SAFE)) {
      darray_push(unsafe, &id);
    }
  }
    
  while(changes) {
    changes = FALSE;
    i = 0;
    while(i < darray_size(unsafe)) {
      id = * ((htbl_id_t *) darray_get(unsafe, i));
      heap_reset(heap);
      s = htbl_get(H, id, heap);
      en = state_events_reduced(s, &reduced, heap);
      all_succ_safe = TRUE;
      while(!list_is_empty(en) && all_succ_safe) {
        list_pick_first(en, &e);
        succ = state_succ(s, e, heap);
        if(htbl_contains(H, succ, &id_succ, &h)
           && por_analysis_state_is_unsafe(unsafe, id_succ)) {
          all_succ_safe = FALSE;
        }
      }
      if(!all_succ_safe) {
        i ++;
      } else {
        htbl_set_attr(H, id, ATTR_SAFE, TRUE);
        id = * ((htbl_id_t *) darray_pop(unsafe));
        if(i != darray_size(unsafe)) {
          darray_set(unsafe, i, &id);
        }
        changes = TRUE;          
      }
    }
  }

  for(i = 0; i < darray_size(scc); i ++) {
    id = * ((htbl_id_t *) darray_get(scc, i));
    if(!htbl_get_attr(H, id, ATTR_SAFE)) {
      POR_ANALYSIS_NO_UNSAFE_STATES ++;
    }
  }
  heap_free(heap);
}
