/**
 * @file stbl.h
 * @brief Implementation of a state table.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_STBL
#define LIB_STBL

#include "state.h"
#include "event.h"
#include "heap.h"
#include "config.h"
#include "htbl.h"


/**
 * @brief stbl_default_new
 */
htbl_t stbl_default_new
();

/**
 * @brief stbl_get_trace
 */
list_t stbl_get_trace
(htbl_t tbl,
 htbl_id_t id);

#endif
