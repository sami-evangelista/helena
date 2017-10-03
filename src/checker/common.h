/**
 * @file common.h
 * @brief Some common declarations.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_COMMON
#define LIB_COMMON

#include "includes.h"


/**
 * @brief Initialise some data.
 */
void init_common
();


/**
 * @brief Free data initialised by init_common.
 */
void free_common
();


/**
 * @typedef termination_state_t
 * @brief possible termination states of helena
 */
typedef uint8_t termination_state_t;
#define SUCCESS             0
#define ERROR               1
#define INTERRUPTION        2
#define SEARCH_TERMINATED   3
#define NO_ERROR            4
#define MEMORY_EXHAUSTED    5
#define TIME_ELAPSED        6
#define STATE_LIMIT_REACHED 7
#define FAILURE             8


/**
 * @typedef bit_vector_t
 * @brief a bit vector
 */
typedef char * bit_vector_t;


/**
 * @typedef hash_key_t
 * @brief a hash value
 */
typedef uint32_t hash_key_t;


/**
 * @typedef worker_id_t
 * @brief identifier of a worker thread
 */
typedef uint8_t worker_id_t;


/**
 * @typedef bool_t
 * @brief a boolean value
 */
typedef uint8_t bool_t;
#define FALSE 0
#define TRUE  1


/**
 * @typedef rseed_t
 * @brief a seed to generate random numbers
 */
typedef uint32_t rseed_t;


/**
 * @typedef order_t
 * @brief an order value
 */
typedef uint8_t order_t; 
#define LESS    1
#define EQUAL   2
#define GREATER 3


/**
 * @struct lna_timer_t
 * @brief a timer used to measure time flow
 */
typedef struct {
  struct timeval start;
  uint64_t value;
} lna_timer_t;


/**
 * @brief atomic compare-and-swap
 */
#define CAS(val, old, new) (__sync_bool_compare_and_swap((val), (old), (new)))


/**
 * @brief Return a seed to generate random numbers.
 */
rseed_t random_seed
(worker_id_t w);


/**
 * @brief Return a random integer and update the seed.
 */
uint32_t random_int
(rseed_t * seed);


/**
 * @brief Initialise an helena timer.
 */
void lna_timer_init
(lna_timer_t * t);


/**
 * @brief Start the helena timer.
 */
void lna_timer_start
(lna_timer_t * t);


/**
 * @brief Stop the helena timer.
 */
void lna_timer_stop
(lna_timer_t * t);


/**
 * @brief Get the timer value, i.e., # of micro-seconds between the
 *        start and stop of the timer.
 */
uint64_t lna_timer_value
(lna_timer_t t);


/**
 * @brief Get the duration in micro-seconds between two time values.
 */
uint64_t duration
(struct timeval t0,
 struct timeval t1);


/**
 * @brief Return a hash value for vector v of length len.
 */
hash_key_t bit_vector_hash
(bit_vector_t v,
 unsigned int len);


/**
 * @brief Raise an error : stop the search and set the error message
 *        of the global context.
 */
bool_t raise_error
(char * msg);


/**
 * @brief Return the sum of the nb first elements of array.
 */
uint64_t large_sum
(uint64_t * array,
 unsigned int nb);


/**
 * @brief Return memory usage of the current process as a % of
 *        available memory.
 */
float mem_usage
();

#endif
