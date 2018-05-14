/**
 * @file debug.h
 * @brief Debugging routines.
 * @date 23 feb 2018
 * @author Sami Evangelista
 */

#ifndef LIB_DEBUG
#define LIB_DEBUG

#include "config.h"
#include "comm.h"

#if CFG_DEBUG == 1
#define debug(...)   {					\
    printf("[");					\
    if(CFG_DISTRIBUTED) {				\
      printf("pe=%d,pid=%d,", comm_me(), getpid());	\
    }							\
    printf("%s:%d] ", __FILE__, __LINE__);		\
    printf(__VA_ARGS__);				\
  }
#else
#define debug(...) {}
#endif

#endif
