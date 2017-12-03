#include "harray.h"

#define HARRAY_NONE 0
#define HARRAY_SOME 1
#define HARRAY_DEL  2

harray_t harray_new
(heap_t heap,
 harray_size_t size,
 harray_hash_func_t fhash,
 harray_cmp_func_t fcmp,
 harray_free_func_t ffree) {
  harray_index_t i;
  harray_t result = mem_alloc (heap, sizeof (struct_harray_t));
  result->num_items = 0;
  result->heap = heap;
  result->size = size;
  result->fhash = fhash;
  result->fcmp = fcmp;
  result->ffree = ffree;
  result->status = mem_alloc (heap, size * sizeof (harray_status_t));
  result->keys = mem_alloc (heap, size * sizeof (harray_key_t));
  result->values = mem_alloc (heap, size * sizeof (harray_value_t));
  for (i = 0; i < size; i ++) {
    result->status[i] = HARRAY_NONE;
  }
  return result;
}

void harray_free
(harray_t harray) {
  harray_index_t i;
  if (harray->ffree) {
    for (i = 0; i < harray->size; i ++) {
      if (harray->status[i] == HARRAY_SOME) {
	(*harray->ffree) (harray->values[i]);
      }
    }
  }
  mem_free (harray->heap, harray->status);
  mem_free (harray->heap, harray->keys);
  mem_free (harray->heap, harray->values);
  mem_free (harray->heap, harray);
}

harray_size_t harray_num_items
(harray_t harray) {
  return harray->num_items;
}

bool_t harray_insert
(harray_t harray,
 harray_value_t val) {
  harray_key_t key = (*harray->fhash) (val);
  harray_index_t new_pos, pos = key % harray->size, fst_pos = pos;
  bool_t loop = TRUE;
  bool_t pos_found = FALSE;
  bool_t result = FALSE;

  while (loop) {
    switch (harray->status[pos]) {
    case HARRAY_NONE: {
      if (pos_found) {
	pos = new_pos;
      }
      harray->status[pos] = HARRAY_SOME;
      harray->keys[pos] = key;
      harray->values[pos] = val;
      harray->num_items ++;
      loop = FALSE;
      result = TRUE;
      break;
    }
    case HARRAY_SOME: {
      if ((harray->keys[pos] == key) &&
	  (EQUAL == (*harray->fcmp) (val, harray->values[pos]))) {
	loop = FALSE;
      } else {
	pos = (pos + 1) % harray->size;
      }
      break;
    }
    case HARRAY_DEL: {
      if (!pos_found) {
	pos_found = TRUE;
	new_pos = pos;
      }
      pos = (pos + 1) % harray->size;
      break;
    }
    }
    assert(!loop || pos != fst_pos);
  }
  return result;
}

void harray_delete
(harray_t harray,
 harray_value_t val) {
  /*  not implemented  */
  assert(0);
}

harray_value_t harray_lookup
(harray_t harray,
 harray_value_t val) {
  harray_value_t result = NULL;
  harray_key_t key = (*harray->fhash) (val);
  harray_index_t pos = key % harray->size;
  bool_t loop = TRUE;

  while (loop) {
    switch (harray->status[pos]) {
    case HARRAY_NONE: {
      loop = FALSE;
    }
    case HARRAY_DEL: {
      pos = (pos + 1) % harray->size;
      break;
    }
    case HARRAY_SOME: {
      if ((harray->keys[pos] == key) &&
	  (EQUAL == (*harray->fcmp) (val, harray->values[pos]))) {
	result = harray->values[pos];
	loop = FALSE;
      } else {
	pos = (pos + 1) % harray->size;
      }
      break;
    }
    }
  }  
  return result;
}

void harray_app
(harray_t harray,
 harray_iter_func_t f,
 harray_iter_data_t data) {
  harray_index_t i;

  for (i = 0; i < harray->size; i ++) {
    if (HARRAY_SOME == harray->status[i]) {
      (*f) (harray->keys[i], harray->values[i], data);
    }
  }
}

void harray_filter
(harray_t harray,
 harray_pred_func_t f,
 harray_iter_data_t data) {
  harray_index_t i;

  for (i = 0; i < harray->size; i ++) {
    if (HARRAY_SOME == harray->status[i]
	&& (!(*f) (harray->keys[i], harray->values[i], data))) {
      harray->status[i] = HARRAY_DEL;
      if (harray->ffree) {
	(*harray->ffree) (harray->values[i]);
      }
    }
  }
}
