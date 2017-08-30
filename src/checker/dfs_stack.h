#ifndef LIB_DFS_STACK
#define LIB_DFS_STACK

#include "includes.h"
#include "report.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

#define DFS_STACK_SLOT_SIZE 100000
#define DFS_STACK_SLOTS 2

typedef struct {
  unsigned char n;
  storage_id_t id;
  event_set_t en;
  heap_t heap_pos;
#if defined(POR) && defined(PROVISO)
  bool_t prov_ok;
  bool_t fully_expanded;
#endif
} dfs_stack_item_t;

typedef struct {
  dfs_stack_item_t items[DFS_STACK_SLOT_SIZE];
} struct_dfs_stack_slot_t;

typedef struct_dfs_stack_slot_t * dfs_stack_slot_t;

typedef struct {
  dfs_stack_slot_t slots[DFS_STACK_SLOTS];
  heap_t heaps[DFS_STACK_SLOTS];
  unsigned char current;
  int top;
  unsigned int size;
  unsigned int files;
  int id;
} struct_dfs_stack_t;

typedef struct_dfs_stack_t * dfs_stack_t;

dfs_stack_t dfs_stack_new
(int id);

void dfs_stack_free
(dfs_stack_t stack);

unsigned int dfs_stack_size
(dfs_stack_t stack);

void dfs_stack_push
(dfs_stack_t stack,
 dfs_stack_item_t item);

void dfs_stack_pop
(dfs_stack_t stack);

dfs_stack_item_t dfs_stack_top
(dfs_stack_t stack);

void dfs_stack_update_top
(dfs_stack_t stack,
 dfs_stack_item_t item);

event_set_t dfs_stack_compute_events
(dfs_stack_t stack,
 state_t s,
 bool_t filter,
 event_t * exec);

void dfs_stack_create_trace
(dfs_stack_t blue_stack,
 dfs_stack_t red_stack,
 report_t r);

#endif
