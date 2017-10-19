#include "includes.h"
#include "common.h"
#include "config.h"
#include "papi_stats.h"

#ifdef CFG_WITH_PAPI
#include "papi.h"
#endif

#if CFG_WITH_PAPI == 1
#define PAPI_STATS_NO_EVENTS 6
int PAPI_STATS_ALL_EVENTS [PAPI_STATS_NO_EVENTS] = {
  PAPI_L1_TCM,
  PAPI_L1_TCH,
  PAPI_L2_TCM,
  PAPI_L2_TCH,
  PAPI_L3_TCM,
  PAPI_L3_TCH
};
int PAPI_STATS_EVENT_SET;
int PAPI_STATS_EVENTS[PAPI_STATS_NO_EVENTS];
#endif


void init_papi_stats
() {
  int i, rc, n;
  
#if CFG_WITH_PAPI == 1
  if(PAPI_library_init(PAPI_VER_CURRENT) != PAPI_VER_CURRENT) {
    /*  do something here  */
  } else {
    PAPI_STATS_EVENT_SET = PAPI_NULL;
    if((rc = PAPI_create_eventset(&PAPI_STATS_EVENT_SET)) != PAPI_OK) {
      assert(0);
    } else {
      for(n = 0, i = 0; i < PAPI_STATS_NO_EVENTS; i ++) {
        rc = PAPI_add_event(PAPI_STATS_EVENT_SET, PAPI_STATS_ALL_EVENTS[i]);
        if(rc != PAPI_OK) {
          /*  do something here  */
        } else {
          PAPI_STATS_EVENTS[n ++] = PAPI_STATS_ALL_EVENTS[i];
        }
      }
      PAPI_start(PAPI_STATS_EVENT_SET);
    }
  }
#endif
}


void finalise_papi_stats
() {
#if CFG_WITH_PAPI == 1
  if(PAPI_is_initialized()) {
    PAPI_shutdown();
  }
#endif
}


void papi_stats_get_stat_name
(int stat,
 char * name) {
#if CFG_WITH_PAPI == 1
  switch(stat) {
  case PAPI_L1_TCM: sprintf(name, "lvl1TotalCacheMiss"); break;
  case PAPI_L1_TCH: sprintf(name, "lvl1TotalCacheHit"); break;
  case PAPI_L2_TCM: sprintf(name, "lvl2TotalCacheMiss"); break;
  case PAPI_L2_TCH: sprintf(name, "lvl2TotalCacheHit"); break;
  case PAPI_L3_TCM: sprintf(name, "lvl3TotalCacheMiss"); break;
  case PAPI_L3_TCH: sprintf(name, "lvl3TotalCacheHit"); break;
  default: assert(0);
  }
#endif
}

void papi_stats_output
(FILE * f) {  
#if CFG_WITH_PAPI == 1
  int i, rc, n;
  long long values[PAPI_STATS_NO_EVENTS];
  char stat_name[256];
  
  n = PAPI_num_events(PAPI_STATS_EVENT_SET);
  PAPI_stop(PAPI_STATS_EVENT_SET, values);
  fprintf(f, "<papiStatistics>\n");
  for(i = 0; i < n; i ++) {
    papi_stats_get_stat_name(PAPI_STATS_EVENTS[i], stat_name);
    fprintf(f, "<%s>%llu</%s>\n", stat_name, values[i], stat_name);
  }
  fprintf(f, "</papiStatistics>\n");
#endif
}
