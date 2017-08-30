#ifndef LIB_SHARED_HASH_TBL
#define LIB_SHARED_HASH_TBL

#include "state.h"
#include "event.h"
#include "heap.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

typedef uint8_t bucket_status_t;

#define BUCKET_EMPTY 1
#define BUCKET_READY 2
#define BUCKET_WRITE 3

#define MAX_TRIALS 1000

typedef struct {
  large_unsigned_t hash_size;
  large_unsigned_t size[NO_WORKERS];
  large_unsigned_t state_cmps[NO_WORKERS];
  bucket_status_t status[HASH_SIZE];
  bit_vector_t state[HASH_SIZE];
  hash_key_t hash[HASH_SIZE];
} struct_shared_hash_tbl_t;

typedef struct_shared_hash_tbl_t * shared_hash_tbl_t;

typedef large_unsigned_t shared_hash_tbl_id_t;

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
(large_unsigned_t hash_size);

shared_hash_tbl_t shared_hash_tbl_default_new
();

void shared_hash_tbl_free
(shared_hash_tbl_t tbl);

large_unsigned_t shared_hash_tbl_size
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

void shared_hash_tbl_set_in_unproc
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id,
 bool_t in_unproc);

bool_t shared_hash_tbl_get_in_unproc
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id);

state_num_t shared_hash_tbl_get_num
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

bool_t shared_hash_tbl_get_is_red
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id);

void shared_hash_tbl_set_is_red
(shared_hash_tbl_t tbl,
 shared_hash_tbl_id_t id);

void shared_hash_tbl_output_stats
(shared_hash_tbl_t tbl,
 FILE * out);

void init_shared_hash_tbl
();

void free_shared_hash_tbl
();

#endif
