#include "bfs_queue.h"
#include "config.h"

#define LOCK_FREE  0
#define LOCK_TAKEN 1

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
  uint8_t lock;
} struct_bfs_queue_slot_t;

typedef struct_bfs_queue_slot_t * bfs_queue_slot_t;

struct struct_bfs_queue_t {
  bfs_queue_slot_t ** slots;
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
    result->heap = local_heap_new();
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
      bfs_queue_block_free(n->next, TRUE);
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
  result->lock = LOCK_FREE;
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
  uint8_t l;
  
  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_bfs_queue_t));
  result->no_workers = no_workers;
  result->slot_size = slot_size;
  result->states_stored = states_stored;
  result->events_stored = events_stored;
  result->slots = mem_alloc(SYSTEM_HEAP,
                            sizeof(bfs_queue_slot_t *) * no_workers);
  for(w = 0; w < no_workers; w ++) {
    result->slots[w] = mem_alloc(SYSTEM_HEAP,
                                    sizeof(bfs_queue_slot_t) * no_workers);
    for(x = 0; x < no_workers; x ++) {
      result->slots[w][x] = bfs_queue_slot_new(slot_size);
    }
  }
  return result;
}

void bfs_queue_free
(bfs_queue_t q) {
  worker_id_t w, x;
  
  for(w = 0; w < q->no_workers; w ++) {
    for(x = 0; x < q->no_workers; x ++) {
      bfs_queue_slot_free(q->slots[w][x]);
    }
    mem_free(SYSTEM_HEAP, q->slots[w]);
  }
  mem_free(SYSTEM_HEAP, q->slots);
  mem_free(SYSTEM_HEAP, q);
}

bool_t bfs_queue_states_stored
(bfs_queue_t q) {
  return q->states_stored;
}

uint16_t bfs_queue_no_workers
(bfs_queue_t q) {
  return q->no_workers;
}

bool_t bfs_queue_slot_is_empty_real
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to) {
  bfs_queue_slot_t slot = q->slots[to][from];
  
  return ((NULL == slot->first) ||
	  (slot->first == slot->last &&
	   slot->first_index == slot->last_index)) ?
    TRUE : FALSE;
}

bool_t bfs_queue_slot_is_empty
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to) {
  return bfs_queue_slot_is_empty_real(q, from, to);
}

bool_t bfs_queue_local_is_empty
(bfs_queue_t q,
 worker_id_t w) {
  worker_id_t x;
  uint8_t l;
  
  for(x = 0; x < q->no_workers; x ++) {
    if(!bfs_queue_slot_is_empty_real(q, x, w)) {
      return FALSE;
    }
  }
  return TRUE;
}

bool_t bfs_queue_is_empty
(bfs_queue_t q) {
  worker_id_t w;
  
  for(w = 0; w < q->no_workers; w ++) {
    if(!bfs_queue_local_is_empty(q, w)) {
      return FALSE;
    }
  }
  return TRUE;
}

void bfs_queue_slot_take_lock
(bfs_queue_slot_t slot) {
  const struct timespec t = { 0, 10 };
  
  while(!CAS(&slot->lock, LOCK_FREE, LOCK_TAKEN)) {
    context_sleep(t);
  }
}

void bfs_queue_slot_release_lock
(bfs_queue_slot_t slot) {
  slot->lock = LOCK_FREE;
}

void bfs_queue_enqueue
(bfs_queue_t q,
 bfs_queue_item_t item,
 worker_id_t from,
 worker_id_t to) {
  bfs_queue_slot_t slot = q->slots[to][from];

 check_head:
  if(!slot->first) {
    slot->last = bfs_queue_block_new(q->slot_size, q->states_stored);
    slot->last_index = 0;
    slot->first = slot->last;
    slot->first->next = NULL;
    slot->first->prev = NULL;
  }
  else if(q->slot_size == slot->last_index) {
    bfs_queue_slot_take_lock(slot);
    if(!slot->first) {
      bfs_queue_slot_release_lock(slot);
      goto check_head;
    }
    slot->last->next = bfs_queue_block_new(q->slot_size, q->states_stored);
    slot->last_index = 0;
    slot->last->next->next = NULL;
    slot->last->next->prev = slot->last;
    slot->last = slot->last->next;
    bfs_queue_slot_release_lock(slot);
  }
  if(q->states_stored) {
    item.s = state_copy(item.s, slot->last->heap);
  }
  if(q->events_stored && item.e_set) {
    item.e = event_copy(item.e, slot->last->heap);
  }
  slot->last->items[slot->last_index] = item;
  slot->last_index ++;
}

void bfs_queue_dequeue
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to) {
  bfs_queue_block_t tmp;
  bfs_queue_slot_t slot = q->slots[to][from];

  slot->first_index ++;
  if(q->slot_size == slot->first_index) {
    bfs_queue_slot_take_lock(slot);
    tmp = slot->first->next;
    bfs_queue_block_free(slot->first, FALSE);
    slot->first = tmp;
    slot->first_index = 0;
    bfs_queue_slot_release_lock(slot);
  }
}

bfs_queue_item_t bfs_queue_next
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to) {
  bfs_queue_item_t result;
  bfs_queue_slot_t slot = q->slots[to][from];

  assert(slot->first && slot->first_index < q->slot_size);
  result = slot->first->items[slot->first_index];
  return result;
}
