#include "config.h"
#include "simulator.h"
#include "model.h"
#include "list.h"
#include "event.h"
#include "context.h"


bool_t check_error() {
  if(!context_error_raised()) {
    return TRUE;
  } else {
    printf("model error: %s\n", context_error_msg());
    context_flush_error();
    return FALSE;
  }
}

void simulator() {
  unsigned int i;
  bool_t loop = TRUE;
  char * cmd = NULL;
  mstate_t s;
  mevent_t e;
  size_t n;
  char prop[65536];
  state_list_t stack;
  event_list_t stack_evts;
  event_list_t en;
  list_iter_t it;

  s = mstate_initial();
  stack = list_new(SYSTEM_HEAP, sizeof(state_t), state_free_void);
  stack_evts = list_new(SYSTEM_HEAP, sizeof(event_t), event_free_void);
  list_append(stack, &s);
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
      list_last(stack, &s);
      mstate_print(s, stdout);
    } else if(!strcmp(cmd, "stack")) {
      if(list_is_empty(stack_evts)) {
	printf("stack is empty\n");
      } else {
	for(it = list_get_iter(stack_evts);
	    !list_iter_at_end(it);
	    it = list_iter_next(it)) {
	  e = * ((mevent_t *) list_iter_item(it));
	  mevent_print(e, stdout);
	}
      }
    } else if(!strncmp(cmd, "eval ", 5)) {
      sscanf(cmd, "eval %s", &prop[0]);
      if(!model_is_state_proposition(prop)) {
	printf("error: %s is not a proposition of the model\n", prop);
      } else {
	printf("evaluation of proposition %s: ", prop);
	list_last(stack, &s);
	if(model_check_state_proposition(prop, s)) {
	  printf("true\n");
	} else {
	  printf("false\n");
	}
      }
    } else if(!strncmp(cmd, "push ", 5)) {
      sscanf(cmd, "push %d", &i);
      list_last(stack, &s);
      en = mstate_events(s);
      if(check_error()) {
	if(i < 1 || i > list_size(en)) {
	  printf("error: state has %d enabled event(s)\n", list_size(en));
	} else {
	  list_nth(en, i - 1, &e);
	  s = mstate_succ(s, e);
	  if(check_error()) {
	    e = mevent_copy(e);
	    list_append(stack, &s);
	    list_append(stack_evts, &e);
	  } else {
	    mstate_free(s);
	  }
	}
      }
      list_free(en);
    } else if(!strcmp(cmd, "pop")) {
      if(list_is_empty(stack_evts)) {
	printf("error: stack is empty\n");
      } else {
	list_pick_last(stack, &s);
	mstate_free(s);
	list_pick_last(stack_evts, &e);
	mevent_free(e);
      }
    } else if(!strcmp(cmd, "enabled")) {
      list_last(stack, &s);
      en = mstate_events(s);
      if(check_error()) {
        if(list_is_empty(en)) {
          printf("no enabled event\n");
        } else {
          for(i = 0; i < list_size(en); i ++) {
            printf("%3d: ", i + 1);
            list_nth(en, i, &e);
            mevent_print(e, stdout);
          }
        }
      }
      list_free(en);
    } else if(!strcmp(cmd, "help")) {
      printf("\
show    -> show the current state (the one on top of the stack)\n\
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
  list_free(stack);
  list_free(stack_evts);
}
