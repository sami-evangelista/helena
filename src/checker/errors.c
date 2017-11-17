#include "errors.h"
#include "context.h"

void error_throw
(char * msg) {
  context_error(msg);
}
