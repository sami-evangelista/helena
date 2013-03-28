/***** ltl2ba : buchi.c *****/

/* Written by Denis Oddoux, LIAFA, France                                 */
/* Copyright (c) 2001  Denis Oddoux                                       */
/* Modified by Paul Gastin, LSV, France                                   */
/* Copyright (c) 2007  Paul Gastin                                        */
/*                                                                        */
/* This program is free software; you can redistribute it and/or modify   */
/* it under the terms of the GNU General Public License as published by   */
/* the Free Software Foundation; either version 2 of the License, or      */
/* (at your option) any later version.                                    */
/*                                                                        */
/* This program is distributed in the hope that it will be useful,        */
/* but WITHOUT ANY WARRANTY; without even the implied warranty of         */
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          */
/* GNU General Public License for more details.                           */
/*                                                                        */
/* You should have received a copy of the GNU General Public License      */
/* along with this program; if not, write to the Free Software            */
/* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA*/
/*                                                                        */
/* Based on the translation algorithm by Gastin and Oddoux,               */
/* presented at the 13th International Conference on Computer Aided       */
/* Verification, CAV 2001, Paris, France.                                 */
/* Proceedings - LNCS 2102, pp. 53-65                                     */
/*                                                                        */
/* Send bug-reports and/or questions to Paul Gastin                       */
/* http://www.lsv.ens-cachan.fr/~gastin                                   */

#include "ltl2ba.h"

/********************************************************************\
|*              Structures and shared variables                     *|
\********************************************************************/

extern GState **init, *gstates;
extern struct rusage tr_debut, tr_fin;
extern struct timeval t_diff;
extern int tl_verbose, tl_stats, tl_simp_diff, tl_simp_fly, tl_simp_scc,
  init_size, *final;
extern void put_uform(void);

extern FILE *tl_out;
extern char *out_dir;		
BState *bstack, *bstates, *bremoved;
BScc *scc_stack;
int accept, bstate_count = 0, btrans_count = 0, rank;

/********************************************************************\
|*        Simplification of the generalized Buchi automaton         *|
\********************************************************************/

void free_bstate(BState *s) /* frees a state and its transitions */
{
  free_btrans(s->trans->nxt, s->trans, 1);
  tfree(s);
}

BState *remove_bstate(BState *s, BState *s1) /* removes a state */
{
  BState *prv = s->prv;
  s->prv->nxt = s->nxt;
  s->nxt->prv = s->prv;
  free_btrans(s->trans->nxt, s->trans, 0);
  s->trans = (BTrans *)0;
  s->nxt = bremoved->nxt;
  bremoved->nxt = s;
  s->prv = s1;
  for(s1 = bremoved->nxt; s1 != bremoved; s1 = s1->nxt)
    if(s1->prv == s)
      s1->prv = s->prv;
  return prv;
} 

void copy_btrans(BTrans *from, BTrans *to) {
  to->to    = from->to;
  copy_set(from->pos, to->pos, 1);
  copy_set(from->neg, to->neg, 1);
}

int simplify_btrans() /* simplifies the transitions */
{
  BState *s;
  BTrans *t, *t1;
  int changed = 0;

  if(tl_stats) getrusage(RUSAGE_SELF, &tr_debut);

  for (s = bstates->nxt; s != bstates; s = s->nxt)
    for (t = s->trans->nxt; t != s->trans;) {
      t1 = s->trans->nxt;
      copy_btrans(t, s->trans);
      while((t == t1) || (t->to != t1->to) ||
            !included_set(t1->pos, t->pos, 1) ||
            !included_set(t1->neg, t->neg, 1))
        t1 = t1->nxt;
      if(t1 != s->trans) {
        BTrans *free = t->nxt;
        t->to    = free->to;
        copy_set(free->pos, t->pos, 1);
        copy_set(free->neg, t->neg, 1);
        t->nxt   = free->nxt;
        if(free == s->trans) s->trans = t;
        free_btrans(free, 0, 0);
        changed++;
      }
      else
        t = t->nxt;
    }
      
  if(tl_stats) {
    getrusage(RUSAGE_SELF, &tr_fin);
    timeval_subtract (&t_diff, &tr_fin.ru_utime, &tr_debut.ru_utime);
    fprintf(tl_out, "\nSimplification of the Buchi automaton - transitions: %i.%06is",
		t_diff.tv_sec, t_diff.tv_usec);
    fprintf(tl_out, "\n%i transitions removed\n", changed);

  }
  return changed;
}

int same_btrans(BTrans *s, BTrans *t) /* returns 1 if the transitions are identical */
{
  return((s->to == t->to) &&
	 same_sets(s->pos, t->pos, 1) &&
	 same_sets(s->neg, t->neg, 1));
}

void remove_btrans(BState *to) 
{             /* redirects transitions before removing a state from the automaton */
  BState *s;
  BTrans *t;
  int i;
  for (s = bstates->nxt; s != bstates; s = s->nxt)
    for (t = s->trans->nxt; t != s->trans; t = t->nxt)
      if (t->to == to) { /* transition to a state with no transitions */
	BTrans *free = t->nxt;
	t->to = free->to;
	copy_set(free->pos, t->pos, 1);
	copy_set(free->neg, t->neg, 1);
	t->nxt   = free->nxt;
	if(free == s->trans) s->trans = t;
	free_btrans(free, 0, 0);
      }
}

void retarget_all_btrans()
{             /* redirects transitions before removing a state from the automaton */
  BState *s;
  BTrans *t;
  for (s = bstates->nxt; s != bstates; s = s->nxt)
    for (t = s->trans->nxt; t != s->trans; t = t->nxt)
      if (!t->to->trans) { /* t->to has been removed */
	t->to = t->to->prv;
	if(!t->to) { /* t->to has no transitions */
	  BTrans *free = t->nxt;
	  t->to = free->to;
	  copy_set(free->pos, t->pos, 1);
	  copy_set(free->neg, t->neg, 1);
	  t->nxt   = free->nxt;
	  if(free == s->trans) s->trans = t;
	  free_btrans(free, 0, 0);
	}
      }
  while(bremoved->nxt != bremoved) { /* clean the 'removed' list */
    s = bremoved->nxt;
    bremoved->nxt = bremoved->nxt->nxt;
    tfree(s);
  }
}

int all_btrans_match(BState *a, BState *b) /* decides if the states are equivalent */
{	
  BTrans *s, *t;
  if (((a->final == accept) || (b->final == accept)) &&
      (a->final + b->final != 2 * accept) && 
      a->incoming >=0 && b->incoming >=0)
    return 0; /* the states have to be both final or both non final */

  for (s = a->trans->nxt; s != a->trans; s = s->nxt) { 
                                /* all transitions from a appear in b */
    copy_btrans(s, b->trans);
    t = b->trans->nxt;
    while(!same_btrans(s, t))
      t = t->nxt;
    if(t == b->trans) return 0;
  }
  for (s = b->trans->nxt; s != b->trans; s = s->nxt) { 
                                /* all transitions from b appear in a */
    copy_btrans(s, a->trans);
    t = a->trans->nxt;
    while(!same_btrans(s, t))
      t = t->nxt;
    if(t == a->trans) return 0;
  }
  return 1;
}

int simplify_bstates() /* eliminates redundant states */
{
  BState *s, *s1;
  int changed = 0;

  if(tl_stats) getrusage(RUSAGE_SELF, &tr_debut);

  for (s = bstates->nxt; s != bstates; s = s->nxt) {
    if(s->trans == s->trans->nxt) { /* s has no transitions */
      s = remove_bstate(s, (BState *)0);
      changed++;
      continue;
    }
    bstates->trans = s->trans;
    bstates->final = s->final;
    s1 = s->nxt;
    while(!all_btrans_match(s, s1))
      s1 = s1->nxt;
    if(s1 != bstates) { /* s and s1 are equivalent */
      if(s1->incoming == -1)
        s1->final = s->final; /* get the good final condition */
      s = remove_bstate(s, s1);
      changed++;
    }
  }
  retarget_all_btrans();

  if(tl_stats) {
    getrusage(RUSAGE_SELF, &tr_fin);
    timeval_subtract (&t_diff, &tr_fin.ru_utime, &tr_debut.ru_utime);
    fprintf(tl_out, "\nSimplification of the Buchi automaton - states: %i.%06is",
		t_diff.tv_sec, t_diff.tv_usec);
    fprintf(tl_out, "\n%i states removed\n", changed);
  }

  return changed;
}

int bdfs(BState *s) {
  BTrans *t;
  BScc *c;
  BScc *scc = (BScc *)tl_emalloc(sizeof(BScc));
  scc->bstate = s;
  scc->rank = rank;
  scc->theta = rank++;
  scc->nxt = scc_stack;
  scc_stack = scc;

  s->incoming = 1;

  for (t = s->trans->nxt; t != s->trans; t = t->nxt) {
    if (t->to->incoming == 0) {
      int result = bdfs(t->to);
      scc->theta = min(scc->theta, result);
    }
    else {
      for(c = scc_stack->nxt; c != 0; c = c->nxt)
	if(c->bstate == t->to) {
	  scc->theta = min(scc->theta, c->rank);
	  break;
	}
    }
  }
  if(scc->rank == scc->theta) {
    if(scc_stack == scc) { /* s is alone in a scc */
      s->incoming = -1;
      for (t = s->trans->nxt; t != s->trans; t = t->nxt)
	if (t->to == s)
	  s->incoming = 1;
    }
    scc_stack = scc->nxt;
  }
  return scc->theta;
}

void simplify_bscc() {
  BState *s;
  rank = 1;
  scc_stack = 0;

  if(bstates == bstates->nxt) return;

  for(s = bstates->nxt; s != bstates; s = s->nxt)
    s->incoming = 0; /* state color = white */

  bdfs(bstates->prv);

  for(s = bstates->nxt; s != bstates; s = s->nxt)
    if(s->incoming == 0)
      remove_bstate(s, 0);
}




/********************************************************************\
|*              Generation of the Buchi automaton                   *|
\********************************************************************/

BState *find_bstate(GState **state, int final, BState *s)
{                       /* finds the corresponding state, or creates it */
  if((s->gstate == *state) && (s->final == final)) return s; /* same state */

  s = bstack->nxt; /* in the stack */
  bstack->gstate = *state;
  bstack->final = final;
  while(!(s->gstate == *state) || !(s->final == final))
    s = s->nxt;
  if(s != bstack) return s;

  s = bstates->nxt; /* in the solved states */
  bstates->gstate = *state;
  bstates->final = final;
  while(!(s->gstate == *state) || !(s->final == final))
    s = s->nxt;
  if(s != bstates) return s;

  s = bremoved->nxt; /* in the removed states */
  bremoved->gstate = *state;
  bremoved->final = final;
  while(!(s->gstate == *state) || !(s->final == final))
    s = s->nxt;
  if(s != bremoved) return s;

  s = (BState *)tl_emalloc(sizeof(BState)); /* creates a new state */
  s->gstate = *state;
  s->id = (*state)->id;
  s->incoming = 0;
  s->final = final;
  s->trans = emalloc_btrans(); /* sentinel */
  s->trans->nxt = s->trans;
  s->nxt = bstack->nxt;
  bstack->nxt = s;
  return s;
}

int next_final(int *set, int fin) /* computes the 'final' value */
{
  if((fin != accept) && in_set(set, final[fin + 1]))
    return next_final(set, fin + 1);
  return fin;
}

void make_btrans(BState *s) /* creates all the transitions from a state */
{
  int state_trans = 0;
  GTrans *t;
  BTrans *t1;
  BState *s1;
  if(s->gstate->trans)
    for(t = s->gstate->trans->nxt; t != s->gstate->trans; t = t->nxt) {
      int fin = next_final(t->final, (s->final == accept) ? 0 : s->final);
      BState *to = find_bstate(&t->to, fin, s);
      
      for(t1 = s->trans->nxt; t1 != s->trans;) {
	if(tl_simp_fly && 
	   (to == t1->to) &&
	   included_set(t->pos, t1->pos, 1) &&
	   included_set(t->neg, t1->neg, 1)) { /* t1 is redondant */
	  BTrans *free = t1->nxt;
	  t1->to->incoming--;
	  t1->to = free->to;
	  copy_set(free->pos, t1->pos, 1);
	  copy_set(free->neg, t1->neg, 1);
	  t1->nxt   = free->nxt;
	  if(free == s->trans) s->trans = t1;
	  free_btrans(free, 0, 0);
	  state_trans--;
	}
	else if(tl_simp_fly &&
		(t1->to == to ) &&
		included_set(t1->pos, t->pos, 1) &&
		included_set(t1->neg, t->neg, 1)) /* t is redondant */
	  break;
	else
	  t1 = t1->nxt;
      }
      if(t1 == s->trans) {
	BTrans *trans = emalloc_btrans();
	trans->to = to;
	trans->to->incoming++;
	copy_set(t->pos, trans->pos, 1);
	copy_set(t->neg, trans->neg, 1);
	trans->nxt = s->trans->nxt;
	s->trans->nxt = trans;
	state_trans++;
      }
    }
  
  if(tl_simp_fly) {
    if(s->trans == s->trans->nxt) { /* s has no transitions */
      free_btrans(s->trans->nxt, s->trans, 1);
      s->trans = (BTrans *)0;
      s->prv = (BState *)0;
      s->nxt = bremoved->nxt;
      bremoved->nxt = s;
      for(s1 = bremoved->nxt; s1 != bremoved; s1 = s1->nxt)
	if(s1->prv == s)
	  s1->prv = (BState *)0;
      return;
    }
    bstates->trans = s->trans;
    bstates->final = s->final;
    s1 = bstates->nxt;
    while(!all_btrans_match(s, s1))
      s1 = s1->nxt;
    if(s1 != bstates) { /* s and s1 are equivalent */
      free_btrans(s->trans->nxt, s->trans, 1);
      s->trans = (BTrans *)0;
      s->prv = s1;
      s->nxt = bremoved->nxt;
      bremoved->nxt = s;
      for(s1 = bremoved->nxt; s1 != bremoved; s1 = s1->nxt)
	if(s1->prv == s)
	  s1->prv = s->prv;
      return;
    }
  }
  s->nxt = bstates->nxt; /* adds the current state to 'bstates' */
  s->prv = bstates;
  s->nxt->prv = s;
  bstates->nxt = s;
  btrans_count += state_trans;
  bstate_count++;
}

/********************************************************************\
|*                  Display of the Buchi automaton                  *|
\********************************************************************/

void print_buchi(BState *s) /* dumps the Buchi automaton */
{
  BTrans *t;
  if(s == bstates) return;

  print_buchi(s->nxt); /* begins with the last state */

  fprintf(tl_out, "state ");
  if(s->id == -1)
    fprintf(tl_out, "init");
  else {
    if(s->final == accept)
      fprintf(tl_out, "accept");
    else
      fprintf(tl_out, "T%i", s->final);
    fprintf(tl_out, "_%i", s->id);
  }
  fprintf(tl_out, "\n");
  for(t = s->trans->nxt; t != s->trans; t = t->nxt) {
    if (empty_set(t->pos, 1) && empty_set(t->neg, 1))
      fprintf(tl_out, "1");
    print_set(t->pos, 1);
    if (!empty_set(t->pos, 1) && !empty_set(t->neg, 1)) fprintf(tl_out, " & ");
    print_set(t->neg, 2);
    fprintf(tl_out, " -> ");
    if(t->to->id == -1) 
      fprintf(tl_out, "init\n");
    else {
      if(t->to->final == accept)
	fprintf(tl_out, "accept");
      else
	fprintf(tl_out, "T%i", t->to->final);
      fprintf(tl_out, "_%i\n", t->to->id);
    }
  }
}

void print_spin_buchi
(FILE * f) {
  BTrans *t;
  BState *s;
  int accept_all = 0, init_count = 0;
  if(bstates->nxt == bstates) { /* empty automaton */
    fprintf(f, "never {\n");
    fprintf(f, "T0_init:\n");
    fprintf(f, "\tfalse;\n");
    fprintf(f, "}\n");
    return;
  }
  if(bstates->nxt->nxt == bstates && bstates->nxt->id == 0) { /* true */
    fprintf(f, "never {\n");
    fprintf(f, "accept_init:\n");
    fprintf(f, "\tif\n");
    fprintf(f, "\t:: (1) -> goto accept_init\n");
    fprintf(f, "\tfi;\n");
    fprintf(f, "}\n");
    return;
  }

  fprintf(f, "never {\n");
  for(s = bstates->prv; s != bstates; s = s->prv) {
    if(s->id == 0) { /* accept_all at the end */
      accept_all = 1;
      continue;
    }
    if(s->final == accept)
      fprintf(f, "accept_");
    else fprintf(f, "T%i_", s->final);
    if(s->id == -1)
      fprintf(f, "init:\n");
    else fprintf(f, "S%i:\n", s->id);
    if(s->trans->nxt == s->trans) {
      fprintf(f, "\tfalse;\n");
      continue;
    }
    fprintf(f, "\tif\n");
    for(t = s->trans->nxt; t != s->trans; t = t->nxt) {
      BTrans *t1;
      fprintf(f, "\t:: (");
      spin_print_set(f, t->pos, t->neg);
      for(t1 = t; t1->nxt != s->trans; )
	if (t1->nxt->to->id == t->to->id &&
	    t1->nxt->to->final == t->to->final) {
	  fprintf(f, ") || (");
	  spin_print_set(f, t1->nxt->pos, t1->nxt->neg);
	  t1->nxt = t1->nxt->nxt;
	}
	else  t1 = t1->nxt;
      fprintf(f, ") -> goto ");
      if(t->to->final == accept)
	fprintf(f, "accept_");
      else fprintf(f, "T%i_", t->to->final);
      if(t->to->id == 0)
	fprintf(f, "all\n");
      else if(t->to->id == -1)
	fprintf(f, "init\n");
      else fprintf(f, "S%i\n", t->to->id);
    }
    fprintf(f, "\tfi;\n");
  }
  if(accept_all) {
    fprintf(f, "accept_all:\n");
    fprintf(f, "\tskip\n");
  }
  fprintf(f, "}\n");
}

unsigned int char_width
(unsigned int n) {
  unsigned int result = 0;
  while (n) {
    n = n >> 1;
    result ++;
  }
  return (result >> 3) + ((result & 7) ? 1 : 0);
}

void print_C_buchi(FILE * f) {
  char fst;
  BTrans *t;
  BState *s;
  int accept_all = 0, init_count = 0, n;
  if (0) {
  if(bstates->nxt == bstates) { /* empty automaton */
    fprintf(f, "never {\n");
    fprintf(f, "T0_init:\n");
    fprintf(f, "\tfalse;\n");
    fprintf(f, "}\n");
    return;
  }
  if(bstates->nxt->nxt == bstates && bstates->nxt->id == 0) { /* true */
    fprintf(f, "never {\n");
    fprintf(f, "accept_init:\n");
    fprintf(f, "\tif\n");
    fprintf(f, "\t:: (1) -> goto accept_init\n");
    fprintf(f, "\tfi;\n");
    fprintf(f, "}\n");
    return;
  }
  }
  /*
   *  definition of all possible states
   */
  fprintf (f, "\n\n");
  n = 0;
  for(s = bstates->prv; s != bstates; s = s->prv) {
    fprintf (f, "#define ");
    if(s->final == accept) fprintf(f, "BSTATE_ACCEPT_");
    else fprintf(f, "T%i_", s->final);
    if(s->id == -1) fprintf(f, "INIT %d\n", n);
    else fprintf(f, "S%i %d\n", s->id, n);
    n ++;
  }
  fprintf(f, "#define BSTATE_ACCEPT_ALL %d\n", n);
  if(bstates->nxt == bstates) {
    fprintf(f, "#define BSTATE_DUMMY 1\n");
  }
  n ++;

  fprintf (f, "\nunsigned int bstate_char_width () {\n");
  fprintf (f, "   return %d;\n", char_width (n));
  fprintf (f, "}\n");

  fprintf (f, "\norder_t bevent_cmp\n");
  fprintf (f, "(bevent_t e,\n");
  fprintf (f, " bevent_t f) {\n");
  fprintf (f, "   if (e.from < f.from) return LESS;\n");
  fprintf (f, "   if (e.from > f.from) return GREATER;\n");
  fprintf (f, "   if (e.to < f.to)     return LESS;\n");
  fprintf (f, "   if (e.to > f.to)     return GREATER;\n");
  fprintf (f, "   return EQUAL;\n");
  fprintf (f, "}\n");
  
  /*
   *  compile function returning the initial state
   */
  fprintf (f, "\nbstate_t bstate_initial () {\n");
  fprintf (f, "   return ");
  if(bstates->nxt == bstates) {
    fprintf(f, "BSTATE_DUMMY;\n");
  } else {
    for(s = bstates->prv; s != bstates; s = s->prv) {
      if(s->id == -1) {
	if(s->final == accept) fprintf(f, "BSTATE_ACCEPT_");
	else fprintf(f, "T%i_", s->final);
	if(s->id == -1) fprintf(f, "INIT;\n");
	else fprintf(f, "S%i;\n", s->id);
      }
    }
  }
  fprintf (f, "}\n\n");
  
  /*
   *  compile function checking if buchi state is accepting
   */
  fprintf (f, "bool_t bstate_accepting (\n");
  fprintf (f, "   bstate_t b) {\n");
  fprintf (f, "   return (b == BSTATE_ACCEPT_ALL)");
  if(bstates->nxt == bstates) {
    fprintf(f, "&& 0;\n");
  } else {
    for(s = bstates->prv; s != bstates; s = s->prv) {
      if(s->id == 0 || s->final == accept) {
	if(s->final == accept) {
	  fprintf(f, "\n       || (b == BSTATE_ACCEPT_");
	  if(s->id == -1) fprintf(f, "INIT);\n");
	  else fprintf(f, "S%i);\n", s->id);
	}
      }
    }
  }
  fprintf (f, "}\n\n");

  /*
   *  compile function computing successor states
   */
  fprintf(f, "void bstate_succs\n");
  fprintf(f, "(bstate_t b,\n");
  fprintf(f, " mstate_t s,\n");
  fprintf(f, " bstate_t * succs,\n");
  fprintf(f, " unsigned int * no_succs) {\n");
  fprintf(f, "   *no_succs = 0;\n");
  if(bstates->nxt == bstates) {
    fprintf(f, "return;\n");
  }
  fprintf(f, "   switch (b) {\n");
  for(s = bstates->prv; s != bstates; s = s->prv) {
    if (s->id == 0) {
      continue;
    }
    fprintf(f, "   case ");
    if(s->final == accept) fprintf(f, "BSTATE_ACCEPT_");
    else fprintf(f, "T%i_", s->final);
    if(s->id == -1) fprintf(f, "INIT: \n");
    else fprintf(f, "S%i: \n", s->id);
    if(s->trans->nxt == s->trans) {
      fprintf(f, "      break;\n");
      continue;
    }
    for(t = s->trans->nxt; t != s->trans; t = t->nxt) {
      BTrans *t1;
      fprintf(f, "      if (");
      C_print_set(f, t->pos, t->neg);
      for(t1 = t; t1->nxt != s->trans; )
	if (t1->nxt->to->id == t->to->id &&
	    t1->nxt->to->final == t->to->final) {
	  fprintf(f, ") || (");
	  C_print_set(f, t1->nxt->pos, t1->nxt->neg);
	  t1->nxt = t1->nxt->nxt;
	}
	else  t1 = t1->nxt;
      fprintf(f, ") {\n");
      fprintf(f, "         succs[*no_succs] = ");
      if(t->to->final == accept) {
	fprintf(f, "BSTATE_ACCEPT_");
      } else {
	fprintf(f, "T%i_", t->to->final);
      }
      if(t->to->id == 0) fprintf(f, "ALL;\n");
      else if(t->to->id == -1) fprintf(f, "INIT;\n");
      else fprintf(f, "S%i;\n", t->to->id);
      fprintf (f, "         (*no_succs) ++;\n");
      fprintf (f, "      }\n");
    }
    fprintf(f, "      break;\n");
  }
  fprintf (f, "   case BSTATE_ACCEPT_ALL:\n");
  fprintf (f, "      succs[*no_succs] = BSTATE_ACCEPT_ALL;\n");
  fprintf (f, "      *no_succs = 1;\n");
  fprintf (f, "      break;\n");
  fprintf (f, "   default:\n");
  fprintf (f, "      fatal_error (\"bstate_succs: undefined buchi state\");\n");
  fprintf (f, "      break;\n");
  fprintf(f, "   }\n");
  fprintf(f, "}\n");
}

/********************************************************************\
|*                       Main method                                *|
\********************************************************************/

void mk_buchi() 
{/* generates a Buchi automaton from the generalized Buchi automaton */
  int i;
  BState *s = (BState *)tl_emalloc(sizeof(BState));
  GTrans *t;
  BTrans *t1;
  accept = final[0] - 1;
  
  if(tl_stats) getrusage(RUSAGE_SELF, &tr_debut);

  bstack        = (BState *)tl_emalloc(sizeof(BState)); /* sentinel */
  bstack->nxt   = bstack;
  bremoved      = (BState *)tl_emalloc(sizeof(BState)); /* sentinel */
  bremoved->nxt = bremoved;
  bstates       = (BState *)tl_emalloc(sizeof(BState)); /* sentinel */
  bstates->nxt  = s;
  bstates->prv  = s;

  s->nxt        = bstates; /* creates (unique) inital state */
  s->prv        = bstates;
  s->id = -1;
  s->incoming = 1;
  s->final = 0;
  s->gstate = 0;
  s->trans = emalloc_btrans(); /* sentinel */
  s->trans->nxt = s->trans;
  for(i = 0; i < init_size; i++) 
    if(init[i])
      for(t = init[i]->trans->nxt; t != init[i]->trans; t = t->nxt) {
	int fin = next_final(t->final, 0);
	BState *to = find_bstate(&t->to, fin, s);
	for(t1 = s->trans->nxt; t1 != s->trans;) {
	  if(tl_simp_fly && 
	     (to == t1->to) &&
	     included_set(t->pos, t1->pos, 1) &&
	     included_set(t->neg, t1->neg, 1)) { /* t1 is redondant */
	    BTrans *free = t1->nxt;
	    t1->to->incoming--;
	    t1->to = free->to;
	    copy_set(free->pos, t1->pos, 1);
	    copy_set(free->neg, t1->neg, 1);
	    t1->nxt   = free->nxt;
	    if(free == s->trans) s->trans = t1;
	    free_btrans(free, 0, 0);
	  }
	else if(tl_simp_fly &&
		(t1->to == to ) &&
		included_set(t1->pos, t->pos, 1) &&
		included_set(t1->neg, t->neg, 1)) /* t is redondant */
	  break;
	  else
	    t1 = t1->nxt;
	}
	if(t1 == s->trans) {
	  BTrans *trans = emalloc_btrans();
	  trans->to = to;
	  trans->to->incoming++;
	  copy_set(t->pos, trans->pos, 1);
	  copy_set(t->neg, trans->neg, 1);
	  trans->nxt = s->trans->nxt;
	  s->trans->nxt = trans;
	}
      }
  
  while(bstack->nxt != bstack) { /* solves all states in the stack until it is empty */
    s = bstack->nxt;
    bstack->nxt = bstack->nxt->nxt;
    if(!s->incoming) {
      free_bstate(s);
      continue;
    }
    make_btrans(s);
  }

  retarget_all_btrans();

  if(tl_stats) {
    getrusage(RUSAGE_SELF, &tr_fin);
    timeval_subtract (&t_diff, &tr_fin.ru_utime, &tr_debut.ru_utime);
    fprintf(tl_out, "\nBuilding the Buchi automaton : %i.%06is",
		t_diff.tv_sec, t_diff.tv_usec);
    fprintf(tl_out, "\n%i states, %i transitions\n", bstate_count, btrans_count);
  }

  if(tl_verbose) {
    fprintf(tl_out, "\nBuchi automaton before simplification\n");
    print_buchi(bstates->nxt);
    if(bstates == bstates->nxt) 
      fprintf(tl_out, "empty automaton, refuses all words\n");  
  }

  if(tl_simp_diff) {
    simplify_btrans();
    if(tl_simp_scc) simplify_bscc();
    while(simplify_bstates()) { /* simplifies as much as possible */
      simplify_btrans();
      if(tl_simp_scc) simplify_bscc();
    }
    
    if(tl_verbose) {
      fprintf(tl_out, "\nBuchi automaton after simplification\n");
      print_buchi(bstates->nxt);
      if(bstates == bstates->nxt) 
	fprintf(tl_out, "empty automaton, refuses all words\n");
      fprintf(tl_out, "\n");
    }
  }
  {
    char file[256];
    FILE * f;
    sprintf (file, "%s/buchi.c", out_dir);
    f = fopen (file, "w");
    fprintf (f, "#include \"buchi.h\"\n");
    fprintf (f, "#include \"model.h\"\n\n");
    fprintf (f, "/*\n\n");
    print_spin_buchi (f);
    fprintf (f, "\n\n*/\n\n");
    print_C_buchi(f);
    fclose (f);
  }
}
