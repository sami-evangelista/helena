#ifndef LIB_HASH_TBL
#define LIB_HASH_TBL

#include "state.h"
#include "event.h"
#include "heap.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

void init_hash_tbl ();
void free_hash_tbl ();

typedef uint8_t pos_t;

typedef struct {
  hash_key_t h;
  pos_t p;
} hash_tbl_id_t;

#ifdef HASH_STANDARD
typedef bit_vector_t encoded_state_t;
#elif defined (HASH_DELTA)
#define ENCODED_STATE_CHAR_WIDTH                        \
  (ATTRIBUTES_CHAR_WIDTH + sizeof (bit_vector_t))
typedef char encoded_state_t[ENCODED_STATE_CHAR_WIDTH];
#elif defined (HASH_COMPACTION)
#define ENCODED_STATE_CHAR_WIDTH                \
  (ATTRIBUTES_CHAR_WIDTH + sizeof (hash_key_t))
typedef char encoded_state_t[ENCODED_STATE_CHAR_WIDTH];
#endif

typedef void (* hash_tbl_fold_func_t) (state_t, hash_tbl_id_t, void *);

hash_tbl_id_t null_hash_tbl_id;

unsigned int hash_tbl_id_char_width;

bool_t hash_tbl_id_is_null
(hash_tbl_id_t id);

void hash_tbl_id_serialise
(hash_tbl_id_t id,
 bit_vector_t v);

hash_tbl_id_t hash_tbl_id_unserialise
(bit_vector_t v);

order_t hash_tbl_id_cmp
(hash_tbl_id_t id1,
 hash_tbl_id_t id2);

typedef struct {
  uint64_t hash_size;
  uint64_t events_executed[NO_WORKERS];
  uint64_t state_cmps[NO_WORKERS];
  unsigned short no_states[HASH_SIZE];
  encoded_state_t * states[HASH_SIZE];
  unsigned int seed;
#ifdef HASH_DELTA
  heap_t reconstruction_heaps[NO_WORKERS];
#endif
#ifdef STATE_CACHING
  hash_tbl_id_t cache[STATE_CACHING_CACHE_SIZE];
  unsigned int cache_size;
  unsigned int cache_ctr;
#endif
} struct_hash_tbl_t;

typedef struct_hash_tbl_t * hash_tbl_t;

hash_tbl_t hash_tbl_default_new
();

hash_tbl_t hash_tbl_new
(uint64_t hash_size);

void hash_tbl_free
(hash_tbl_t storage);

void hash_tbl_insert
(hash_tbl_t storage,
 state_t s,
 hash_tbl_id_t * pred,
 event_id_t * exec,
 unsigned int depth,
 worker_id_t w,
 bool_t * is_new,
 hash_tbl_id_t * id,
 hash_key_t * h);

void hash_tbl_remove
(hash_tbl_t storage,
 hash_tbl_id_t id);

void hash_tbl_lookup
(hash_tbl_t storage,
 state_t s,
 worker_id_t w,
 bool_t * found,
 hash_tbl_id_t * id);

uint64_t storage_size
(hash_tbl_t storage);

order_t hash_tbl_id_cmp
(hash_tbl_id_t id1,
 hash_tbl_id_t id2);

state_t hash_tbl_get
(hash_tbl_t storage,
 hash_tbl_id_t id,
 worker_id_t w);

state_t hash_tbl_get_mem
(hash_tbl_t storage,
 hash_tbl_id_t id,
 worker_id_t w,
 heap_t heap);

void hash_tbl_set_cyan
(hash_tbl_t storage,
 hash_tbl_id_t id,
 worker_id_t w,
 bool_t cyan);

bool_t hash_tbl_get_cyan
(hash_tbl_t storage,
 hash_tbl_id_t id,
 worker_id_t w);

void hash_tbl_set_blue
(hash_tbl_t storage,
 hash_tbl_id_t id,
 bool_t blue);

bool_t hash_tbl_get_blue
(hash_tbl_t storage,
 hash_tbl_id_t id);

void hash_tbl_set_pink
(hash_tbl_t storage,
 hash_tbl_id_t id,
 worker_id_t w,
 bool_t pink);

bool_t hash_tbl_get_pink
(hash_tbl_t storage,
 hash_tbl_id_t id,
 worker_id_t w);

void hash_tbl_set_red
(hash_tbl_t storage,
 hash_tbl_id_t id,
 bool_t red);

bool_t hash_tbl_get_red
(hash_tbl_t storage,
 hash_tbl_id_t id);

uint64_t hash_tbl_size
(hash_tbl_t storage);

void hash_tbl_fold
(hash_tbl_t storage,
 worker_id_t w,
 hash_tbl_fold_func_t f,
 void * data);

void hash_tbl_output_stats
(hash_tbl_t storage,
 FILE * out);

#endif
