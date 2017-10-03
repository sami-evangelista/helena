/**
 * @file bfs_queue.h
 * @brief Implementation of the queue used by BFS based algorithm.
 * @date 12 sep 2017
 * @author Sami Evangelista
 *
 * The queue is decomposed in two parts: the *current* queue storing
 * states of the current BFS level ; and the *next* queue storing
 * states of the next BFS level.  States are dequeued from the current
 * queue and new states are enqueued in the next queue.  Once a BFS
 * level terminated, the next queue is moved to the current queue and
 * the next queue is emptied.  Each of these queues is a W*W array
 * (with W = number of working threads).  Each slot (w_from, w_to) of
 * this array contains states enqueued by worker w_from and destinated
 * (i.e., that must be processed) by worker w_to.  Decomposing the
 * queue in two distinct parts and clustering each one into a
 * two-dimensional array allows to avoid the use of locks.
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
 * save the full state descriptor.  In some case (e.g. edge-lean
 * reduction, we also store the event that generated the state from
 * the successor).  e_set = TRUE if and only if the event e is
 * relevant.  Otherwise it is false, e.g. for the initial state.
 */
typedef struct {
  storage_id_t id;
  state_t s;
  event_t e;
  bool_t e_set;
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
 * @param events_stored - do we store events in the queue?
 */
bfs_queue_t bfs_queue_new
(uint16_t no_workers,
 uint32_t slot_size,
 bool_t states_stored,
 bool_t events_stored);


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
 * @brief Free queue q.
 */
void bfs_queue_free
(bfs_queue_t q);


/**
 * @brief Get the size of queue q.
 */
uint64_t bfs_queue_size
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
 * @brief Dequeue an item from the current slot (from, to).
 */
bfs_queue_item_t bfs_queue_dequeue
(bfs_queue_t q,
 worker_id_t from,
 worker_id_t to);


/**
 * @brief Swap all next slots (from, w) by next slots (from, w).  This
 *        has to be call by all workers.
 */
void bfs_queue_switch_level
(bfs_queue_t q,
 worker_id_t w);

#endif
