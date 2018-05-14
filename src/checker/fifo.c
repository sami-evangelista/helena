#include "fifo.h"

#define LOCK_FREE  0
#define LOCK_TAKEN 1

struct struct_fifo_block_t {
  void * items;
  struct struct_fifo_block_t * prev;
  struct struct_fifo_block_t * next;
};

typedef struct struct_fifo_block_t struct_fifo_block_t;

typedef struct_fifo_block_t * fifo_block_t;

struct struct_fifo_t{
  heap_t heap;
  fifo_block_t first;
  fifo_block_t last;
  uint32_t first_index;
  uint32_t last_index;
  uint32_t block_size;
  uint32_t sizeof_item;
  char concurrent;
  char lock;
};

typedef struct struct_fifo_t struct_fifo_t;

#define fifo_item_addr(fifo, block, no)		\
  ((block)->items + (no) * (fifo)->sizeof_item)

fifo_block_t fifo_block_new
(uint32_t block_size,
 uint32_t sizeof_item) {
  fifo_block_t result;
  
  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_fifo_block_t));
  result->items = mem_alloc(SYSTEM_HEAP, sizeof_item * block_size);
  return result;
}


void fifo_block_free
(fifo_block_t block,
 char free_next) {
  if(block) {
    if(free_next && block->next) {
      fifo_block_free(block->next, 1);
    }
    mem_free(SYSTEM_HEAP, block->items);
    mem_free(SYSTEM_HEAP, block);
  }
}


fifo_t fifo_new
(heap_t heap,
 uint32_t block_size,
 uint32_t sizeof_item,
 char concurrent) {
  fifo_t result;
  
  result = mem_alloc(heap, sizeof(struct_fifo_t));
  result->heap = heap;
  result->first = NULL;
  result->last = NULL;
  result->first_index = 0;
  result->last_index = 0;
  result->lock = LOCK_FREE;
  result->concurrent = concurrent;
  result->sizeof_item = sizeof_item;
  result->block_size = block_size;
  return result;
}


void fifo_free
(fifo_t fifo) {
  fifo_block_free(fifo->first, 1);
  mem_free(fifo->heap, fifo);
}


char fifo_is_empty
(fifo_t fifo) {
  return (NULL == fifo->first)
    || (fifo->first == fifo->last && fifo->first_index == fifo->last_index);
}


void fifo_lock
(fifo_t fifo) {
  const struct timespec t = { 0, 10 };
  
  while(!CAS(&fifo->lock, LOCK_FREE, LOCK_TAKEN)) {
    nanosleep(&t, NULL);
  }
}


void fifo_unlock
(fifo_t fifo) {
  fifo->lock = LOCK_FREE;
}


void fifo_enqueue
(fifo_t fifo,
 void * item) {
  void * result;

 check_head:
  if(!fifo->first) {
    fifo->last = fifo_block_new(fifo->block_size, fifo->sizeof_item);
    fifo->last_index = 0;
    fifo->first = fifo->last;
    fifo->first->next = NULL;
    fifo->first->prev = NULL;
  } else if(fifo->block_size == fifo->last_index) {
    if(fifo->concurrent) {
      fifo_lock(fifo);
      if(!fifo->first) {
	fifo_unlock(fifo);
	goto check_head;
      }
    }
    fifo->last->next = fifo_block_new(fifo->block_size, fifo->sizeof_item);
    fifo->last_index = 0;
    fifo->last->next->next = NULL;
    fifo->last->next->prev = fifo->last;
    fifo->last = fifo->last->next;
    if(fifo->concurrent) {
      fifo_unlock(fifo);
    }
  }  
  memcpy(fifo_item_addr(fifo, fifo->last, fifo->last_index),
	 item, fifo->sizeof_item);
  fifo->last_index ++;
}


void fifo_dequeue
(fifo_t fifo,
 void * item) {
  fifo_block_t tmp;

  fifo_next(fifo, item);
  fifo->first_index ++;
  if(fifo->block_size == fifo->first_index) {
    fifo_lock(fifo);
    tmp = fifo->first->next;
    fifo_block_free(fifo->first, 0);
    fifo->first = tmp;
    fifo->first_index = 0;
    fifo_unlock(fifo);
  }
}



void fifo_next
(fifo_t fifo,
 void * item) {
  assert(fifo->first && fifo->first_index < fifo->block_size);
  memcpy(item, fifo_item_addr(fifo, fifo->first, fifo->first_index),
	 fifo->sizeof_item);
}
