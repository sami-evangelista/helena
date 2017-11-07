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
#include "papi_stats.h"

int main
(int argc,
 char ** argv) {
  int i;

  /**
   * initialisation of all libraries
   */
  init_heap();
  init_bit_stream();
  init_model();
  if(CFG_DISTRIBUTED) {
    init_comm_shmem();
  }
  if(CFG_WITH_PAPI) {
    init_papi_stats();
  }
  init_context();

  if(CFG_ACTION_SIMULATE) { 
    simulator();
  } else {

    /**
     * get compilation time from command line
     */
    for(i = 1; i < argc; i += 2) {
      if(0 == strcmp(argv[i], "comp-time")) {
        float comp_time;
        sscanf(argv[i + 1], "%f", &comp_time);
        context_set_comp_time(comp_time);
      }
    }

    /**
     * catch SIGINT by changing the context state
     */
    signal(SIGINT, context_interruption_handler);
    
    /**
     * launch the appropriate search algorithm
     */
    if(CFG_ALGO_BFS || CFG_ALGO_DBFS) {
      bfs();
    } else if(CFG_ALGO_DFS || CFG_ALGO_DDFS) {
      dfs();
    } else if(CFG_ALGO_DELTA_DDD) {
      delta_ddd();
    } else if(CFG_ALGO_RWALK) {
      rwalk();
    }

    /**
     * generation of the reachability graph report
     */
    if(CFG_ACTION_BUILD_GRAPH
       && SEARCH_TERMINATED == context_termination_state()) {
      graph_make_report(CFG_GRAPH_FILE, CFG_RG_REPORT_FILE);
    }
    
    /**
     * termination of all libraries
     */
    finalise_context();
    if(CFG_DISTRIBUTED) {
      finalise_comm_shmem();
    }
    if(CFG_WITH_PAPI) {
      finalise_papi_stats();
    }
  }

  exit(EXIT_SUCCESS);
}
