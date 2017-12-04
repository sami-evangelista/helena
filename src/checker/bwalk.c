#include "bwalk.h"
#include "context.h"
#include "common.h"
#include "dfs_stack.h"
#include "htbl.h"
#include "workers.h"

#define BWALK_KEYS_BLOCK_SIZE 65536

void bwalk_key_file_name
(worker_id_t w,
 char * file_name) {
  const uint32_t wid = context_global_worker_id(w);
  
  sprintf(file_name, "keys-%d.dat", wid);
}

void bwalk_sort_keys_aux
(hkey_t * harray,
 uint32_t lo,
 uint32_t hi) {
  uint32_t middle, i, ihi, ilo;

  if(lo != hi) {
    middle = lo + (hi - lo) / 2;
    bwalk_sort_keys_aux(harray, lo, middle);
    bwalk_sort_keys_aux(harray, middle + 1, hi);
    {
      bool_t lo_done = FALSE, hi_done = FALSE;
      hkey_t result[hi - lo + 1];
      
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
      memcpy(&harray[lo], result, sizeof(hkey_t) * (hi - lo + 1));
    }
  }
}

void bwalk_sort_keys
(hkey_t * harray,
 uint32_t no) {
  uint32_t i;
  
  bwalk_sort_keys_aux(harray, 0, no - 1);
  for(i = 1; i < no; i ++) {
    assert(harray[i - 1] <= harray[i]);
  }
}

void bwalk_load_keys
(FILE * f,
 hkey_t * harray,
 uint32_t * read) {
  uint32_t i, n = 0;
  hkey_t h;
  
  for(i = 0; i < BWALK_KEYS_BLOCK_SIZE; i ++) {
    if(!fread(&h, sizeof(hkey_t), 1, f)) {
      break;      
    } else {
      harray[n ++] = h;
    }
  }
  (*read) = n;
}

void bwalk_unload_keys
(FILE * f,
 hkey_t * harray,
 uint32_t no) {
  uint32_t i;

  for(i = 0; i < no; i ++) {
    if(i == 0 || harray[i] != harray[i - 1]) {
      fwrite(&harray[i], sizeof(hkey_t), 1, f);
    }
  }
}

uint32_t bwalk_split_key_file
() {
  FILE * f, * out;
  uint32_t read = 0;
  hkey_t harray[BWALK_KEYS_BLOCK_SIZE];
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
    unlink("keys.dat");
  }
  return result;
}

void bwalk_merge_two_sorted_key_files
(uint32_t id1,
 uint32_t id2) {
  uint32_t imin, i, no[2], idx[2] = { 0, 0 }, id[2] = { id1, id2 };
  FILE * in[2], * out;
  char name[2][20];
  bool_t first = TRUE, min_set;
  hkey_t prev, harray[2][BWALK_KEYS_BLOCK_SIZE];

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

  while(no[0] + no[1] > 0) {

    if(no[0] > 0 && no[1] > 0) {
      if(harray[0][idx[0]] < harray[1][idx[1]]) {
	imin = 0;
      } else {
	imin = 1;
      }
    } else if(no[1] == 0) {
      imin = 0;
    } else {
      imin = 1;
    }
    if(first || prev != harray[imin][idx[imin]]) {
      fwrite(&harray[imin][idx[imin]], sizeof(hkey_t), 1, out);
      first = FALSE;
    }
    prev = harray[imin][idx[imin]];
    idx[imin] ++;
    
    /* read next items from the file we took the min element from */
    if(idx[imin] == no[imin]) {
      idx[imin] = 0;
      bwalk_load_keys(in[imin], harray[imin], &no[imin]);
      if(no[imin] == 0) {
	fclose(in[imin]);
      }
    }
  }
  
  /* close files */
  fclose(out);
  rename("keys.tmp.dat", name[0]);
  unlink(name[1]);
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
  rename("keys-0.dat", "keys.dat");
}

void bwalk_merge_key_files
() {
  worker_id_t w;
  char file_name[20];
  FILE * f, * out;
  hkey_t h;

  if(out = fopen("keys.dat", "w")) {
    for(w = 0; w < context_no_workers(); w ++) {
      bwalk_key_file_name(w, file_name);
      if(f = fopen(file_name, "r")) {
        while(fread(&h, sizeof(hkey_t), 1, f)) {
          fwrite(&h, sizeof(hkey_t), 1, out);
        }
        fclose(f);
      }
    }
    fclose(out);
  }
}

void bwalk_key_files_analysis
() {
  uint32_t no_files, keys;
  struct stat st;

  bwalk_merge_key_files();
  no_files = bwalk_split_key_file();
  bwalk_merge_sorted_key_files(no_files);
  stat("keys.dat", &st);
  keys = st.st_size / sizeof(hkey_t);
  unlink("keys.dat");
  context_set_stat(STAT_STATES_UNIQUE, 0, keys);
}


#if defined(MODEL_EVENT_UNDOABLE)
#define bwalk_recover_state() {                 \
    dfs_stack_event_undo(stack, now);		\
  }
#else
#define bwalk_recover_state() {                 \
    now = dfs_stack_top_state(stack, heap);     \
  }
#endif

#define bwalk_insert_now() {					\
    h = state_hash(now);                                        \
    htbl_insert_hashed(htbl, now, h ^ rnd, &is_new, &id);       \
  }

#define bwalk_push() {                                  \
    dfs_stack_push(stack, id, now);                     \
    dfs_stack_compute_events(stack, now, FALSE, NULL);  \
    context_incr_stat(STAT_STATES_STORED, w, 1);        \
    fwrite(&h, sizeof(hkey_t), 1, out);             \
  }

void * bwalk_worker
(void * arg) {
  const worker_id_t w = (worker_id_t) (unsigned long int) arg;
  const uint32_t wid = context_global_worker_id(w);
#if defined(MODEL_EVENT_UNDOABLE)
  const bool_t states_stored = FALSE;
#else
  const bool_t states_stored = TRUE;
#endif    
  htbl_id_t id;
  dfs_stack_t stack;
  uint64_t rnd;
  rseed_t rseed = random_seed(w);
  state_t now, copy;
  htbl_t htbl = htbl_default_new();  
  bool_t is_new;
  hkey_t h;
  event_t e;
  char out_name[20];
  FILE * out;
  heap_t heap = local_heap_new();
  hkey_t roots[1000000];
  uint32_t i, no_roots = 0;
    
  bwalk_key_file_name(w, out_name);
  out = fopen(out_name, "w");
  now = state_initial_mem(heap);

  while(context_keep_searching()) {

    stack = dfs_stack_new(wid, CFG_DFS_STACK_BLOCK_SIZE,        
                          TRUE, states_stored);
    h = roots[no_roots ++] = state_hash(now);
    copy = state_copy(now);
    heap_reset(heap);
    htbl_reset(htbl);
    now = state_copy_mem(copy, heap);
    //now = state_initial_mem(heap);
    state_free(copy);
    rnd = random_int(&rseed);
    for(i = 0; i < no_roots; i ++) {
      htbl_insert_hashed(htbl, now, roots[i] ^ rnd, &is_new, &id);
    }
    context_set_stat(STAT_STATES_STORED, w, i);
    bwalk_push();
  
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
        bwalk_insert_now();
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
