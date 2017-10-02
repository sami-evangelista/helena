#include "heap.h"
#include "list.h"

#define LOCAL_HEAP_BLOCK_SIZE 10000

#define HEAP_TYPES 2

#define MALLOC(ptr, ptr_type, size) {           \
    assert(ptr = (ptr_type) malloc(size));      \
  }

typedef struct {
  void * data;
  mem_size_t next;
} struct_local_heap_block_t;

typedef struct_local_heap_block_t * local_heap_block_t;

typedef struct {
  unsigned char type;
  mem_size_t block_size;  
  list_t blocks;
  local_heap_block_t current;
  list_iter_t it;
  mem_size_t pos;
} struct_local_heap_t;

typedef struct_local_heap_t * local_heap_t;

void local_heap_block_free
(void * data) {
  local_heap_block_t block = (local_heap_block_t) data;

  free(block->data);
}

heap_t local_heap_new
() {
  local_heap_t result;
  struct_local_heap_block_t block;
  
  MALLOC(result, local_heap_t, sizeof(struct_local_heap_t));
  result->type = LOCAL_HEAP;
  result->pos = 0;
  result->block_size = LOCAL_HEAP_BLOCK_SIZE;
  result->blocks = list_new(SYSTEM_HEAP, sizeof(struct_local_heap_block_t),
                            local_heap_block_free);
  MALLOC(block.data, void *, result->block_size);
  block.next = 0;
  list_append(result->blocks, &block);
  result->it = list_get_iter(result->blocks);
  result->current = list_iter_item(result->it);
  return result;
}

local_heap_t local_heap_free
(local_heap_t heap) {
  list_free(heap->blocks);
  free(heap);
}

void local_heap_reset
(local_heap_t heap) {
  heap->it = list_get_iter(heap->blocks);
  heap->current = list_iter_item(heap->it);
  heap->current->next = 0;
  heap->pos = 0;
}

mem_size_t local_heap_size
(local_heap_t heap) {
  return heap->pos;
}

void * local_heap_mem_alloc
(local_heap_t heap,
 mem_size_t size) {
  list_iter_t it;
  void * result;
  struct_local_heap_block_t block;

  assert(size <= heap->block_size);
  if(heap->current->next + size <= heap->block_size) {
    result = heap->current->data + heap->current->next;
    heap->current->next += size;
  } else {
    heap->it = list_iter_next(heap->it);
    if(!list_iter_at_end(heap->it)) {
      heap->current = list_iter_item(heap->it);
      heap->current->next = 0;
    } else {
      block.next = 0;
      MALLOC(block.data, void *, heap->block_size);
      list_append(heap->blocks, &block);
      for(it = list_get_iter(heap->blocks);
          !list_iter_at_end(list_iter_next(it));
          it = list_iter_next(it));
      heap->it = it;
      heap->current = list_iter_item(heap->it);
    }
    result = local_heap_mem_alloc(heap, size);
  }
  heap->pos += size;
  return result;
}

mem_size_t local_heap_get_position
(local_heap_t heap) {
  return heap->pos;
}

void local_heap_set_position
(local_heap_t heap,
 mem_size_t pos) {
  list_iter_t it;
  bool_t found = FALSE;
  local_heap_block_t block;
  mem_size_t current = 0;

  for(it = list_get_iter(heap->blocks);
      !list_iter_at_end(it);
      it = list_iter_next(it)) {
    block = list_iter_item(it);
    if(pos - current > block->next) {
      current += block->next;
    } else {
      found = TRUE;
      heap->it = it;
      heap->current = block;
      heap->current->next = pos - current;
      break;
    }
  }
  assert(found);
  heap->pos = pos;
}

void local_heap_mem_free
(local_heap_t heap,
 void * ptr) {
}

bool_t local_heap_has_mem_free
(local_heap_t heap) {
  return FALSE;
}


typedef void(* heap_free_func_t)(void *);
typedef void(* heap_reset_func_t)(void *);
typedef void *(* heap_mem_alloc_func_t)(void *, mem_size_t);
typedef void(* heap_mem_free_func_t)(void *, void *);
typedef mem_size_t(* heap_size_func_t) (void *);
typedef bool_t(* heap_has_mem_free_func_t)(void *);
typedef void(* heap_set_position_func_t)(void *, mem_size_t);
typedef mem_size_t (* heap_get_position_func_t)(void *);

heap_free_func_t heap_free_funcs[HEAP_TYPES];
heap_reset_func_t heap_reset_funcs[HEAP_TYPES];
heap_mem_alloc_func_t heap_mem_alloc_funcs[HEAP_TYPES];
heap_mem_free_func_t heap_mem_free_funcs[HEAP_TYPES];
heap_size_func_t heap_size_funcs[HEAP_TYPES];
heap_has_mem_free_func_t heap_has_mem_free_funcs[HEAP_TYPES];
heap_set_position_func_t heap_set_position_funcs[HEAP_TYPES];
heap_get_position_func_t heap_get_position_funcs[HEAP_TYPES];


/*
 *  generic heap operations
 */
void heap_free
(heap_t heap) {
  if(heap) {
    heap_free_funcs[((char *) heap)[0]](heap);
  }
}

void heap_reset
(heap_t heap) {
  if(heap) {
    heap_reset_funcs[((char *) heap)[0]](heap);
  }
}

void * mem_alloc
(heap_t heap,
 mem_size_t size) {
  if(NULL == heap) {
    return malloc(size);
  }
  else {
    return heap_mem_alloc_funcs[((char *) heap)[0]](heap, size);
  }
}

void * mem_alloc0
(heap_t heap,
 mem_size_t size) {
  void * result = mem_alloc(heap, size);
  memset(result, 0, size);
  return result;
}

void mem_free
(heap_t heap,
 void * ptr) {
  if(NULL == heap) {
    free(ptr);
  }
  else {
    heap_mem_free_funcs[((char *) heap)[0]](heap, ptr);
  }
}

mem_size_t heap_get_position
(heap_t heap) {
  if(heap) {
    return heap_get_position_funcs[((char *) heap)[0]](heap);
  } else {
    return 0;
  }
}

void heap_set_position
(heap_t heap,
 mem_size_t pos) {
  if(heap) {
    heap_set_position_funcs[((char *) heap)[0]](heap, pos);
  }
}

bool_t heap_has_mem_free
(heap_t heap) {
  if(heap) {
    return heap_has_mem_free_funcs[((char *) heap)[0]](heap);
  } else {
    return TRUE;
  }
}

mem_size_t heap_size
(heap_t heap) {
  if(heap) {
    return heap_size_funcs[((char *) heap)[0]](heap);
  } else {
    return UINT_MAX;
  }
}


void init_heap
() {
  unsigned char t;

  t = LOCAL_HEAP;
  heap_free_funcs[t] =
    (heap_free_func_t) local_heap_free;
  heap_reset_funcs[t] =
    (heap_reset_func_t) local_heap_reset;
  heap_mem_alloc_funcs[t] =
    (heap_mem_alloc_func_t) local_heap_mem_alloc;
  heap_mem_free_funcs[t] =
    (heap_mem_free_func_t) local_heap_mem_free;
  heap_get_position_funcs[t] =
    (heap_get_position_func_t) local_heap_get_position;
  heap_set_position_funcs[t] =
    (heap_set_position_func_t) local_heap_set_position;
  heap_has_mem_free_funcs[t] =
    (heap_has_mem_free_func_t) local_heap_has_mem_free;
  heap_size_funcs[t] =
    (heap_size_func_t) local_heap_size;
}
