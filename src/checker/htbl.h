/**
 * @file htbl.h
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

#ifndef LIB_HTBL
#define LIB_HTBL

#include "state.h"
#include "event.h"
#include "heap.h"
#include "config.h"


/**
 * hash table type
 */
typedef enum {
  HTBL_HASH_COMPACTION,
  HTBL_BITSTATE,
  HTBL_FULL
} htbl_type_t;


/**
 * state attribute definitions
 */
typedef enum {
  ATTR_CYAN,
  ATTR_BLUE,
  ATTR_PINK,
  ATTR_RED,
  ATTR_PRED,
  ATTR_EVT,
  ATTR_INDEX,
  ATTR_LOWLINK,
  ATTR_LIVE,
  ATTR_SAFE,
  ATTR_UNSAFE_SUCC,
  ATTR_TO_REVISIT
} attr_state_t;

typedef struct struct_htbl_t * htbl_t;

typedef uint64_t htbl_id_t;

typedef void (* htbl_fold_func_t)
(state_t, htbl_id_t, void *);


/**
 * @brief htbl_new
 */
htbl_t htbl_new
(bool_t use_system_heap,
 uint64_t hash_size,
 uint16_t no_workers,
 htbl_type_t type,
 uint32_t attrs);


/**
 * @brief htbl_default_new
 */
htbl_t htbl_default_new
();


/**
 * @brief htbl_free
 */
void htbl_free
(htbl_t tbl);


/**
 * @brief htbl_contains
 */
bool_t htbl_contains
(htbl_t tbl,
 state_t s,
 htbl_id_t * id,
 hash_key_t * h);


/**
 * @brief htbl_insert
 */
void htbl_insert
(htbl_t tbl,
 state_t s,
 bool_t * is_new,
 htbl_id_t * id,
 hash_key_t * h);


/**
 * @brief htbl_insert_hashed
 */
void htbl_insert_hashed
(htbl_t tbl,
 state_t s,
 hash_key_t h,
 bool_t * is_new,
 htbl_id_t * id);


/**
 * @brief htbl_insert_serialised
 */
void htbl_insert_serialised
(htbl_t tbl,
 bit_vector_t s,
 uint16_t s_char_len,
 hash_key_t h,
 bool_t * is_new,
 htbl_id_t * id);


/**
 * @brief htbl_erase
 */
void htbl_erase
(htbl_t tbl,
 htbl_id_t id);


/**
 * @brief htbl_get
 */
state_t htbl_get
(htbl_t tbl,
 htbl_id_t id);


/**
 * @brief htbl_get_mem
 */
state_t htbl_get_mem
(htbl_t tbl,
 htbl_id_t id,
 heap_t heap);


/**
 * @brief htbl_get_serialised
 */
void htbl_get_serialised
(htbl_t tbl,
 htbl_id_t id,
 bit_vector_t * s,
 uint16_t * size,
 hash_key_t * h);


/**
 * @brief htbl_get_hash
 */
hash_key_t htbl_get_hash
(htbl_t tbl,
 htbl_id_t id);


/**
 * @brief htbl_get_attr
 */
uint64_t htbl_get_attr
(htbl_t tbl,
 htbl_id_t id,
 attr_state_t attr);


/**
 * @brief htbl_set_attr
 */
void htbl_set_attr
(htbl_t tbl,
 htbl_id_t id,
 attr_state_t attr,
 uint64_t val);


/**
 * @brief htbl_get_worker_attr
 */
uint64_t htbl_get_worker_attr
(htbl_t tbl,
 htbl_id_t id,
 attr_state_t attr,
 worker_id_t w);


/**
 * @brief htbl_set_worker_attr
 */
void htbl_set_worker_attr
(htbl_t tbl,
 htbl_id_t id,
 attr_state_t attr,
 worker_id_t w,
 uint64_t val);


/**
 * @brief htbl_get_any_cyan
 */
bool_t htbl_get_any_cyan
(htbl_t tbl,
 htbl_id_t id);


/**
 * @brief htbl_fold
 */
void htbl_fold
(htbl_t tbl,
 htbl_fold_func_t f,
 void * data);


/**
 * @brief htbl_reset
 */
void htbl_reset
(htbl_t tbl);


/**
 * @brief htbl_has_attr
 */
bool_t htbl_has_attr
(htbl_t tbl,
 attr_state_t attr);


/**
 * @brief htbl_get_trace
 */
list_t htbl_get_trace
(htbl_t tbl,
 htbl_id_t id);

#endif
