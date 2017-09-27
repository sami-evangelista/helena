with
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Compiler.Config,
  Pn.Compiler.Domains,
  Pn.Compiler.Event,
  Pn.Compiler.State,
  Pn.Compiler.Util,
  Pn.Nodes,
  Pn.Vars;

use
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Compiler.Config,
  Pn.Compiler.Domains,
  Pn.Compiler.Event,
  Pn.Compiler.State,
  Pn.Compiler.Util,
  Pn.Nodes,
  Pn.Vars;

package body Pn.Compiler.Por is

   procedure Gen_Compute_Reduced_Set_Func
     (N  : in Net;
      Lib: in Library) is
      Prototype: Ustring;
   begin
      Prototype := To_Ustring
        ("list_t mstate_events_reduced_mem" & Nl &
           "(mstate_t s," & Nl &
           " bool_t * reduced," & Nl &
           " heap_t heap)");
      Plh(Lib, Prototype & ";");
      Plc(Lib, "char is_safe_and_invisible(void * item, void * data) {");
      Plc(Lib, 1, "mevent_t e = * (mevent_t *) item;");
      Plc(Lib, 1, "if(TRANS_ID_is_safe(e.tid) && " &
	    "!TRANS_ID_is_visible(e.tid)) { return TRUE; }");
      Plc(Lib, 1, "else { return FALSE; }");
      Plc(Lib, "}");
      Plc(Lib, "char is_not_id(void * item, void * data) {");
      Plc(Lib, 1, "mevent_t e = * (mevent_t *) item;");
      Plc(Lib, 1, "mevent_id_t id = * (mevent_id_t *) data;");
      Plc(Lib, 1, "if(e.id != id) { return TRUE; }");
      Plc(Lib, 1, "else { return FALSE; }");
      Plc(Lib, "}");
      Plc(Lib, "char in_set_and_invisible(void * item, void * data) {");
      Plc(Lib, 1, "mevent_t e = * (mevent_t *) item;");
      Plc(Lib, 1, "if(TRANS_ID_safe_set(e.tid) > 0 && " &
	    "!TRANS_ID_is_visible(e.tid)) { return TRUE; }");
      Plc(Lib, 1, "else { return FALSE; }");
      Plc(Lib, "}");
      Plc(Lib, "char in_set_and_visible(void * item, void * data) {");
      Plc(Lib, 1, "mevent_t e = * (mevent_t *) item;");
      Plc(Lib, 1, "unsigned int set = * (unsigned int *) data;");
      Plc(Lib, 1, "if(TRANS_ID_safe_set(e.tid) == set && " &
	    "TRANS_ID_is_visible(e.tid)) { return TRUE; }");
      Plc(Lib, 1, "else { return FALSE; }");
      Plc(Lib, "}");
      Plc(Lib, "char is_not_in_set(void * item, void * data) {");
      Plc(Lib, 1, "mevent_t e = * (mevent_t *) item;");
      Plc(Lib, 1, "unsigned int set = * (unsigned int *) data;");
      Plc(Lib, 1, "if(TRANS_ID_safe_set(e.tid) != set) { return TRUE; }");
      Plc(Lib, 1, "else { return FALSE; }");
      Plc(Lib, "}");

      Plc(Lib, Prototype & " {");
      if With_Priority(N) then
	 Plc(Lib, 1, "*reduced = FALSE;");
	 Plc(Lib, 1, "return mstate_events_mem(s, heap);");
      else
	 Plc(Lib, 1, "mevent_t e;");
	 Plc(Lib, 1, "void * data;");
	 Plc(Lib, 1, "unsigned int set;");
	 Plc(Lib, 1, "list_t result = mstate_events_mem(s, heap);");
	 Plc(Lib, 1, "const list_size_t len = list_size(result);");
	 Plc(Lib, 1, "list_size_t len_reduced;");

	 --===
	 --  first check if there is an enabled transition which is
	 --    1 - statically safe
	 --    2 - invisible
	 --  the singleton composed of this transition is a valid reduced set
	 --===
	 Plc(Lib, 1,
             "if(data = list_find(result, is_safe_and_invisible, NULL)) {");
	 Plc(Lib, 2, "e = * (mevent_t *) data;");
	 Plc(Lib, 2, "list_filter(result, is_not_id, &e.id);");
	 Plc(Lib, 1, "} else {");

	 --===
	 --  otherwise check if there is a safe set of invisible transitions
	 --===
	 Plc(Lib, 2,
             "if(data = list_find(result, in_set_and_invisible, NULL)) {");
	 Plc(Lib, 3, "e = * (mevent_t *) data;");
	 Plc(Lib, 3, "set = TRANS_ID_safe_set(e.tid);");
	 Plc(Lib, 3, "data = &set;");
	 Plc(Lib, 3,
             "if(NULL == list_find(result, in_set_and_visible, data)) {");
	 Plc(Lib, 4, "list_filter(result, is_not_in_set, data);");
	 Plc(Lib, 3, "}");
	 Plc(Lib, 2, "}");
	 Plc(Lib, 1, "}");
	 Plc(Lib, 1, "len_reduced = list_size(result);");
	 Plc(Lib, 1, "if(len_reduced != len) { *reduced = TRUE; }");
	 Plc(Lib, 1, "else { *reduced = FALSE; }");
	 Plc(Lib, 1, "return result;");
      end if;
      Plc(Lib, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("list_t mstate_events_reduced" & Nl &
           "(mstate_t s," & Nl &
           " bool_t * reduced)");
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1,
          "return mstate_events_reduced_mem(s, reduced, SYSTEM_HEAP);");
      Plc(Lib, "}");
   end;



   --==========================================================================
   --  main generation procedure
   --==========================================================================

   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      Lib    : Library;
      Comment: constant String :=
        "This library implements the partial order algorithm of Helena.";

      procedure Gen_Lib_Init_Func is
         Prototype: constant Ustring :=
           "void " & Lib_Init_Func(Por_Lib) & Nl & "()";
      begin
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype & " {}");
      end;

      procedure Gen_Lib_Free_Func is
         Prototype: constant Ustring :=
           "void " & Lib_Free_Func(Por_Lib) & Nl & "()";
      begin
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype & " {}");
      end;

   begin
      Init_Library(Por_Lib, To_Ustring(Comment), Path, Lib);
      Plh(Lib, "#include ""model.h""");
      Gen_Compute_Reduced_Set_Func(N, Lib);
      Gen_Lib_Init_Func;
      Gen_Lib_Free_Func;
      End_Library(Lib);
   end;

end Pn.Compiler.Por;
