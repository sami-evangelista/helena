/**
 * @file dfs_stack.h
 * @brief Implementation of the DFS stack used by DFS based algorithms.
 * @date 12 sep 2017
 * @author Sami Evangelista
 *
 * A DFS stack has an in memory part which consists of two blocks B1,
 * B2 of states.  States are first pushed on B1 and then on B2 when B1
 * is full.  When both are full, B1 is written to disk, B1 = B2, and
 * B2 = empty.  When the last state is popped from the stack (i.e., B1
 * is empty), a block is read from disk and put in B1.
 *
 * The stack stores state identifiers unless some technique preventing
 * the recovery of states from the hash table is used (e.g., hash
 * compaction).  In this case, the stack also stores full states.  The
 * stack also stores enabled events of states.
 */

#ifndef LIB_DFS_STACK
#define LIB_DFS_STACK

#include "includes.h"
#include "config.h"
#include "hash_tbl.h"

/**
 * @typedef the stack type
 */
typedef struct struct_dfs_stack_t * dfs_stack_t;


/**
 * @brief DFS stack constructor.
 * @param id - unique id of the stack
 * @param block_size - size in states of an in memory block of states
 * @param shuffle - TRUE if enabled events of a stack state are randomly
 *        shuffled (e.g., for MC-NDFS)
 * @param states_stored - TRUE if states are fully stored in the stack (i.e.,
 *        not just the state ids)
 */
dfs_stack_t dfs_stack_new
(int id,
 uint32_t block_size,
 bool_t shuffle,
 bool_t states_stored);


/**
 * @brief Free a DFS stack.
 */
void dfs_stack_free
(dfs_stack_t stack);


/**
 * @brief Return the number of states in the stack.
 */
unsigned int dfs_stack_size
(dfs_stack_t stack);


/**
 * @brief Push an item on top of the stack
 */
void dfs_stack_push
(dfs_stack_t stack,
 hash_tbl_id_t sid,
 state_t s);


/**
 * @brief Pop the item on top of the stack.
 */
void dfs_stack_pop
(dfs_stack_t stack);


/**
 * @brief Return the item on top of the stack
 */
hash_tbl_id_t dfs_stack_top
(dfs_stack_t stack);


/**
 * @brief Return a copy of the state on top of the stack that is allocated in
 *        heap h.
 */
state_t dfs_stack_top_state
(dfs_stack_t stack,
 heap_t h);


/**
 * @brief Return enabled events of the state on top of the stack.
 */
event_list_t dfs_stack_top_events
(dfs_stack_t stack);


/**
 * @brief Compute the enabled events of the state on top of the stack.
 * @param s - the state on top of the stack if states are not stored in the
 *        stack
 * @param filter - TRUE if enabled events are filtered according to POR
 * @param e - the event executed to reach s (to apply edge-lean reduction).
 *        NULL if edge-reduction if OFF or s is the initial state
 */
event_list_t dfs_stack_compute_events
(dfs_stack_t stack,
 state_t s,
 bool_t filter,
 event_t * e);


/**
 * @brief Pick the next enabled event of the state on top of the stack.
 */
void dfs_stack_pick_event
(dfs_stack_t stack,
 event_t * e);


/**
 * @brief Undo the last executed event on the state on top of the stack.
 * @param s - the state
 */
void dfs_stack_event_undo
(dfs_stack_t stack,
 state_t s);


/**
 * @brief Unset the proviso of the state on top of the stack to indicate it
 *        has to be later fully expanded by the DFS algorithm.
 */
void dfs_stack_unset_proviso
(dfs_stack_t stack);


/**
 * @brief Check if the state on top of the stack has been expanded.
 */
bool_t dfs_stack_top_expanded
(dfs_stack_t stack);


/**
 * @brief Check if the POR proviso has been verified for the state on top of
 *        the stack.
 */
bool_t dfs_stack_proviso
(dfs_stack_t stack);


/**
 * @brief Create a trace in the global context from the initial state to the
 *        state on top of the stack.
 */
void dfs_stack_create_trace
(dfs_stack_t stack);

#endif
