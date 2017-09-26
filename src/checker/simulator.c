#if defined(CFG_ACTION_SIMULATE)

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
  event_list_t en;
  state_t stack[65536], succ;
  unsigned int stack_evt[65536];
  event_t e;
  size_t n;
  char prop[65536];
  
  stack[0] = state_initial();
  while(loop) {
    printf("# ");
    fflush(stdout);
    n = getline(&cmd, &n, stdin);
    if(n == -1) {
      printf("\n");
      continue;
    }
    cmd[n - 1] = '\0';
    if(!strcmp(cmd, "show")) {
      state_print(stack[top], stdout);
    } else if(!strcmp(cmd, "stack")) {
      state_t now = state_initial();
      for(i = 0; i < top; i ++) {
	en = state_enabled_events(now);
	e = event_set_nth(en, stack_evt[i] - 1);
	event_print(e, stdout);
	event_exec(e, now);
	event_set_free(en);
      }
      state_free(now);
    } else if(!strncmp(cmd, "eval ", 5)) {
      sscanf(cmd, "eval %s", &prop[0]);
      if(!model_is_state_proposition(prop)) {
	printf("error: %s is not a proposition of the model\n", prop);
      } else {
	printf("evaluation of proposition %s: ", prop);
	if(model_check_state_proposition(prop, stack[top])) {
	  printf("true\n");
	} else {
	  printf("false\n");
	}
      }
    } else if(!strncmp(cmd, "push ", 5)) {
      sscanf(cmd, "push %d", &i);
      en = state_enabled_events(stack[top]);
      if(check_error()) {
	if(i < 1 || i > event_set_size(en)) {
	  printf("error: state has %d enabled event(s)\n",
		  event_set_size(en));
	} else {
	  e = event_set_nth(en, i - 1);
	  succ = state_succ(stack[top], e);
	  if(check_error()) {
	    stack_evt[top] = i;
	    top ++;
	    stack[top] = succ;
	  } else {
	    state_free(succ);
	  }
	}
      }
      event_set_free(en);
    } else if(!strcmp(cmd, "pop")) {
      if(0 == top) {
	printf("error: stack is empty\n");
      } else {
	state_free(stack[top]);
	top --;
      }
    } else if(!strcmp(cmd, "enabled")) {
      en = state_enabled_events(stack[top]);
      if(check_error()) {
	for(i = 0; i < event_set_size(en); i ++) {
	  printf("%3d: ", i + 1);
	  event_print(event_set_nth(en, i), stdout);
	}
      }
      event_set_free(en);
    } else if(!strcmp(cmd, "help")) {
      printf("\
show    -> show the current state(the one on top of the stack)\n\
stack   -> show the stack of executed events\n\
enabled -> show enabled events of the current state\n\
pop     -> pop the state on top of the stack\n\
push N  -> push the Nth successor of the current state on the stack\n\
eval P  -> evaluate proposition on the current state\n\
help\n\
quit\n");
    } else if(!strcmp(cmd, "quit")) {
      loop = FALSE;
    } else if(cmd[0] != '\0') {
      printf("error: unrecognized command: %s\n", cmd);
    }
    free(cmd);
    cmd = NULL;
  }
  for(; top >= 0; top --) {
    state_free(stack[top]);
  }
}

#endif  /*  defined(CFG_ACTION_SIMULATE)  */
