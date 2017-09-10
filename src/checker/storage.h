#ifndef LIB_STORAGE
#define LIB_STORAGE

#include "hash_tbl.h"
#include "pd4.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif


/*****
 *  hash table
 *****/
#if defined (CFG_HASH_STORAGE)

typedef hash_tbl_t storage_t;
typedef hash_tbl_id_t storage_id_t;

#define init_storage              init_hash_tbl
#define free_storage              free_hash_tbl
#define storage_id_serialise      hash_tbl_id_serialise
#define storage_id_unserialise    hash_tbl_id_unserialise
#define storage_id_char_width     hash_tbl_id_char_width
#define storage_new               hash_tbl_default_new
#define storage_free              hash_tbl_free
#define storage_size              hash_tbl_size
#define storage_insert            hash_tbl_insert
#define storage_insert_serialised hash_tbl_insert_serialised
#define storage_remove            hash_tbl_remove
#define storage_id_cmp            hash_tbl_id_cmp
#define storage_get_serialised    hash_tbl_get_serialised
#define storage_get               hash_tbl_get
#define storage_get_mem           hash_tbl_get_mem
#define storage_get_hash          hash_tbl_get_hash
#define storage_set_cyan          hash_tbl_set_cyan
#define storage_get_cyan          hash_tbl_get_cyan
#define storage_set_blue          hash_tbl_set_blue
#define storage_get_blue          hash_tbl_get_blue
#define storage_set_pink          hash_tbl_set_pink
#define storage_get_pink          hash_tbl_get_pink
#define storage_set_red           hash_tbl_set_red
#define storage_get_red           hash_tbl_get_red
#define storage_ref               hash_tbl_ref
#define storage_unref             hash_tbl_unref
#define storage_do_gc             hash_tbl_do_gc
#define storage_gc                hash_tbl_gc
#define storage_wait_barrier      hash_tbl_wait_barrier
#define storage_output_stats      hash_tbl_output_stats


/*****
 *  storage used by delta-ddd algorithm
 *****/
#elif defined (CFG_PD4_STORAGE)

typedef pd4_storage_t storage_t;
typedef pd4_storage_id_t storage_id_t;

#define init_storage           init_pd4_storage
#define free_storage           free_pd4_storage
#define storage_new            pd4_storage_new
#define storage_free           pd4_storage_free
#define storage_size           pd4_storage_size
#define storage_output_stats   pd4_storage_output_stats

#endif

#endif
