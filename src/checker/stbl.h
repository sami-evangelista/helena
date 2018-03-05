/**
 * @file stbl.h
 * @brief Implementation of a state table.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_STBL
#define LIB_STBL

#include "list.h"
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


/**
 * @brief stbl_insert
 */
#define stbl_insert(tbl, meta, is_new) {				\
    htbl_insert_code_t ic;                                              \
    if(HTBL_INSERT_FULL == (ic = htbl_insert(tbl, &meta))) {		\
      context_error							\
	("state table too small (increase --hash-size and rerun)");	\
    }                                                                   \
    is_new = ic == HTBL_INSERT_OK;                                      \
  }

#endif
