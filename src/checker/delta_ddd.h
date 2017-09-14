/**
 * @file delta_ddd.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Implementation of the delta DDD algorithm.
 */

#ifndef LIB_DELTA_DDD
#define LIB_DELTA_DDD

#include "includes.h"
#include "common.h"
#include "state.h"
#include "event.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

void init_delta_ddd_storage ();
void free_delta_ddd_storage ();

typedef uint32_t delta_ddd_storage_id_t;

typedef struct {
  delta_ddd_storage_id_t fst_child;
  delta_ddd_storage_id_t next;
  bool_t father;
  bool_t dd;
  bool_t dd_visit;
  bool_t recons[2];
  event_id_t e;
#if defined(CFG_ACTION_BUILD_RG)
  uint32_t num;
#endif
} delta_ddd_state_t;

typedef struct {
  unsigned char content;
  delta_ddd_storage_id_t id;
  delta_ddd_storage_id_t pred;
  event_id_t e;
  bit_vector_t s;
  hash_key_t h;
  uint16_t width;
} delta_ddd_candidate_t;

typedef struct {
  delta_ddd_storage_id_t root;
  delta_ddd_state_t ST[CFG_HASH_SIZE];
  int32_t size[CFG_NO_WORKERS];
  uint64_t dd_time;
  uint64_t barrier_time[CFG_NO_WORKERS];
} struct_delta_ddd_storage_t;

typedef struct_delta_ddd_storage_t * delta_ddd_storage_t;

#include "report.h"

void delta_ddd
(report_t r);

delta_ddd_storage_t delta_ddd_storage_new
();

void delta_ddd_storage_free
(delta_ddd_storage_t storage);

uint64_t delta_ddd_storage_size
(delta_ddd_storage_t storage);

void delta_ddd_storage_output_stats
(delta_ddd_storage_t storage,
 FILE * out);

#endif
