#include "pss.h"

#define PSS_EXPORTABLE() (p >= on_local)
#define PSS_ACCEPTABLE() (p == on_local)
#define PSS_PREEMPTS()   (p == on_all)

static report_t R;

void pss_local
(uint32_t   mod,
 uint32_t * exported) {
  bool_t dead;
  bool_t synchpt;
  mstate_t s;
  mevent_set_t en;
  mevent_t e;
  unsigned int i;
  priority_t p, on_local, on_all;

  *exported = 0;
  while (TRUE) {
    dead = TRUE;
    synchpt = FALSE;

    en = mstate_enabled_events_module (s, mod);
    mevent_set_max_priority (en, &on_local, &on_all);

    /*
     *  1st loop on fused transitions
     */
    for (i = 0; i < mevent_set_size (en); i ++) {
      e = mevent_set_nth (en, i);
      p = mevent_priority (e);
      if (!mevent_is_local (e) && PSS_EXPORTABLE ()) {
	dead = FALSE;
	synchpt = TRUE;
      }
    }

    /*
     *  2nd loop on local transitions
     */
    for (i = 0; i < mevent_set_size (en); i ++) {
      e = mevent_set_nth (en, i);
      if (mevent_is_local (e) && PSS_ACCEPTABLE ()) {
	dead = FALSE;
	if (PSS_EXPORTABLE ()) {
	  //  todo: ajouter export
	}
	if (!synchpt || PSS_PREEMPTS ()) {
	  //  todo: ajouter insertion dans NODE
	}
      }
    }

    if (dead) {
      //  todo: ajouter export
    }
    mevent_set_free (en);
  }
}

void pss
(report_t r) {
  R = r;
}
