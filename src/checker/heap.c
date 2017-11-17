#include "heap.h"

#define LOCAL_HEAP_BLOCK_SIZE 100000

#define HEAP_TYPES 1

#define MALLOC(ptr, ptr_type, size) {           \
    assert(ptr = (ptr_type) malloc(size));      \
  }

typedef struct {
  void * data;
  mem_size_t next;
  mem_size_t first;
} local_heap_block_t;

typedef struct {
  unsigned char type;
  mem_size_t block_size;  
  local_heap_block_t * blocks;
  uint32_t current;
  uint32_t no_blocks;
  mem_size_t pos;
} struct_local_heap_t;

typedef struct_local_heap_t * local_heap_t;

heap_t local_heap_new
() {
  local_heap_t result;
  local_heap_block_t block;
  
  MALLOC(result, local_heap_t, sizeof(struct_local_heap_t));
  MALLOC(result->blocks, local_heap_block_t *, sizeof(local_heap_block_t));
  result->type = LOCAL_HEAP;
  result->pos = 0;
  result->block_size = LOCAL_HEAP_BLOCK_SIZE;
  result->current = 0;
  result->no_blocks = 1;
  
  MALLOC(result->blocks[0].data, void *, result->block_size);
  result->blocks[0].first = 0;
  result->blocks[0].next = 0;
  return result;
}

local_heap_t local_heap_free
(local_heap_t heap) {
  int i;

  for(i = 0; i < heap->no_blocks; i ++) {
    free(heap->blocks[i].data);
  }
  free(heap->blocks);
  free(heap);
}

void local_heap_reset
(local_heap_t heap) {
  heap->current = 0;
  heap->pos = 0;
  heap->blocks[0].first = 0;
  heap->blocks[0].next = 0;
}

mem_size_t local_heap_size
(local_heap_t heap) {
  return heap->pos;
}

void * local_heap_mem_alloc
(local_heap_t heap,
 mem_size_t size) {
  int i;
  void * result;
  local_heap_block_t * block = &(heap->blocks[heap->current]);
  local_heap_block_t * new_blocks;

  assert(size <= heap->block_size);
  if(block->next + size > heap->block_size) {
    heap->current ++;
    if(heap->current == heap->no_blocks) {
      MALLOC(new_blocks, local_heap_block_t *,
             (heap->no_blocks * 2) * sizeof(local_heap_block_t));
      for(i = 0; i < heap->no_blocks; i ++) {
        new_blocks[i] = heap->blocks[i];
      }
      heap->no_blocks *= 2;
      for(; i < heap->no_blocks; i ++) {
        MALLOC(new_blocks[i].data, void *, heap->block_size);
      }
      free(heap->blocks);
      heap->blocks = new_blocks;
    }
    block = &(heap->blocks[heap->current]);
    block->first = (heap->blocks[heap->current - 1].first +
                    heap->blocks[heap->current - 1].next);
    block->next = 0;
  }
  result = block->data + block->next;
  block->next += size;
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
  int i;
  bool_t found = FALSE;
  local_heap_block_t block;
  mem_size_t current = 0;

  for(i = heap->current; i >= 0 && heap->blocks[i].first > pos; i --);
  assert(i >= 0);
  heap->current = i;
  heap->blocks[i].next = pos - heap->blocks[i].first;
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
