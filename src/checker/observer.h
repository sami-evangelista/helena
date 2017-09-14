/**
 * @file observer.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Implementation of an observer thread that periodically prints some
 *        statistics during the search.
 */

#ifndef LIB_OBSERVER
#define LIB_OBSERVER

#include "report.h"
#include "storage.h"

#ifndef CFG_MODEL_CONFIG
#error Model configuration missing!
#endif

void * observer_start (void * arg);

#endif
