#ifndef LIB_SHARED_HASH_TBL
#define LIB_SHARED_HASH_TBL

#include "state.h"
#include "event.h"
#include "heap.h"
#include "hash_compaction.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

void init_shared_hash_tbl
();

void free_shared_hash_tbl
();

typedef uint8_t bucket_status_t;

#if defined(CFG_DISTRIBUTED)
#define NO_WORKERS_STORAGE (CFG_NO_WORKERS + 1)
#else
#define NO_WORKERS_STORAGE (CFG_NO_WORKERS)
#endif

typedef struct {
  uint64_t hash_size;
  heap_t heaps[NO_WORKERS_STORAGE];
  uint64_t size[NO_WORKERS_STORAGE];
  uint64_t state_cmps[NO_WORKERS_STORAGE];
  bucket_status_t update_status[CFG_HASH_SIZE];
  bucket_status_t status[CFG_HASH_SIZE];
#ifdef CFG_HASH_COMPACTION
  char state[CFG_HASH_SIZE][ATTRIBUTES_CHAR_WIDTH + sizeof(hash_compact_t)];
#else
  bit_vector_t state[CFG_HASH_SIZE];
  hash_key_t hash[CFG_HASH_SIZE];
#endif
  pthread_barrier_t barrier;
} struct_shared_hash_tbl_t;

typedef struct_shared_hash_tbl_t * shared_hash_tbl_t;

typedef uint64_t shared_hash_tbl_id_t;

unsigned int shared_hash_tbl_id_char_width;

void shared_hash_tbl_id_serialise
(shared_hash_tbl_id_t id,
 bit_vector_t v);

shared_hash_tbl_id_t shared_hash_tbl_id_unserialise
(bit_vector_t v);

order_t shared_hash_tbl_id_cmp
(shared_hash_tbl_id_t id1,
 shared_hash_tbl_id_t id2);

shared_hash_tbl_t shared_hash_tbl_new
(uint64_t hash_size);

shared_hash_tbl_t shared_hash_tbl_default_new
();

void shared_hash_tbl_free
(shared_hash_tbl_t tbl);

uint64_t shared_hash_tbl_size
(shared_hash_tbl_t tbl);

void shared_hash_tbl_insert_serialised
(shared_hash_tbl_t tbl,
 bit_vector_t s,
 uint16_t s_char_len,
 hash_key_t h,
 worker_id_t w,
 bool_t * is_new,
 shared_hash_tbl_id_t * id);

void shared_hash_tbl_insert
(shared_hash_tbl_t tbl,
 state_t s,
 worker_id_t w,
 bool_t * is_new,
 shared_hash_tbl_id_t * id,
 hash_key_t * h);

void shared_hash_tbl_remove
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id);

void shared_hash_tbl_lookup
(shared_hash_tbl_t tbl,
 state_t s,
 worker_id_t w,
 bool_t * found,
 shared_hash_tbl_id_t * id);

state_t shared_hash_tbl_get
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 worker_id_t w);

state_t shared_hash_tbl_get_mem
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 worker_id_t w,
 heap_t heap);

void shared_hash_tbl_get_serialised
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 bit_vector_t * s,
 uint16_t * size);

hash_key_t shared_hash_tbl_get_hash
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id);

void shared_hash_tbl_set_cyan
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 worker_id_t w,
 bool_t cyan);

bool_t shared_hash_tbl_get_cyan
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 worker_id_t w);

void shared_hash_tbl_set_blue
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 bool_t blue);

bool_t shared_hash_tbl_get_blue
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id);

void shared_hash_tbl_set_pink
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 worker_id_t w,
 bool_t pink);

bool_t shared_hash_tbl_get_pink
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 worker_id_t w);

void shared_hash_tbl_set_red
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 bool_t red);

bool_t shared_hash_tbl_get_red
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id);

void shared_hash_tbl_ref
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id);

void shared_hash_tbl_unref
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id);

bool_t shared_hash_tbl_do_gc
(shared_hash_tbl_t tbl,
 worker_id_t w);

void shared_hash_tbl_gc
(shared_hash_tbl_t tbl,
 worker_id_t w);

void shared_hash_tbl_wait_barrier
(shared_hash_tbl_t tbl);

void shared_hash_tbl_output_stats
(shared_hash_tbl_t tbl,
 FILE * out);

#endif
