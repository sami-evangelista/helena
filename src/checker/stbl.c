#include "config.h"
#include "stbl.h"
#include "context.h"
#include "bit_stream.h"


htbl_t stbl_default_new
() {
  uint32_t attrs_available = 0;
  uint16_t no_workers;
  htbl_type_t type;
  uint64_t hsize;
  uint16_t data_size = 0;

  /**
   *  check which attributes are enabled according to the
   *  configuration
   */
  attrs_available |= ATTR_ID(ATTR_CYAN);
  attrs_available |= ATTR_ID(ATTR_BLUE);
  if(CFG_ACTION_CHECK_LTL) {
    attrs_available |= ATTR_ID(ATTR_PINK);
    attrs_available |= ATTR_ID(ATTR_RED);
  }
  if(CFG_ALGO_BFS) {
    attrs_available |= ATTR_ID(ATTR_PRED);
    attrs_available |= ATTR_ID(ATTR_EVT);
  }
  if(CFG_ALGO_TARJAN) {
    attrs_available |= ATTR_ID(ATTR_INDEX);
    attrs_available |= ATTR_ID(ATTR_LOWLINK);
    attrs_available |= ATTR_ID(ATTR_LIVE);
    attrs_available |= ATTR_ID(ATTR_SAFE);
  }
  if(CFG_PROVISO) {
    attrs_available |= ATTR_ID(ATTR_SAFE);
    if(CFG_ALGO_DFS) {
      attrs_available |= ATTR_ID(ATTR_UNSAFE_SUCC);
      attrs_available |= ATTR_ID(ATTR_TO_REVISIT);
    }
  }

  /**
   *  type of hash table
   */
  if(CFG_HASH_COMPACTION) {
    type = HTBL_HASH_COMPACTION;
  } else if(CFG_ALGO_BWALK) {
    type = HTBL_BITSTATE;
  } else {
#if defined(MODEL_STATE_VECTOR_SIZE)
    type = HTBL_FULL_STATIC;
    data_size = MODEL_STATE_VECTOR_SIZE;
#else
    type = HTBL_FULL_DYNAMIC;
#endif
  }

  /**
   *  hash table size
   */
  hsize = CFG_HASH_SIZE;
  if(HTBL_BITSTATE == type) {
    hsize = hsize >> 3;
  }

  /**
   *  number of threads accessing the table
   */
  no_workers = CFG_NO_WORKERS;
  if(CFG_DISTRIBUTED) {
    no_workers ++;
  }
  return htbl_new(no_workers > 1, hsize, no_workers, type, data_size,
                  attrs_available,
                  (htbl_hash_func_t) state_hash,
                  (htbl_serialise_func_t) state_serialise,
                  (htbl_unserialise_func_t) state_unserialise,
                  (htbl_char_size_func_t) state_char_size,
                  (htbl_cmp_func_t) state_cmp_vector);
}

list_t stbl_get_trace
(htbl_t tbl,
 htbl_id_t id) {
  htbl_id_t id_pred;
  mevent_id_t evt;
  list_t result = list_new(SYSTEM_HEAP, sizeof(mevent_id_t), NULL);

  assert(htbl_has_attr(tbl, ATTR_PRED));
  while(id != (id_pred = htbl_get_attr(tbl, id, ATTR_PRED))) {
    evt = htbl_get_attr(tbl, id, ATTR_EVT);
    list_prepend(result, &evt);
    id = id_pred;
  }
  return result;
}
