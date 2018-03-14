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

typedef void(* state_hook_t)(state_t, void *);


/**
 * @brief Launch the bitstate walk algorithm.
 */
void bwalk
();


/**
 * @brief bwalk_generic
 */
void bwalk_generic
(worker_id_t w,
 uint32_t hash_log,
 bool_t update_stats,
 uint32_t max_time_ms,
 state_hook_t hook,
 void * hook_data);

#endif
