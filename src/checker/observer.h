#ifndef LIB_OBSERVER
#define LIB_OBSERVER

#include "report.h"
#include "storage.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

void * observer_start (void * arg);

#endif
