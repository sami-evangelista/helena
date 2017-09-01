#include "report.h"
#include "dfs.h"
#include "bfs.h"
#include "pd4.h"
#include "simulator.h"
#include "random_walk.h"
#include "graph.h"

int main
(int argc,
 char ** argv) {
  int i;

  /*
   *  initialisation of all libraries
   */
  init_heap();
  init_vectors();
  init_common();
  init_storage();
  init_model();

  /*
   *  simulation mode
   */
#if defined(ACTION_SIMULATE)
  
  simulator();

#else

  /*
   *  normal mode
   */
  printf("Running...\n");

  /*
   *  catch SIGINT by changing the report state
   */
  signal(SIGINT, report_interruption_handler);

  /*
   *  initialisation of the report
   */
  glob_report = report_new(NO_WORKERS);
  for(i = 1; i < argc; i += 2) {
    if(0 == strcmp(argv[i], "comp-time")) {
      float comp_time;
      sscanf(argv[i + 1], "%f", &comp_time);
      report_set_comp_time(glob_report, comp_time);
    }
  }

  /*
   *  launch the search and create the report
   */
#if defined(ALGO_BFS) || defined(ALGO_FRONTIER)
  bfs(glob_report);
#elif defined(ALGO_DFS)
  dfs(glob_report);
#elif defined(ALGO_PD4)
  pd4(glob_report);
#elif defined(ALGO_RWALK)
  random_walk(glob_report);
#endif
  report_finalise(glob_report);

  /*
   *  termination of all libraries
   */
  free_heap();
  free_vectors();
  free_common();
  free_storage();
  free_model();

  report_free(glob_report);

#ifdef ACTION_BUILD_RG
  graph_make_report(GRAPH_FILE, RG_REPORT_FILE, NULL);
#endif

#endif

  exit(EXIT_SUCCESS);
}
