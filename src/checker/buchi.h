#ifndef LIB_BUCHI
#define LIB_BUCHI

#include "common.h"
#include "includes.h"
#include "model.h"

#ifndef MODEL_CONFIG
#error Model configuration missing!
#endif

typedef int bstate_t;

typedef struct {
  bstate_t from;
  bstate_t to;
} bevent_t;

bstate_t bstate_initial
();

bool_t bstate_accepting
(bstate_t b);

void bstate_succs
(bstate_t b,
 mstate_t s,
 bstate_t * succs,
 unsigned int * no_succs);

unsigned int bstate_char_width
();

order_t bevent_cmp
(bevent_t e,
 bevent_t f);

#endif
