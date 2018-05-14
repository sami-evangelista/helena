/**
 * @file fifo.h
 * @brief Implementation of fifo.
 * @date 10 may 2018
 * @author Sami Evangelista
 */

#ifndef LIB_FIFO
#define LIB_FIFO

#include "includes.h"
#include "heap.h"

typedef struct struct_fifo_t * fifo_t;


/**
 * @brief fifo_new
 */
fifo_t fifo_new
(heap_t heap,
 uint32_t slot_size,
 uint32_t sizeof_item,
 char concurrent);


/**
 * @brief fifo_free
 */
void fifo_free
(fifo_t fifo);


/**
 * @brief fifo_is_empty
 */
char fifo_is_empty
(fifo_t fifo);


/**
 * @brief fifo_enqueue
 */
void fifo_enqueue
(fifo_t fifo,
 void * item);


/**
 * @brief fifo_dequeue
 */
void fifo_dequeue
(fifo_t fifo,
 void * item);


/**
 * @brief fifo_next
 */
void fifo_next
(fifo_t fifo,
 void * item);

#endif
