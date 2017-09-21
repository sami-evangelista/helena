#include "heap.h"

/*
 *  bounded size heap without free operation
 */
typedef struct {
  unsigned char type;
  char * name;
  void * ptr;
  mem_size_t next;
  mem_size_t size;
} struct_bounded_heap_t;

typedef struct_bounded_heap_t * bounded_heap_t;

void * bounded_heap_new
(char * name,
 mem_size_t size) {
#if defined(CFG_USE_HELENA_HEAPS)
  bounded_heap_t result;
  MALLOC(result, bounded_heap_t, sizeof(struct_bounded_heap_t));
  MALLOC(result->name, char *, strlen(name) + 1);
  MALLOC(result->ptr, void *, size);
  result->type = BOUNDED_HEAP;
  result->next = 0;
  result->size = size;
  strcpy(result->name, name);
  return result;
#else
  return SYSTEM_HEAP;
#endif
}

bounded_heap_t bounded_heap_free
(bounded_heap_t heap) {
  free(heap->name);
  free(heap->ptr);
  free(heap);
}

void * bounded_heap_reset
(bounded_heap_t heap) {
  heap->next = 0;
}

void * bounded_heap_mem_alloc
(bounded_heap_t heap,
 mem_size_t size) {
  void * result;

  if(heap->next + size > heap->size) {
    char msg[100];
    sprintf(msg, "bounded heap \"%s\" too small", heap->name);
    fatal_error(msg);
  }
  result = heap->ptr + heap->next;
  heap->next += size;
  return result;
}

void * bounded_heap_mem_free
(bounded_heap_t heap,
 void * ptr) {
}

void * bounded_heap_get_position
(bounded_heap_t heap) {
  return heap->ptr + heap->next;
}

void bounded_heap_set_position
(bounded_heap_t heap,
 void * pos) {
  heap->next = pos - heap->ptr;
}

mem_size_t bounded_heap_space_left
(bounded_heap_t heap) {
  return heap->size - heap->next;
}

bool_t bounded_heap_has_mem_free
(bounded_heap_t heap) {
  return FALSE;
}



/*
 *  evergrowing heap
 */
typedef struct struct_evergrowing_heap_block_t {
  void * ptr;
  mem_size_t size;
  struct struct_evergrowing_heap_block_t * next;
} struct_evergrowing_heap_block_t;

typedef struct_evergrowing_heap_block_t * evergrowing_heap_block_t;

typedef struct {
  unsigned char type;
  char * name;
  mem_size_t block_size;
  mem_size_t next;
  evergrowing_heap_block_t fst;
  evergrowing_heap_block_t last;
} struct_evergrowing_heap_t;

typedef struct_evergrowing_heap_t * evergrowing_heap_t;

void * evergrowing_heap_new
(char * name,
 mem_size_t block_size) {
#if defined(CFG_USE_HELENA_HEAPS)
  evergrowing_heap_t result;
  MALLOC(result, evergrowing_heap_t, sizeof(struct_evergrowing_heap_t));
  MALLOC(result->name, char *, strlen(name) + 1);
  result->type = EVERGROWING_HEAP;
  strcpy(result->name, name);
  result->block_size = block_size;
  result->next = 0;
  result->last = result->fst = NULL;
  return result;
#else
  return SYSTEM_HEAP;
#endif
}

void evergrowing_heap_free_blocks
(evergrowing_heap_t heap) {
  evergrowing_heap_block_t tmp = heap->fst, next;
  
  while(tmp) {
    next = tmp->next;
    free(tmp->ptr);
    free(tmp);
    tmp = next;
  }
}

evergrowing_heap_t evergrowing_heap_free
(evergrowing_heap_t heap) {
  evergrowing_heap_free_blocks(heap);
  free(heap->name);  
  free(heap);
}

void * evergrowing_heap_reset
(evergrowing_heap_t heap) {
  evergrowing_heap_free_blocks(heap);
  heap->next = 0;
  heap->last = heap->fst = NULL;
}

void * evergrowing_heap_mem_alloc
(evergrowing_heap_t heap,
 mem_size_t size) {
  void * result;
  evergrowing_heap_block_t new_block;
  
  if((NULL == heap->fst) || (size + heap->next >= heap->last->size)) {
    heap->next = 0;
    MALLOC(new_block, evergrowing_heap_block_t,
           sizeof(struct_evergrowing_heap_block_t));
    new_block->size = (heap->block_size >= size) ? heap->block_size : size;
    new_block->next = NULL;
    MALLOC(new_block->ptr, char *, new_block->size);
    if(NULL == heap->fst) {
      heap->fst = heap->last = new_block;
    } else {
      heap->last->next = new_block;
      heap->last = new_block;
    }
  }
  result = heap->last->ptr + heap->next;
  heap->next += size;
  return result;
}

void * evergrowing_heap_mem_free
(evergrowing_heap_t heap,
 void * ptr) {
}

void * evergrowing_heap_get_position
(evergrowing_heap_t heap) {
  fatal_error("evergrowing_heap_get_position: impossible operation");
  return NULL;
}

void evergrowing_heap_set_position
(evergrowing_heap_t heap,
 void * pos) {
  fatal_error("evergrowing_heap_set_position: impossible operation");
}

mem_size_t evergrowing_heap_space_left
(evergrowing_heap_t heap) {
  fatal_error("evergrowing_heap_space_left: impossible operation");
}

bool_t evergrowing_heap_has_mem_free
(evergrowing_heap_t heap) {
  return FALSE;
}





/*
 *  generic heap operations
 */
typedef void(* heap_free_func_t)(void *);
heap_free_func_t heap_free_funcs[HEAP_TYPES];

void heap_free
(heap_t heap) {
  if(heap) {
    heap_free_funcs[((char *) heap)[0]](heap);
  }
}

typedef void(* heap_reset_func_t)(void *);
heap_reset_func_t heap_reset_funcs[HEAP_TYPES];

void heap_reset
(heap_t heap) {
  if(heap) {
    heap_reset_funcs[((char *) heap)[0]](heap);
  }
}

typedef void *(* heap_mem_alloc_func_t)(void *, mem_size_t);
heap_mem_alloc_func_t heap_mem_alloc_funcs[HEAP_TYPES];

void * mem_alloc
(heap_t     heap,
 mem_size_t size) {
  if(NULL == heap) {
    return malloc(size);
  }
  else {
    return heap_mem_alloc_funcs[((char *) heap)[0]](heap, size);
  }
}

void * mem_alloc0
(heap_t     heap,
 mem_size_t size) {
  void * result = mem_alloc(heap, size);
  memset(result, 0, size);
  return result;
}

typedef void(* heap_mem_free_func_t)(void *, void *);
heap_mem_free_func_t heap_mem_free_funcs[HEAP_TYPES];

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

typedef void *(* heap_get_position_func_t)(void *);
heap_get_position_func_t heap_get_position_funcs[HEAP_TYPES];

void * heap_get_position
(heap_t heap) {
  if(heap) {
    return heap_get_position_funcs[((char *) heap)[0]](heap);
  } else {
    return NULL;
  }
}

typedef void(* heap_set_position_func_t)(void *, void *);
heap_set_position_func_t heap_set_position_funcs[HEAP_TYPES];

void heap_set_position
(heap_t heap,
 void * pos) {
  if(heap) {
    heap_set_position_funcs[((char *) heap)[0]](heap, pos);
  }
}

typedef mem_size_t(* heap_space_left_func_t)(void *);
heap_space_left_func_t heap_space_left_funcs[HEAP_TYPES];

mem_size_t heap_space_left
(heap_t heap) {
  if(heap) {
    return heap_space_left_funcs[((char *) heap)[0]](heap);
  } else {
    return INT_MAX;
  }
}

typedef bool_t(* heap_has_mem_free_func_t)(void *);
heap_has_mem_free_func_t heap_has_mem_free_funcs[HEAP_TYPES];

bool_t heap_has_mem_free
(heap_t heap) {
  if(heap) {
    return heap_has_mem_free_funcs[((char *) heap)[0]](heap);
  } else {
    return TRUE;
  }
}


void init_heap
() {
  unsigned char t;

  t = BOUNDED_HEAP;
  heap_free_funcs[t] =
    (heap_free_func_t) bounded_heap_free;
  heap_reset_funcs[t] =
    (heap_reset_func_t) bounded_heap_reset;
  heap_mem_alloc_funcs[t] =
    (heap_mem_alloc_func_t) bounded_heap_mem_alloc;
  heap_mem_free_funcs[t] =
    (heap_mem_free_func_t) bounded_heap_mem_free;
  heap_get_position_funcs[t] =
    (heap_get_position_func_t) bounded_heap_get_position;
  heap_set_position_funcs[t] =
    (heap_set_position_func_t) bounded_heap_set_position;
  heap_space_left_funcs[t] =
    (heap_space_left_func_t) bounded_heap_space_left;
  heap_has_mem_free_funcs[t] =
    (heap_has_mem_free_func_t) bounded_heap_has_mem_free;

  t = EVERGROWING_HEAP;
  heap_free_funcs[t] =
    (heap_free_func_t) evergrowing_heap_free;
  heap_reset_funcs[t] =
    (heap_reset_func_t) evergrowing_heap_reset;
  heap_mem_alloc_funcs[t] =
    (heap_mem_alloc_func_t) evergrowing_heap_mem_alloc;
  heap_mem_free_funcs[t] =
    (heap_mem_free_func_t) evergrowing_heap_mem_free;
  heap_get_position_funcs[t] =
    (heap_get_position_func_t) evergrowing_heap_get_position;
  heap_set_position_funcs[t] =
    (heap_set_position_func_t) evergrowing_heap_set_position;
  heap_space_left_funcs[t] =
    (heap_space_left_func_t) evergrowing_heap_space_left;
  heap_has_mem_free_funcs[t] =
    (heap_has_mem_free_func_t) evergrowing_heap_has_mem_free;
}
