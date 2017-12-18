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

#include "heap.h"
#include "config.h"


/**
 * @typedef htbl_type_t
 * @brief hash table type
 */
typedef enum {
  HTBL_HASH_COMPACTION,
  HTBL_FULL_DYNAMIC,
  HTBL_FULL_STATIC
} htbl_type_t;


/**
 * @typedef htbl_insert_code_t
 * @brief result of insert
 */
typedef enum {
  HTBL_INSERT_FULL,
  HTBL_INSERT_OK,
  HTBL_INSERT_FOUND
} htbl_insert_code_t;


/**
 * @typedef attr_state_t
 * @brief state attribute definitions
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

#define ATTR_ID(a) (1 << a)

typedef struct struct_htbl_t * htbl_t;

typedef uint16_t htbl_data_size_t;

typedef uint64_t htbl_id_t;

typedef void (* htbl_compress_func_t) (void *, char *, uint16_t *);

typedef void * (* htbl_uncompress_func_t) (char *, heap_t);

typedef void (* htbl_fold_func_t) (void *, htbl_id_t, void *);


/**
 * @brief htbl_new
 */
htbl_t htbl_new
(bool_t use_system_heap,
 uint64_t hash_bits,
 uint16_t no_workers,
 htbl_type_t type,
 htbl_data_size_t data_size,
 uint32_t attrs,
 htbl_compress_func_t compress_func,
 htbl_uncompress_func_t uncompress_func);


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
 void * data,
 htbl_id_t * id,
 hkey_t * h);


/**
 * @brief htbl_insert
 */
htbl_insert_code_t htbl_insert
(htbl_t tbl,
 void * data,
 htbl_id_t * id,
 hkey_t * h);


/**
 * @brief htbl_get
 */
void * htbl_get
(htbl_t tbl,
 htbl_id_t id,
 heap_t heap);


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
 * @brief htbl_has_attr
 */
bool_t htbl_has_attr
(htbl_t tbl,
 attr_state_t attr);

#endif
