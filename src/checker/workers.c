#include "workers.h"
#include "context.h"
#include "debug.h"

void launch_and_wait_workers
(worker_func_t f) {
  const uint16_t no_workers = context_no_workers();
  pthread_t * workers = context_workers();
  worker_id_t w;
  void * dummy;
  
  for(w = 0; w < no_workers; w ++) {
    pthread_create(&(workers[w]), NULL, f, (void *) (long) w);
    debug("worker %d launched\n", w);
  }
  for(w = 0; w < no_workers; w ++) {
    pthread_join(workers[w], &dummy);
    debug("worker %d has terminated\n", w);
  }
}
