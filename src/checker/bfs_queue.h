/**
 * @file   bfs_queue.h
 * @author Sami Evangelista
 * @date   12 sep 2017
 * @brief  Implementation of the queue used by BFS based algorithm.
 *
 */

#ifndef LIB_BFS_QUEUE
#define LIB_BFS_QUEUE

#include "bfs.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

#if !defined(STORAGE_STATE_RECOVERABLE)
#define BFS_QUEUE_STATE_IN_QUEUE
#endif

/**
 * @struct bfs_queue_item_t
 * @brief  items of the BFS queue
 *
 * If states cannot be recovered from the storage (e.g., if
 * hash-compaction is one) we need to save the full state descriptor
 * in the queue (symbol BFS_QUEUE_STATE_IN_QUEUE is defined).
 */
typedef struct {
  state_t s;
  storage_id_t id;
} bfs_queue_item_t;


/**
 * @typedef bfs_queue_t
 */
typedef struct struct_bfs_queue_t * bfs_queue_t;


/**
 * @brief BFS queue constructor
 */
bfs_queue_t bfs_queue_new
(uint16_t no_workers);


/**
 * @brief check if queue q is empty
 */
bool_t bfs_queue_is_empty
(bfs_queue_t q);


/**
 * @brief bfs_queue_free
 */
void bfs_queue_free
(bfs_queue_t q);


/**
 * @brief bfs_queue_size
 */
uint64_t bfs_queue_size
(bfs_queue_t q);


/**
 * @brief bfs_queue_no_workers
 */
uint16_t bfs_queue_no_workers
(bfs_queue_t q);


/**
 * @brief bfs_queue_slot_is_empty
 */
bool_t bfs_queue_slot_is_empty
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to);


/**
 * @brief bfs_queue_enqueue
 */
void bfs_queue_enqueue
(bfs_queue_t  q,
 bfs_queue_item_t item,
 worker_id_t from,
 worker_id_t to);


/**
 * @brief bfs_queue_dequeue
 */
bfs_queue_item_t bfs_queue_dequeue
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to);


/**
 * @brief bfs_queue_switch_level
 */
void bfs_queue_switch_level
(bfs_queue_t q,
 worker_id_t w);

#endif
