with
  Pn.Classes,
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Config,
  Pn.Compiler.Domains,
  Pn.Compiler.Mappings,
  Pn.Compiler.Util,
  Pn.Compiler.Names,
  Pn.Mappings,
  Pn.Nodes,
  Utils.Math;

use
  Pn.Classes,
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Config,
  Pn.Compiler.Domains,
  Pn.Compiler.Mappings,
  Pn.Compiler.Util,
  Pn.Compiler.Names,
  Pn.Mappings,
  Pn.Nodes,
  Utils.Math;

package body Pn.Compiler.State is

   --==========================================================================
   --  Function names for local state
   --==========================================================================
   function Local_State_Type
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_t"; end;
   function Local_State_List_Type
     (P: in Place) return Ustring is
   begin return "list_token_" & State_Component_Name(P) & "_t"; end;
   function Local_State_Init_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_init"; end;
   function Local_State_Set_Heap_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_set_heap"; end;
   function Local_State_Card_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_card"; end;
   function Local_State_Cmp_Local_State_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_cmp_" & Local_State_Type(P); end;
   function Local_State_Add_Tokens_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_add_token"; end;
   function Local_State_Free_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_free"; end;
   function Local_State_Is_Empty_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_is_empty"; end;
   function Local_State_Copy_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_copy"; end;
   function Local_State_Print_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_print"; end;
   function Local_State_To_Xml_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_to_xml"; end;
   function Local_State_Hash_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_hash"; end;
   function Local_State_Bit_Width_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_bit_width"; end;
   function Local_State_Encode_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_encode"; end;
   function Local_State_Decode_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_decode"; end;
   function Local_State_Cmp_Vector_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_cmp_vector"; end;
   function Local_State_Union_Func
     (P: in Place) return Ustring is
   begin return "mstate_" & Place_Name(P) & "_union"; end;

   procedure Gen_Local_State
     (P: in Place;
      L: in Library) is
      Prototype: Ustring;
      Test     : Ustring;
      C        : Cls;
      D        : constant Dom := Get_Dom(P);
      Mult_Size: constant Natural := Bit_Width(Big_Int(Get_Capacity(P)));
      T        : constant Ustring := Local_State_List_Type(P);
      Comment  : constant Ustring :=
        "/*****  definitions for place " & Get_Name(P) & "  *****/";
   begin
      Nlh(L, 3);
      Nlc(L, 3);
      Plh(L, Comment);
      Plc(L, Comment);
      --=======================================================================
      Plh(L, "struct " & T & "_struct_t {");
      Plh(L, 1, Place_Dom_Type(P) & " c;");
      Plh(L, 1, "int mult;");
      Plh(L, 1, "int cons;");
      Plh(L, 1, "int icons;");
      Plh(L, 1, "struct " & T & "_struct_t *next;");
      Plh(L, "};");
      Plh(L, "typedef struct " & T & "_struct_t * " & T & ";");
      Plh(L, "typedef struct {");
      Plh(L, 1, "unsigned int card;");
      Plh(L, 1, "int      mult;");
      Plh(L, 1, "heap_t   heap;");
      Plh(L, 1, T & " list;");
      Plh(L, "} " & Local_State_Type(P) & ";");
      Nlh(L);
      --=======================================================================
      Plh(L, "#define " & Local_State_Init_Func(P) & "(m, mheap) { \");
      Plh(L, "   m.list = NULL; \");
      Plh(L, "   m.card = 0; \");
      Plh(L, "   m.mult = 0; \");
      Plh(L, "   m.heap = mheap; \");
      Plh(L, "}");
      --=======================================================================
      Plh(L, "#define " & Local_State_Card_Func(P) & "(m) (m.card)");
      --=======================================================================
      Plh(L, "#define " & Local_State_Is_Empty_Func(P) & "(s) (!" &
            Local_State_Card_Func(P) & "(s))");
      --=======================================================================
      Plh(L, "#define " & Local_State_Free_Func(P) & "(s) { \");
      Plh(L, 1, T & " next = s.list; \");
      Plh(L, 1, T & " tmp_list; \");
      Plh(L, 1, "while (next) { \");
      Plh(L, 2, "tmp_list = next; \");
      Plh(L, 2, "next = next->next; \");
      Plh(L, 2, "mem_free (s.heap, tmp_list); \");
      Plh(L, 1, "} \");
      Plh(L, "}");
      --=======================================================================
      Plh(L, "#define " & Local_State_Hash_Func(P) & "(s, result) { \");
      Plh(L, 1, T & " l = s.list; \");
      Plh(L, 1, "for(; l; l = l->next) { \");
      Plh(L, 2, Place_Dom_Hash_Func(P) & "(l->c, result); \");
      Plh(L, 1, "} \");
      Plh(L, "}");
      --=======================================================================
      Prototype :=
        "bool_t " & T & "_equal (" & Nl &
        "   " & T & " list1," & Nl &
        "   " & T & " list2)";
      Plc(L, Prototype & " {");
      Plc(L, 1, "for(; list2 && list1 && list1->mult == list2->mult && " &
          Place_Dom_Eq_Func(P) & "(list1->c, list2->c);" &
          " list1=list1->next, list2=list2->next);");
      Plc(L, 1, "return ((!list1) && (!list2)) ? TRUE : FALSE;");
      Plc(L, "}");
      Plh(L, Prototype & ";");
      Plh(L, "#define " &
          Local_State_Cmp_Local_State_Func(P) &
          "(s1, s2) (s1.card == s2.card && s1.mult == s2.mult && " &
          T & "_equal(s1.list, s2.list))");
      --=======================================================================
      Prototype :=
        "char " & Local_State_Add_Tokens_Func(P) & "_func (" & Nl &
        "   " & T & " *list," & Nl &
        "   " & Place_Dom_Type(P) & " c," & Nl &
        "   int mult," & Nl &
        "   heap_t heap)";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, T & " tmp_list = *list;");
      Plc(L, 1, T & " prec = NULL;");
      Plc(L, 1, T & " new;");
      Plc(L, 1, "int cmp;");
      Plc(L, 1, "for(;");
      Plc(L, 1, "    tmp_list && (GREATER == (cmp = " &
          Place_Dom_Cmp_Func(P) & "(c, tmp_list->c)));");
      Plc(L, 1, "    prec = tmp_list, tmp_list = tmp_list->next);");
      Plc(L, 1, "if(tmp_list && (EQUAL == cmp)) {");
      Plc(L, 2, "tmp_list->mult += mult;");
      Plc(L, 2, "if(tmp_list->mult > " & Capacity_Const_Name(P) & ")");
      if Get_Run_Time_Checks then
	 Plc(L, 3, "raise_error (""capacity exceeded in place " &
	       Get_Printable_String(Get_Name(P)) & """);");
      else
	 Plc(L, 3, "tmp_list->mult = " & Capacity_Const_Name(P) & ";");
      end if;
      Plc(L, 2, "if(tmp_list->mult)");
      Plc(L, 3, "return LIST_UNCHANGED;");
      Plc(L, 2, "else {");
      Plc(L, 3, "if(!prec)");
      Plc(L, 4, "*list = (*list)->next;");
      Plc(L, 3, "else");
      Plc(L, 4, "prec->next = tmp_list->next;");
      Plc(L, 3, "mem_free(heap, tmp_list);");
      Plc(L, 3, "return LIST_REMOVED;");
      Plc(L, 2, "}");
      Plc(L, 1, "}");
      Plc(L, 1, "else {");
      Plc(L, 2, "new = (" & T & ") mem_alloc (heap, sizeof(struct " &
            T & "_struct_t));");
      Plc(L, 2, "new->c = c;");
      Plc(L, 3, "new->mult = mult;");
      Plc(L, 3, "new->cons = new->icons = 0;");
      Plc(L, 2, "if(new->mult > " & Capacity_Const_Name(P) & ")");
      if Get_Run_Time_Checks then
	 Plc(L, 3, "raise_error (""capacity exceeded in place " &
	       Get_Printable_String(Get_Name(P)) & """);");
      else
	 Plc(L, 3, "new->mult = " & Capacity_Const_Name(P) & ";");
      end if;
      Plc(L, 2, "if(!prec) {");
      Plc(L, 3, "new->next = (*list);");
      Plc(L, 3, "(*list) = new;");
      Plc(L, 2, "}");
      Plc(L, 2, "else {");
      Plc(L, 3, "new->next = tmp_list;");
      Plc(L, 3, "prec->next = new;");
      Plc(L, 2, "}");
      Plc(L, 2, "return LIST_ADDED;");
      Plc(L, 1, "}");
      Plc(L, "}");
      Plh(L, "#define " & Local_State_Add_Tokens_Func(P) &
          "(m, item_col, item_mult) { \");
      Plh(L, 1, "switch(" & Local_State_Add_Tokens_Func(P) &
            "_func(&m.list, item_col, item_mult, m.heap)) { \");
      Plh(L, 2, "case LIST_ADDED  : m.card++; break;\");
      Plh(L, 2, "case LIST_REMOVED: m.card--; break;\");
      Plh(L, 1, "} \");
      Plh(L, 1, "m.mult += item_mult; \");
      Plh(L, "}");
      --=======================================================================
      Prototype :=
        T & " " & T & "_copy (" & Nl &
        "   " & T & " list," & Nl &
        "   heap_t heap)";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, T & " result = NULL;");
      Plc(L, 1, T & " tmp;");
      Plc(L, 1, "for(; list; list=list->next) {");
      Plc(L, 2, "if(!result) {");
      Plc(L, 3, "tmp = (" & T & ") mem_alloc " &
            "(heap, sizeof (struct " & T & "_struct_t));");
      Plc(L, 3, "result = tmp;");
      Plc(L, 3, "(*result) = (*list);");
      Plc(L, 2, "}");
      Plc(L, 2, "else {");
      Plc(L, 3, "tmp->next = (" & T & ") mem_alloc " &
            "(heap, sizeof (struct " & T & "_struct_t));");
      Plc(L, 3, "(*(tmp->next)) = (*list);");
      Plc(L, 3, "tmp = tmp->next;");
      Plc(L, 3, "tmp->next = NULL;");
      Plc(L, 2, "}");
      Plc(L, 1, "}");
      Plc(L, 1, "return result;");
      Plc(L, "}");
      Plh(L, "#define " & Local_State_Copy_Func(P) & "(src, dest) { \");
      Plh(L, 1, "dest.card = src.card; \");
      Plh(L, 1, "dest.mult = src.mult; \");
      Plh(L, 1, "dest.list = " & T & "_copy(src.list, dest.heap); \");
      Plh(L, "}");
      --=======================================================================
      Prototype := "void " & Local_State_Print_Func(P) & " (" & Nl &
        "   " & Local_State_Type(P) & " s," & Nl &
	"   FILE * out)";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, T & " tmp_list = s.list;");
      Plc(L, 1, "for(; tmp_list; tmp_list=tmp_list->next) {");
      Plc(L, 2, "if(tmp_list != s.list && tmp_list->mult > 0) {");
      Plc(L, 3, "fprintf(out, "" + "");");
      Plc(L, 2, "}");
      Plc(L, 2, "if(tmp_list->mult != 1) {");
      Plc(L, 3, "fprintf(out, ""%i*"", tmp_list->mult);");
      Plc(L, 2, "}");
      Plc(L, 2, Place_Dom_Print_Func(P) & "(tmp_list->c);");
      Plc(L, 1, "}");
      Plc(L, "}");
      --=======================================================================
      Prototype :=
        "unsigned int " & Local_State_Bit_Width_Func(P) & "_func (" & Nl &
        "   " & T & " list)";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "unsigned int result = 0;");
      Plc(L, 1, T & " tmp_list = list;");
      Plc(L, 1, "for(; tmp_list; tmp_list = tmp_list->next)");
      Plc(L, 2, "result += " & Dom_Bit_Width_Func(D) & "(tmp_list->c);");
      Plc(L, 1, "return result;");
      Plc(L, "}");
      Ph(L, "#define " & Local_State_Bit_Width_Func(P) & "(s) ");
      if Has_Constant_Bit_Width(D) then
         Plh(L, "(s.card * " & (1 + Mult_Size + Bit_Width(D)) & ")");
      else
         Plh(L, "(s.card * " & (1 + Mult_Size) & " + " &
               Local_State_Bit_Width_Func(P) & "_func(s.list))");
      end if;
      --=======================================================================
      Plh(L, "#define " & Local_State_Encode_Func(P) & "(s, bits) { \");
      Plh(L, 1, T & " tmp_list = s.list; \");
      Plh(L, 1, "for(; tmp_list; tmp_list=tmp_list->next)  { \");
      if Mult_Size > 0 then
         Plh(L, 2, Bit_Stream_Set_Func(Mult_Size) &
               "(bits, tmp_list->mult - 1); \");
      end if;
      Plh(L, 2, Place_Dom_Encode_Func(P) & "(tmp_list->c, bits); \");
      Plh(L, 2, "if(tmp_list->next) { " &
            Bit_Stream_Set_Func(1) & "(bits, FALSE); } \");
      Plh(L, 2, "else { " &
            Bit_Stream_Set_Func(1) & "(bits, TRUE);  } \");
      Plh(L, 1, "} \");
      Plh(L, "}");
      --=======================================================================
      Plh(L, "#define " & Local_State_Decode_Func(P) & "(bits, s, heap) { \");
      Plh(L, 1, T & " new; \");
      Plh(L, 1, "char last = FALSE; \");
      Plh(L, 1, Local_State_Init_Func(P) & "(s, heap); \");
      Plh(L, 1, "new = NULL; \");
      Plh(L, 1, "while(!last) { \");
      Plh(L, 2, "if(!(s.list)) { \");
      Plh(L, 3, "s.list = mem_alloc (heap, sizeof (struct " & T &
            "_struct_t)); \");
      Plh(L, 3, "new = s.list; \");
      Plh(L, 2, "} \");
      Plh(L, 2, "else { \");
      Plh(L, 3, "new->next = mem_alloc (heap, sizeof (struct " & T &
            "_struct_t)); \");
      Plh(L, 3, "new = new->next; \");
      Plh(L, 2, "} \");
      if Mult_Size > 0 then
         Plh(L, 2, Bit_Stream_Get_Func(Mult_Size) & "(bits, new->mult); \");
         Plh(L, 2, "new->mult ++; \");
         Plh(L, 2, "s.mult += new->mult; \");
      else
         Plh(L, 2, "new->mult = 1; \");
         Plh(L, 2, "s.mult ++; \");
      end if;
      Plh(L, 2, "new->cons = new->icons = 0; \");
      Plh(L, 2, Place_Dom_Decode_Func(P) & "(bits, new->c); \");
      Plh(L, 2, "new->next = NULL; \");
      Plh(L, 2, "s.card ++; \");
      Plh(L, 2, Bit_Stream_Get_Func(1) & "(bits, last); \");
      Plh(L, 1, "} \");
      Plh(L, "}");
      --=======================================================================
      Prototype :=
        "bool_t " & Local_State_Cmp_Vector_Func(P) & "_func (" & Nl &
        "   " & T & " list," & Nl &
        "   bit_stream_t * bits)";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "bool_t last = FALSE;");
      Plc(L, 1, T & " tmp = list;");
      if Mult_Size > 0 then
         Plc(L, 1, "unsigned int mult;");
      end if;
      Plc(L, 1, Place_Dom_Type(P) & " cp;");
      Plc(L, 1, "while((!last) && tmp) {");
      if Mult_Size > 0 then
         Plc(L, 2, Bit_Stream_Get_Func(Mult_Size) & "((*bits), mult);");
         Plc(L, 2, "mult ++;");
      end if;
      Plc(L, 2, Place_Dom_Decode_Func(P) & "((*bits), cp);");
      Test := "(!(" & Place_Dom_Eq_Func(P) & "(tmp->c, cp)))";
      if Mult_Size > 0 then
         Test := Test & " || (tmp->mult != mult)";
      else
         Test := Test & " || (tmp->mult != 1)";
      end if;
      Plc(L, 2, "if(" & Test & ") return FALSE;");
      Plc(L, 2, Bit_Stream_Get_Func(1) & "((*bits), last);");
      Plc(L, 2, "tmp = tmp->next;");
      Plc(L, 1, "}");
      Plc(L, 1, "return last && !tmp;");
      Plc(L, "}");
      Plh(L, "#define " & Local_State_Cmp_Vector_Func(P) & "(m, bits) " &
            Local_State_Cmp_Vector_Func(P) & "_func(m.list, bits)");
      --=======================================================================
      Prototype :=
        "void " & Local_State_To_Xml_Func(P) & " (" & Nl &
        "   " & Local_State_Type(P) & " s," & Nl &
        "   FILE * out)";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, T & " l = s.list;");
      Plc(L, 1, "for (; l; l = l->next) {");
      Plc(L, 2, "fprintf (out, " &
            """<token><mult>%d</mult><exprList>""" &
            ", l->mult);");
      for I in 1..Size(D) loop
         C := Ith(D, I);
         Plc(L, 2, Cls_To_Xml_Func(C) &
               "(l->c." & Dom_Ith_Comp_Name(I) & ", out);");
      end loop;
      Plc(L, 2, "fprintf (out, ""</exprList></token>\n"");");
      Plc(L, 1, "}");
      Plc(L, "}");
      --=======================================================================
      Prototype :=
        "void " & Local_State_Union_Func(P) & " (" & Nl &
        "   " & Local_State_Type(P) & " * p," & Nl &
        "   " & Local_State_Type(P) & "   q)";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "order_t cmp;");
      Plc(L, 1, T & " lp = p->list, lq = q.list;");
      Plc(L, 1, T & " pred = NULL, lnew;");
      Plc(L, 1, "while (lq) {");
      Plc(L, 2, "cmp = (lp) ? " &
	    "(" & Place_Dom_Cmp_Func(P) & " (lp->c, lq->c)) : " &
	    "GREATER;");
      Plc(L, 2, "switch (cmp) {");
      Plc(L, 2, "case EQUAL: {");
      Plc(L, 3, "if (lq->mult > lp->mult) {");
      Plc(L, 4, "p->mult = p->mult + (lq->mult - lp->mult);");
      Plc(L, 4, "lp->mult = lq->mult;");
      Plc(L, 3, "}");
      Plc(L, 3, "pred = lp;");
      Plc(L, 3, "lp = lp->next;");
      Plc(L, 3, "lq = lq->next;");
      Plc(L, 3, "break;");
      Plc(L, 2, "}");
      Plc(L, 2, "case LESS: {");
      Plc(L, 3, "pred = lp;");
      Plc(L, 3, "lp = lp->next;");
      Plc(L, 3, "break;");
      Plc(L, 2, "}");
      Plc(L, 2, "case GREATER: {");
      Plc(L, 3, "lnew = mem_alloc (p->heap, " &
	    "sizeof (struct " & T & "_struct_t));");
      Plc(L, 3, "lnew->c = lq->c;");
      Plc(L, 3, "lnew->mult = lq->mult;");
      Plc(L, 3, "lnew->cons = lq->cons;");
      Plc(L, 3, "lnew->icons = lq->icons;");
      Plc(L, 3, "lnew->next = lp;");
      Plc(L, 3, "p->card ++;");
      Plc(L, 3, "p->mult += lq->mult;");
      Plc(L, 3, "if (pred) { pred->next = lnew; }");
      Plc(L, 3, "else      { p->list = lnew; }");
      Plc(L, 3, "pred = lnew;");
      Plc(L, 3, "lq = lq->next;");
      Plc(L, 3, "break;");
      Plc(L, 3, "}");
      Plc(L, 2, "}");
      Plc(L, 1, "}");
      Plc(L, "}");
   end;



   --==========================================================================
   --  Global state
   --==========================================================================

   function State_Component_Name
     (P: in Place) return Ustring is
   begin
      return Place_Name(P);
   end;

   procedure Gen_State
     (N: in Net;
      L: in Library) is
      Prototype     : Ustring;
      Id            : Ustring;
      Comp          : Ustring;
      P             : Place;
      Non_Empty_Size: constant Natural := Bit_Width(Big_Int(P_Size(N) + 1));
   begin
      Plh(L, "typedef struct {");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Comp := State_Component_Name(P);
         Plh(L, 1, Local_State_Type(P) & " " & Comp & ";");
      end loop;
      Plh(L, 1, "heap_t heap;");
      Plh(L, "} mstate_struct_t;");
      Plh(L, "typedef mstate_struct_t * mstate_t;");
      --=======================================================================
      Plh(L, "#define mstate_init(s, sheap) { \");
      Plh(L, 1, "s = (mstate_t) mem_alloc " &
            "(sheap, sizeof (mstate_struct_t)); \");
      Plh(L, 1, "s->heap = sheap; \");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Plh(L, 1, Local_State_Init_Func(P) &
               " (s->" & State_Component_Name(P) & ", s->heap); \");
      end loop;
      Plh(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("bool_t mstate_equal (" & Nl &
           "   mstate_t s1," & Nl &
           "   mstate_t s2)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Pc(L, 1, "return TRUE");
      for I in 1..P_Size(N) loop
	 P := Ith_Place(N, I);
	 Plc(L, " && " & Local_State_Cmp_Local_State_Func(P) &
	       "(s1->" & State_Component_Name(P) & ", s2->" &
	       State_Component_Name(P) & ")");
      end loop;
      Plc(L, 1, ";");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("mstate_t mstate_initial ()");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mstate_t result;");
      Plc(L, 1, "mstate_init (result, SYSTEM_HEAP);");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Plc(L, 1, M0_Func(P, Add) & " (result, DUMMY);");
      end loop;
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("mstate_t mstate_initial_mem (" & Nl &
           "   heap_t heap)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mstate_t result;");
      Plc(L, 1, "mstate_init (result, heap);");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Plc(L, 1, M0_Func(P, Add) & " (result, DUMMY);");
      end loop;
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("void mstate_print" & Nl &
           "(mstate_t s," & Nl &
	   " FILE *   out)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "fprintf(out, ""{\n"");");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Plc(L, 1, "if (!(" & Local_State_Is_Empty_Func(P) &
               "(s->" & State_Component_Name(P) & "))) {");
         Plc(L, 2, "fprintf(out, ""  " & Get_Printable_String(Get_Name(P)) &
               " =\n"");");
         Plc(L, 2, "fprintf(out, ""    "");");
         Plc(L, 2, Local_State_Print_Func(P) &
               "(s->" & State_Component_Name(P) & ", out);");
         Plc(L, 2, "fprintf(out, ""\n"");");
         Plc(L, 1, "}");
      end loop;
      Plc(L, 1, "fprintf(out, ""}\n"");");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("void mstate_free" & Nl &
           "(mstate_t s)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "if (!heap_has_mem_free (s->heap)) { return; }");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Plc(L, 1, "if (!(" & Local_State_Is_Empty_Func(P) &
               "(s->" & State_Component_Name(P) & "))) " &
               Local_State_Free_Func(P) & "(s->" &
               State_Component_Name(P) & ");");
      end loop;
      Plc(L, 1, "mem_free (s->heap, s);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("mstate_t mstate_copy_mem (" & Nl &
           "   mstate_t s," & Nl &
           "   heap_t heap)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mstate_t result;");
      Plc(L, 1, "mstate_init (result, heap);");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Comp := State_Component_Name(P);
         Plc(L, 1, Local_State_Copy_Func(P) &
               "(s->" & Comp & ", result->" & Comp & ");");
      end loop;
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("mstate_t mstate_copy (" & Nl &
           "   mstate_t s)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "return mstate_copy_mem (s, SYSTEM_HEAP);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("void mstate_to_xml (" & Nl &
           "   mstate_t s," & Nl &
           "   FILE *   out)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Comp := State_Component_Name(P);
         Plc(L, 1, "if (!(" & Local_State_Is_Empty_Func(P) &
             "(s->" & Comp & "))) {");
         Plc(L, 1, "fprintf (out, ""<placeState>\n"");");
         Plc(L, 1, "fprintf (out, ""<place>" &
               Get_Printable_String(Get_Name(P)) & "</place>\n"");");
         Plc(L, 2, Local_State_To_Xml_Func(P) & " (s->" & Comp & ", out);");
         Plc(L, 1, "fprintf (out, ""</placeState>\n"");");
         Plc(L, 1, "}");
      end loop;
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("hash_key_t mstate_hash (" & Nl &
           "   mstate_t s)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "hash_key_t result = 37;");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Id := Pid(P);
         Comp := State_Component_Name(P);
         Plc(L, 1, "if (!(" & Local_State_Is_Empty_Func(P) &
             "(s->" & Comp & "))) {");
         Plc(L, 1, "result = (result << 5) + result + " & Id & " + 720;");
         Plc(L, 2, Local_State_Hash_Func(P) & " (s->" & Comp & ", &result);");
         Plc(L, 1, "}");
      end loop;
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("unsigned int mstate_char_size (" & Nl &
           "   mstate_t s)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "unsigned int result = " & Non_Empty_Size);
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Comp := State_Component_Name(P);
         Plc(L, 1, " + ((" & Local_State_Is_Empty_Func(P) &
              "(s->" & Comp & ")) ? 0 : (PID_SIZE + ");
         Plc(L, 1, Local_State_Bit_Width_Func(P) & "(s->" & Comp & ")))");
      end loop;
      Plc(L, 1, ";");
      Plc(L, 1, "return (result & 7) ? ((result >> 3) + 1) : (result >> 3);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("void mstate_serialise (" & Nl &
           "   mstate_t s," & Nl &
           "   bit_vector_t v)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "bit_stream_t vec;");
      Plc(L, 1, "bit_stream_init(vec, v);");
      Plc(L, 1, "unsigned int ne = mstate_non_empty_places (s);");
      Plc(L, 1, Bit_Stream_Set_Func(Non_Empty_Size) & "(vec, ne);");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Plc(L, 1, "if(!(" & Local_State_Is_Empty_Func(P) &
               "(s->" & State_Component_Name(P) & "))) {");
         Plc(L, 2, "PLACE_ID_encode(" & Pid(P) & ", vec);");
         Plc(L, 2, Local_State_Encode_Func(P) &
               "(s->" & State_Component_Name(P) & ", vec);");
         Plc(L, 1, "}");
      end loop;
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("mstate_t mstate_unserialise_mem (" & Nl &
           "   bit_vector_t v," & Nl &
           "   heap_t heap)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mstate_t result;");
      Plc(L, 1, "unsigned int ne;");
      Plc(L, 1, "pl_id_t pid;");
      Plc(L, 1, "bit_stream_t vec;");
      Plc(L, 1, "bit_stream_init(vec, v);");
      Plc(L, 1, Bit_Stream_Get_Func(Non_Empty_Size) & "(vec, ne);");
      Plc(L, 1, "mstate_init (result, heap);");
      Plc(L, 1, "for(; ne; ne--) {");
      Plc(L, 2, "PLACE_ID_decode(vec, pid);");
      Plc(L, 2, "switch(pid) {");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Plc(L, 2, "case " & Pid(P) & ":");
         Plc(L, 3, Local_State_Decode_Func(P) &
               " (vec, result->" & State_Component_Name(P) & ", heap);");
         Plc(L, 3, "break;");
      end loop;
      Plc(L, 2, "default: assert(0);");
      Plc(L, 2, "}");
      Plc(L, 1, "}");
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("mstate_t mstate_unserialise (" & Nl &
           "   bit_vector_t v)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, "   return mstate_unserialise_mem (v, SYSTEM_HEAP);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("bool_t mstate_cmp_vector (" & Nl &
           "   mstate_t s," & Nl &
           "   bit_vector_t v)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "unsigned int ne, i = 0;");
      Plc(L, 1, "pl_id_t pid;");
      Plc(L, 1, "bit_stream_t bits;");
      Plc(L, 1, "bit_stream_init(bits, v);");
      Plc(L, 1, Bit_Stream_Get_Func(Non_Empty_Size) & " (bits, ne);");
      Plc(L, 1, "if (mstate_non_empty_places (s) != ne) return FALSE;");
      Plc(L, 1, "for (; i<ne; i++) {");
      Plc(L, 2, "PLACE_ID_decode (bits, pid);");
      Plc(L, 2, "switch (pid) {");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Comp := State_Component_Name(P);
         Plc(L, 2, "case " & Pid(P) & ":");
         Plc(L, 3, "if (!(" &
               Local_State_Cmp_Vector_Func(P) & " (s->" & Comp &
               ", &bits))) return FALSE;");
	 Plc(L, 3, "break;");
      end loop;
      Plc(L, 2, "default: assert(0);");
      Plc(L, 2, "}");
      Plc(L, 1, "}");
      Plc(L, 1, "return TRUE;");
      Plc(L, "}");
      --=======================================================================
      Plh(L, "#define mstate_non_empty_places(s) (\");
      for I in 1..P_Size(N) loop
	 P := Ith_Place(N, I);
	 Plh(L, "   ((!(" & Local_State_Is_Empty_Func(P) &
	       "(s->" & State_Component_Name(P) & "))) ? 1 : 0) + \");
      end loop;
      Plh(L, "   0)");
      --=======================================================================
      Prototype := To_Ustring
        ("void mstate_union (" & Nl &
	   "   mstate_t s1," & Nl &
	   "   mstate_t s2)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      for J in 1..P_Size(N) loop
	 P := Ith_Place(N, J);
	 Plc(L, 1, Local_State_Union_Func(P) & " (&(s1->" &
	       State_Component_Name(P) & "), s2->" &
	       State_Component_Name(P) & ");");
      end loop;
      Plc(L, "}");
   end;



   --==========================================================================
   --  Main generation procedure
   --==========================================================================

   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      Comment  : constant String :=
        "This library contains the definition of states.";
      Prototype: Ustring;
      L        : Library;
   begin
      Init_Library(State_Lib, To_Ustring(Comment), Path, L);
      Plh(L, "#include ""mappings.h""");
      Plh(L, "#include ""domains.h""");
      Nlh(L);
      Plh(L, "#define LIST_UNCHANGED 0");
      Plh(L, "#define LIST_ADDED 1");
      Plh(L, "#define LIST_REMOVED 2");
      Nlh(L);
      for I in 1..P_Size(N) loop
         Gen_Local_State(Ith_Place(N, I), L);
      end loop;
      Gen_State(N, L);
      Prototype := "void " & Lib_Init_Func(State_Lib) & " ()";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {}");
      End_Library(L);
   end;

end Pn.Compiler.State;
