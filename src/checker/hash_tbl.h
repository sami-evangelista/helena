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

#if defined(CFG_DISTRIBUTED)
#define NO_WORKERS_STORAGE (CFG_NO_WORKERS + 1)
#else
#define NO_WORKERS_STORAGE (CFG_NO_WORKERS)
#endif

#if !defined(CFG_HASH_COMPACTION)
#define STORAGE_STATE_RECOVERABLE
#endif

unsigned int hash_tbl_id_char_width;

typedef struct struct_hash_tbl_t * hash_tbl_t;

typedef uint64_t hash_tbl_id_t;

typedef void(* hash_tbl_fold_func_t)(state_t, hash_tbl_id_t, void *);

void init_hash_tbl
();

void free_hash_tbl
();

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

void hash_tbl_barrier
(hash_tbl_t tbl);

uint64_t hash_tbl_gc_time
(hash_tbl_t tbl);

void hash_tbl_output_stats
(hash_tbl_t tbl,
 FILE * out);

void hash_tbl_fold
(hash_tbl_t tbl,
 hash_tbl_fold_func_t f,
 void * data);

#endif
