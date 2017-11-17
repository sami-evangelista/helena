#include "common.h"
#include "por_analysis.h"
#include "reduction.h"

uint32_t POR_ANALYSIS_NO_UNSAFE = 0;

bool_t por_analysis_state_in_scc
(darray_t scc,
 htbl_id_t id) {
  int i;

  for(i = 0; i < darray_size(scc); i ++) {
    if(id == * ((htbl_id_t *) darray_get(scc, i))) {
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
  hash_key_t h;
  bool_t all_succ_safe;

  while(changes) {
    changes = FALSE;
    for(i = 0; i < darray_size(scc); i ++) {
      heap_reset(heap);
      id = * ((htbl_id_t *) darray_get(scc, i));
      s = htbl_get_mem(H, id, heap);
      if(!htbl_get_attr(H, id, ATTR_SAFE)) {
        en = state_events_reduced_mem(s, &reduced, heap);
        all_succ_safe = TRUE;
        while(!list_is_empty(en) && all_succ_safe) {
          list_pick_first(en, &e);
          succ = state_succ_mem(s, e, heap);
          if(htbl_contains(H, succ, &id_succ, &h)
             && por_analysis_state_in_scc(scc, id_succ)
             && !htbl_get_attr(H, id_succ, ATTR_SAFE)) {
            all_succ_safe = FALSE;
          }
        }
        if(all_succ_safe) {
          htbl_set_attr(H, id, ATTR_SAFE, TRUE);
          changes = TRUE;
        }
      }
    }
  }

  for(i = 0; i < darray_size(scc); i ++) {
    id = * ((htbl_id_t *) darray_get(scc, i));
    if(!htbl_get_attr(H, id, ATTR_SAFE)) {
      POR_ANALYSIS_NO_UNSAFE ++;
    }
  }
  printf("POR_ANALYSIS_NO_UNSAFE == %d\n", POR_ANALYSIS_NO_UNSAFE);
  heap_free(heap);
}
