#ifndef LIB_STORAGE
#define LIB_STORAGE

#include "hash_storage.h"
#include "pd4.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif


/*****
 *  storage used by delta-ddd algorithm
 *****/
#if defined (PD4_STORAGE)

typedef pd4_storage_t storage_t;
typedef pd4_storage_id_t storage_id_t;
typedef void * storage_state_attr_t;

#define init_storage           init_pd4_storage
#define free_storage           free_pd4_storage
#define storage_id_serialise   pd4_storage_id_serialise
#define storage_id_unserialise pd4_storage_id_unserialise
#define storage_id_char_width  pd4_storage_id_char_width
#define storage_new            pd4_storage_new
#define storage_free           pd4_storage_free
#define storage_size           pd4_storage_size
#define storage_insert         pd4_storage_insert
#define storage_remove         pd4_storage_remove
#define storage_id_cmp         pd4_storage_id_cmp
#define storage_get            pd4_storage_get
#define storage_get_mem        pd4_storage_get_mem
#define storage_set_in_unproc  pd4_storage_set_in_unproc
#define storage_get_in_unproc  pd4_storage_get_in_unproc
#define storage_get_num        pd4_storage_get_num
#define storage_set_is_red     pd4_storage_set_is_red
#define storage_update_refs    pd4_storage_update_refs
#define storage_get_attr       pd4_storage_get_attr
#define storage_output_stats   pd4_storage_output_stats


/*****
 *  hash table storage is the default storage
 *****/
#else

typedef hash_storage_t storage_t;
typedef hash_storage_id_t storage_id_t;
typedef hash_storage_state_attr_t storage_state_attr_t;

#define init_storage           init_hash_storage
#define free_storage           free_hash_storage
#define storage_id_serialise   hash_storage_id_serialise
#define storage_id_unserialise hash_storage_id_unserialise
#define storage_id_char_width  hash_storage_id_char_width
#define storage_new            hash_storage_default_new
#define storage_free           hash_storage_free
#define storage_size           hash_storage_size
#define storage_insert         hash_storage_insert
#define storage_remove         hash_storage_remove
#define storage_id_cmp         hash_storage_id_cmp
#define storage_get            hash_storage_get
#define storage_get_mem        hash_storage_get_mem
#define storage_set_in_unproc  hash_storage_set_in_unproc
#define storage_get_in_unproc  hash_storage_get_in_unproc
#define storage_get_num        hash_storage_get_num
#define storage_set_is_red     hash_storage_set_is_red
#define storage_update_refs    hash_storage_update_refs
#define storage_get_attr       hash_storage_get_attr
#define storage_output_stats   hash_storage_output_stats

#endif

#endif
