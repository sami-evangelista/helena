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
#include "config.h"


/**
 * state attribute definitions
 */
#define ATTR_CYAN     0
#define ATTR_BLUE     1
#define ATTR_PINK     2
#define ATTR_RED      3
#define ATTR_PRED     4
#define ATTR_EVT      5
#define ATTR_INDEX    6
#define ATTR_LOWLINK  7
#define ATTR_LIVE     8

typedef struct struct_hash_tbl_t * hash_tbl_t;

typedef uint64_t hash_tbl_id_t;

typedef void (* hash_tbl_fold_func_t)
(state_t, hash_tbl_id_t, void *);


/**
 * @brief hash_tbl_new
 */
hash_tbl_t hash_tbl_new
(uint64_t hash_size,
 uint16_t no_workers,
 bool_t hash_compaction,
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
 * @brief hash_tbl_erase
 */
void hash_tbl_erase
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
 uint16_t * size,
 hash_key_t * h);


/**
 * @brief hash_tbl_get_hash
 */
hash_key_t hash_tbl_get_hash
(hash_tbl_t tbl,
 hash_tbl_id_t id);


/**
 * @brief hash_tbl_get_attr
 */
uint64_t hash_tbl_get_attr
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 uint32_t attr);


/**
 * @brief hash_tbl_set_attr
 */
void hash_tbl_set_attr
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 uint32_t attr,
 uint64_t val);


/**
 * @brief hash_tbl_get_worker_attr
 */
uint64_t hash_tbl_get_worker_attr
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 uint32_t attr,
 worker_id_t w);


/**
 * @brief hash_tbl_set_worker_attr
 */
void hash_tbl_set_worker_attr
(hash_tbl_t tbl,
 hash_tbl_id_t id,
 uint32_t attr,
 worker_id_t w,
 uint64_t val);


/**
 * @brief hash_tbl_get_any_cyan
 */
bool_t hash_tbl_get_any_cyan
(hash_tbl_t tbl,
 hash_tbl_id_t id);


/**
 * @brief hash_tbl_fold
 */
void hash_tbl_fold
(hash_tbl_t tbl,
 hash_tbl_fold_func_t f,
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
 * @brief hash_tbl_get_trace
 */
list_t hash_tbl_get_trace
(hash_tbl_t tbl,
 hash_tbl_id_t id);

#endif
