#ifndef LIB_SHARED_HASH_TBL
#define LIB_SHARED_HASH_TBL

#include "state.h"
#include "event.h"
#include "heap.h"
#include "hash_compaction.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

void init_shared_hash_tbl
();

void free_shared_hash_tbl
();

typedef uint8_t bucket_status_t;

#define BUCKET_EMPTY 1
#define BUCKET_READY 2
#define BUCKET_WRITE 3

#define MAX_TRIALS 1000

typedef struct {
  uint64_t hash_size;
  heap_t heaps[NO_WORKERS];
  uint64_t size[NO_WORKERS];
  uint64_t state_cmps[NO_WORKERS];
  bucket_status_t update_status[HASH_SIZE];
  bucket_status_t status[HASH_SIZE];
#ifdef HASH_COMPACTION
  char state[HASH_SIZE][ATTRIBUTES_CHAR_WIDTH + sizeof(hash_compact_t)];
#else
  bit_vector_t state[HASH_SIZE];
#endif
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

void shared_hash_tbl_insert
(shared_hash_tbl_t tbl,
 state_t s,
 shared_hash_tbl_id_t * pred,
 event_id_t * exec,
 unsigned int depth,
 worker_id_t w,
 bool_t * is_new,
 shared_hash_tbl_id_t * id);

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

void shared_hash_tbl_update_refs
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 int update);

void shared_hash_tbl_build_trace
(shared_hash_tbl_t tbl,
 worker_id_t w,
 shared_hash_tbl_id_t id,
 event_t ** trace,
 unsigned int * trace_len);

void shared_hash_tbl_output_stats
(shared_hash_tbl_t tbl,
 FILE * out);

#endif
