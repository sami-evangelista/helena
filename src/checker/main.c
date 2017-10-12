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

  if(cfg_action_simulate()) { 
    simulator();
  } else {
    if(cfg_distributed()) {
      comm_shmem_init();
    }

    /*
     *  catch SIGINT by changing the context state
     */
    signal(SIGINT, context_interruption_handler);
    
    /*
     *  launch the search
     */
    if(cfg_algo_bfs() || cfg_algo_dbfs() || cfg_algo_frontier()) {
      bfs();
    } else if(cfg_algo_dfs() || cfg_algo_ddfs()) {
      dfs();
    } else if(cfg_algo_delta_ddd()) {
      delta_ddd();
    } else if(cfg_algo_rwalk()) {
      rwalk();
    }

    context_finalise();
    
    /*
     *  termination of all libraries
     */
    free_bit_stream();
    free_model();

    if(cfg_action_build_graph()) {
      graph_make_report(CFG_GRAPH_FILE, CFG_RG_REPORT_FILE, NULL);
    }
  }

  exit(EXIT_SUCCESS);
}
