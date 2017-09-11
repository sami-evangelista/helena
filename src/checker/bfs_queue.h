#ifndef LIB_BFS_QUEUE
#define LIB_BFS_QUEUE

#include "bfs.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

#define BFS_QUEUE_NODE_SIZE 10000

#if defined(CFG_ALGO_DBFS)
#define NO_WORKERS_QUEUE (CFG_NO_WORKERS + 1)
#else
#define NO_WORKERS_QUEUE CFG_NO_WORKERS
#endif

typedef struct {
  storage_id_t s;
#ifdef CFG_WITH_TRACE
  unsigned int l;
  unsigned char * trace;
#endif
} bfs_queue_item_t;      

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
  uint64_t first_index;
  uint64_t last_index;
  uint64_t size;
} struct_bfs_queue_slot_t;

typedef struct_bfs_queue_slot_t * bfs_queue_slot_t;

typedef struct {
  bfs_queue_slot_t current[NO_WORKERS_QUEUE][NO_WORKERS_QUEUE];
  bfs_queue_slot_t next[NO_WORKERS_QUEUE][NO_WORKERS_QUEUE];  
} struct_bfs_queue_t;

typedef struct_bfs_queue_t * bfs_queue_t;

bfs_queue_t bfs_queue_new
();

bool_t bfs_queue_is_empty
(bfs_queue_t q);

void bfs_queue_free
(bfs_queue_t q);

uint64_t bfs_queue_size
(bfs_queue_t q);

bool_t bfs_queue_slot_is_empty
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to);

void bfs_queue_enqueue
(bfs_queue_t  q,
 bfs_queue_item_t s,
 worker_id_t from,
 worker_id_t to);

bfs_queue_item_t bfs_queue_dequeue
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to);

void bfs_queue_switch_level
(bfs_queue_t q,
 worker_id_t w);

#endif
