/**
 * @file darray.h
 * @brief Implementation of dynamic arrays.
 * @date 6 nov 2017
 * @author Sami Evangelista
 */

#ifndef LIB_DARRAY
#define LIB_DARRAY

#include "heap.h"

typedef uint32_t darray_size_t;

typedef uint32_t darray_index_t;

typedef struct struct_darray_t * darray_t;


/**
 * @brief darray_new
 */
darray_t darray_new
(heap_t heap,
 uint32_t sizeof_item);


/**
 * @brief darray_free
 */
void darray_free
(darray_t darray);


/**
 * @brief darray_size
 */
darray_size_t darray_size
(darray_t darray);



/**
 * @brief darray_reset
 */
void darray_reset
(darray_t darray);


/**
 * @brief darray_push
 */
void darray_push
(darray_t darray,
 void * item);


/**
 * @brief darray_pop
 */
void * darray_pop
(darray_t darray);


/**
 * @brief darray_top
 */
void * darray_top
(darray_t darray);


/**
 * @brief darray_get
 */
void * darray_get
(darray_t darray,
 darray_index_t i);


/**
 * @brief darray_set
 */
void darray_set
(darray_t darray,
 darray_index_t i,
 void * item);

#endif
