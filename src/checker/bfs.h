/**
 * @file bfs.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Implementation of BFS based algorithms: BFS, DBFS (distributed BFS)
 *        and FRONTIER (BFS that only stores states of the current and next
 *        BFS levels)
 */

#ifndef LIB_BFS
#define LIB_BFS

#include "includes.h"
#include "report.h"
#include "state.h"
#include "event.h"
#include "storage.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

void bfs
(report_t r);

#endif
