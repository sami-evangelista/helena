/**
 * @file bfs_queue.h
 * @brief Implementation of the queue used by BFS based algorithm.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_BFS_QUEUE
#define LIB_BFS_QUEUE

#include "bfs.h"


/**
 * @struct bfs_queue_item_t
 * @brief  items of the BFS queue
 *
 * The queue stores state identifiers.  If states cannot be recovered
 * from the storage (e.g., if hash-compaction is one) we also need to
 * save the full state descriptor.
 */
typedef struct {
  state_t s;
  event_t e;
  bool_t e_set;
  storage_id_t id;
} bfs_queue_item_t;


/**
 * @typedef bfs_queue_t
 * @brief the BFS queue type
 */
typedef struct struct_bfs_queue_t * bfs_queue_t;


/**
 * @brief BFS queue constructor
 */
bfs_queue_t bfs_queue_new
(uint16_t no_workers,
 uint32_t slot_size,
 bool_t states_stored,
 bool_t events_stored);


/**
 * @brief check if full states are stored in the queue
 */
bool_t bfs_queue_states_stored
(bfs_queue_t q);


/**
 * @brief check if queue q is empty
 */
bool_t bfs_queue_is_empty
(bfs_queue_t q);


/**
 * @brief free the queue q
 */
void bfs_queue_free
(bfs_queue_t q);


/**
 * @brief get the size of queue q
 */
uint64_t bfs_queue_size
(bfs_queue_t q);


/**
 * @brief return the number of threads having access to the queue
 */
uint16_t bfs_queue_no_workers
(bfs_queue_t q);


/**
 * @brief check if the next slot (from, to) is empty
 */
bool_t bfs_queue_slot_is_empty
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to);


/**
 * @brief enqueue item in the next slot (from, to)
 */
void bfs_queue_enqueue
(bfs_queue_t  q,
 bfs_queue_item_t item,
 worker_id_t from,
 worker_id_t to);


/**
 * @brief dequeue an item from the current slot (from, to)
 */
bfs_queue_item_t bfs_queue_dequeue
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to);


/**
 * @brief swap all next slots (from, w) by next slots (from, w)
 */
void bfs_queue_switch_level
(bfs_queue_t q,
 worker_id_t w);

#endif
