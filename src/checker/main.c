#include "config.h"
#include "context.h"
#include "dfs.h"
#include "bfs.h"
#include "delta_ddd.h"
#include "simulator.h"
#include "rwalk.h"
#include "graph.h"
#include "bit_stream.h"
#include "comm_shmem.h"

int main
(int argc,
 char ** argv) {
  int i;

  /*
   *  initialisation of all libraries
   */
  init_heap();
  init_bit_stream();
  init_model();

  /*
   *  initialisation of the context
   */
  context_init();
  for(i = 1; i < argc; i += 2) {
    if(0 == strcmp(argv[i], "comp-time")) {
      float comp_time;
      sscanf(argv[i + 1], "%f", &comp_time);
      context_set_comp_time(comp_time);
    }
  }

  
#if defined(CFG_ACTION_SIMULATE)
  
  simulator();

#else

#if defined CFG_DISTRIBUTED
  comm_shmem_init();
#endif

  /*
   *  catch SIGINT by changing the context state
   */
  signal(SIGINT, context_interruption_handler);

  /*
   *  launch the search
   */
#if defined(CFG_ALGO_BFS) || defined(CFG_ALGO_DBFS) || \
  defined(CFG_ALGO_FRONTIER)
  bfs();
#elif defined(CFG_ALGO_DFS) || defined(CFG_ALGO_DDFS)
  dfs();
#elif defined(CFG_ALGO_DELTA_DDD)
  delta_ddd();
#elif defined(CFG_ALGO_RWALK)
  rwalk();
#endif

  context_finalise();

  /*
   *  termination of all libraries
   */
  free_bit_stream();
  free_model();

#if defined(CFG_ACTION_BUILD_GRAPH)
  graph_make_report(CFG_GRAPH_FILE, CFG_RG_REPORT_FILE, NULL);
#endif

#endif

  exit(EXIT_SUCCESS);
}
