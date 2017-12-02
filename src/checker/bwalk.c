#include "bwalk.h"
#include "context.h"
#include "common.h"
#include "dfs_stack.h"
#include "htbl.h"
#include "workers.h"

#define MAX_ITERATION   1000
#define KEYS_BLOCK_SIZE 65536

void bwalk_key_file_name
(worker_id_t w,
 char * file_name) {
  const uint32_t wid = context_global_worker_id(w);
  
  sprintf(file_name, "keys-%d.dat", wid);
}

void bwalk_sort_keys_aux
(hash_key_t * harray,
 uint32_t lo,
 uint32_t hi) {
  uint32_t middle, i, ihi, ilo;

  if(lo != hi) {
    middle = lo + (hi - lo) / 2;
    bwalk_sort_keys_aux(harray, lo, middle);
    bwalk_sort_keys_aux(harray, middle + 1, hi);
    {
      bool_t lo_done = FALSE, hi_done = FALSE;
      hash_key_t result[hi - lo + 1];
      
      for(i = 0, ilo = lo, ihi = middle + 1; !lo_done || !hi_done; i ++) {
        if(lo_done || (!hi_done && harray[ihi] <= harray[ilo])) {
          result[i] = harray[ihi ++];
          if(ihi > hi) {
            hi_done = TRUE;
          }
        } else {
          result[i] = harray[ilo ++];
          if(ilo > middle) {
            lo_done = TRUE;
          }
        }
      }        
      memcpy(&harray[lo], result, sizeof(hash_key_t) * (hi - lo + 1));
    }
  }
}

void bwalk_sort_keys
(hash_key_t * harray,
 uint32_t no) {
  uint32_t i;
  
  bwalk_sort_keys_aux(harray, 0, no - 1);
  for(i = 1; i < no; i ++) {
    assert(harray[i - 1] <= harray[i]);
  }
}

void bwalk_load_keys
(FILE * f,
 hash_key_t * harray,
 uint32_t * read) {
  uint32_t i, n = 0;
  hash_key_t h;
  
  for(i = 0; i < KEYS_BLOCK_SIZE; i ++) {
    if(!fread(&h, sizeof(hash_key_t), 1, f)) {
      break;      
    } else {
      harray[n ++] = h;
    }
  }
  (*read) = n;
}

void bwalk_unload_keys
(FILE * f,
 hash_key_t * harray,
 uint32_t no) {
  uint32_t i;

  for(i = 0; i < no; i ++) {
    if(i == 0 || harray[i] != harray[i - 1]) {
      fwrite(&harray[i], sizeof(hash_key_t), 1, f);
    }
  }
}

uint32_t bwalk_split_key_file
() {
  FILE * f, * out;
  uint32_t read = 0;
  hash_key_t harray[KEYS_BLOCK_SIZE];
  uint32_t result = 0;
  char file_name[20];
  
  if(f = fopen("keys.dat", "r")) {
    do {
      bwalk_load_keys(f, harray, &read);
      if(read) {
        bwalk_sort_keys(harray, read);
        sprintf(file_name, "keys-%d.dat", result);
        out = fopen(file_name, "w");
        bwalk_unload_keys(out, harray, read);
        fclose(out);
        result ++;
      }
    } while(read > 0);
    fclose(f);
  }
  return result;
}

void bwalk_merge_two_sorted_key_files
(uint32_t id1,
 uint32_t id2) {
  uint32_t imin, i, no[2], idx[2] = { 0, 0 }, id[2] = { id1, id2 };
  FILE * in[2], * out;
  char name[2][20];
  bool_t min_set, loop = TRUE, empty[2] = { FALSE, FALSE };
  hash_key_t prev, min, harray[2][KEYS_BLOCK_SIZE];

  /* open files */
  for(i = 0; i < 2; i ++) {
    sprintf(name[i], "keys-%d.dat", id[i]);
    in[i] = fopen(name[i], "r");
  }
  out = fopen("keys.tmp.dat", "w");

  /*  read first block of keys from files */
  for(i = 0; i < 2; i ++) {
    bwalk_load_keys(in[i], harray[i], &no[i]);
  }

  while(loop) {

    min_set = FALSE;
    for(i = 0; i < 2; i ++) {
      if(idx[i] < no[i] && (!min_set || harray[i][idx[i]] < harray[imin][idx[imin]])) {
        imin = i;
        min_set = TRUE;
        printf("ok\n");
      }
    }
    assert(min_set);
    fwrite(&harray[imin][idx[imin]], sizeof(hash_key_t), 1, out);
    idx[imin] ++;
    /* reload the file */
  }
  
  /* close files */
  fclose(out);
}

void bwalk_merge_sorted_key_files
(uint32_t no_files) {
  uint32_t inc = 2, remaining = no_files, i;

  while(remaining != 1) {
    for(i = 0; i < no_files; i += inc) {
      if(i + (inc / 2) < no_files) {
        remaining --;
        bwalk_merge_two_sorted_key_files(i, i + (inc / 2));
      }
    }
    inc *= 2;
  }
}

void bwalk_merge_key_files
() {
  worker_id_t w;
  char file_name[20];
  FILE * f, * out;
  hash_key_t h;

  if(out = fopen("keys.dat", "w")) {
    for(w = 0; w < context_no_workers(); w ++) {
      bwalk_key_file_name(w, file_name);
      if(f = fopen(file_name, "r")) {
        while(fread(&h, sizeof(hash_key_t), 1, f)) {
          fwrite(&h, sizeof(hash_key_t), 1, out);
        }
        fclose(f);
      }
    }
    fclose(out);
  }
}

void bwalk_key_files_analysis
() {
  uint32_t no_files;
  
  bwalk_merge_key_files();
  no_files = bwalk_split_key_file();
  bwalk_merge_sorted_key_files(no_files);
}


#if defined(MODEL_EVENT_UNDOABLE)
#define bwalk_recover_state() {                 \
    dfs_stack_event_undo(stack, now);           \
  }
#else
#define bwalk_recover_state() {                 \
    now = dfs_stack_top_state(stack, heap);     \
  }
#endif

#define bwalk_insert_state() {                                  \
    h = state_hash(now);                                        \
    htbl_insert_hashed(htbl, now, h ^ rnd, &is_new, &id);       \
  }

#define bwalk_initiate_walk() {                                 \
    stack = dfs_stack_new(wid, CFG_DFS_STACK_BLOCK_SIZE,        \
                          TRUE, states_stored);                 \
    htbl_reset(htbl);                                           \
    heap_reset(heap);                                           \
    rnd = random_int(&rseed);                                   \
    now = state_initial_mem(heap);                              \
    context_set_stat(STAT_STATES_STORED, w, 0);                 \
    bwalk_insert_state();                                       \
    bwalk_push();                                               \
  }

#define bwalk_push() {                                  \
    dfs_stack_push(stack, id, now);                     \
    dfs_stack_compute_events(stack, now, FALSE, NULL);  \
    context_incr_stat(STAT_STATES_STORED, w, 1);        \
    fwrite(&h, sizeof(hash_key_t), 1, out);             \
  }

void * bwalk_worker
(void * arg) {
  const worker_id_t w = (worker_id_t) (unsigned long int) arg;
  const uint32_t wid = context_global_worker_id(w);
  const bool_t states_stored = 
#if defined(MODEL_EVENT_UNDOABLE)
    FALSE
#else
    CFG_HASH_COMPACTION
#endif
    ;
  htbl_id_t id;
  dfs_stack_t stack;
  uint32_t i;
  uint64_t rnd;
  rseed_t rseed = random_seed(w);
  state_t now, copy;
  htbl_t htbl = htbl_default_new();  
  bool_t is_new;
  hash_key_t h;
  event_t e;
  char out_name[20];
  FILE * out;
  heap_t heap = local_heap_new();
    
  bwalk_key_file_name(w, out_name);
  out = fopen(out_name, "w");

  for(i = 0; i < MAX_ITERATION; i ++) {
    bwalk_initiate_walk();
    while(dfs_stack_size(stack) && context_keep_searching()) {
      if(heap_size(heap) >= 1000000) {
        copy = state_copy(now);
        heap_reset(heap);
        now = state_copy_mem(copy, heap);
        state_free(copy);
      }
      if(dfs_stack_top_expanded(stack)) {
        dfs_stack_pop(stack);
        if(dfs_stack_size(stack)) {
          bwalk_recover_state();
        }
        context_incr_stat(STAT_STATES_PROCESSED, w, 1);
      } else {
        dfs_stack_pick_event(stack, &e);
        event_exec(e, now);
        bwalk_insert_state();
        if(is_new) {
          bwalk_push();
        } else {
          bwalk_recover_state();
        }
      }
    }
    state_free(now);
    dfs_stack_free(stack);
  }
  htbl_free(htbl);
  heap_free(heap);
  fclose(out);
  return NULL;
}

void bwalk
() {
  launch_and_wait_workers(&bwalk_worker);
  bwalk_key_files_analysis();
}
