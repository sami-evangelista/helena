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

void bfs
(report_t r);

#endif
