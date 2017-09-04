#ifndef LIB_COMMON
#define LIB_COMMON

#include "includes.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

void init_common
();
void free_common
();

int crc32_tab[256];

char * glob_error_msg;

typedef char termination_state_t;
#define SUCCESS             0
#define ERROR               1
#define INTERRUPTION        2
#define SEARCH_TERMINATED   3
#define NO_ERROR            4
#define MEMORY_EXHAUSTED    5
#define TIME_ELAPSED        6
#define STATE_LIMIT_REACHED 7
#define FAILURE             8

typedef unsigned short state_sizeof_t;

typedef char * bit_vector_t;

typedef uint32_t hash_key_t;

typedef uint32_t state_num_t;

typedef uint8_t worker_id_t;

typedef int32_t priority_t;

typedef uint8_t bool_t;
#define FALSE 0
#define TRUE  1

typedef uint8_t order_t; 
#define LESS    1
#define EQUAL   2
#define GREATER 3

typedef uint32_t rseed_t;

rseed_t random_seed(worker_id_t w);

rseed_t random_int(rseed_t * seed);

typedef struct {
  struct timeval start;
  uint64_t value;
} lna_timer_t;

void lna_timer_init
(lna_timer_t * t);

void lna_timer_start
(lna_timer_t * t);

void lna_timer_stop
(lna_timer_t * t);

uint64_t lna_timer_value
(lna_timer_t t);

uint64_t duration
(struct timeval t0,
 struct timeval t1);

hash_key_t bit_vector_hash
(bit_vector_t v,
 unsigned int len);

#define MALLOC(ptr, ptr_type, size) {				\
    if(!((ptr) = (ptr_type) malloc(size))) {			\
      stop_search(MEMORY_EXHAUSTED);				\
    }								\
  }

#define fatal_error(msg) {						\
    printf("file       : %s\n", __FILE__);				\
    printf("line       : %d\n", __LINE__);				\
    printf("fatal error: %s\n", msg);					\
    printf("please send a mail with a file that caused this bug to\n"); \
    printf("      sami.evangelista@lipn.univ-paris13.fr\n");		\
    exit(EXIT_FAILURE);						\
  }

bool_t raise_error
(char * msg);

void flush_error
();

void stop_search
(termination_state_t state);

FILE * open_graph_file
();

uint64_t do_large_sum
(uint64_t * array,
 unsigned int nb);

uint32_t worker_global_id
(worker_id_t w);

#define CAS(val, old, new) (__sync_bool_compare_and_swap((val), (old), (new)))

#endif
