/**
 * @file bwalk.h
 * @brief Implementation of BWALK (bitstate walk) algorithm.
 * @date 1 dec 2017
 * @author Sami Evangelista
 *
 * TODO
 *
 * - the implementaton assumes that 1 char = 8 bits, but we should use
 *   1 char = CHAR_BIT instead
 */

#ifndef LIB_BWALK
#define LIB_BWALK

#include "includes.h"
#include "common.h"
#include "state.h"

typedef bool_t (* state_hook_t) (state_t, void *);

typedef struct struct_bwalk_data_t * bwalk_data_t;

/**
 * @brief Launch the bitstate walk algorithm.
 */
void bwalk
();


/**
 * @brief bwalk_data_init
 */
bwalk_data_t bwalk_data_init
(uint32_t hash_bits);


/**
 * @brief bwalk_data_init
 */
void bwalk_data_free
(bwalk_data_t data);


/**
 * @brief bwalk_generic
 */
void bwalk_generic
(worker_id_t w,
 state_t s,
 bwalk_data_t data,
 uint32_t iterations,
 bool_t update_stats,
 state_hook_t hook,
 void * hook_data);

#endif
