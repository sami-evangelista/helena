/**
 * @file random_walk.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Implementation of RWALK (random walk) algorithm.
 */

#ifndef LIB_RANDOM_WALK
#define LIB_RANDOM_WALK

#include "includes.h"
#include "report.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

void random_walk
(report_t r);

#endif
