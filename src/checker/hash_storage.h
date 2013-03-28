#ifndef LIB_HASH_STORAGE
#define LIB_HASH_STORAGE

#include "state.h"
#include "event.h"
#include "heap.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

void init_hash_storage ();
void free_hash_storage ();

typedef uint8_t pos_t;

typedef struct {
  hash_key_t h;
  pos_t p;
} hash_storage_id_t;

#ifdef STORAGE_HASH
typedef bit_vector_t encoded_state_t;
#elif defined (STORAGE_DELTA)
#define ENCODED_STATE_CHAR_WIDTH			\
  (ATTRIBUTES_CHAR_WIDTH + sizeof (bit_vector_t))
typedef char encoded_state_t[ENCODED_STATE_CHAR_WIDTH];
#elif defined (STORAGE_HASH_COMPACTION)
#define ENCODED_STATE_CHAR_WIDTH		\
  (ATTRIBUTES_CHAR_WIDTH + sizeof (hash_key_t))
typedef char encoded_state_t[ENCODED_STATE_CHAR_WIDTH];
#endif

typedef struct {
#ifdef ATTRIBUTE_NUM
  uint32_t num;
#endif
#ifdef ATTRIBUTE_IN_UNPROC
  bool_t in_unproc;
#endif
#ifdef ATTRIBUTE_REFS
  unsigned int refs;
#endif
#ifdef ATTRIBUTE_PRED
  hash_storage_id_t pred;
#endif
#ifdef ATTRIBUTE_IS_RED
  bool_t is_red;
#endif
} hash_storage_state_attr_t;

typedef void (* hash_storage_fold_func_t) (state_t, hash_storage_id_t, void *);

hash_storage_id_t null_hash_storage_id;

unsigned int hash_storage_id_char_width;

bool_t hash_storage_id_is_null
(hash_storage_id_t id);

void hash_storage_id_serialise
(hash_storage_id_t id,
 bit_vector_t v);

hash_storage_id_t hash_storage_id_unserialise
(bit_vector_t v);

order_t hash_storage_id_cmp
(hash_storage_id_t id1,
 hash_storage_id_t id2);

typedef struct {
  large_unsigned_t  hash_size;
  large_unsigned_t  events_executed[NO_WORKERS];
  large_unsigned_t  state_cmps[NO_WORKERS];
  unsigned short    no_states[HASH_SIZE];
  encoded_state_t * states[HASH_SIZE];
  state_num_t       state_next_num;
  unsigned int      seed;
#ifdef STORAGE_DELTA
  heap_t            reconstruction_heaps[NO_WORKERS];
#endif
#ifdef STATE_CACHING
  hash_storage_id_t cache[STATE_CACHING_CACHE_SIZE];
  unsigned int      cache_size;
  unsigned int      cache_ctr;
#endif
} struct_hash_storage_t;

typedef struct_hash_storage_t * hash_storage_t;

hash_storage_t hash_storage_default_new
();

hash_storage_t hash_storage_new
(large_unsigned_t hash_size);

void hash_storage_free
(hash_storage_t storage);

void hash_storage_insert
(hash_storage_t      storage,
 state_t             s,
 hash_storage_id_t * pred,
 event_id_t *        exec,
 unsigned int        depth,
 worker_id_t         w,
 bool_t *            is_new,
 hash_storage_id_t * id);

void hash_storage_remove
(hash_storage_t    storage,
 hash_storage_id_t id);

large_unsigned_t storage_size
(hash_storage_t storage);

order_t hash_storage_id_cmp
(hash_storage_id_t id1,
 hash_storage_id_t id2);

state_t hash_storage_get
(hash_storage_t    storage,
 hash_storage_id_t ptr,
 worker_id_t       w);

state_t hash_storage_get_mem
(hash_storage_t    storage,
 hash_storage_id_t ptr,
 worker_id_t       w,
 heap_t            heap);

#ifdef ATTRIBUTE_IN_UNPROC
void hash_storage_set_in_unproc
(hash_storage_t    storage,
 hash_storage_id_t id,
 bool_t            in_unproc);
#else
#define hash_storage_set_in_unproc(s, i, val) {}
#endif

bool_t hash_storage_get_in_unproc
(hash_storage_t    storage,
 hash_storage_id_t id);

state_num_t hash_storage_get_num
(hash_storage_t    storage,
 hash_storage_id_t id);

void hash_storage_update_refs
(hash_storage_t    storage,
 hash_storage_id_t id,
 int               update);

void hash_storage_get_attr
(hash_storage_t              storage,
 state_t                     s,
 worker_id_t                 w,
 bool_t *                    found,
 hash_storage_id_t *         id,
 hash_storage_state_attr_t * attrs);

void hash_storage_build_trace
(hash_storage_t    storage,
 worker_id_t       w,
 hash_storage_id_t id,
 event_t **        trace,
 unsigned int *    trace_len);

void hash_storage_set_is_red
(hash_storage_t    storage,
 hash_storage_id_t id);

void hash_storage_fold
(hash_storage_t           storage,
 worker_id_t              w,
 hash_storage_fold_func_t f,
 void *                   data);

void hash_storage_output_stats
(hash_storage_t storage,
 FILE *         out);

#endif
