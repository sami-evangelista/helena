/**
 * @file observer.h
 * @brief Implementation of an observer thread that periodically prints some
 *        statistics during the search.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_OBSERVER
#define LIB_OBSERVER

#include "includes.h"


/**
 * @brief Launches the observer thread.
 * @param arg - ignored
 * @return always NULL
 */
void * observer_start
(void * arg);

#endif
