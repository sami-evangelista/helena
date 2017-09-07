#include "bfs_queue.h"

#if defined(CFG_ALGO_BFS) || defined(CFG_ALGO_FRONTIER)

bfs_queue_slot_t bfs_queue_slot_new
() {
  bfs_queue_slot_t result;
  MALLOC(result, bfs_queue_slot_t, sizeof (struct_bfs_queue_slot_t));
  result->first = NULL;
  result->last = NULL;
  result->first_index = 0;
  result->last_index = 0;
  result->size = 0;
  return result;
}

void bfs_queue_slot_free
(bfs_queue_slot_t q) {
  bfs_queue_node_t tmp = q->first, next;
  while(tmp) {
    next = tmp->next;
    free(tmp);
    tmp = next;
  }
  free(q);
}

bfs_queue_t bfs_queue_new
() {
  worker_id_t w, x;
  bfs_queue_t result;
  
  MALLOC(result, bfs_queue_t, sizeof (struct_bfs_queue_t));
  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    for(x = 0; x < CFG_NO_WORKERS; x ++) {
      result->current[w][x] = bfs_queue_slot_new();
      result->next[w][x] = bfs_queue_slot_new();
    }
  }
  return result;
}

bool_t bfs_queue_is_empty
(bfs_queue_t q) {
  return (bfs_queue_size(q) == 0) ? TRUE : FALSE;
}

void bfs_queue_free
(bfs_queue_t q) {
  worker_id_t w, x;

  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    for(x = 0; x < CFG_NO_WORKERS; x ++) {
      bfs_queue_slot_free(q->current[w][x]);
      bfs_queue_slot_free(q->next[w][x]);
    }
  }
}

uint64_t bfs_queue_size
(bfs_queue_t q) {
  uint64_t result = 0;
  worker_id_t w, x;

  for(w = 0; w < CFG_NO_WORKERS; w ++) {
    for(x = 0; x < CFG_NO_WORKERS; x ++) {
      result += q->current[w][x]->size + q->next[w][x]->size;
    }
  }
  return result;
}

bool_t bfs_queue_slot_is_empty
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to) {
  return (q->current[to][from]->size > 0) ? FALSE : TRUE;
}

void bfs_queue_enqueue
(bfs_queue_t  q,
 bfs_queue_item_t s,
 worker_id_t from,
 worker_id_t to) {
  bfs_queue_slot_t slot = q->next[to][from];
  
  if(!slot->first) {
    slot->last_index = 0;
    MALLOC(slot->last, bfs_queue_node_t,
           sizeof (struct_bfs_queue_node_t));
    slot->first = slot->last;
    slot->first->next = NULL;
    slot->first->prev = NULL;
  }
  else if(BFS_QUEUE_NODE_SIZE == slot->last_index) {
    slot->last_index = 0;
    MALLOC(slot->last->next, bfs_queue_node_t,
           sizeof (struct_bfs_queue_node_t));
    slot->last->next->next = NULL;
    slot->last->next->prev = slot->last;
    slot->last = slot->last->next;
  }
  slot->last->elements[slot->last_index] = s;
  slot->last_index ++;
  slot->size ++;
}

bfs_queue_item_t bfs_queue_dequeue
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to) {
  bfs_queue_node_t tmp;
  bfs_queue_item_t result;
  bfs_queue_slot_t slot = q->current[to][from];

  if(BFS_QUEUE_NODE_SIZE == slot->first_index) {
    tmp = slot->first->next;
    free(slot->first);
    slot->first = tmp;
    slot->first_index = 0;
  }
  result = slot->first->elements[slot->first_index];
  slot->first_index ++;
  slot->size --;
  return result;
}

void bfs_queue_switch_level
(bfs_queue_t q,
 worker_id_t w) {
  worker_id_t x;

  for(x = 0; x < CFG_NO_WORKERS; x ++) {
    bfs_queue_slot_free(q->current[w][x]);
    q->current[w][x] = q->next[w][x];
    q->next[w][x] = bfs_queue_slot_new();
  }
}

#endif  /*  defined(CFG_ALGO_BFS) || defined(CFG_ALGO_FRONTIER)  */
