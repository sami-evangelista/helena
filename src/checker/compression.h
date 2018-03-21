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
 * @brief compression_compress
 */
void compression_compress
(mstate_t s,
 char * v,
 uint16_t * size);


/**
 * @brief compression_uncompress
 */
void * compression_uncompress
(char * v,
 heap_t heap);


/**
 * @brief compression_char_size
 */
uint16_t compression_char_size
();


/**
 * @brief compression_output_statistics
 */
void compression_output_statistics
(FILE * f);

#endif
