#include "model.h"
#include "htbl.h"
#include "darray.h"

#ifndef LIB_POR_ANALYSIS
#define LIB_POR_ANALYSIS

void por_analysis_scc
(htbl_t H,
 darray_t scc);

uint64_t por_analysis_no_unsafe_states
();

#endif
