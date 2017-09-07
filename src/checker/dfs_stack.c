#include "dfs_stack.h"
#include "model.h"

#if defined(CFG_ALGO_DFS) || defined(CFG_ALGO_DDFS)

void dfs_stack_slot_free
(dfs_stack_slot_t slot) {
  free(slot);
}

dfs_stack_slot_t dfs_stack_slot_new
() {
  dfs_stack_slot_t result;

  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_dfs_stack_slot_t));
  return result;
}

dfs_stack_t dfs_stack_new
(int id) {
  dfs_stack_t result;
  int i;
  char name[100];

  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_dfs_stack_t));
  result->id = id;
  result->top = - 1;
  result->size = 0;
  result->current = 0;
  result->files = 0;
  result->seed = random_seed(id);
  for(i = 0; i < DFS_STACK_SLOTS; i ++) {
    sprintf(name, "DFS stack heap");
    result->heaps[i] = bounded_heap_new(name, DFS_STACK_SLOT_SIZE * 1024);
    result->slots[i] = dfs_stack_slot_new();
  }
  return result;
}

void dfs_stack_free
(dfs_stack_t stack) {
  int i;

  if(stack) {
    for(i = 0; i < DFS_STACK_SLOTS; i ++) {
      if(stack->slots[i]) {
	dfs_stack_slot_free(stack->slots[i]);
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
  int i;
  unsigned int w;
  FILE * f;
  char buffer[10000];
  dfs_stack_slot_t slot = stack->slots[0];
    
  sprintf(buffer, "STACK-%d-%d", stack->id, stack->files);
  f = fopen(buffer, "w");
  for(i = 0; i < DFS_STACK_SLOT_SIZE; i ++) {
    w = event_set_char_width(slot->items[i].en);
    fwrite(&(slot->items[i].n), sizeof(unsigned char), 1, f);
    event_set_serialise(slot->items[i].en, buffer);
    event_set_free(slot->items[i].en);
    fwrite(&w, sizeof(unsigned int), 1, f);
    fwrite(buffer, w, 1, f);
    storage_id_serialise(slot->items[i].id, buffer);
    fwrite(buffer, storage_id_char_width, 1, f);
#if defined(CFG_PARALLEL) || defined(CFG_DISTRIBUTED)
      fwrite(slot->items[i].shuffle, sizeof(unsigned int),
             event_set_size(slot->items[i].en), f);
#endif
#if defined(CFG_POR) && defined(CFG_PROVISO)
    fwrite(&slot->items[i].prov_ok, sizeof(bool_t), 1, f);
    fwrite(&slot->items[i].fully_expanded, sizeof(bool_t), 1, f);
#endif
  }
  fclose(f);
  stack->files ++;
}

void dfs_stack_read
(dfs_stack_t stack) {
  int i;
  unsigned int w, en_size;
  FILE * f;
  char buffer[10000], name[20];
  dfs_stack_item_t item;
  
  stack->files --;
  sprintf(name, "STACK-%d-%d", stack->id, stack->files);
  f = fopen(name, "r");
  heap_reset(stack->heaps[0]);
  for(i = 0; i < DFS_STACK_SLOT_SIZE; i ++) {
    fread(&item.n, sizeof(unsigned char), 1, f);
    fread(&w, sizeof(unsigned int), 1, f);
    fread(buffer, w, 1, f);
    item.heap_pos = heap_get_position(stack->heaps[0]);
    item.en = event_set_unserialise_mem(buffer, stack->heaps[0]);
    fread(buffer, storage_id_char_width, 1, f);
    item.id = storage_id_unserialise(buffer);
#if defined(CFG_PARALLEL) || defined(CFG_DISTRIBUTED)
    en_size = event_set_size(item.en);
    item.shuffle = mem_alloc(stack->heaps[stack->current],
                             sizeof(unsigned int) * en_size);
    fread(item.shuffle, sizeof(unsigned int), en_size, f);
#endif
#if defined(CFG_POR) && defined(CFG_PROVISO)
    fread(&item.prov_ok, sizeof(bool_t), 1, f);
    fread(&item.fully_expanded, sizeof(bool_t), 1, f);
#endif
    stack->slots[0]->items[i] = item;
  }
  fclose(f);
  remove(name);
}

void dfs_stack_push
(dfs_stack_t stack,
 storage_id_t sid) {
  dfs_stack_item_t item;
  
  item.id = sid;
  item.en = NULL;
  stack->top ++;
  stack->size ++;
  if(stack->top == DFS_STACK_SLOT_SIZE) {
    if(stack->current == 1) {
      char name[100];
      dfs_stack_write(stack);
      dfs_stack_slot_free(stack->slots[0]);
      stack->slots[0] = stack->slots[1];
      stack->slots[1] = dfs_stack_slot_new();
      heap_free(stack->heaps[0]);
      stack->heaps[0] = stack->heaps[1];
      sprintf(name, "DFS stack heap");
      stack->heaps[1] = bounded_heap_new(name, DFS_STACK_SLOT_SIZE * 1024);
    }
    stack->current = 1;
    stack->top = 0;
  }
  stack->slots[stack->current]->items[stack->top] = item;
}

void dfs_stack_pop
(dfs_stack_t stack) {
  if(stack->size == 0) {
    fatal_error("dfs_stack_pop: empty stack");
  }
  heap_set_position(stack->heaps[stack->current],
                    stack->slots[stack->current]->items[stack->top].heap_pos);
  event_set_free(stack->slots[stack->current]->items[stack->top].en);
  stack->top --;
  stack->size --;
  if(stack->size > 0 && stack->top == -1) {
    if(stack->current == 0) {
      if(stack->files <= 0) {
	fatal_error("dfs_stack_read: no file to read from");
      }
      dfs_stack_read(stack);
    }
    stack->current = 0;
    stack->top = DFS_STACK_SLOT_SIZE - 1;
  }
}

storage_id_t dfs_stack_top
(dfs_stack_t stack) {
  if(stack->size == 0) {
    fatal_error("dfs_stack_top: empty stack");
  }
  return stack->slots[stack->current]->items[stack->top].id;
}

event_set_t dfs_stack_top_events
(dfs_stack_t stack) {
  if(stack->size == 0) {
    fatal_error("dfs_stack_top: empty stack");
  }
  return stack->slots[stack->current]->items[stack->top].en;
}

event_set_t dfs_stack_compute_events
(dfs_stack_t stack,
 state_t s,
 bool_t filter) {
  heap_t h = stack->heaps[stack->current];
  int i;
  event_set_t result;
  unsigned int en_size, en_size_reduced;
  dfs_stack_item_t item = stack->slots[stack->current]->items[stack->top];

  if(stack->size == 0) {
    fatal_error("dfs_stack_compute_events: empty stack");
  }
  if(item.en) {
    event_set_free(item.en);
  }
  item.n = 0;
  item.heap_pos = heap_get_position(h);
  result = state_enabled_events_mem(s, h);

  /*  compute a stubborn set if POR is activated  */
#if defined(CFG_POR)
  if(filter) {
    en_size = event_set_size(result);
    state_stubborn_set(s, result);
#if defined(CFG_PROVISO)
    item.prov_ok = TRUE;
    item.fully_expanded = (en_size == event_set_size(result)) ?
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

  /*  shuffle enabled events in parallel or distributed mode  */
#if defined(CFG_PARALLEL) || defined(CFG_DISTRIBUTED)
  en_size = event_set_size(result);
  {
    unsigned int num[en_size];
    uint32_t rnd;
    for(i = 0; i < en_size; i ++) {
      num[i] = i;
    }
    item.shuffle = mem_alloc(stack->heaps[stack->current],
                             sizeof(unsigned int) * en_size);
    for(i = 0; i < en_size; i ++) {
      rnd = random_int(&stack->seed) % (en_size - i);
      item.shuffle[i] = num[rnd];
      num[rnd] = num[en_size - i - 1];
    }
  }
#endif

  stack->slots[stack->current]->items[stack->top] = item;
  return result;
}

void dfs_stack_pick_event
(dfs_stack_t stack,
 event_t * e,
 event_id_t * eid) {
  dfs_stack_item_t item = stack->slots[stack->current]->items[stack->top];
  int chosen;
#if defined(CFG_PARALLEL) || defined(CFG_DISTRIBUTED)
  chosen = item.shuffle[item.n];
#else
  chosen = item.n;
#endif
  (*e) = event_set_nth(item.en, chosen);
  (*eid) = event_set_nth_id(item.en, chosen);
  item.n ++;
  stack->slots[stack->current]->items[stack->top] = item;
}

void dfs_stack_event_undo
(dfs_stack_t stack,
 state_t s) {
  dfs_stack_item_t item = stack->slots[stack->current]->items[stack->top];
  unsigned int n;
#if defined(CFG_PARALLEL) || defined(CFG_DISTRIBUTED)
  n = item.shuffle[item.n - 1];
#else
  n = item.n - 1;
#endif
  event_undo(event_set_nth(item.en, n), s);
}

void dfs_stack_unset_proviso
(dfs_stack_t stack) {
#if defined(CFG_POR) && defined(CFG_PROVISO)
  stack->slots[stack->current]->items[stack->top].prov_ok = FALSE;
#endif
}

bool_t dfs_stack_top_expanded
(dfs_stack_t stack) {
  dfs_stack_item_t item = stack->slots[stack->current]->items[stack->top];
  return (item.n == event_set_size(item.en)) ? TRUE : FALSE;
} 

bool_t dfs_stack_proviso
(dfs_stack_t stack) {
  bool_t result = TRUE;
  dfs_stack_item_t item;
  
#if defined(CFG_POR) && defined(CFG_PROVISO)
  item = stack->slots[stack->current]->items[stack->top];
  result = item.prov_ok || item.fully_expanded;
#endif
  return result;
}

void dfs_stack_create_trace
(dfs_stack_t blue_stack,
 dfs_stack_t red_stack,
 report_t r) {
  int now;
  dfs_stack_t stack, stacks[2];
  dfs_stack_item_t item;
  int i;
  unsigned int n;

  stacks[0] = red_stack;
  stacks[1] = blue_stack;
  r->trace_len = blue_stack->size - 1;
  if(red_stack) {
    r->trace_len += red_stack->size - 1;
  }
  r->trace = mem_alloc(SYSTEM_HEAP, sizeof(event_t) * r->trace_len);
  now = r->trace_len - 1;

  for(i = 0; i < 2; i ++) {
    stack = stacks[i];
    if(stack) {
      dfs_stack_pop(stack);
      while(stack->size > 0) {
        item = stack->slots[stack->current]->items[stack->top];
#if defined(CFG_PARALLEL) || defined(CFG_DISTRIBUTED)
        n = item.shuffle[item.n - 1];
#else
        n = item.n - 1;
#endif
        r->trace[now --] = event_copy(event_set_nth(item.en, n));
        dfs_stack_pop(stack);
      }
    }
  }
}

#endif  /*  defined(CFG_ALGO_DFS) || defined(CFG_ALGO_DDFS)  */
