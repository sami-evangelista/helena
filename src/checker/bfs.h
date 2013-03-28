#ifndef LIB_BFS
#define LIB_BFS

#include "includes.h"
#include "report.h"
#include "state.h"
#include "event.h"
#include "storage.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

typedef struct {
  storage_id_t s;
  unsigned int l;
#ifdef WITH_TRACE
  unsigned char * trace;
#endif
} bfs_queue_item_t;

void bfs
(report_t r);

#endif
