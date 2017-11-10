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


/**
 * @brief delta_ddd
 */
void delta_ddd
();


/**
 * @brief Report on the delta-ddd search progress.
 */
void delta_ddd_progress_report
(uint64_t * states_stored);


/**
 * @brief Finalisation of the DELTA-DDD.  Used to free data allocated
 *        by delta_ddd.
 */
void delta_ddd_finalise
();

#endif
