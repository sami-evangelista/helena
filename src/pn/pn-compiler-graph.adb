with
  Pn.Compiler.State,
  Pn.Compiler.Util,
  Pn.Nodes;

use
  Pn.Compiler.State,
  Pn.Compiler.Util,
  Pn.Nodes;

package body Pn.Compiler.Graph is

   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      L        : Library;
      P        : Place;
      T        : Trans;
      Comment  : constant String :=
	"This library implements model-specific graph routines.";
      Prototype: Ustring;
      C        : Ustring;
   begin
      Init_Library(Graph_Lib, To_Ustring(Comment), Path, L);
      Plh(L, "#include ""graph.h""");
      Plh(L, "#include ""model.h""");
      Plh(L, "#include ""htbl.h""");
      Plh(L, "#include ""config.h""");
      Plh(L, "#include ""hash_array.h""");
      Plh(L, "#include ""htbl.h""");
      Nlh(L);
      Plh(L, "#define MAX_DEAD 10");
      --=======================================================================
      Plh(L, "typedef struct {");
      Plh(L, 1, "bool_t   bit;");
      Plh(L, 1, "mevent_t e;");
      Plh(L, "} struct_ptr_mevent_t;");
      Plh(L, "typedef struct_ptr_mevent_t * ptr_mevent_t;");
      Plc(L, "harray_key_t ptr_mevent_hash (harray_value_t e) {");
      Plc(L, 1, "return mevent_hash (((ptr_mevent_t) e)->e);");
      Plc(L, "}");
      Plc(L, "order_t ptr_mevent_cmp (harray_value_t e, harray_value_t f) {");
      Plc(L, 1, "return mevent_cmp (((ptr_mevent_t) e)->e, " &
	    "((ptr_mevent_t) f)->e);");
      Plc(L, "}");
      Plc(L, "void ptr_mevent_free (harray_value_t e) {");
      Plc(L, 1, "mevent_free (((ptr_mevent_t) e)->e);");
      Plc(L, 1, "mem_free (SYSTEM_HEAP, e);");
      Plc(L, "}");
      Plc(L, "void ptr_mevent_to_xml (harray_key_t k, harray_value_t e," &
	    " harray_iter_data_t data) {");
      Plc(L, 1, "mevent_t ev = ((ptr_mevent_t) e)->e;");
      Plc(L, 1, "model_graph_data_t mg_data = (model_graph_data_t) data;");
      Plc(L, 1, "if (ev.tid == mg_data->current_tid) {");
      Plc(L, 2, "mevent_to_xml_aux (ev, TRUE, mg_data->out);");
      Plc(L, 1, "}");
      Plc(L, "}");
      Plc(L, "void ptr_mevent_qlive_to_xml (harray_key_t k," &
	    " harray_value_t e, harray_iter_data_t data) {");
      Plc(L, 1, "ptr_mevent_t p = (ptr_mevent_t) e;");
      Plc(L, 1, "mevent_t ev = p->e;");
      Plc(L, 1, "model_graph_data_t mg_data = (model_graph_data_t) data;");
      Plc(L, 1, "if (ev.tid == mg_data->current_tid && " &
	    " NULL == harray_lookup (mg_data->live_events, (void *) p)) {");
      Plc(L, 2, "mevent_to_xml_aux (ev, TRUE, mg_data->out);");
      Plc(L, 1, "}");
      Plc(L, "}");
      Plc(L, "bool_t ptr_mevent_pred (harray_key_t k, harray_value_t e," &
	    " harray_iter_data_t data) {");
      Plc(L, 1, "ptr_mevent_t p = (ptr_mevent_t) e;");
      Plc(L, 1, "model_graph_data_t mg_data = (model_graph_data_t) data;");
      Plc(L, 1, "return (p->bit == mg_data->alt_bit) ? TRUE : FALSE;");
      Plc(L, "}");
      --=======================================================================
      Plh(L, "typedef struct {");
      Plh(L, 1, "FILE * out;");
      Plh(L, 1, "mstate_t now;");
      Plh(L, 1, "mstate_t proj;");
      Plh(L, 1, "mstate_t all;");
      Plh(L, 1, "int64_t top;");
      Plh(L, 1, "mevent_t * stack;");
      Plh(L, 1, "htbl_t tbl;");
      Plh(L, 1, "bool_t in_terminal;");
      Plh(L, 1, "bool_t alt_bit;");
      Plh(L, 1, "mstate_t dead[MAX_DEAD];");
      Plh(L, 1, "uint32_t no_dead;");
      Plh(L, 1, "uint32_t terminals;");
      Plh(L, 1, "harray_t qlive_events;");
      Plh(L, 1, "harray_t live_events;");
      Plh(L, 1, "uint32_t min_card[" & P_Size(N) & "];");
      Plh(L, 1, "uint32_t max_card[" & P_Size(N) & "];");
      Plh(L, 1, "uint32_t min_mult[" & P_Size(N) & "];");
      Plh(L, 1, "uint32_t max_mult[" & P_Size(N) & "];");
      Plh(L, 1, "tr_id_t current_tid;");
      Plh(L, "} struct_model_graph_data_t;");
      Plh(L, "typedef struct_model_graph_data_t * model_graph_data_t;");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_data_init (" & Nl &
	   "   model_graph_data_t * data," & Nl &
	   "   uint32_t no_states)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "(*data) = mem_alloc (SYSTEM_HEAP, " &
	    "sizeof (struct_model_graph_data_t));");
      Plc(L, 1, "(*data)->stack = mem_alloc (SYSTEM_HEAP, " &
	    "sizeof (mevent_t) * no_states);");
      Pc(L, 1, "(*data)->tbl = htbl_new");
      Plc(L, "(TRUE, 4194304, 1, FALSE, 0);");
      Plc(L, 1, "mstate_init ((*data)->all, SYSTEM_HEAP);");
      Plc(L, 1, "(*data)->qlive_events = harray_new " &
	    "(SYSTEM_HEAP, 1000000, ptr_mevent_hash," &
	    " ptr_mevent_cmp, ptr_mevent_free);");
      Plc(L, 1, "(*data)->live_events = harray_new " &
	    "(SYSTEM_HEAP, 1000000, ptr_mevent_hash," &
	    " ptr_mevent_cmp, ptr_mevent_free);");
      for I in 1..P_Size(N) loop
	 P := Ith_Place(N, I);
	 Plc(L, 1, "(*data)->min_card[" & Pid(P) & "] = UINT_MAX;");
	 Plc(L, 1, "(*data)->max_card[" & Pid(P) & "] = 0;");
	 Plc(L, 1, "(*data)->min_mult[" & Pid(P) & "] = UINT_MAX;");
	 Plc(L, 1, "(*data)->max_mult[" & Pid(P) & "] = 0;");
      end loop;
      Plc(L, 1, "(*data)->no_dead = 0;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_data_free" & Nl &
	   "(model_graph_data_t * data)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "unsigned int i;");
      Plc(L, 1, "mstate_free ((*data)->all);");
      Plc(L, 1, "htbl_free ((*data)->tbl);");
      Plc(L, 1, "harray_free ((*data)->qlive_events);");
      Plc(L, 1, "harray_free ((*data)->live_events);");
      Plc(L, 1, "mem_free (SYSTEM_HEAP, (*data)->stack);");
      Plc(L, 1, "for (i = 0; i < (*data)->no_dead && i < MAX_DEAD; i ++) {");
      Plc(L, 2, "mstate_free ((*data)->dead[i]);");
      Plc(L, 1, "}");
      Plc(L, 1, "mem_free (SYSTEM_HEAP, *data);");
      Plc(L, 1, "*data = NULL;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_data_output" & Nl &
	   "(model_graph_data_t data," & Nl &
	   " FILE *             out)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "unsigned int i;");
      Plc(L, 1, "data->out = out;");
      Plc(L, 1, "fprintf(out, ""<model-info>"");");
      Plc(L, 1, "fprintf(out, ""<placeBounds>"");");
      for I in 1..P_Size(N) loop
	 P := Ith_Place(N, I);
	 Plc(L, 1, "fprintf(out, ""<placeBound>"");");
         Plc(L, 1, "fprintf(out, ""<place>" & Get_Name(P) & "</place>"");");
         Plc(L, 1, "fprintf(out, ""<minCard>%d</minCard>"", " &
	       "data->min_card[" & Pid(P) & "]);");
         Plc(L, 1, "fprintf(out, ""<maxCard>%d</maxCard>"", " &
	       "data->max_card[" & Pid(P) & "]);");
         Plc(L, 1, "fprintf(out, ""<minMult>%d</minMult>"", " &
	       "data->min_mult[" & Pid(P) & "]);");
         Plc(L, 1, "fprintf(out, ""<maxMult>%d</maxMult>"", " &
	       "data->max_mult[" & Pid(P) & "]);");
	 Plc(L, 1, "fprintf(out, ""</placeBound>"");");
      end loop;
      Plc(L, 1, "fprintf(out, ""</placeBounds>"");");
      Plc(L, 1, "fprintf(out, ""<possibleTokens>"");");
      for I in 1..P_Size(N) loop
	 P := Ith_Place(N, I);
	 C := State_Component_Name(P);
         Plc(L, 1, "fprintf(out, ""<possibleTokensPlace>"");");
         Plc(L, 1, "fprintf(out, ""<place>" & Get_Name(P) & "</place>"");");
	 Plc(L, 1, Local_State_To_Xml_Func(P) &
	       "(data->all->" & C & ", out);");
         Plc(L, 1, "fprintf(out, ""</possibleTokensPlace>"");");
      end loop;
      Plc(L, 1, "fprintf(out, ""</possibleTokens>"");");
      Plc(L, 1, "fprintf(out, ""<deadMarkings>"");");
      Plc(L, 1, "fprintf(out, ""<noDeadMarkings>%d</noDeadMarkings>""," &
	    " data->no_dead);");
      Plc(L, 1, "for (i = 0; i < data->no_dead && i < MAX_DEAD; i ++) {");
      Plc(L, 2, "mstate_to_xml (data->dead[i], out);");
      Plc(L, 1, "}");
      Plc(L, 1, "fprintf(out, ""</deadMarkings>"");");
      Plc(L, 1, "fprintf(out, ""<livenessInfo>"");");
      for I in 1..T_Size(N) loop
	 T := Ith_Trans(N, I);
	 Plc(L, 1, "data->current_tid = " & Tid(T) & ";");
	 Plc(L, 1, "fprintf(out, ""<livenessInfoTrans>"");");
         Plc(L, 1, "fprintf(out, ""<transition>" & Get_Name(T) &
	       "</transition>"");");
	 Plc(L, 1, "fprintf(out, ""<liveBindings>"");");
	 Plc(L, 1, "harray_app" &
	       " (data->live_events, ptr_mevent_to_xml, data);");
	 Plc(L, 1, "fprintf(out, ""</liveBindings>"");");
	 Plc(L, 1, "fprintf(out, ""<quasiLiveBindings>"");");
	 Plc(L, 1, "harray_app" &
	       " (data->qlive_events, ptr_mevent_qlive_to_xml, data);");
	 Plc(L, 1, "fprintf(out, ""</quasiLiveBindings>"");");
	 Plc(L, 1, "fprintf(out, ""</livenessInfoTrans>"");");
      end loop;
      Plc(L, 1, "fprintf(out, ""</livenessInfo>"");");
      Plc(L, 1, "fprintf(out, ""</model-info>"");");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_dfs_start" & Nl &
	   "(model_graph_data_t data)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "data->now = mstate_initial ();");
      Plc(L, 1, "data->top = -1;");
      Plc(L, 1, "mstate_init (data->proj, SYSTEM_HEAP);");
      Plc(L, 1, "model_graph_handle_state (data, data->now);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_fold" & Nl &
	   "(mstate_t s," & Nl &
	   " htbl_id_t id," & Nl &
	   " void * data)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "model_graph_data_t dfs_data = (model_graph_data_t) data;");
      Plc(L, 1, "mstate_union (dfs_data->all, s);");
      Plc(L, "}");
      Prototype := To_Ustring
	("void model_graph_dfs_stop" & Nl &
	   "(model_graph_data_t data)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mstate_free (data->now);");
      Plc(L, 1, "mstate_free (data->proj);");
      Plc(L, "#if CFG_ACTION_BUILD_GRAPH == 1");
      Plc(L, 1, "htbl_fold (data->tbl, " &
	    "&model_graph_fold, (void *) data);");
      Plc(L, "#endif");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_dfs_push" & Nl &
	   "(model_graph_data_t data," & Nl &
	   " edge_num_t         num," & Nl &
	   " bool_t             new_succ)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "ptr_mevent_t pe;");
      Plc(L, 1, "mevent_t e = mstate_event (data->now, num);");
      Plc(L, 1, "pe = mem_alloc (SYSTEM_HEAP, sizeof (struct_ptr_mevent_t));");
      Plc(L, 1, "pe->bit = 0;");
      Plc(L, 1, "pe->e = mevent_copy_mem (e, SYSTEM_HEAP);");
      Plc(L, 1, "if (!harray_insert (data->qlive_events, (void *) pe)) {");
      Plc(L, 2, "ptr_mevent_free (pe);");
      Plc(L, 1, "}");
      Plc(L, 1, "if (!new_succ) {");
      Plc(L, 2, "mevent_free(e);");
      Plc(L, 1, "} else {");
      Plc(L, 2, "data->top ++;");
      Plc(L, 2, "data->stack[data->top] = e;");
      Plc(L, 2, "mevent_exec (e, data->now);");
      Plc(L, 2, "model_graph_handle_state (data, data->now);");
      Plc(L, 1, "}");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_dfs_pop" & Nl &
	   "(model_graph_data_t data)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_t e = data->stack[data->top];");
      Plc(L, 1, "mevent_undo (e, data->now);");
      Plc(L, 1, "mevent_free (e);");
      Plc(L, 1, "data->top --;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_handle_state" & Nl &
	   "(model_graph_data_t data," & Nl &
	   " mstate_t s)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "hash_key_t h;");
      Plc(L, 1, "bool_t b;");
      Plc(L, 1, "htbl_id_t id;");
      Plc(L, 1, "list_t en = mstate_events(s);");
      Plc(L, 1, "if(list_is_empty(en)) {");
      Plc(L, 2, "if(data->no_dead < MAX_DEAD) {");
      Plc(L, 3, "data->dead[data->no_dead] = mstate_copy (s);");
      Plc(L, 2, "}");
      Plc(L, 2, "data->no_dead ++;");
      Plc(L, 1, "}");
      Plc(L, 1, "list_free (en);");
      for I in 1..P_Size(N) loop
	 P := Ith_Place(N, I);
	 C := State_Component_Name(P);
         Plc(L, 1, "data->proj->" & C & ".list = s->" & C & ".list;");
         Plc(L, 1, "data->proj->" & C & ".card = s->" & C & ".card;");
         Plc(L, 1, "data->proj->" & C & ".mult = s->" & C & ".mult;");
         Plc(L, 1, "data->proj->" & C & ".heap = s->" & C & ".heap;");
         Plc(L, "#if CFG_ACTION_BUILD_GRAPH == 1");
	 Plc(L, 1, "htbl_insert(data->tbl, data->proj, " &
	       "0, &b, &id, &h);");
         Plc(L, "#endif");
	 Plc(L, 1, Local_State_Init_Func(P) &
	       "(data->proj->" & C & ", SYSTEM_HEAP);");
	 Plc(L, 1, "if (s->" & C &
	       ".mult < data->min_mult[" & Pid(P) & "]) { " &
	       "data->min_mult[" & Pid(P) & "] = " &
	       "s->" & C & ".mult; }");
	 Plc(L, 1, "if (s->" & C &
	       ".mult > data->max_mult[" & Pid(P) & "]) { " &
	       "data->max_mult[" & Pid(P) & "] = " &
	       "s->" & C & ".mult; }");
	 Plc(L, 1, "if (s->" & C &
	       ".card < data->min_card[" & Pid(P) & "]) { " &
	       "data->min_card[" & Pid(P) & "] = " &
	       "s->" & C & ".card; }");
	 Plc(L, 1, "if (s->" & C &
	       ".card > data->max_card[" & Pid(P) & "]) { " &
	       "data->max_card[" & Pid(P) & "] = " &
	       "s->" & C & ".card; }");
      end loop;
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_scc_dfs_start" & Nl &
	   "(model_graph_data_t data)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "data->in_terminal = FALSE;");
      Plc(L, 1, "data->terminals = 0;");
      Plc(L, 1, "data->now = mstate_initial ();");
      Plc(L, 1, "data->top = -1;");
      Plc(L, 1, "data->alt_bit = FALSE;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_scc_dfs_stop" & Nl &
	   "(model_graph_data_t data)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mstate_free (data->now);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_scc_enter" & Nl &
	   "(model_graph_data_t data," & Nl &
	   " bool_t terminal)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "assert (!data->in_terminal);");
      Plc(L, 1, "if (data->in_terminal = terminal) {");
      Plc(L, 2, "data->terminals ++;");
      Plc(L, 2, "data->alt_bit = (data->alt_bit) ? FALSE : TRUE;");
      Plc(L, 1, "}");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_scc_exit" & Nl &
	   "(model_graph_data_t data)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "if (data->in_terminal) {");
      Plc(L, 2, "harray_filter" &
	    " (data->live_events, ptr_mevent_pred, (void *) data);");
      Plc(L, 1, "}");
      Plc(L, 1, "data->in_terminal = FALSE;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_scc_dfs_push" & Nl &
	   "(model_graph_data_t data," & Nl &
	   " edge_num_t num)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "ptr_mevent_t pe, prev;");
      Plc(L, 1, "mevent_t e = mstate_event (data->now, num);");
      Plc(L, 1, "data->top ++;");
      Plc(L, 1, "data->stack[data->top] = e;");
      Plc(L, 1, "mevent_exec (e, data->now);");
      Plc(L, 1, "if (data->in_terminal) {");
      Plc(L, 2, "pe = mem_alloc (SYSTEM_HEAP, sizeof (struct_ptr_mevent_t));");
      Plc(L, 2, "pe->bit = data->alt_bit;");
      Plc(L, 2, "pe->e = mevent_copy_mem (e, SYSTEM_HEAP);");
      Plc(L, 2, "if (data->terminals == 1) {");
      Plc(L, 3, "if (!harray_insert (data->live_events, (void *) pe)) {");
      Plc(L, 4, "ptr_mevent_free (pe);");
      Plc(L, 3, "}");
      Plc(L, 2, "} else {");
      Plc(L, 3, "prev = harray_lookup (data->live_events, (void *) pe);");
      Plc(L, 3, "ptr_mevent_free (pe);");
      Plc(L, 3, "if (prev != NULL) {");
      Plc(L, 4, "prev->bit = data->alt_bit;");
      Plc(L, 3, "}");
      Plc(L, 2, "}");
      Plc(L, 1, "}");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void model_graph_scc_dfs_pop" & Nl &
	   "(model_graph_data_t data)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_t e = data->stack[data->top];");
      Plc(L, 1, "mevent_undo (e, data->now);");
      Plc(L, 1, "mevent_free (e);");
      Plc(L, 1, "data->top --;");
      Plc(L, "}");
      --=======================================================================
      End_Library(L);
   end;

end;
