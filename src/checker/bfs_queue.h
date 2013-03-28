#ifndef LIB_BFS_QUEUE
#define LIB_BFS_QUEUE

#include "bfs.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

struct struct_bfs_queue_node_t {
  bfs_queue_item_t  elements [BFS_QUEUE_NODE_SIZE];
  struct struct_bfs_queue_node_t * prev;
  struct struct_bfs_queue_node_t * next;
};

typedef struct struct_bfs_queue_node_t struct_bfs_queue_node_t;

typedef struct_bfs_queue_node_t * bfs_queue_node_t;

typedef struct {
  bfs_queue_node_t first;
  bfs_queue_node_t last;
  large_unsigned_t first_index;
  large_unsigned_t last_index;
  large_unsigned_t size;
  bool_t shared;
} struct_bfs_queue_t;

typedef struct_bfs_queue_t * bfs_queue_t;


bfs_queue_t bfs_queue_init
();

bool_t bfs_queue_is_empty
(bfs_queue_t q);

void bfs_queue_free
(bfs_queue_t q);

large_unsigned_t bfs_queue_size
(bfs_queue_t q);

large_unsigned_t bfs_queue_enqueue
(bfs_queue_t  q,
 bfs_queue_item_t s);

bfs_queue_item_t bfs_queue_dequeue
(bfs_queue_t q);

#endif
