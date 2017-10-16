/**
 * @file bfs.h
 * @brief 
 * @date 16 oct 2017
 * @author Sami Evangelista
 */

#ifndef LIB_PAPI_STATS
#define LIB_PAPI_STATS


/**
 * @brief init_papi_stats
 */
void init_papi_stats
();


/**
 * @brief finalise_papi_stats
 */
void finalise_papi_stats
();


/**
 * @brief papi_stats_output
 */
void papi_stats_output
(FILE * f);

#endif
