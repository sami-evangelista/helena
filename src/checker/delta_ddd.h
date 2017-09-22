/**
 * @file delta_ddd.h
 * @brief Implementation of the delta DDD algorithm.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_DELTA_DDD
#define LIB_DELTA_DDD

#include "includes.h"
#include "common.h"
#include "state.h"
#include "event.h"

typedef uint32_t delta_ddd_storage_id_t;

typedef struct struct_delta_ddd_storage_t * delta_ddd_storage_t;


/**
 * @brief delta_ddd
 */
void delta_ddd
();


/**
 * @brief delta_ddd_storage_new
 */
delta_ddd_storage_t delta_ddd_storage_new
();


/**
 * @brief delta_ddd_storage_free
 */
void delta_ddd_storage_free
(delta_ddd_storage_t storage);


/**
 * @brief delta_ddd_storage_size
 */
uint64_t delta_ddd_storage_size
(delta_ddd_storage_t storage);


/**
 * @brief delta_ddd_storage_barrier_time
 */
uint64_t delta_ddd_storage_barrier_time
(delta_ddd_storage_t storage);


/**
 * @brief delta_ddd_storage_dd_time
 */
uint64_t delta_ddd_storage_dd_time
(delta_ddd_storage_t storage);


/**
 * @brief delta_ddd_storage_output_stats
 */
void delta_ddd_storage_output_stats
(delta_ddd_storage_t storage,
 FILE * out);

#endif
