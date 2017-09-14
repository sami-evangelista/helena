/**
 * @file dfs.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Implementation of DFS based algorithms: DFS, DDFS (distributed DFS).
 *        Nested DFS algorithms for LTL verification (sequential or multi-core)
 *        are also implemented here.
 */

#ifndef LIB_DFS
#define LIB_DFS

#include "includes.h"
#include "report.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

void dfs
(report_t r);

#endif
