/**
 * @file heap.h
 * @brief Implementation of various heap structures.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_HEAP
#define LIB_HEAP

#include "common.h"

#define SYSTEM_HEAP NULL
#define LOCAL_HEAP  0

void init_heap
();

typedef uint64_t mem_size_t;

typedef void * heap_t;


/**
 * @brief local_heap_new
 */
heap_t local_heap_new
();


/**
 * @brief mem_alloc
 */
void * mem_alloc
(heap_t heap,
 mem_size_t size);


/**
 * @brief mem_alloc0
 */
void * mem_alloc0
(heap_t heap,
 mem_size_t size);


/**
 * @brief mem_free
 */
void mem_free
(heap_t heap,
 void * ptr);


/**
 * @brief heap_reset
 */
void heap_reset
(heap_t heap);


/**
 * @brief heap_free
 */
void heap_free
(heap_t heap);


/**
 * @brief heap_get_position
 */
mem_size_t heap_get_position
(heap_t heap);


/**
 * @brief heap_set_position
 */
void heap_set_position
(heap_t heap,
 mem_size_t pos);


/**
 * @brief heap_has_mem_free
 */
bool_t heap_has_mem_free
(heap_t heap);


/**
 * @brief heap_size
 */
mem_size_t heap_size
(heap_t heap);

#endif
