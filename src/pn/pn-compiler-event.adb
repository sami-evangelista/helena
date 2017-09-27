with
  Pn.Classes,
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Domains,
  Pn.Compiler.Mappings,
  Pn.Compiler.State,
  Pn.Compiler.Util,
  Pn.Compiler.Names,
  Pn.Guards,
  Pn.Nodes,
  Pn.Vars;

use
  Pn.Classes,
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Domains,
  Pn.Compiler.Mappings,
  Pn.Compiler.State,
  Pn.Compiler.Util,
  Pn.Compiler.Names,
  Pn.Guards,
  Pn.Nodes,
  Pn.Vars;

package body Pn.Compiler.Event is

   function Build_Map
     (T: in Trans;
      C: in String) return Var_Mapping is
      Vars  : constant Var_List := Get_Vars(T);
      Result: Var_Mapping(1 .. Length(Vars));
   begin
      for I in Result'Range loop
         Result(I) := (V    => Ith(Vars, I),
		       Expr => "((" & Trans_Dom_Type(T) & " *) " & C &
			 ") ->" & Dom_Ith_Comp_Name(I));
      end loop;
      return Result;
   end;

   procedure Gen_Let_Vars_Evaluation
     (T   : in Trans;
      L   : in Library;
      Tabs: in Natural;
      C   : in String) is
      Lvars: constant Var_List := Get_Lvars(T);
      Map  : constant Var_Mapping := Build_Map(T, C);
      V    : Var;
   begin
      for I in 1..Length(Lvars) loop
	 V := Ith(Lvars, I);
	 Plc(L, Tabs, Cls_Name(Get_Cls(V)) & " " & Var_Name(V) & " = " &
	       Compile_Evaluation(Get_Init(V), Map) & ";");
      end loop;
   end;

   --  firing function of transition T
   function Trans_Exec_Func
     (T: in Trans;
      F: in Firing_Mode) return Ustring is
      Result: Ustring := Trans_Name(T);
   begin
      case F is
         when Firing   => Result := "exec_" & Result;
         when Unfiring => Result := "undo_" & Result;
      end case;
      return Result;
   end;

   procedure Gen_Trans_Exec_Func
     (T: in Trans;
      N: in Net;
      F: in Firing_Mode;
      L: in Library) is
      Pl       : constant Place_Vector := Get_Places(N);
      Prototype: constant Ustring :=
        "void " & Trans_Exec_Func(T, F) & Nl &
        "(mstate_t s," & Nl &
        " " & Trans_Dom_Type(T) & " * ct)";
      P        : Place;
      Pre_P_T  : Mapping;
      Post_P_T : Mapping;
   begin
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Gen_Let_Vars_Evaluation(T, L, 1, "ct");
      for I in 1..Size(Pl) loop
         P := Ith(Pl, I);
         Pre_P_T := Get_Arc_Label(N, Pre, P, T);
         Post_P_T := Get_Arc_Label(N, Post, P, T);
         if
           (not Is_Empty(Pre_P_T) or not Is_Empty(Post_P_T))
	   and not Static_Equal(Pre_P_T, Post_P_T)
         then
	    case F is
	       when Firing   =>
		  if not Is_Empty(Pre_P_T) then
		     Plc(L, 1, Arc_Mapping_Func(P, T, Pre, Remove) &
			   " (s, (*ct));");
		  end if;
		  if not Is_Empty(Post_P_T) then
		     Plc(L, 1, Arc_Mapping_Func(P, T, Post, Add) &
			   " (s, (*ct));");
		  end if;
	       when Unfiring =>
		  if not Is_Empty(Post_P_T) then
		     Plc(L, 1, Arc_Mapping_Func(P, T, Post, Remove) &
			   " (s, (*ct));");
		  end if;
		  if not Is_Empty(Pre_P_T) then
		     Plc(L, 1, Arc_Mapping_Func(P, T, Pre, Add) &
			   " (s, (*ct));");
		  end if;
	    end case;
	 end if;
      end loop;
      Plc(L, "}");
   end;

   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      Tid_Size : constant Natural := Bit_To_Encode_Tid(N);
      Comment  : constant String := "This library implements events.";
      Prototype: Ustring;
      Id       : Ustring;
      T        : Trans;
      U        : Trans;
      Pre_T    : Place_Vector;
      Pre_U    : Place_Vector;
      Inter    : Place_Vector;
      Vl       : Var_List;
      V        : Var;
      C        : Cls;
      Prio     : Expr;
      El       : Expr_List;
      L        : Library;
      Mode     : Ustring;
      Func_Name: Ustring;
   begin
      Init_Library(Event_Lib, To_Ustring(Comment), Path, L);
      Plh(L, "#include ""domains.h""");
      Plh(L, "#include ""mappings.h""");
      Plh(L, "#include ""mstate.h""");
      --=======================================================================
      Prototype := "void " & Lib_Init_Func(Event_Lib) & Nl & "()";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {}");
      --=======================================================================
      Prototype := "void " & Lib_Free_Func(Event_Lib) & Nl & "()";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {}");
      --=======================================================================
      for I in 1..T_Size(N) loop
         T := Ith_Trans(N, I);
	 for F in Firing_Mode loop
	    Gen_Trans_Exec_Func(T, N, F, L);
	 end loop;
      end loop;
      --=======================================================================
      Plh(L, "typedef uint8_t mevent_id_t;");
      --=======================================================================
      Plh(L, "typedef struct {");
      Plh(L, 1, "mevent_id_t id;");
      Plh(L, 1, "tr_id_t tid;");
      Plh(L, 1, "void * c;");
      Plh(L, 1, "heap_t h;");
      Plh(L, 1, "int priority;");
      Plh(L, "} mevent_t;");
      --=======================================================================
      Prototype := To_Ustring
	("mevent_id_t mevent_id" & Nl &
	   "(mevent_t e)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "return e.id;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void mevent_free (" & Nl &
	   "   mevent_t e)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mem_free(e.h, e.c);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void mevent_free_void" & Nl &
	   "(void * data)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_free(* ((mevent_t *) data));");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("mevent_t mevent_copy_mem (" & Nl &
	   "   mevent_t e," & Nl &
	   "   heap_t  heap)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_t result;");
      Plc(L, 1, "result.tid = e.tid;");
      Plc(L, 1, "result.h = heap;");
      if With_Priority(N) then
	 Plc(L, 1, "result.priority = e.priority;");
      end if;
      Plc(L, 1, "switch (e.tid) {");
      for I in 1..T_Size(N) loop
	 T := Ith_Trans(N, I);
	 Id := Tid(T);
	 Plc(L, 1, "case " & Id & ":");
	 Plc(L, 2, "result.c = (" &
	       Trans_Dom_Type(T) & " *) mem_alloc (heap, sizeof (" &
	       Trans_Dom_Type(T) & "));");
	 Plc(L, 2, "(*(" & Trans_Dom_Type(T) & " *) result.c) ="
	       & "(*(" & Trans_Dom_Type(T) & " *) e.c);");
	 Plc(L, 2, "break;");
      end loop;
      Plc(L, 1, "default: assert(0);");
      Plc(L, 1, "}");
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("mevent_t mevent_copy (" & Nl &
	   "   mevent_t e)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "return mevent_copy_mem (e, SYSTEM_HEAP);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void mevent_compute_priority" & Nl &
	   "(mevent_t * e," & Nl &
	   " mstate_t   prop_state)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "switch (e->tid) {");
      for I in 1..T_Size(N) loop
         T := Ith_Trans(N, I);
         Id := Tid(T);
         Prio := Get_Priority(T);
         Plc(L, 1, "case " & Id & ": {");
         if Prio = No_Priority then
            Plc(L, 2, "e->priority = 0;");
         else
            Gen_Let_Vars_Evaluation(T, L, 2, "e->c");
            Plc(L, 2, "e->priority = " &
                  Compile_Evaluation(Prio, Build_Map(T, "e->c")) & ";");
         end if;
         Plc(L, 2, "break;");
         Plc(L, 1, "}");
      end loop;
      Plc(L, 1, "default: assert(0);");
      Plc(L, 1, "}");
      Plc(L, "}");
      --=======================================================================
      for F in Firing_Mode loop
	 if F = Firing then
	    Mode := To_Ustring("succ");
	 else
	    Mode := To_Ustring("pred");
	 end if;
	 Prototype :=
	   "mstate_t mstate_" & Mode & "_mem" & Nl &
	   "(mstate_t s," & Nl &
	   " mevent_t e," & Nl &
	   " heap_t heap)";
	 Plh(L, Prototype & ";");
	 Plc(L, Prototype & " {");
	 Plc(L, 1, "mstate_t result = mstate_copy_mem (s, heap);");
	 Plc(L, 1, "switch (e.tid) {");
	 for I in 1..T_Size(N) loop
	    T := Ith_Trans(N, I);
	    Id := Tid(T);
	    Plc(L, 1, "case " & Id & ":");
	    Plc(L, 2, Trans_Exec_Func(T, F) & " (result, e.c);");
	    Plc(L, 2, "break;");
	 end loop;
	 Plc(L, 1, "default: assert(0);");
	 Plc(L, 1, "}");
	 Plc(L, 1, "return result;");
	 Plc(L, "}");
	 Prototype :=
	   "mstate_t mstate_" & Mode & " (" & Nl &
	   "   mstate_t s," & Nl &
	   "   mevent_t e)";
	 Plh(L, Prototype & ";");
	 Plc(L, Prototype & " {");
	 Plc(L, 1, "return mstate_" & Mode & "_mem (s, e, SYSTEM_HEAP);");
	 Plc(L, "}");
      end loop;
      --=======================================================================
      for F in Firing_Mode loop
	 if F = Firing then
	    Func_Name := To_Ustring("mevent_exec");
	 else
	    Func_Name := To_Ustring("mevent_undo");
	 end if;
	 Prototype :=
	   "void " & Func_Name & Nl &
	   "(mevent_t e," & Nl &
	   " mstate_t s)";
	 Plh(L, Prototype & ";");
	 Plc(L, Prototype & " {");
	 Plc(L, 1, "switch (e.tid) {");
	 for I in 1..T_Size(N) loop
	    T := Ith_Trans(N, I);
	    Id := Tid(T);
	    Plc(L, 1, "case " & Id & ":");
	    Plc(L, 2, Trans_Exec_Func(T, F) & " (s, e.c);");
	    Plc(L, 2, "break;");
	 end loop;
	 Plc(L, 1, "default: assert(0);");
	 Plc(L, 1, "}");
	 Plc(L, "}");
      end loop;
      --=======================================================================
      Prototype := To_Ustring
	("unsigned int mevent_char_width" & Nl &
	   "(mevent_t e)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "unsigned int result;");
      Plc(L, 1, "switch (e.tid) {");
      for I in 1..T_Size(N) loop
	 T := Ith_Trans(N, I);
	 Plc(L, 1, "case " & Tid(T) & ":");
	 Plc(L, 2, "result = " & Tid_Size & " + " &
	       Encoded_Size
	       (Get_Dom(T), "(*(" & Trans_Dom_Type(T) & " *) e.c)") & ";");
	 Plc(L, 2, "break;");
      end loop;
      Plc(L, 1, "default: assert(0);");
      Plc(L, 1, "}");
      Plc(L, 1, "return (result >> 3) + ((result & 7) ? 1 : 0);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("hash_key_t mevent_hash (" & Nl &
	   "   mevent_t e)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "hash_key_t result = e.tid;");
      Plc(L, 1, "switch (e.tid) {");
      for I in 1..T_Size(N) loop
	 T := Ith_Trans(N, I);
	 Plc(L, 1, "case " & Tid(T) & ":");
	 Plc(L, 2, Trans_Dom_Hash_Func(T) &
	       "((*(" & Trans_Dom_Type(T) & " *) e.c), (&result));");
	 Plc(L, 2, "break;");
      end loop;
      Plc(L, 1, "default: assert(0);");
      Plc(L, 1, "}");
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void mevent_serialise (" & Nl &
	   "   mevent_t e," & Nl &
	   "   bit_vector_t v)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "bit_stream_t bits;");
      Plc(L, 1, "bit_stream_init(bits, v);");
      Plc(L, 1, "TRANS_ID_encode (e.tid, bits);");
      Plc(L, 1, "switch (e.tid) {");
      for I in 1..T_Size(N) loop
	 T := Ith_Trans(N, I);
	 Id := Tid(T);
	 Plc(L, 1, "case " & Id & ": " &
	       Trans_Dom_Encode_Func(T) &
	       " ((*(" & Trans_Dom_Type(T) & " *) e.c), bits); break;");
      end loop;
      Plc(L, 1, "default: assert(0);");
      Plc(L, 1, "}");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("mevent_t mevent_unserialise_mem (" & Nl &
	   "   bit_vector_t v," & Nl &
	   "   heap_t heap)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_t result;");
      Plc(L, 1, "result.h = heap;");
      Plc(L, 1, "bit_stream_t bits;");
      Plc(L, 1, "bit_stream_init(bits, v);");
      Plc(L, 1, "TRANS_ID_decode (bits, result.tid);");
      Plc(L, 1, "switch (result.tid) {");
      for I in 1..T_Size(N) loop
	 T := Ith_Trans(N, I);
	 Id := Tid(T);
	 Plc(L, 1, "case " & Id & ": {");
	 Plc(L, 2, Trans_Dom_Type(T) & " c;");
	 Plc(L, 2, Trans_Dom_Decode_Func(T) & " (bits, c);");
	 Plc(L, 2, "result.c = (" & Trans_Dom_Type(T) &
	       " *) mem_alloc (heap, sizeof(" & Trans_Dom_Type(T) & "));");
	 Plc(L, 2, "*((" & Trans_Dom_Type(T) & " *) result.c) = c;");
	 Plc(L, 2, "break;");
	 Plc(L, 1, "}");
      end loop;
      Plc(L, 1, "default: assert(0);");
      Plc(L, 1, "}");
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("mevent_t mevent_unserialise (" & Nl &
	   "   bit_vector_t v)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "return mevent_unserialise_mem (v, SYSTEM_HEAP);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void mevent_to_xml_aux (" & Nl &
	   "   mevent_t e," & Nl &
	   "   bool_t binding_only," & Nl &
	   "   FILE * out)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "if (!binding_only) { fprintf (out, ""<event>""); }");
      Plc(L, 1, "switch(e.tid) {");
      for I in 1..T_Size(N) loop
	 T := Ith_Trans(N, I);
	 Vl := Get_Vars(T);
	 Plc(L, 1, "case " & Tid(T) & ": {");
	 Plc(L, 2, "if (!binding_only) {");
	 if Has_Desc(T) then
	    Plc(L, 3, "fprintf (out, ""<eventDescription>"");");
	    Plc(L, 3, "mevent_print_aux (e, out, FALSE);");
	    Plc(L, 3, "fprintf (out, ""</eventDescription>\n"");");
	 end if;
	 Plc(L, 2, "fprintf (out, ""<transition>" &
	       Get_Printable_String(Get_Name(T)) & "</transition>\n"");");
	 Plc(L, 2, "}");
	 Plc(L, 2, "fprintf (out, ""<binding>"");");
	 for J in 1..Length(Vl) loop
	    V := Ith(Vl, J);
	    C := Get_Cls(V);
	    Plc(L, 2, "fprintf (out, ""<varBinding>"");");
	    Plc(L, 2, "fprintf (out, ""<var>" &
		  Get_Printable_String(Get_Name(V)) & "</var>"");");
	    Plc(L, 2, Cls_To_Xml_Func(C) &
		  "(((" & Trans_Dom_Type(T) &
		  " *) e.c)->" & Dom_Ith_Comp_Name(J) & ", out);");
	    Plc(L, 2, "fprintf (out, ""</varBinding>"");");
	 end loop;
	 Plc(L, 2, "fprintf (out, ""</binding>\n"");");
	 Plc(L, 2, "break;");
	 Plc(L, 1, "}");
      end loop;
      Plc(L, 1, "default: assert(0);");
      Plc(L, 1, "}");
      Plc(L, 1, "if (!binding_only) { fprintf (out, ""</event>\n""); }");
      Plc(L, "}");
      --=========================================================
      Prototype := To_Ustring
	("void mevent_to_xml (" & Nl &
	   "   mevent_t e," & Nl &
	   "   FILE * out)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_to_xml_aux (e, FALSE, out);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void mevent_print_aux (" & Nl &
	   "   mevent_t e," & Nl &
	   "   FILE *   out," & Nl &
	   "   bool_t   nl)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "switch(e.tid) {");
      for I in 1..T_Size(N) loop
	 T := Ith_Trans(N, I);
	 Vl := Get_Vars(T);
	 Plc(L, 1, "case " & Tid(T) & ": {");
	 if Has_Desc(T) then
	    Gen_Let_Vars_Evaluation(T, L, 2, "e.c");
	    Pc(L, 2, "fprintf (out, """ & Get_Desc(T) & """");
	    El := Get_Desc_Exprs(T);
	    for I in 1..Length(El) loop
	       Pc(L, ", " & Compile_Evaluation(Ith(El, I),
					       Build_Map(T, "e.c")));
	    end loop;
	    Plc(L, ");");
	 else
	    Plc(L, 2, "fprintf (out, ""(" &
		  Get_Printable_String(Get_Name(T)) & """);");
	    if Length(Vl) = 0 then
	       Plc(L, 2, "fprintf (out, "")"");");
	    else
	       Plc(L, 2, "fprintf (out, "", ["");");
	       for J in 1..Length(Vl) loop
		  V := Ith(Vl, J);
		  C := Get_Cls(V);
		  Plc(L, 2, "fprintf (out, """ &
			Get_Printable_String(Get_Name(V)) & " = "");");
		  Plc(L, 2, Cls_Print_Func(C) &
			"(((" & Trans_Dom_Type(T) &
		     " *) e.c)->" & Dom_Ith_Comp_Name(J) & ");");
		  if J < Length(Vl) then
		     Plc(L, 2, "fprintf (out, "", "");");
		  end if;
	       end loop;
	       Plc(L, 2, "fprintf (out, ""])"");");
	    end if;
	 end if;
	 Plc(L, 2, "if (nl) { fprintf (out, ""\n""); }");
	 Plc(L, 2, "break;");
	 Plc(L, 1, "}");
      end loop;
      Plc(L, 1, "default: assert(0);");
      Plc(L, 1, "}");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void mevent_print (" & Nl &
	   "   mevent_t e," & Nl &
	   "   FILE *   out)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_print_aux (e, out, TRUE);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("order_t mevent_cmp (" & Nl &
	   "   mevent_t e," & Nl &
	   "   mevent_t f)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "if (e.tid < f.tid) return LESS;");
      Plc(L, 1, "if (e.tid > f.tid) return GREATER;");
      Plc(L, 1, "switch(e.tid) {");
      for I in 1..T_Size(N) loop
	 T := Ith_Trans(N, I);
	 Plc(L, 1, "case " & Tid(T) & ":");
	 Plc(L, 2, "return " & Trans_Dom_Cmp_Func(T) & " (" &
	       "(* ((" & Trans_Dom_Type(T) & " *) e.c)), " &
	       "(* ((" & Trans_Dom_Type(T) & " *) f.c)));");
      end loop;
      Plc(L, 1, "default: assert(0);");
      Plc(L, 1, "}");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("bool_t mevent_are_independent (" & Nl &
	   "   mevent_t e," & Nl &
	   "   mevent_t f)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      if With_Priority(N) then
	 Plc(L, 1, "return FALSE;");
      else
	 Plc(L, 1, "switch (e.tid) {");
	 for I in 1..T_Size(N) loop
	    T := Ith_Trans(N, I);
	    Plc(L, 1, "case " & Tid(T) & ":");
	    Plc(L, 2, "switch (f.tid) {");
	    Pre_T := Pre_Set(N, T);
	    for J in 1..T_Size(N) loop
	       U := Ith_Trans(N, J);
	       Pre_U := Pre_Set(N, U);
	       Inter := Intersect(Pre_U, Pre_T);
	       if Is_Empty(Inter) then
		  Plc(L, 2, "case " & Tid(U) & ": return TRUE;");
	       end if;
	       Free(Pre_U);
	       Free(Inter);
	    end loop;
	    Plc(L, 2, "default: return FALSE;");
	    Plc(L, 2, "}");
	    Free(Pre_T);
	 end loop;
	 Plc(L, 1, "default: assert(0);");
	 Plc(L, 1, "}");
      end if;
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("priority_t mevent_priority (" & Nl &
	   "   mevent_t e)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      if With_Priority(N) then
	 Plc(L, 1, "return e.priority;");
      else
	 Plc(L, 1, "return 0;");
      end if;
      Plc(L, "}");
      --=======================================================================
      End_Library(L);
   end;

end Pn.Compiler.Event;
