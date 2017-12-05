#include "list.h"

struct struct_list_node_t {
  void * item;
  struct struct_list_node_t * prev;
  struct struct_list_node_t * next;
};
typedef struct struct_list_node_t struct_list_node_t;
typedef struct_list_node_t * list_node_t;

struct struct_list_t {
  heap_t heap;
  list_size_t no_items;
  list_node_t first;
  list_node_t last;
  uint32_t sizeof_item;
  list_free_func_t free_func;  
};

typedef struct struct_list_t struct_list_t;

list_t list_new
(heap_t heap,
 uint32_t sizeof_item,
 list_free_func_t free_func) {
  list_t result;

  result = mem_alloc(heap, sizeof(struct_list_t));
  result->heap = heap;
  result->no_items = 0;
  result->first = NULL;
  result->last = NULL;
  result->free_func = free_func;
  result->sizeof_item = sizeof_item;
  return result;
}

void list_free
(list_t list) {
  list_node_t ptr = list->first, next;

  if(heap_has_mem_free(list->heap)) {
    while(ptr) {
      next = ptr->next;
      if(list->free_func) {
        list->free_func(ptr->item);
      }
      mem_free(list->heap, ptr->item);
      mem_free(list->heap, ptr);
      ptr = next;
    }
    mem_free(list->heap, list);
  }
}

void list_reset
(list_t list) {
  list_node_t ptr = list->first, next;

  if(heap_has_mem_free(list->heap)) {
    while(ptr) {
      next = ptr->next;
      if(list->free_func) {
        list->free_func(ptr->item);
      }
      mem_free(list->heap, ptr->item);
      mem_free(list->heap, ptr);
      ptr = next;
    }
  }
  list->no_items = 0;
  list->first = NULL;
  list->last = NULL;
}

char list_is_empty
(list_t list) {
  return 0 == list->no_items;
}

list_size_t list_size
(list_t list) {
  return list->no_items;
}

list_t list_copy
(list_t list,
 heap_t heap,
 list_free_func_t free_func) {
  list_t result;
  list_node_t ptr;

  result = list_new(heap, list->sizeof_item, free_func);
  for(ptr = list->first; ptr; ptr = ptr->next) {
    list_append(result, ptr->item);
  }
  return result;
}

void * list_first
(list_t list) {
  assert(list->first);
  return list->first->item;
}

void * list_last
(list_t list) {
  assert(list->last);
  return list->last->item;
}

void * list_nth
(list_t list,
 list_index_t n) {
  list_node_t ptr = list->first;
  list_index_t i = n;
  
  while(i) {
    assert(ptr);
    ptr = ptr->next;
    i --;
  }
  assert(ptr);
  return ptr->item;
}

void list_app
(list_t list,
 list_app_func_t app_func,
 void * data) {
  list_node_t ptr = list->first;

  while(ptr) {
    app_func(ptr->item, data);
    ptr = ptr->next;
  }
}

void list_prepend
(list_t list,
 void * item) {
  list_node_t ptr = mem_alloc(list->heap, sizeof(struct_list_node_t));

  ptr->item = mem_alloc(list->heap, list->sizeof_item);
  memcpy(ptr->item, item, list->sizeof_item);
  ptr->prev = NULL;
  if(!list->first) {
    ptr->next = NULL;
    list->first = ptr;
    list->last = ptr;
  } else {
    ptr->next = list->first;
    list->first->prev = ptr;
    list->first = ptr;
  }
  list->no_items ++;
}

void list_append
(list_t list,
 void * item) {
  list_node_t ptr = mem_alloc(list->heap, sizeof(struct_list_node_t));

  ptr->item = mem_alloc(list->heap, list->sizeof_item);
  memcpy(ptr->item, item, list->sizeof_item);
  ptr->next = NULL;
  if(!list->first) {
    ptr->prev = NULL;
    list->first = ptr;
    list->last = ptr;
  } else {
    ptr->prev = list->last;
    list->last->next = ptr;
    list->last = ptr;
  }
  list->no_items ++;
}

void list_insert_sorted
(list_t list,
 void * item,
 list_item_cmp_func_t item_cmp_func) {
  list_node_t ptr = list->first;
  list_node_t new_node;
  int cmp = 1;

  while(ptr && (cmp = item_cmp_func(ptr->item, item)) == -1) {
    ptr = ptr->next;
  }
  if(cmp != 0) {
    if(ptr == list->first) {
      list_prepend(list, item);
    } else if(NULL == ptr) {
      list_append(list, item);
    } else {
      new_node = mem_alloc(list->heap, sizeof(struct_list_node_t));
      new_node->item = mem_alloc(list->heap, list->sizeof_item);
      memcpy(new_node->item, item, list->sizeof_item);
      new_node->prev = ptr->prev;
      new_node->next = ptr;
      ptr->prev->next = new_node;
      ptr->prev = new_node;
      list->no_items ++;
    }
  }
}

void list_pick_last
(list_t list,
 void * item) {
  list_pick_nth(list, list->no_items - 1, item);
}

void list_pick_first
(list_t list,
 void * item) {
  list_pick_nth(list, 0, item);
}

void list_pick_nth
(list_t list,
 list_index_t n,
 void * item) {
  list_node_t ptr = list->first;

  assert(n < list->no_items);
  while(n) {
    ptr = ptr->next;
    n --;
  }
  if(item) {
    memcpy(item, ptr->item, list->sizeof_item);
  }
  mem_free(list->heap, ptr->item);
  if(ptr->prev) {
    ptr->prev->next = ptr->next;
  } else {
    list->first = ptr->next;
  }
  if(ptr->next) {
    ptr->next->prev = ptr->prev;
  } else {
    list->last = ptr->next;
  }
  mem_free(list->heap, ptr);
  list->no_items --;
}

void * list_find
(list_t list,
 list_pred_func_t pred_func,
 void * find_data) {
  void * result = NULL;
  list_node_t ptr = list->first;

  while(ptr && !result) {
    if(pred_func(ptr->item, find_data)) {
      result = ptr->item;
    }
    ptr = ptr->next;
  }
  return result;
}

void list_filter
(list_t list,
 list_pred_func_t pred_func,
 void * filter_data) {
  list_node_t ptr = list->first, next, prev;

  prev = NULL;
  while(ptr) {
    next = ptr->next;
    if(!pred_func(ptr->item, filter_data)) {
      prev = ptr;
    } else {
      if(prev) {
	prev->next = next;
	if(next) {
	  next->prev = prev;
	} else {
	  list->last = prev;
	}
      } else {
	list->first = next;
	if(next) {
	  next->prev = NULL;
	}
      }
      mem_free(list->heap, ptr->item);
      mem_free(list->heap, ptr);
      list->no_items --;
    }
    ptr = next;
  }
}

uint32_t list_char_size
(list_t list,
 list_char_size_func_t char_size_func) {
  uint32_t result = sizeof(list_size_t);
  list_node_t ptr = list->first;

  while(ptr) {
    result += char_size_func(ptr->item);
    ptr = ptr->next;
  }
  return result;
}

void list_serialise
(list_t list,
 char * data,
 list_char_size_func_t char_size_func,
 list_serialise_func_t serialise_func) {
  const list_size_t size = list->no_items;
  list_node_t ptr = list->first;
  uint32_t pos = sizeof(list_size_t);

  memcpy(data, &size, sizeof(list_size_t));
  while(ptr) {
    serialise_func(ptr->item, data + pos);
    pos += char_size_func(ptr->item);
    ptr = ptr->next;
  }
}

list_t list_unserialise
(heap_t heap,
 uint32_t sizeof_item,
 list_free_func_t free_func,
 char * data,
 list_char_size_func_t char_size_func,
 list_unserialise_func_t unserialise_func) {
  list_node_t ptr, prev = NULL;
  list_t result = list_new(heap, sizeof_item, free_func);
  uint32_t size, pos;

  memcpy(&size, data, sizeof(list_size_t));
  pos = sizeof(list_size_t);
  result->no_items = size;
  while(size) {
    ptr = mem_alloc(heap, sizeof(struct_list_node_t));
    if(!result->first) {
      result->first = ptr;
    }
    if(prev) {
      prev->next = ptr;
    }
    ptr->prev = prev;
    ptr->next = NULL;
    ptr->item = mem_alloc(heap, result->sizeof_item);
    unserialise_func(data + pos, heap, ptr->item);
    pos += char_size_func(ptr->item);
    size --;
    prev = ptr;
  }
  result->last = ptr;
  return result;
}

list_iter_t list_get_iter
(list_t list) {
  return list->first;
}

list_iter_t list_iter_next
(list_iter_t it) {
  return it->next;
}

char list_iter_at_end
(list_iter_t it) {
  if(it) {
    return 0;
  } else {
    return 1;
  }
}

void * list_iter_item
(list_iter_t it) {
  return it->item;
}
