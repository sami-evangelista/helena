#ifndef LIB_PD4
#define LIB_PD4

#include "includes.h"
#include "common.h"
#include "state.h"
#include "event.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

void init_pd4_storage ();
void free_pd4_storage ();

typedef uint32_t pd4_storage_id_t;

typedef struct {
  pd4_storage_id_t fst_child;
  pd4_storage_id_t next;
  bool_t           father;
  bool_t           dd;
  bool_t           dd_visit;
  bool_t           recons[2];
  event_id_t       e;
#ifdef BUILD_RG
  uint32_t         num;
#endif
} pd4_state_t;

typedef struct {
  unsigned char    content;
  pd4_storage_id_t id;
  pd4_storage_id_t pred;
  event_id_t       e;
  bit_vector_t     s;
  hash_key_t       h;
  uint16_t         width;
} pd4_candidate_t;

typedef struct {
  pd4_storage_id_t root;
  pd4_state_t      ST[HASH_SIZE];
  int32_t          size[NO_WORKERS];
  large_unsigned_t dd_time;
  large_unsigned_t barrier_time[NO_WORKERS];
} struct_pd4_storage_t;

typedef struct_pd4_storage_t * pd4_storage_t;

uint32_t pd4_storage_id_char_width;

#include "report.h"

void pd4
(report_t r);

pd4_storage_t pd4_storage_new
();

void pd4_storage_free
(pd4_storage_t storage);

large_unsigned_t pd4_storage_size
(pd4_storage_t storage);

void pd4_storage_output_stats
(pd4_storage_t storage,
 FILE *        out);

void pd4_storage_id_serialise
(pd4_storage_id_t id,
 bit_vector_t     v);

pd4_storage_id_t pd4_storage_id_unserialise
(bit_vector_t v);

void pd4_storage_insert
(pd4_storage_t      storage,
 state_t            s,
 pd4_storage_id_t * pred,
 event_id_t *       exec,
 uint32_t           depth,
 worker_id_t        w,
 bool_t *           is_new,
 pd4_storage_id_t * id);

void pd4_storage_remove
(pd4_storage_t    storage,
 pd4_storage_id_t id);

order_t pd4_storage_id_cmp
(pd4_storage_id_t id1,
 pd4_storage_id_t id2);

state_t pd4_storage_get
(pd4_storage_t    storage,
 pd4_storage_id_t ptr,
 worker_id_t      w);

state_t pd4_storage_get_mem
(pd4_storage_t    storage,
 pd4_storage_id_t ptr,
 worker_id_t      w,
 heap_t           heap);

void pd4_storage_set_in_unproc
(pd4_storage_t    storage,
 pd4_storage_id_t id,
 bool_t           in_unproc);

bool_t pd4_storage_get_in_unproc
(pd4_storage_t    storage,
 pd4_storage_id_t id);

state_num_t pd4_storage_get_num
(pd4_storage_t    storage,
 pd4_storage_id_t id);

void pd4_storage_update_refs
(pd4_storage_t    storage,
 pd4_storage_id_t id,
 int              update);

void pd4_storage_set_is_red
(pd4_storage_t    storage,
 pd4_storage_id_t id);

#endif
