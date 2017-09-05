#ifndef LIB_STORAGE
#define LIB_STORAGE

#include "shared_hash_tbl.h"
#include "hash_tbl.h"
#include "pd4.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif


/*****
 *  shared hash table used in multi-core algorithms
 *****/
#if defined (HASH_STORAGE)

typedef shared_hash_tbl_t storage_t;
typedef shared_hash_tbl_id_t storage_id_t;

#define init_storage              init_shared_hash_tbl
#define free_storage              free_shared_hash_tbl
#define storage_id_serialise      shared_hash_tbl_id_serialise
#define storage_id_unserialise    shared_hash_tbl_id_unserialise
#define storage_id_char_width     shared_hash_tbl_id_char_width
#define storage_new               shared_hash_tbl_default_new
#define storage_free              shared_hash_tbl_free
#define storage_size              shared_hash_tbl_size
#define storage_insert            shared_hash_tbl_insert
#define storage_insert_serialised shared_hash_tbl_insert_serialised
#define storage_remove            shared_hash_tbl_remove
#define storage_lookup            shared_hash_tbl_lookup
#define storage_id_cmp            shared_hash_tbl_id_cmp
#define storage_get_serialised    shared_hash_tbl_get_serialised
#define storage_get               shared_hash_tbl_get
#define storage_get_mem           shared_hash_tbl_get_mem
#define storage_get_hash          shared_hash_tbl_get_hash
#define storage_set_cyan          shared_hash_tbl_set_cyan
#define storage_get_cyan          shared_hash_tbl_get_cyan
#define storage_set_blue          shared_hash_tbl_set_blue
#define storage_get_blue          shared_hash_tbl_get_blue
#define storage_set_pink          shared_hash_tbl_set_pink
#define storage_get_pink          shared_hash_tbl_get_pink
#define storage_set_red           shared_hash_tbl_set_red
#define storage_get_red           shared_hash_tbl_get_red
#define storage_output_stats      shared_hash_tbl_output_stats


/*****
 *  storage used by delta-ddd algorithm
 *****/
#elif defined (PD4_STORAGE)

typedef pd4_storage_t storage_t;
typedef pd4_storage_id_t storage_id_t;

#define init_storage           init_pd4_storage
#define free_storage           free_pd4_storage
#define storage_new            pd4_storage_new
#define storage_free           pd4_storage_free
#define storage_size           pd4_storage_size
#define storage_output_stats   pd4_storage_output_stats


/*****
 *  hash table storage is the default storage
 *****/
#else

typedef hash_tbl_t storage_t;
typedef hash_tbl_id_t storage_id_t;

#define init_storage           init_hash_tbl
#define free_storage           free_hash_tbl
#define storage_id_serialise   hash_tbl_id_serialise
#define storage_id_unserialise hash_tbl_id_unserialise
#define storage_id_char_width  hash_tbl_id_char_width
#define storage_new            hash_tbl_default_new
#define storage_free           hash_tbl_free
#define storage_size           hash_tbl_size
#define storage_insert         hash_tbl_insert
#define storage_remove         hash_tbl_remove
#define storage_lookup         hash_tbl_lookup
#define storage_id_cmp         hash_tbl_id_cmp
#define storage_get            hash_tbl_get
#define storage_get_mem        hash_tbl_get_mem
#define storage_set_cyan       hash_tbl_set_cyan
#define storage_get_cyan       hash_tbl_get_cyan
#define storage_set_blue       hash_tbl_set_blue
#define storage_get_blue       hash_tbl_get_blue
#define storage_set_pink       hash_tbl_set_pink
#define storage_get_pink       hash_tbl_get_pink
#define storage_set_red        hash_tbl_set_red
#define storage_get_red        hash_tbl_get_red
#define storage_update_refs    hash_tbl_update_refs
#define storage_output_stats   hash_tbl_output_stats

#endif

#endif
