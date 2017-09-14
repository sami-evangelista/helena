/**
 * @file hash_tbl.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Implementation of an hash table supporting concurrent accesses.
 */

#ifndef LIB_HASH_TBL
#define LIB_HASH_TBL

#include "state.h"
#include "event.h"
#include "heap.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

void init_hash_tbl
();

void free_hash_tbl
();

typedef uint8_t bucket_status_t;

#if defined(CFG_DISTRIBUTED)
#define NO_WORKERS_STORAGE (CFG_NO_WORKERS + 1)
#else
#define NO_WORKERS_STORAGE (CFG_NO_WORKERS)
#endif

#if !defined(CFG_HASH_COMPACTION)
#define STORAGE_STATE_RECOVERABLE
#endif

typedef struct {
  uint64_t hash_size;
  heap_t heaps[NO_WORKERS_STORAGE];
  uint64_t size[NO_WORKERS_STORAGE];
  uint64_t state_cmps[NO_WORKERS_STORAGE];
  bucket_status_t update_status[CFG_HASH_SIZE];
  bucket_status_t status[CFG_HASH_SIZE];
#if defined(CFG_HASH_COMPACTION)
  char state[CFG_HASH_SIZE][CFG_ATTRS_CHAR_SIZE + sizeof(hash_key_t)];
#else
  bit_vector_t state[CFG_HASH_SIZE];
  hash_key_t hash[CFG_HASH_SIZE];
#endif
  uint64_t gc_time;
  pthread_barrier_t barrier;
  uint32_t seeds[NO_WORKERS_STORAGE];
} struct_hash_tbl_t;

typedef struct_hash_tbl_t * hash_tbl_t;

typedef uint64_t hash_tbl_id_t;

unsigned int hash_tbl_id_char_width;

void hash_tbl_id_serialise
(hash_tbl_id_t id,
 bit_vector_t v);

hash_tbl_id_t hash_tbl_id_unserialise
(bit_vector_t v);

order_t hash_tbl_id_cmp
(hash_tbl_id_t id1,
 hash_tbl_id_t id2);

hash_tbl_t hash_tbl_new
(uint64_t hash_size);

hash_tbl_t hash_tbl_default_new
();

void hash_tbl_free
(hash_tbl_t tbl);

uint64_t hash_tbl_size
(hash_tbl_t tbl);

void hash_tbl_insert
(hash_tbl_t tbl,
 state_t s,
 worker_id_t w,
 bool_t * is_new,
 hash_tbl_id_t * id,
 hash_key_t * h);

void hash_tbl_insert_hashed
(hash_tbl_t tbl,
 state_t s,
 worker_id_t w,
 hash_key_t h,
 bool_t * is_new,
 hash_tbl_id_t * id);

void hash_tbl_insert_serialised
(hash_tbl_t tbl,
 bit_vector_t s,
 uint16_t s_char_len,
 hash_key_t h,
 worker_id_t w,
 bool_t * is_new,
 hash_tbl_id_t * id);

void hash_tbl_remove
(hash_tbl_t tbl,
 hash_tbl_id_t id);

state_t hash_tbl_get
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w);

state_t hash_tbl_get_mem
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 heap_t heap);

void hash_tbl_get_serialised
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bit_vector_t * s,
 uint16_t * size);

hash_key_t hash_tbl_get_hash
(hash_tbl_t tbl,
 hash_tbl_id_t id);

void hash_tbl_set_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 bool_t cyan);

bool_t hash_tbl_get_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w);

void hash_tbl_set_blue
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t blue);

bool_t hash_tbl_get_blue
(hash_tbl_t tbl,
 hash_tbl_id_t id);

void hash_tbl_set_pink
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 bool_t pink);

bool_t hash_tbl_get_pink
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w);

void hash_tbl_set_red
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t red);

bool_t hash_tbl_get_red
(hash_tbl_t tbl,
 hash_tbl_id_t id);

void hash_tbl_ref
(hash_tbl_t tbl,
 hash_tbl_id_t id);

void hash_tbl_unref
(hash_tbl_t tbl,
 hash_tbl_id_t id);

bool_t hash_tbl_do_gc
(hash_tbl_t tbl,
 worker_id_t w);

void hash_tbl_gc
(hash_tbl_t tbl,
 worker_id_t w);
    
void hash_tbl_gc_all
(hash_tbl_t tbl,
 worker_id_t w);

void hash_tbl_wait_barrier
(hash_tbl_t tbl);

void hash_tbl_output_stats
(hash_tbl_t tbl,
 FILE * out);

#endif
