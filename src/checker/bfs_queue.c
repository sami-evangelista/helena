#include "bfs_queue.h"

bfs_queue_t bfs_queue_init
() {
  bfs_queue_t result = (bfs_queue_t)
    malloc (sizeof (struct_bfs_queue_t));
  result->first = NULL;
  result->last = NULL;
  result->first_index = 0;
  result->last_index = 0;
  result->size = 0;
  return result;
}

bool_t bfs_queue_is_empty
(bfs_queue_t q) {
  bool_t result;
  result = (q->size == 0) ? TRUE : FALSE;
  return result;
}

void bfs_queue_free
(bfs_queue_t q) {
  bfs_queue_node_t tmp = q->first, next;
  while(tmp) {
    next = tmp->next;
    free (tmp);
    tmp = next;
  }
  free (q);
}

large_unsigned_t bfs_queue_size
(bfs_queue_t q) {
  large_unsigned_t result;
  result = q->size;
  return result;
}

large_unsigned_t bfs_queue_enqueue
(bfs_queue_t  q,
 bfs_queue_item_t s) {
  large_unsigned_t result;
  if(!q->first) {
    q->last_index = 0;
    q->last = (bfs_queue_node_t)
      malloc (sizeof (struct_bfs_queue_node_t));
    q->first = q->last;
    q->first->next = NULL;
    q->first->prev = NULL;
  }
  else if(BFS_QUEUE_NODE_SIZE == q->last_index) {
    q->last_index = 0;
    q->last->next = (bfs_queue_node_t)
      malloc (sizeof (struct_bfs_queue_node_t));
    q->last->next->next = NULL;
    q->last->next->prev = q->last;
    q->last = q->last->next;
  }
  q->last->elements[q->last_index] = s;
  q->last_index ++;
  q->size ++;
  result = q->size;
  return result;
}

bfs_queue_item_t bfs_queue_dequeue
(bfs_queue_t q) {
  bfs_queue_item_t  result;
  if(BFS_QUEUE_NODE_SIZE == q->first_index) {
    bfs_queue_node_t tmp = q->first->next;
    free(q->first);
    q->first = tmp;
    q->first_index = 0;
  }
  result = q->first->elements[q->first_index];
  q->first_index ++;
  q->size --;
  return result;
}
