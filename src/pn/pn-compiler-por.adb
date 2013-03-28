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

   procedure Gen_Compute_Stubborn_Set_Func
     (N  : in Net;
      Lib: in Library) is
      Prototype: constant String :=
        "void mstate_stubborn_set (" & Nl &
        "   mstate_t s," & Nl &
        "   mevent_set_t en)";
   begin
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      if not With_Priority(N) then
	 Plc(Lib, 1, "mevent_list_t tmp, tmp2, tmp3, * last;");
	 Plc(Lib, 1, "bool_t ok;");
	 Plc(Lib, 1, "unsigned int size, set;");
	 Nlc(Lib);

	 --===
	 --  first check if there is an enabled transition which is
	 --    1 - statically safe
	 --    2 - invisible
	 --  the singleton composed of this transition is a valid stubborn set
	 --===
	 Plc(Lib, 1, "for (tmp = en->first; tmp; tmp = tmp->next) {");
	 Plc(Lib, 2, "if (TRANS_ID_is_safe (tmp->e.tid) && " &
	       "!TRANS_ID_is_visible (tmp->e.tid)) {");
	 Plc(Lib, 3, "for (tmp2 = en->first; tmp2; tmp2 = tmp3) {");
	 Plc(Lib, 4, "tmp3 = tmp2->next;");
	 Plc(Lib, 4, "if (tmp != tmp2) {");
	 Plc(Lib, 5, "mevent_free_mem (tmp2->e, en->heap);");
	 Plc(Lib, 5, "mem_free (en->heap, tmp2);");
	 Plc(Lib, 4, "}");
	 Plc(Lib, 3, "}");
	 Plc(Lib, 3, "tmp->next = NULL;");
	 Plc(Lib, 3, "en->first = tmp;");
	 Plc(Lib, 3, "en->size  = 1;");
	 Plc(Lib, 3, "return;");
	 Plc(Lib, 2, "}");
	 Plc(Lib, 1, "}");

	 --===
	 --  otherwise check if there is a safe set of invisible transitions
	 --===
	 Plc(Lib, 1, "for (tmp = en->first; tmp; tmp = tmp->next) {");
	 Plc(Lib, 2, "if (TRANS_ID_safe_set (tmp->e.tid) > 0 && " &
	       "!TRANS_ID_is_visible (tmp->e.tid)) {");
	 Plc(Lib, 3, "ok  = TRUE;");
	 Plc(Lib, 3, "set = TRANS_ID_safe_set (tmp->e.tid);");
	 Plc(Lib, 3, "for (tmp2 = en->first; tmp2; tmp2 = tmp2->next) {");
	 Plc(Lib, 4, "if (TRANS_ID_safe_set (tmp2->e.tid) == set && " &
	       "TRANS_ID_is_visible (tmp2->e.tid)) {");
	 Plc(Lib, 5, "ok = FALSE;");
	 Plc(Lib, 4, "}");
	 Plc(Lib, 3, "}");
	 Plc(Lib, 3, "if (ok) {");
	 Plc(Lib, 4, "last = &(en->first);");
	 Plc(Lib, 4, "size = 0;");
	 Plc(Lib, 4, "for (tmp2 = en->first; tmp2; tmp2 = tmp3) {");
	 Plc(Lib, 5, "tmp3 = tmp2->next;");
	 Plc(Lib, 5, "if (TRANS_ID_safe_set (tmp2->e.tid) != set) {");
	 Plc(Lib, 6, "mevent_free_mem (tmp2->e, en->heap);");
	 Plc(Lib, 6, "mem_free (en->heap, tmp2);");
	 Plc(Lib, 5, "} else {");
	 Plc(Lib, 6, "size ++;");
	 Plc(Lib, 6, "*last = tmp2;");
	 Plc(Lib, 6, "last = &(tmp2->next);");
	 Plc(Lib, 5, "}");
	 Plc(Lib, 4, "}");
	 Plc(Lib, 4, "*last = NULL;");
	 Plc(Lib, 4, "en->size = size;");
	 Plc(Lib, 4, "return;");
	 Plc(Lib, 3, "}");
	 Plc(Lib, 2, "}");
	 Plc(Lib, 1, "}");
      end if;
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
      Gen_Compute_Stubborn_Set_Func(N, Lib);
      Gen_Lib_Init_Func;
      Gen_Lib_Free_Func;
      End_Library(Lib);
   end;

end Pn.Compiler.Por;
