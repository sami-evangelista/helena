/**
 * @file dfs_stack.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Implementation of the DFS stack used by DFS based algorithms.
 */

#ifndef LIB_DFS_STACK
#define LIB_DFS_STACK

#include "includes.h"
#include "report.h"
#include "storage.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

#define DFS_STACK_SLOT_SIZE 10000
#define DFS_STACK_SLOTS 2

#if !defined(CFG_EVENT_UNDOABLE) && !defined(STORAGE_STATE_RECOVERABLE)
#define DFS_STACK_STATE_IN_STACK
#endif

typedef struct struct_dfs_stack_t * dfs_stack_t;

dfs_stack_t dfs_stack_new
(int id);

void dfs_stack_free
(dfs_stack_t stack);

unsigned int dfs_stack_size
(dfs_stack_t stack);

void dfs_stack_push
(dfs_stack_t stack,
 storage_id_t sid,
 state_t s);

void dfs_stack_pop
(dfs_stack_t stack);

storage_id_t dfs_stack_top
(dfs_stack_t stack);

state_t dfs_stack_top_state
(dfs_stack_t stack,
 heap_t h);

event_set_t dfs_stack_top_events
(dfs_stack_t stack);

event_set_t dfs_stack_compute_events
(dfs_stack_t stack,
 state_t s,
 bool_t filter);

void dfs_stack_pick_event
(dfs_stack_t stack,
 event_t * e,
 event_id_t * eid);

void dfs_stack_event_undo
(dfs_stack_t stack,
 state_t s);

void dfs_stack_unset_proviso
(dfs_stack_t stack);

bool_t dfs_stack_top_expanded
(dfs_stack_t stack);

bool_t dfs_stack_proviso
(dfs_stack_t stack);

void dfs_stack_create_trace
(dfs_stack_t blue_stack,
 dfs_stack_t red_stack,
 report_t r);

#endif
