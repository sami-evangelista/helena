#include "workers.h"

void launch_and_wait_workers
(report_t r,
 worker_func_t f) {
  worker_id_t w;
  void * dummy;
  for(w = 0; w < r->no_workers; w ++) {
    pthread_create(&(r->workers[w]), NULL, f, (void *) (long) w);
  }
  for(w = 0; w < r->no_workers; w ++) {
    pthread_join(r->workers[w], &dummy);
  }
}
