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

void init_delta_ddd_storage
();
void free_delta_ddd_storage
();

typedef uint32_t delta_ddd_storage_id_t;

typedef struct struct_delta_ddd_storage_t * delta_ddd_storage_t;

#include "report.h"

void delta_ddd
(report_t r);

delta_ddd_storage_t delta_ddd_storage_new
();

void delta_ddd_storage_free
(delta_ddd_storage_t storage);

uint64_t delta_ddd_storage_size
(delta_ddd_storage_t storage);

uint64_t delta_ddd_storage_barrier_time
(delta_ddd_storage_t storage);

uint64_t delta_ddd_storage_dd_time
(delta_ddd_storage_t storage);

void delta_ddd_storage_output_stats
(delta_ddd_storage_t storage,
 FILE * out);

#endif
