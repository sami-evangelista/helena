/**
 * @file bfs.h
 * @brief Implementation of BFS based algorithms: BFS, DBFS (distributed BFS)
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_BFS
#define LIB_BFS

#include "includes.h"
#include "context.h"
#include "state.h"
#include "event.h"


/**
 * @brief Launch the BFS based algorithm.
 */
void bfs
();


/**
 * @brief Report on the BFS progress.
 */
void bfs_progress_report
(uint64_t * states_stored);


/**
 * @brief Finalisation of the BFS.  Used to free data allocated by
 *        bfs.
 */
void bfs_finalise
();

#endif
