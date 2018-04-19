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
 * @brief dist_compression_output_statistics
 */
void dist_compression_output_statistics
(FILE * f);


/**
 * @brief dist_compression_compress
 */
void dist_compression_compress
(mstate_t s,
 char * v,
 uint16_t * size);


/**
 * @brief dist_compression_uncompress
 */
void * dist_compression_uncompress
(char * v,
 heap_t heap);


/**
 * @brief dist_compression_char_size
 */
uint16_t dist_compression_char_size
();


/**
 * @brief dist_compression_training_run
 */
void dist_compression_training_run
();


/**
 *  @brief dist_compression_process_serialised_component
 */
void dist_compression_process_serialised_component
(char * data);

#endif
