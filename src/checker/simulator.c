#include "simulator.h"

bool_t check_error () {
  if (!glob_error_msg) {
    return TRUE;
  } else {
    printf ("model error: %s\n", glob_error_msg);
    flush_error ();
    return FALSE;
  }
}

void simulator () {
  unsigned int i;
  bool_t loop = TRUE;
  char * cmd = NULL;
  int top = 0;
  mevent_set_t en;
  mstate_t stack[65536], succ;
  unsigned int stack_evt[65536];
  mevent_t e;
  size_t n;
  char prop[65536];
  
  stack[0] = mstate_initial ();
  while (loop) {
    printf ("# ");
    fflush (stdout);
    n = getline (&cmd, &n, stdin);
    if (n == -1) {
      printf ("\n");
      continue;
    }
    cmd[n - 1] = '\0';
    if (!strcmp (cmd, "show")) {
      mstate_print (stack[top], stdout);
    } else if (!strcmp (cmd, "stack")) {
      mstate_t now = mstate_initial ();
      for (i = 0; i < top; i ++) {
	en = mstate_enabled_events (now);
	e = mevent_set_nth (en, stack_evt[i] - 1);
	mevent_print (e, stdout);
	mevent_exec (e, now);
	mevent_set_free (en);
      }
      mstate_free (now);
    } else if (!strncmp (cmd, "eval ", 5)) {
      sscanf (cmd, "eval %s", &prop[0]);
      if (!model_is_state_proposition(prop)) {
	printf ("error: %s is not a proposition of the model\n", prop);
      } else {
	printf ("evaluation of proposition %s: ", prop);
	if (model_check_state_proposition (prop, stack[top])) {
	  printf ("true\n");
	} else {
	  printf ("false\n");
	}
      }
    } else if (!strncmp (cmd, "push ", 5)) {
      sscanf (cmd, "push %d", &i);
      en = mstate_enabled_events (stack[top]);
      if (check_error ()) {
	if (i < 1 || i > mevent_set_size (en)) {
	  printf ("error: state has %d enabled event(s)\n",
		  mevent_set_size (en));
	} else {
	  e = mevent_set_nth (en, i - 1);
	  succ = mstate_succ (stack[top], e);
	  if (check_error ()) {
	    stack_evt[top] = i;
	    top ++;
	    stack[top] = succ;
	  } else {
	    mstate_free (succ);
	  }
	}
      }
      mevent_set_free (en);
    } else if (!strcmp (cmd, "pop")) {
      if (0 == top) {
	printf ("error: stack is empty\n");
      } else {
	mstate_free (stack[top]);
	top --;
      }
    } else if (!strcmp (cmd, "enabled")) {
      en = mstate_enabled_events (stack[top]);
      if (check_error ()) {
	for (i = 0; i < mevent_set_size (en); i ++) {
	  printf ("%3d: ", i + 1);
	  mevent_print (mevent_set_nth (en, i), stdout);
	}
      }
      mevent_set_free (en);
    } else if (!strcmp (cmd, "help")) {
      printf ("\
show    -> show the current state (the one on top of the stack)\n\
stack   -> show the stack of executed events\n\
enabled -> show enabled events of the current state\n\
pop     -> pop the state on top of the stack\n\
push N  -> push the Nth successor of the current state on the stack\n\
eval P  -> evaluate proposition on the current state\n\
help\n\
quit\n");
    } else if (!strcmp (cmd, "quit")) {
      loop = FALSE;
    } else if (cmd[0] != '\0') {
      printf ("error: unrecognized command: %s\n", cmd);
    }
    free (cmd);
    cmd = NULL;
  }
  for (; top >= 0; top --) {
    mstate_free (stack[top]);
  }
}
