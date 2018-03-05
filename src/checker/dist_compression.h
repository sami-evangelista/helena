/**
 * @file dist_compression.h
 * @brief Implementation of the distributed collapsed compression.
 * @date 28 feb 2018
 * @author Sami Evangelista
 */

#ifndef LIB_DIST_COMPRESSION
#define LIB_DIST_COMPRESSION

#include "includes.h"
#include "model.h"


/**
 * @brief init_dist_compression
 */
void init_dist_compression
();


/**
 * @brief finalise_dist_compression
 */
void finalise_dist_compression
();


/**
 * @brief mstate_dist_compress
 */
void mstate_dist_compress
(mstate_t s,
 char * v,
 uint16_t * size);


/**
 * @brief mstate_dist_uncompress
 */
void * mstate_dist_uncompress
(char * v,
 heap_t heap);


/**
 * @brief mstate_dist_compressed_char_size
 */
uint16_t mstate_dist_compressed_char_size
();

#endif
