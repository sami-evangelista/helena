#include "bfs_queue.h"

#if defined(CFG_ALGO_BFS) || defined(CFG_ALGO_DBFS) || \
  defined(CFG_ALGO_FRONTIER)

struct struct_bfs_queue_block_t {
  bfs_queue_item_t * items;
  heap_t heap;
  struct struct_bfs_queue_block_t * prev;
  struct struct_bfs_queue_block_t * next;
};

typedef struct struct_bfs_queue_block_t struct_bfs_queue_block_t;

typedef struct_bfs_queue_block_t * bfs_queue_block_t;

typedef struct {
  bfs_queue_block_t first;
  bfs_queue_block_t last;
  uint64_t first_index;
  uint64_t last_index;
  uint64_t size;
} struct_bfs_queue_slot_t;

typedef struct_bfs_queue_slot_t * bfs_queue_slot_t;

struct struct_bfs_queue_t {
  bfs_queue_slot_t ** current;
  bfs_queue_slot_t ** next;
  uint16_t no_workers;
  uint32_t slot_size;
  bool_t states_stored;
  bool_t events_stored;
};

typedef struct struct_bfs_queue_t struct_bfs_queue_t;

bfs_queue_block_t bfs_queue_block_new
(uint32_t slot_size,
 bool_t allocate_heap) {
  bfs_queue_block_t result;
  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_bfs_queue_block_t));
  result->items = mem_alloc(SYSTEM_HEAP, sizeof(bfs_queue_item_t) * slot_size);
  if(allocate_heap) {
    result->heap = evergrowing_heap_new("", 1000);
  } else {
    result->heap = NULL;
  }
  return result;
}

void bfs_queue_block_free
(bfs_queue_block_t n,
 bool_t free_next) {  
  if(n) {
    if(free_next && n->next) {
      bfs_queue_block_free(n->next, free_next);
    }
    heap_free(n->heap);
    mem_free(SYSTEM_HEAP, n->items);
    mem_free(SYSTEM_HEAP, n);
  }
}

bfs_queue_slot_t bfs_queue_slot_new
() {
  bfs_queue_slot_t result;
  result = mem_alloc(SYSTEM_HEAP, sizeof (struct_bfs_queue_slot_t));
  result->first = NULL;
  result->last = NULL;
  result->first_index = 0;
  result->last_index = 0;
  result->size = 0;
  return result;
}

void bfs_queue_slot_free
(bfs_queue_slot_t q) {
  bfs_queue_block_free(q->first, TRUE);
  mem_free(SYSTEM_HEAP, q);
}

bfs_queue_t bfs_queue_new
(uint16_t no_workers,
 uint32_t slot_size,
 bool_t states_stored,
 bool_t events_stored) {
  worker_id_t w, x;
  bfs_queue_t result;
  
  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_bfs_queue_t));
  result->no_workers = no_workers;
  result->slot_size = slot_size;
  result->states_stored = states_stored;
  result->events_stored = events_stored;
  result->current = mem_alloc(SYSTEM_HEAP,
                              sizeof(bfs_queue_slot_t *) * no_workers);
  result->next = mem_alloc(SYSTEM_HEAP,
                           sizeof(bfs_queue_slot_t *) * no_workers);
  for(w = 0; w < no_workers; w ++) {
    result->current[w] = mem_alloc(SYSTEM_HEAP,
                                   sizeof(bfs_queue_slot_t) * no_workers);
    result->next[w] = mem_alloc(SYSTEM_HEAP,
                                sizeof(bfs_queue_slot_t) * no_workers);
    for(x = 0; x < no_workers; x ++) {
      result->current[w][x] = bfs_queue_slot_new(slot_size);
      result->next[w][x] = bfs_queue_slot_new(slot_size);
    }
  }
  return result;
}

void bfs_queue_free
(bfs_queue_t q) {
  worker_id_t w, x;

  for(w = 0; w < q->no_workers; w ++) {
    for(x = 0; x < q->no_workers; x ++) {
      bfs_queue_slot_free(q->current[w][x]);
      bfs_queue_slot_free(q->next[w][x]);
    }
    mem_free(SYSTEM_HEAP, q->next[w]);
    mem_free(SYSTEM_HEAP, q->current[w]);
  }
  mem_free(SYSTEM_HEAP, q->next);
  mem_free(SYSTEM_HEAP, q->current);
  mem_free(SYSTEM_HEAP, q);
}

bool_t bfs_queue_states_stored
(bfs_queue_t q) {
  return q->states_stored;
}

bool_t bfs_queue_is_empty
(bfs_queue_t q) {
  return (bfs_queue_size(q) == 0) ? TRUE : FALSE;
}

uint64_t bfs_queue_size
(bfs_queue_t q) {
  uint64_t result = 0;
  worker_id_t w, x;

  for(w = 0; w < q->no_workers; w ++) {
    for(x = 0; x < q->no_workers; x ++) {
      result += q->current[w][x]->size + q->next[w][x]->size;
    }
  }
  return result;
}

uint16_t bfs_queue_no_workers
(bfs_queue_t q) {
  return q->no_workers;
}

bool_t bfs_queue_slot_is_empty
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to) {
  return (q->current[to][from]->size > 0) ? FALSE : TRUE;
}

void bfs_queue_enqueue
(bfs_queue_t q,
 bfs_queue_item_t item,
 worker_id_t from,
 worker_id_t to) {
  bfs_queue_slot_t slot = q->next[to][from];
  
  if(!slot->first) {
    slot->last = bfs_queue_block_new(q->slot_size, q->states_stored);
    slot->last_index = 0;
    slot->first = slot->last;
    slot->first->next = NULL;
    slot->first->prev = NULL;
  }
  else if(q->slot_size == slot->last_index) {
    slot->last->next = bfs_queue_block_new(q->slot_size, q->states_stored);
    slot->last_index = 0;
    slot->last->next->next = NULL;
    slot->last->next->prev = slot->last;
    slot->last = slot->last->next;
  }
  if(q->states_stored) {
    item.s = state_copy_mem(item.s, slot->last->heap);
  }
  if(q->events_stored && item.e_set) {
    item.e = event_copy_mem(item.e, slot->last->heap);
  }
  slot->last->items[slot->last_index] = item;
  slot->last_index ++;
  slot->size ++;
}

bfs_queue_item_t bfs_queue_dequeue
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to) {
  bfs_queue_item_t result;
  bfs_queue_block_t tmp;
  bfs_queue_slot_t slot = q->current[to][from];

  if(q->slot_size == slot->first_index) {
    tmp = slot->first->next;
    bfs_queue_block_free(slot->first, FALSE);
    slot->first = tmp;
    slot->first_index = 0;
  }
  result = slot->first->items[slot->first_index];
  slot->first_index ++;
  slot->size --;
  return result;
}

void bfs_queue_switch_level
(bfs_queue_t q,
 worker_id_t w) {
  worker_id_t x;

  for(x = 0; x < q->no_workers; x ++) {
    bfs_queue_slot_free(q->current[w][x]);
    q->current[w][x] = q->next[w][x];
    q->next[w][x] = bfs_queue_slot_new();
  }
}

#endif  /*  defined(CFG_ALGO_BFS) || defined(CFG_ALGO_FRONTIER)  */
