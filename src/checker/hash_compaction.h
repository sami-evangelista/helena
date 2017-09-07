#ifndef LIB_CFG_HASH_COMPACTION
#define LIB_CFG_HASH_COMPACTION

#include "state.h"

typedef struct {
  hash_key_t keys[CFG_HASH_COMPACTION_KEYS];
} hash_compact_t;

void hash_compact
(state_t s,
 hash_compact_t * result);

bool_t hash_compact_equal
(hash_compact_t h1,
 hash_compact_t h2);

#endif
