#include "dfs_stack.h"
#include "model.h"
#include "context.h"
#include "reduction.h"

#define DFS_STACK_BLOCKS 2

typedef struct {
  hash_tbl_id_t id;
  event_list_t en;
  event_t e;
  bool_t e_set;
  mem_size_t heap_pos;
  bool_t prov_ok;
  bool_t fully_expanded;
  state_t s;
} dfs_stack_item_t;

typedef struct {
  dfs_stack_item_t * items;
} struct_dfs_stack_block_t;

typedef struct_dfs_stack_block_t * dfs_stack_block_t;

struct struct_dfs_stack_t {
  dfs_stack_block_t blocks[DFS_STACK_BLOCKS];
  heap_t heaps[DFS_STACK_BLOCKS];
  int32_t id;
  uint8_t current;
  int32_t top;
  uint32_t size;
  uint32_t files;
  uint32_t block_size;
  bool_t shuffle;
  bool_t states_stored;
  rseed_t seed;  
};

typedef struct struct_dfs_stack_t struct_dfs_stack_t;

dfs_stack_block_t dfs_stack_block_new
(uint32_t block_size) {
  dfs_stack_block_t result;

  result = mem_alloc(SYSTEM_HEAP,
                     sizeof(struct_dfs_stack_block_t));
  result->items = mem_alloc(SYSTEM_HEAP,
                            block_size * sizeof(dfs_stack_item_t));
  return result;
}

void dfs_stack_block_free
(dfs_stack_block_t block) {
  free(block->items);
  free(block);
}

dfs_stack_t dfs_stack_new
(int id,
 uint32_t block_size,
 bool_t shuffle,
 bool_t states_stored) {
  dfs_stack_t result;
  int i;

  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_dfs_stack_t));
  result->id = id;
  result->block_size = block_size;
  result->shuffle = shuffle;
  result->states_stored = states_stored;
  result->top = - 1;
  result->size = 0;
  result->current = 0;
  result->files = 0;
  result->seed = random_seed(id);
  for(i = 0; i < DFS_STACK_BLOCKS; i ++) {
    result->heaps[i] = local_heap_new();
    result->blocks[i] = dfs_stack_block_new(result->block_size);
  }
  return result;
}

void dfs_stack_free
(dfs_stack_t stack) {
  int i;
  char buffer[256];

  if(stack) {
    for(i = 0; i < stack->files; i ++) {
      sprintf(buffer, "STACK-%d-%d", stack->id, i);
      unlink(buffer);
    }
    for(i = 0; i < DFS_STACK_BLOCKS; i ++) {
      if(stack->blocks[i]) {
	dfs_stack_block_free(stack->blocks[i]);
      }
      if(stack->heaps[i]) {
	heap_free(stack->heaps[i]);
      }
    }
    free(stack);
  }
}

unsigned int dfs_stack_size
(dfs_stack_t stack) {
  if(stack) {
    return stack->size;
  } else {
    return 0;
  }
}

void dfs_stack_write
(dfs_stack_t stack) {
  int i, len;
  unsigned int w;
  FILE * f;
  char buffer[10000];
  heap_t h = stack->heaps[0];
  dfs_stack_block_t block = stack->blocks[0];
  dfs_stack_item_t item;

  sprintf(buffer, "STACK-%d-%d", stack->id, stack->files);
  f = fopen(buffer, "w");
  for(i = 0; i < stack->block_size; i ++) {
    item = block->items[i];

    /*  event list  */
    w = event_list_char_size(item.en);
    event_list_serialise(item.en, buffer);
    fwrite(&w, sizeof(unsigned int), 1, f);
    fwrite(buffer, w, 1, f);

    /*  last event  */
    w = event_char_size(item.e);
    event_serialise(item.e, buffer);
    fwrite(&w, sizeof(unsigned int), 1, f);
    fwrite(buffer, w, 1, f);

    /*  state id  */
    fwrite(&item.id, sizeof(hash_tbl_id_t), 1, f);

    /*  proviso info  */
    if(CFG_PROVISO) {
      fwrite(&item.prov_ok, sizeof(bool_t), 1, f);
      fwrite(&item.fully_expanded, sizeof(bool_t), 1, f);
    }

    /*  state  */
    if(stack->states_stored) {
      len = state_char_size(item.s);
      fwrite(&len, sizeof(int), 1, f);
      state_serialise(item.s, buffer);
      fwrite(buffer, len, 1, f);
    }
  }
  fclose(f);
  stack->files ++;
}

void dfs_stack_read
(dfs_stack_t stack) {
  int i, len;
  unsigned int w, en_size;
  FILE * f;
  char buffer[10000], name[20];
  dfs_stack_item_t item;
  heap_t h = stack->heaps[0];

  stack->files --;
  sprintf(name, "STACK-%d-%d", stack->id, stack->files);
  f = fopen(name, "r");
  heap_reset(h);
  for(i = 0; i < stack->block_size; i ++) {
    item.heap_pos = heap_get_position(h);
    
    /*  event list  */
    fread(&w, sizeof(unsigned int), 1, f);
    fread(buffer, w, 1, f);
    item.en = event_list_unserialise_mem(buffer, h);
    
    /*  last event  */
    fread(&w, sizeof(unsigned int), 1, f);
    fread(buffer, w, 1, f);
    item.e = event_unserialise_mem(buffer, h);
    item.e_set = TRUE;
    
    /*  state id  */
    fread(&item.id, sizeof(hash_tbl_id_t), 1, f);

    /*  proviso info  */
    if(CFG_PROVISO) {
      fread(&item.prov_ok, sizeof(bool_t), 1, f);
      fread(&item.fully_expanded, sizeof(bool_t), 1, f);
    }

    /*  state  */
    if(stack->states_stored) {
      fread(&len, sizeof(int), 1, f);
      fread(buffer, len, 1, f);
      item.s = state_unserialise_mem(buffer, h);
    }
    stack->blocks[0]->items[i] = item;
  }
  fclose(f);
  remove(name);
}

void dfs_stack_push
(dfs_stack_t stack,
 hash_tbl_id_t sid,
 state_t s) {
  heap_t h = stack->heaps[stack->current];
  dfs_stack_item_t item;
  
  stack->top ++;
  stack->size ++;
  if(stack->top == stack->block_size) {
    if(stack->current == 1) {
      dfs_stack_write(stack);
      dfs_stack_block_free(stack->blocks[0]);
      stack->blocks[0] = stack->blocks[1];
      stack->blocks[1] = dfs_stack_block_new(stack->block_size);
      heap_free(stack->heaps[0]);
      stack->heaps[0] = stack->heaps[1];
      stack->heaps[1] = local_heap_new();
    }
    stack->current = 1;
    stack->top = 0;
  }
  h = stack->heaps[stack->current];
  item.id = sid;
  item.en = NULL;
  item.e_set = FALSE;
  if(stack->states_stored) {
    item.s = state_copy_mem(s,h);
  }
  stack->blocks[stack->current]->items[stack->top] = item;
}

void dfs_stack_pop
(dfs_stack_t stack) {
  heap_t h = stack->heaps[stack->current];
  dfs_stack_item_t item = stack->blocks[stack->current]->items[stack->top];
  
  assert(0 != stack->size);
  heap_set_position(h, item.heap_pos);
  stack->top --;
  stack->size --;
  if(stack->size > 0 && stack->top == -1) {
    if(stack->current == 0) {
      assert(stack->files > 0);
      dfs_stack_read(stack);
    }
    stack->current = 0;
    stack->top = stack->block_size - 1;
  }
}

hash_tbl_id_t dfs_stack_top
(dfs_stack_t stack) {
  assert(0 != stack->size);
  return stack->blocks[stack->current]->items[stack->top].id;
}

state_t dfs_stack_top_state
(dfs_stack_t stack,
 heap_t h) {
  state_t result;

  assert(stack->states_stored);
  assert(0 != stack->size);
  result = stack->blocks[stack->current]->items[stack->top].s;
  result = state_copy_mem(result, h);
  return result;
}

event_list_t dfs_stack_top_events
(dfs_stack_t stack) {
  assert(0 != stack->size);
  return stack->blocks[stack->current]->items[stack->top].en;
}

event_list_t dfs_stack_compute_events
(dfs_stack_t stack,
 state_t s,
 bool_t filter,
 event_t * e) {
  heap_t h = stack->heaps[stack->current];
  event_list_t result;
  dfs_stack_item_t item = stack->blocks[stack->current]->items[stack->top];
  bool_t reduced;

  assert(0 != stack->size);
  item.heap_pos = heap_get_position(h);
  
  if(filter) {
    result = state_events_reduced_mem(s, &reduced, h);
    if(CFG_PROVISO) {
      item.prov_ok = TRUE;
      item.fully_expanded = !reduced;
    }
  }
  else {
    result = state_events_mem(s, h);
    if(CFG_PROVISO) {
      item.prov_ok = TRUE;
      item.fully_expanded = TRUE;
    }
  }
  if(e != NULL) {
    edge_lean_reduction(result, *e);
  }
  item.en = result;
  stack->blocks[stack->current]->items[stack->top] = item;
  return result;
}

void dfs_stack_pick_event
(dfs_stack_t stack,
 event_t * e) {
  dfs_stack_item_t item = stack->blocks[stack->current]->items[stack->top];
  int chosen;
  
  if(stack->shuffle) {
    list_pick_random(item.en, &item.e, &stack->seed);
  } else {
    list_pick_first(item.en, &item.e);
  }
  item.e_set = TRUE;
  stack->blocks[stack->current]->items[stack->top] = item;
  *e = item.e;
}

void dfs_stack_event_undo
(dfs_stack_t stack,
 state_t s) {
  dfs_stack_item_t item = stack->blocks[stack->current]->items[stack->top];
   
  event_undo(item.e, s);
}

void dfs_stack_unset_proviso
(dfs_stack_t stack) {
  if(CFG_PROVISO) {
    stack->blocks[stack->current]->items[stack->top].prov_ok = FALSE;
  }
}

bool_t dfs_stack_top_expanded
(dfs_stack_t stack) {
  dfs_stack_item_t item = stack->blocks[stack->current]->items[stack->top];
  
  return list_is_empty(item.en);
} 

bool_t dfs_stack_proviso
(dfs_stack_t stack) {
  bool_t result = TRUE;
  dfs_stack_item_t item;
  
  if(CFG_PROVISO) {
    item = stack->blocks[stack->current]->items[stack->top];
    result = item.prov_ok || item.fully_expanded;
  }
  return result;
}

void dfs_stack_create_trace
(dfs_stack_t stack) {
  event_t e;
  dfs_stack_item_t item;
  int i;
  event_list_t trace = list_new(SYSTEM_HEAP, sizeof(event_t), event_free_void);

  dfs_stack_pop(stack);
  while(stack->size > 0) {
    item = stack->blocks[stack->current]->items[stack->top];
    if(item.e_set) {
      e = event_copy(item.e);
      list_prepend(trace, &e);
    }
    dfs_stack_pop(stack);
  }
  context_set_trace(trace);
}
