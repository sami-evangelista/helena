/**
 * @file compression.h
 * @brief State compression.
 * @date 15 dec 2017
 * @author Sami Evangelista
 */

#ifndef LIB_COMPRESSION
#define LIB_COMPRESSION

#include "model.h"
#include "heap.h"


/**
 * @brief init_compression
 */
void init_compression
();


/**
 * @brief finalise_compression
 */
void finalise_compression
();


/**
 * @brief mstate_compress
 */
void mstate_compress
(mstate_t s,
 char * v,
 uint16_t * size);


/**
 * @brief mstate_uncompress
 */
void * mstate_uncompress
(char * v,
 heap_t heap);


/**
 * @brief mstate_compressed_char_size
 */
uint16_t mstate_compressed_char_size
();

#endif
