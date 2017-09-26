#include "dfs_stack.h"
#include "model.h"
#include "context.h"

#if defined(CFG_ALGO_DFS) || defined(CFG_ALGO_DDFS)

#define DFS_STACK_BLOCKS 2

typedef struct {
  storage_id_t id;
  event_list_t en;
  event_t e;
  bool_t e_set;
  heap_t heap_pos;
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
  char name[100];

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
    sprintf(name, "DFS stack heap");
    result->heaps[i] = bounded_heap_new(name, result->block_size * 1000);
    result->blocks[i] = dfs_stack_block_new(result->block_size);
  }
  return result;
}

void dfs_stack_free
(dfs_stack_t stack) {
  int i;

  if(stack) {
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
    w = event_list_char_width(item.en);
    event_list_serialise(item.en, buffer);
    fwrite(&w, sizeof(unsigned int), 1, f);
    fwrite(buffer, w, 1, f);

    /*  last event  */
    w = event_char_width(item.e);
    event_serialise(item.e, buffer);
    fwrite(&w, sizeof(unsigned int), 1, f);
    fwrite(buffer, w, 1, f);

    /*  state id  */
    fwrite(&item.id, sizeof(storage_id_t), 1, f);
    
#if defined(CFG_POR) && defined(CFG_PROVISO)
    fwrite(&item.prov_ok, sizeof(bool_t), 1, f);
    fwrite(&item.fully_expanded, sizeof(bool_t), 1, f);
#endif

    /*  state  */
    if(stack->states_stored) {
      len = state_char_width(item.s);
      fwrite(&len, sizeof(int), 1, f);
      state_serialise(item.s, buffer);
      fwrite(buffer, len, 1, f);
      state_free(item.s);
    }
    event_list_free(item.en);
    event_free(item.e);
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
    fread(&item.id, sizeof(storage_id_t), 1, f);
    
#if defined(CFG_POR) && defined(CFG_PROVISO)
    fread(&item.prov_ok, sizeof(bool_t), 1, f);
    fread(&item.fully_expanded, sizeof(bool_t), 1, f);
#endif

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
 storage_id_t sid,
 state_t s) {
  heap_t h = stack->heaps[stack->current];
  dfs_stack_item_t item;
  
  stack->top ++;
  stack->size ++;
  if(stack->top == stack->block_size) {
    if(stack->current == 1) {
      char name[100];
      dfs_stack_write(stack);
      dfs_stack_block_free(stack->blocks[0]);
      stack->blocks[0] = stack->blocks[1];
      stack->blocks[1] = dfs_stack_block_new(stack->block_size);
      heap_free(stack->heaps[0]);
      stack->heaps[0] = stack->heaps[1];
      sprintf(name, "DFS stack heap");
      stack->heaps[1] = bounded_heap_new(name, stack->block_size * 1000);
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
  if(stack->states_stored) {
    state_free(item.s);
  }
  event_list_free(item.en);
  if(item.e_set) {
    event_free(item.e);
  }
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

storage_id_t dfs_stack_top
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
 bool_t filter) {
  heap_t h = stack->heaps[stack->current];
  int i;
  event_list_t result;
  unsigned int en_size, en_size_reduced;
  dfs_stack_item_t item = stack->blocks[stack->current]->items[stack->top];

  assert(0 != stack->size);
  if(item.en) {
    event_list_free(item.en);
  }
  item.heap_pos = heap_get_position(h);
  result = state_enabled_events_mem(s, h);
  
  /*  compute a stubborn set if POR is activated  */
#if defined(CFG_POR)
  if(filter) {
    en_size = event_list_size(result);
    state_stubborn_set(s, result);
#if defined(CFG_PROVISO)
    item.prov_ok = TRUE;
    item.fully_expanded = (en_size == event_list_size(result)) ?
      TRUE : FALSE;
#endif
  }
#if defined(CFG_PROVISO)
  else {
    item.prov_ok = TRUE;
    item.fully_expanded = TRUE;
  }
#endif
#endif
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
    event_list_pick_random(item.en, &item.e, &stack->seed);
  } else {
    event_list_pick_first(item.en, &item.e);
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
#if defined(CFG_POR) && defined(CFG_PROVISO)
  stack->blocks[stack->current]->items[stack->top].prov_ok = FALSE;
#endif
}

bool_t dfs_stack_top_expanded
(dfs_stack_t stack) {
  dfs_stack_item_t item = stack->blocks[stack->current]->items[stack->top];
  
  return event_list_is_empty(item.en);
} 

bool_t dfs_stack_proviso
(dfs_stack_t stack) {
  bool_t result = TRUE;
  dfs_stack_item_t item;
  
#if defined(CFG_POR) && defined(CFG_PROVISO)
  item = stack->blocks[stack->current]->items[stack->top];
  result = item.prov_ok || item.fully_expanded;
#endif
  return result;
}

void dfs_stack_create_trace
(dfs_stack_t blue_stack,
 dfs_stack_t red_stack) {
  event_t e;
  dfs_stack_t stack, stacks[2];
  dfs_stack_item_t item;
  int i;
  list_t trace = list_new(SYSTEM_HEAP, sizeof(event_t), NULL);

  stacks[0] = red_stack;
  stacks[1] = blue_stack;
  for(i = 0; i < 2; i ++) {
    stack = stacks[i];
    if(stack) {
      dfs_stack_pop(stack);
      while(stack->size > 0) {
        item = stack->blocks[stack->current]->items[stack->top];
        if(item.e_set) {
          e = event_copy(item.e);
          list_append(trace, &e);
        }
        dfs_stack_pop(stack);
      }
    }
  }
  context_set_trace(trace);
}

#endif  /*  defined(CFG_ALGO_DFS) || defined(CFG_ALGO_DDFS)  */
