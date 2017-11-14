/**
 * @file rwalk.h
 * @brief Implementation of RWALK (random walk) algorithm.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_RWALK
#define LIB_RWALK

#include "includes.h"

/**
 * @brief Launch the random walk algorithm.
 */
void rwalk
();


/**
 * @brief Report on the RWALK progress.
 */
void rwalk_progress_report
(uint64_t * states_stored);


/**
 * @brief Finalisation of the RWALK.  Used to free data allocated by
 *        rwalk.
 */
void rwalk_finalise
();

#endif
