/**
 * @file dfs.h
 * @brief Implementation of DFS based algorithms: DFS, DDFS (distributed DFS).
 *        Nested DFS algorithms for LTL verification (sequential or multi-core)
 *        are also implemented here.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_DFS
#define LIB_DFS

#include "includes.h"
#include "context.h"


/**
 * @brief Launch the DFS based algorithm.
 */
void dfs
();


/**
 * @brief Report on the DFS progress.
 */
void dfs_progress_report
(uint64_t * states_stored);


/**
 * @brief Finalisation of the DFS.  Used to free data allocated by
 *        dfs.
 */
void dfs_finalise
();

#endif
