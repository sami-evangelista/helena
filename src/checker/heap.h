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
#define HEAP_TYPES       2

void init_heap
();

void free_heap
();

typedef unsigned long long int mem_size_t;


/*
 *  bounded size heap without free operation
 */
void * bounded_heap_new
(char * name,
 mem_size_t size);


/*
 *  evergrowing heap
 */
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
