/**
 * @file storage.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Storage definition.
 */

#ifndef LIB_STORAGE
#define LIB_STORAGE

#include "hash_tbl.h"
#include "delta_ddd.h"
#include "config.h"

#define ATTR_CYAN     1
#define ATTR_BLUE     2
#define ATTR_PINK     4
#define ATTR_RED      8
#define ATTR_GARBAGE  16
#define ATTR_REFS     32
#define ATTR_PRED     64
#define ATTR_EVT      128

/*****
 *  storage used by delta-ddd algorithm
 *****/
#if defined (CFG_DELTA_DDD_STORAGE)

typedef delta_ddd_storage_t storage_t;
typedef delta_ddd_storage_id_t storage_id_t;

#define storage_new          delta_ddd_storage_new
#define storage_free         delta_ddd_storage_free
#define storage_size         delta_ddd_storage_size
#define storage_barrier_time delta_ddd_storage_barrier_time
#define storage_dd_time      delta_ddd_storage_dd_time


/*****
 *  default storage is hash table
 *****/
#else

typedef hash_tbl_t storage_t;
typedef hash_tbl_id_t storage_id_t;

#define storage_new               hash_tbl_default_new
#define storage_free              hash_tbl_free
#define storage_size              hash_tbl_size
#define storage_insert            hash_tbl_insert
#define storage_insert_hashed     hash_tbl_insert_hashed
#define storage_insert_serialised hash_tbl_insert_serialised
#define storage_remove            hash_tbl_remove
#define storage_get_serialised    hash_tbl_get_serialised
#define storage_get               hash_tbl_get
#define storage_get_mem           hash_tbl_get_mem
#define storage_get_hash          hash_tbl_get_hash
#define storage_set_cyan          hash_tbl_set_cyan
#define storage_get_cyan          hash_tbl_get_cyan
#define storage_get_any_cyan      hash_tbl_get_any_cyan
#define storage_set_blue          hash_tbl_set_blue
#define storage_get_blue          hash_tbl_get_blue
#define storage_set_pink          hash_tbl_set_pink
#define storage_get_pink          hash_tbl_get_pink
#define storage_set_red           hash_tbl_set_red
#define storage_get_red           hash_tbl_get_red
#define storage_set_garbage       hash_tbl_set_garbage
#define storage_set_pred          hash_tbl_set_pred
#define storage_ref               hash_tbl_ref
#define storage_unref             hash_tbl_unref
#define storage_gc                hash_tbl_gc
#define storage_gc_all            hash_tbl_gc_all
#define storage_gc_time           hash_tbl_gc_time
#define storage_gc_barrier        hash_tbl_gc_barrier
#define storage_has_attr          hash_tbl_has_attr
#define storage_get_trace         hash_tbl_get_trace

#endif

#endif
