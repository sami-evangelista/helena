#include "workers.h"
#include "context.h"
#include "debug.h"

void launch_and_wait_workers
(worker_func_t f) {
  worker_id_t w;
  void * dummy;
  uint16_t no_workers = context_no_workers();
  pthread_t * workers = context_workers();
  
  for(w = 0; w < no_workers; w ++) {
    pthread_create(&(workers[w]), NULL, f, (void *) (long) w);
    debug("[%d] worker %d launched\n", context_proc_id(), w);
  }
  for(w = 0; w < no_workers; w ++) {
    pthread_join(workers[w], &dummy);
    debug("[%d] worker %d has terminated\n", context_proc_id(), w);
  }
}
