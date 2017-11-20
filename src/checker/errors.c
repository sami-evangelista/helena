#include "errors.h"
#include "context.h"

unsigned int error_throw
(char * msg) {
  context_error(msg);
  return 0;
}
