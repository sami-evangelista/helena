/**
 * @file hash_array.h
 * @brief Implementation of an hash array.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_HASH_ARRAY
#define LIB_HASH_ARRAY

#include "common.h"
#include "heap.h"

typedef hash_key_t harray_key_t;

typedef uint32_t harray_index_t;

typedef uint32_t harray_size_t;

typedef uint8_t harray_status_t;

typedef void * harray_value_t;

typedef void * harray_iter_data_t;

typedef void (* harray_iter_func_t) (harray_key_t, harray_value_t,
				     harray_iter_data_t);

typedef bool_t (* harray_pred_func_t) (harray_key_t, harray_value_t,
				       harray_iter_data_t);

typedef harray_key_t (* harray_hash_func_t) (harray_value_t);

typedef order_t (* harray_cmp_func_t) (harray_value_t, harray_value_t);

typedef void (* harray_free_func_t) (harray_value_t);

typedef struct {
  heap_t             heap;
  harray_size_t      num_items;
  harray_size_t      size;
  harray_status_t *  status;
  harray_key_t *     keys;
  harray_value_t *   values;
  harray_hash_func_t fhash;
  harray_cmp_func_t  fcmp;
  harray_free_func_t ffree;
} struct_harray_t;

typedef struct_harray_t * harray_t;

harray_t harray_new
(heap_t             heap,
 harray_size_t      size,
 harray_hash_func_t fhash,
 harray_cmp_func_t  fcmp,
 harray_free_func_t ffree);

void harray_free
(harray_t harray);

harray_size_t harray_num_items
(harray_t harray);

bool_t harray_insert
(harray_t harray,
 harray_value_t val);

void harray_delete
(harray_t harray,
 harray_value_t val);

harray_value_t harray_lookup
(harray_t harray,
 harray_value_t val);

void harray_app
(harray_t harray,
 harray_iter_func_t f,
 harray_iter_data_t data);

void harray_filter
(harray_t harray,
 harray_pred_func_t f,
 harray_iter_data_t data);

#endif
