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
 * @typedef hkey_t
 * @brief a hash value
 */
typedef uint64_t hkey_t;


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
typedef uint64_t rseed_t;


/**
 * @typedef order_t
 * @brief an order value
 */
typedef enum { 
  LESS,
  EQUAL,
  GREATER
} order_t;


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
uint64_t random_int
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
 * @brief Get the duration in nano-seconds between two time values.
 */
uint64_t duration
(struct timeval t0,
 struct timeval t1);


/**
 * @brief Return a hash value for string v of length len.
 */
hkey_t string_hash
(char * v,
 unsigned int len);


/**
 * @brief Parametrised version of string_hash.
 */
hkey_t string_hash_init
(char * v,
 unsigned int len,
 hkey_t init);


/**
 * @brief Return CPU usage of the current process as a %.
 */
float cpu_usage
(unsigned long * total,
 unsigned long * utime,
 unsigned long * stime);

#endif
