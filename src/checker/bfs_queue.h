/**
 * @file bfs_queue.h
 * @brief Implementation of the queue used by BFS based algorithm.
 * @date 12 sep 2017
 * @author Sami Evangelista
 *
 * The BFS queue is a W*W array (with W = number of working threads).
 * Each slot (w_from, w_to) of this array contains states enqueued by
 * worker w_from and destinated (i.e., that must be processed) by
 * worker w_to.
 */

#ifndef LIB_BFS_QUEUE
#define LIB_BFS_QUEUE

#include "bfs.h"
#include "stbl.h"


/**
 * @struct bfs_queue_item_t
 * @brief  items of the BFS queue
 *
 * The queue stores state identifiers.  If states cannot be recovered
 * from the hash table (e.g., if hash-compaction is one) we also need
 * to save the full state descriptor
 */
typedef struct {
  htbl_id_t id;
  state_t s;
} bfs_queue_item_t;


/**
 * @typedef bfs_queue_t
 * @brief the BFS queue type
 */
typedef struct struct_bfs_queue_t * bfs_queue_t;


/**
 * @brief BFS queue constructor.
 * @param no_workers - number of workers that will access the queue
 * @param slot_size - number of states in each block of a slot
 * @param states_stored - do we store full states in the queue?
 */
bfs_queue_t bfs_queue_new
(uint16_t no_workers,
 uint32_t slot_size,
 bool_t states_stored);


/**
 * @brief Check if full states are stored in the queue.
 */
bool_t bfs_queue_states_stored
(bfs_queue_t q);


/**
 * @brief Check if queue q is empty.
 */
bool_t bfs_queue_is_empty
(bfs_queue_t q);


/**
 * @brief Check if local queue q of worker w is empty.
 */
bool_t bfs_queue_local_is_empty
(bfs_queue_t q,
 worker_id_t w);


/**
 * @brief Free queue q.
 */
void bfs_queue_free
(bfs_queue_t q);


/**
 * @brief Return the number of threads having access to the queue.
 */
uint16_t bfs_queue_no_workers
(bfs_queue_t q);


/**
 * @brief Check if the next slot (from, to) is empty.
 */
bool_t bfs_queue_slot_is_empty
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to);


/**
 * @brief Enqueue item in the next slot (from, to).
 */
void bfs_queue_enqueue
(bfs_queue_t  q,
 bfs_queue_item_t item,
 worker_id_t from,
 worker_id_t to);


/**
 * @brief Dequeue an item from slot (from, to).
 */
void bfs_queue_dequeue
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to);


/**
 * @brief Get the next item from slot (from, to) but leave it in the
 *        queue.
 */
bfs_queue_item_t bfs_queue_next
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to);

#endif
