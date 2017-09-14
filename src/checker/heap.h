/**
 * @file heap.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Implementation of various heap structures.
 */

#ifndef LIB_HEAP
#define LIB_HEAP

#include "common.h"

#define SYSTEM_HEAP      NULL
#define BOUNDED_HEAP     0
#define EVERGROWING_HEAP 1

#define HEAP_TYPES 2


void init_heap
();

void free_heap
();

typedef unsigned long long int mem_size_t;



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
 mem_size_t size);



/*
 *  evergrowing heap
 */
typedef struct struct_evergrowing_heap_node_t {
  void * ptr;
  mem_size_t size;
  struct struct_evergrowing_heap_node_t * next;
} struct_evergrowing_heap_node_t;

typedef struct_evergrowing_heap_node_t * evergrowing_heap_node_t;

typedef struct {
  unsigned char type;
  char * name;
  mem_size_t block_size;
  mem_size_t next;
  evergrowing_heap_node_t fst;
  evergrowing_heap_node_t last;
} struct_evergrowing_heap_t;

typedef struct_evergrowing_heap_t * evergrowing_heap_t;

void * evergrowing_heap_new
(char * name,
 mem_size_t block_size);



/*
 *  generic heap operations
 */
typedef void * heap_t;

void * mem_alloc
(heap_t heap,
 mem_size_t size);

void * mem_alloc0
(heap_t heap,
 mem_size_t size);

void mem_free
(heap_t heap,
 void * ptr);

void heap_reset
(heap_t heap);

void heap_free
(heap_t heap);

void * heap_get_position
(heap_t heap);

void heap_set_position
(heap_t heap,
 void * pos);

mem_size_t heap_space_left
(heap_t heap);

bool_t heap_has_mem_free
(heap_t heap);

#endif
