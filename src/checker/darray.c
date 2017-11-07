#include "darray.h"

struct struct_darray_t {
  void * items;
  darray_size_t items_size;
  darray_size_t no_items;
  heap_t heap;
  uint32_t sizeof_item;
};
typedef struct struct_darray_t struct_darray_t;

#define darray_item(darray, i) \
  (darray->items + i * darray->sizeof_item)

darray_t darray_new
(heap_t heap,
 uint32_t sizeof_item) {
  darray_t result;

  result = mem_alloc(heap, sizeof(struct_darray_t));
  result->heap = heap;
  result->no_items = 0;
  result->items_size = 0;
  result->sizeof_item = sizeof_item;
  result->items = NULL;
  return result;
}


void darray_free
(darray_t darray) {
  if(heap_has_mem_free(darray->heap)) {
    if(darray->items) {
      mem_free(darray->heap, darray->items);
    }
    mem_free(darray->heap, darray);
  }
}


darray_size_t darray_size
(darray_t darray) {
  return darray->no_items;
}


void darray_reset
(darray_t darray) {
  darray->no_items = 0;
}


void darray_push
(darray_t darray,
 void * item) {
  void * new_items;
  uint32_t i;
  
  if(darray->no_items == darray->items_size) {
    if(0 == darray->items_size) {
      darray->items_size = 1;
    } else {
      darray->items_size *= 2;
    }
    new_items = mem_alloc(darray->heap,
                          darray->items_size * darray->sizeof_item);
    for(i = 0; i < darray->no_items; i ++) {
      memcpy(new_items + i * darray->sizeof_item,
             darray_item(darray, i),
             darray->sizeof_item);
    }
    mem_free(darray->heap, darray->items);
    darray->items = new_items;
  }
  memcpy(darray_item(darray, darray->no_items), item, darray->sizeof_item);
  darray->no_items ++;
}


void * darray_ith
(darray_t darray,
 darray_index_t i) {
  assert(i >= 0 && i < darray->no_items);
  return darray_item(darray, i);
}
