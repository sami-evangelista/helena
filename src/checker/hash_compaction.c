#include "hash_compaction.h"

void hash_compact
(state_t s,
 hash_compact_t * result) {
  int i;
  
  memset(result, 0, sizeof(hash_compact_t));
  for(i = 0; i < CFG_HASH_COMPACTION_KEYS; i++) {
    result->keys[i] = state_hash(s);
  }
}

bool_t hash_compact_equal
(hash_compact_t h1,
 hash_compact_t h2) {
  int i;
  
  for(i = 0; i < CFG_HASH_COMPACTION_KEYS; i++) {
    if(h1.keys[i] != h2.keys[i]) {
      return FALSE;
    }
  }
  return TRUE;
}
