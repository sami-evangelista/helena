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
  bool_t father;
  bool_t dd;
  bool_t dd_visit;
  bool_t recons[2];
  event_id_t e;
#ifdef ACTION_BUILD_RG
  uint32_t num;
#endif
} pd4_state_t;

typedef struct {
  unsigned char content;
  pd4_storage_id_t id;
  pd4_storage_id_t pred;
  event_id_t e;
  bit_vector_t s;
  hash_key_t h;
  uint16_t width;
} pd4_candidate_t;

typedef struct {
  pd4_storage_id_t root;
  pd4_state_t ST[HASH_SIZE];
  int32_t size[NO_WORKERS];
  uint64_t dd_time;
  uint64_t barrier_time[NO_WORKERS];
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

uint64_t pd4_storage_size
(pd4_storage_t storage);

void pd4_storage_output_stats
(pd4_storage_t storage,
 FILE * out);

#endif
