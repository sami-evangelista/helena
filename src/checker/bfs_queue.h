/**
 * @file bfs_queue.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Implementation of the queue used by BFS based algorithm.
 */

#ifndef LIB_BFS_QUEUE
#define LIB_BFS_QUEUE

#include "bfs.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

#define BFS_QUEUE_BLOCK_SIZE 10000

#if defined(CFG_ALGO_DBFS)
#define NO_WORKERS_QUEUE (CFG_NO_WORKERS + 1)
#else
#define NO_WORKERS_QUEUE CFG_NO_WORKERS
#endif

#if !defined(STORAGE_STATE_RECOVERABLE)
#define BFS_QUEUE_STATE_IN_QUEUE
#endif

/**
 *  items of the BFS queue
 *
 *  if states cannot be recovered from the storage (e.g., if
 *  hash-compaction is one) we need to save the full state descriptor
 *  in the queue (symbol BFS_QUEUE_STATE_IN_QUEUE is defined)
 */
typedef struct {
  state_t s;
  storage_id_t id;
} bfs_queue_item_t;

typedef struct struct_bfs_queue_t * bfs_queue_t;

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
 bfs_queue_item_t item,
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
