/**
 * @file hash_tbl.h
 * @brief Implementation of an hash table supporting concurrent accesses.
 * @date 12 sep 2017
 * @author Sami Evangelista
 *
 * The hash table is a small variation of the structure presented in:
 *
 * Boosting Multi-Core Reachability Performance with Shared Hash Tables
 * by Alfons Laarman, Jaco van de Pol, Michael Weber.
 * in Formal Methods in Computer-Aided Design.
 *
 */

#ifndef LIB_HASH_TBL
#define LIB_HASH_TBL

#include "state.h"
#include "event.h"
#include "heap.h"

#if !defined(CFG_HASH_COMPACTION)
#define STORAGE_STATE_RECOVERABLE
#endif

typedef struct struct_hash_tbl_t * hash_tbl_t;

typedef uint64_t hash_tbl_id_t;

typedef void (* hash_tbl_fold_func_t)
(state_t, hash_tbl_id_t, void *);

typedef void (* hash_tbl_fold_serialised_func_t)
(bit_vector_t, uint16_t, hash_key_t, void *);


/**
 * @brief hash_tbl_new
 */
hash_tbl_t hash_tbl_new
(uint64_t hash_size,
 uint16_t no_workers,
 bool_t hash_compaction,
 uint8_t gc_threshold,
 float gc_ratio,
 uint32_t attrs);


/**
 * @brief hash_tbl_default_new
 */
hash_tbl_t hash_tbl_default_new
();


/**
 * @brief hash_tbl_free
 */
void hash_tbl_free
(hash_tbl_t tbl);


/**
 * @brief hash_tbl_size
 */
uint64_t hash_tbl_size
(hash_tbl_t tbl);


/**
 * @brief hash_tbl_insert
 */
void hash_tbl_insert
(hash_tbl_t tbl,
 state_t s,
 worker_id_t w,
 bool_t * is_new,
 hash_tbl_id_t * id,
 hash_key_t * h);


/**
 * @brief hash_tbl_insert_hashed
 */
void hash_tbl_insert_hashed
(hash_tbl_t tbl,
 state_t s,
 worker_id_t w,
 hash_key_t h,
 bool_t * is_new,
 hash_tbl_id_t * id);


/**
 * @brief hash_tbl_insert_serialised
 */
void hash_tbl_insert_serialised
(hash_tbl_t tbl,
 bit_vector_t s,
 uint16_t s_char_len,
 hash_key_t h,
 worker_id_t w,
 bool_t * is_new,
 hash_tbl_id_t * id);


/**
 * @brief hash_tbl_remove
 */
void hash_tbl_remove
(hash_tbl_t tbl,
 worker_id_t w,
 hash_tbl_id_t id);


/**
 * @brief hash_tbl_get
 */
state_t hash_tbl_get
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w);


/**
 * @brief hash_tbl_get_mem
 */
state_t hash_tbl_get_mem
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 heap_t heap);


/**
 * @brief hash_tbl_get_serialised
 */
void hash_tbl_get_serialised
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bit_vector_t * s,
 uint16_t * size);


/**
 * @brief hash_tbl_get_hash
 */
hash_key_t hash_tbl_get_hash
(hash_tbl_t tbl,
 hash_tbl_id_t id);


/**
 * @brief hash_tbl_set_cyan
 */
void hash_tbl_set_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 bool_t cyan);


/**
 * @brief hash_tbl_get_cyan
 */
bool_t hash_tbl_get_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w);


/**
 * @brief hash_tbl_get_any_cyan
 */
bool_t hash_tbl_get_any_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id);


/**
 * @brief hash_tbl_set_blue
 */
void hash_tbl_set_blue
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t blue);


/**
 * @brief hash_tbl_get_blue
 */
bool_t hash_tbl_get_blue
(hash_tbl_t tbl,
 hash_tbl_id_t id);


/**
 * @brief hash_tbl_set_pink
 */
void hash_tbl_set_pink
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w,
 bool_t pink);


/**
 * @brief hash_tbl_get_pink
 */
bool_t hash_tbl_get_pink
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 worker_id_t w);


/**
 * @brief hash_tbl_set_red
 */
void hash_tbl_set_red
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t red);


/**
 * @brief hash_tbl_get_red
 */
bool_t hash_tbl_get_red
(hash_tbl_t tbl,
 hash_tbl_id_t id);


/**
 * @brief hash_tbl_set_expanded
 */
void hash_tbl_set_expanded
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t expanded);


/**
 * @brief hash_tbl_get_expanded
 */
bool_t hash_tbl_get_expanded
(hash_tbl_t tbl,
 hash_tbl_id_t id);


/**
 * @brief hash_tbl_set_garbage
 */
void hash_tbl_set_garbage
(hash_tbl_t tbl,
 worker_id_t w,
 hash_tbl_id_t id,
 bool_t garbage);


/**
 * @brief hash_tbl_ref
 */
void hash_tbl_ref
(hash_tbl_t tbl,
 worker_id_t w,
 hash_tbl_id_t id);


/**
 * @brief hash_tbl_unref
 */
void hash_tbl_unref
(hash_tbl_t tbl,
 worker_id_t w,
 hash_tbl_id_t id);


/**
 * @brief hash_tbl_gc
 */
void hash_tbl_gc
(hash_tbl_t tbl,
 worker_id_t w);


/**
 * @brief hash_tbl_gc_all
 */
void hash_tbl_gc_all
(hash_tbl_t tbl,
 worker_id_t w);


/**
 * @brief hash_tbl_gc_barrier
 */
void hash_tbl_gc_barrier
(hash_tbl_t tbl,
 worker_id_t w);


/**
 * @brief hash_tbl_gc_time
 */
uint64_t hash_tbl_gc_time
(hash_tbl_t tbl);


/**
 * @brief hash_tbl_output_stats
 */
void hash_tbl_output_stats
(hash_tbl_t tbl,
 FILE * out);


/**
 * @brief hash_tbl_fold
 */
void hash_tbl_fold
(hash_tbl_t tbl,
 hash_tbl_fold_func_t f,
 void * data);


/**
 * @brief hash_tbl_fold_serialised
 */
void hash_tbl_fold_serialised
(hash_tbl_t tbl,
 hash_tbl_fold_serialised_func_t f,
 void * data);


/**
 * @brief hash_tbl_set_heap
 */
void hash_tbl_set_heap
(hash_tbl_t tbl,
 heap_t h);


/**
 * @brief hash_tbl_has_attr
 */
bool_t hash_tbl_has_attr
(hash_tbl_t tbl,
 uint32_t attr);


/**
 * @brief hash_tbl_set_pred
 */
void hash_tbl_set_pred
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 bool_t pred_ok,
 hash_tbl_id_t pred,
 uint8_t evt);

#endif
