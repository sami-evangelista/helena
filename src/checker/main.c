#include "compression.h"
#include "config.h"
#include "context.h"
#include "dfs.h"
#include "bfs.h"
#include "delta_ddd.h"
#include "simulator.h"
#include "bwalk.h"
#include "rwalk.h"
#include "graph.h"
#include "bit_stream.h"
#include "comm.h"
#include "papi_stats.h"

int main
(int argc,
 char ** argv) {
  int i;
  double comp_time;

  /**
   * initialisation of all libraries
   */
  init_heap();
  init_bit_stream();
  init_model();
  if(CFG_DISTRIBUTED) {
    init_comm();
  }
  if(CFG_WITH_PAPI) {
    init_papi_stats();
  }
  init_context();
  init_compress_data();

  if(CFG_ACTION_SIMULATE) { 
    simulator();
  } else {

    /**
     * get compilation time from command line
     */
    for(i = 1; i < argc; i += 2) {
      if(0 == strcmp(argv[i], "comp-time")) {
        sscanf(argv[i + 1], "%lf", &comp_time);
        context_set_stat(STAT_TIME_COMP, 0, comp_time * 1000000000.0);
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
    } else if(CFG_ALGO_DFS || CFG_ALGO_TARJAN) {
      dfs();
    } else if(CFG_ALGO_DELTA_DDD) {
      delta_ddd();
    } else if(CFG_ALGO_RWALK) {
      rwalk();
    } else if(CFG_ALGO_BWALK) {
      bwalk();
    } else {
      assert(FALSE);
    }

    /**
     * generation of the reachability graph report
     */
    if(CFG_ACTION_BUILD_GRAPH
       && TERM_SEARCH_TERMINATED == context_termination_state()) {
      graph_make_report(CFG_GRAPH_FILE, CFG_RG_REPORT_FILE);
    }
    
    /**
     * termination of all libraries
     */
    finalise_context();
    if(CFG_WITH_PAPI) {
      finalise_papi_stats();
    }
    if(CFG_DISTRIBUTED) {
      finalise_comm();
    }
    finalise_compress_data();
    finalise_model();
  }

  exit(EXIT_SUCCESS);
}
