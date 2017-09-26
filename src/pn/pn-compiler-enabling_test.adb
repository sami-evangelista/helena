with
  Pn.Classes,
  Pn.Compiler.Domains,
  Pn.Compiler.Event,
  Pn.Compiler.Names,
  Pn.Compiler.State,
  Pn.Compiler.Util,
  Pn.Exprs,
  Pn.Exprs.Var_Refs,
  Pn.Nodes,
  Pn.Vars,
  Pn.Vars.Iter;

use
  Pn.Classes,
  Pn.Compiler.Domains,
  Pn.Compiler.Event,
  Pn.Compiler.Names,
  Pn.Compiler.State,
  Pn.Compiler.Util,
  Pn.Exprs,
  Pn.Exprs.Var_Refs,
  Pn.Nodes,
  Pn.Vars,
  Pn.Vars.Iter;

package body Pn.Compiler.Enabling_Test is

   --==========================================================================
   --  unification algorithm
   --==========================================================================

   use Evaluation_Item_Array_Pkg;

   procedure Free is
      new Evaluation_Item_Array_Pkg.Generic_Apply(Action => Free);

   function New_Evaluation_Item_Tuple
     (P: in Place;
      T: in Tuple) return Evaluation_Item is
      Result: constant Evaluation_Item :=
	new Evaluation_Item_Record(A_Tuple);
   begin
      Result.P := P;
      Result.T := T;
      return Result;
   end;

   function New_Evaluation_Item_Inhib_Tuple
     (P: in Place;
      T: in Tuple) return Evaluation_Item is
      Result: constant Evaluation_Item :=
	new Evaluation_Item_Record(A_Inhib_Tuple);
   begin
      Result.P := P;
      Result.T := T;
      return Result;
   end;

   function New_Evaluation_Item_Guard
     (G: in Guard) return Evaluation_Item is
      Result: constant Evaluation_Item :=
        new Evaluation_Item_Record(A_Guard);
   begin
      Result.G := G;
      return Result;
   end;

   function New_Evaluation_Item_Pick_Var
     (Pv: in Var) return Evaluation_Item is
      Result: constant Evaluation_Item :=
        new Evaluation_Item_Record(A_Pick_Var);
   begin
      Result.Pv := Pv;
      return Result;
   end;

   function New_Evaluation_Item_Let_Var
     (Lv: in Var) return Evaluation_Item is
      Result: constant Evaluation_Item :=
        new Evaluation_Item_Record(A_Let_Var);
   begin
      Result.Lv := Lv;
      return Result;
   end;

   procedure Free
     (E: in out Evaluation_Item) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Evaluation_Item_Record,
                                        Evaluation_Item);
   begin
      Deallocate(E);
      E := null;
   end;

   function Get_Defined_Vars
     (E: in Evaluation_Item) return Var_List is
      Result: Var_List;
   begin
      case E.K is
         when A_Guard       => Result := New_Var_List;
         when A_Let_Var     => Result := New_Var_List((1 => E.Lv));
         when A_Pick_Var    => Result := New_Var_List((1 => E.Pv));
         when A_Inhib_Tuple
	   |  A_Tuple       =>
	    if Get_Guard(E.T) /= True_Guard then
	       Result := New_Var_List;
	    else
	       Result := Vars_At_Top(E.T);
	    end if;
      end case;
      return Result;
   end;

   function Get_Used_Vars
     (E: in Evaluation_Item) return Var_List is
      Result : Var_List;
      Defined: Var_List;
   begin
      case E.K is
         when A_Guard =>
	    Result := Vars_In(E.G);
	 when A_Let_Var =>
	    Result := Vars_In(Get_Init(E.Lv));
         when A_Pick_Var =>
	    Result := Vars_In(Get_Iter_Var_Dom(Iter_Var(E.Pv)));
         when A_Inhib_Tuple
	   |  A_Tuple =>
            Result := Vars_In(E.T);
            Defined := Get_Defined_Vars(E);
            Difference(Result, Defined);
            Free(Defined);
      end case;
      return Result;
   end;



   function Get_Evaluation_Order
     (T: in Trans;
      N: in Net) return Evaluation_Order is
      Result : Evaluation_Order := Empty_Array;
      P      : Place;
      M      : Mapping;
      Vars   : Var_List;
      Item   : Evaluation_Item;
      V      : Var;
   begin
      --===
      --  guard of the transition
      --===
      if Get_Guard(T) /= True_Guard then
         Item := New_Evaluation_Item_Guard(Get_Guard(T));
         Append(Result, Item);
      end if;

      --===
      --  tuples appearing in the input arcs of the transition
      --===
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         M := Get_Arc_Label(N, Pre, P, T);
         for J in 1..Size(M) loop
            Item := New_Evaluation_Item_Tuple(P, Ith(M, J));
            Append(Result, Item);
         end loop;
      end loop;

      --===
      --  tuples appearing in the inhibitor arcs of the transition
      --===
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         M := Get_Arc_Label(N, Inhibit, P, T);
         for J in 1..Size(M) loop
            Item := New_Evaluation_Item_Inhib_Tuple(P, Ith(M, J));
            Append(Result, Item);
         end loop;
      end loop;

      --===
      --  pick variables of the transition
      --===
      Vars := Get_Vars(T);
      for I in 1..Length(Vars) loop
         V := Ith(Vars, I);
         case Get_Type(V) is
            when A_Container_Iter_Var
              |  A_Discrete_Cls_Iter_Var => null;
            when others => V := null;
         end case;
         if V /= null then
            Item := New_Evaluation_Item_Pick_Var(V);
            Append(Result, Item);
         end if;
      end loop;

      --===
      --  pick variables of the transition
      --===
      Vars := Get_Lvars(T);
      for I in 1..Length(Vars) loop
         V := Ith(Vars, I);
	 Append(Result, New_Evaluation_Item_Let_Var(V));
      end loop;
      return Result;
   end;

   function Find_Valid_Evaluation_Order
     (T: in Trans;
      N: in Net) return Evaluation_Order is
      Order   : Evaluation_Order := Get_Evaluation_Order(T, N);
      Items_Nb: constant Natural := Length(Order);
      Result  : Evaluation_Order := Empty_Array;
      Item    : Evaluation_Item;
      Defined : Var_List := Copy(Get_Consts(N));
      Used    : Var_List;
      New_Vars: Var_List;
      Found   : Boolean;
      Found_I : Index_Type;
      Ik      : Evaluation_Item_Kind;
   begin
      for I in 1..Items_Nb loop
         Found := False;
         for J in 1..Length(Order) loop
            Item := Ith(Order, J);
            Used := Get_Used_Vars(Item);
            Found := Included(Used, Defined);
            Free(Used);
            if Found then
	       --  inhibitor tuples must appear in last positions
	       if Item.K = A_Inhib_Tuple then
		  for K in 1..Length(Order) loop
		     Ik := Ith(Order, K).K;
		     if Ik /= A_Inhib_Tuple then
			Found := False;
			exit;
		     end if;
		  end loop;
	       end if;
	       if Found then
		  Found_I := J;
		  exit;
	       end if;
            end if;
         end loop;
         if Found then
            New_Vars := Get_Defined_Vars(Item);
            Union(Defined, New_Vars);
            Append(Result, Item);
            Delete(Order, Found_I);
         else
            Free(Order);
            Free(Defined);
            raise No_Valid_Evaluation_Order;
         end if;
      end loop;
      Free(Defined);
      return Result;
   end;

   function Is_Evaluable
     (T: in Trans;
      N: in Net) return Boolean is
      Order: Evaluation_Order;
   begin
      Order := Find_Valid_Evaluation_Order(T, N);
      Free(Order);
      return True;
   exception
      when No_Valid_Evaluation_Order =>
         Free(Order);
         return False;
   end;

   type Gen_Trans_Code is access procedure (T   : in Trans;
					    Tabs: in Natural;
					    L   : in Library);

   procedure Gen_Evaluation_Code
     (T  : in Trans;
      N  : in Net;
      Gen: in Gen_Trans_Code;
      L  : in Library) is

      Order      : constant Evaluation_Order :=
	Find_Valid_Evaluation_Order(T, N);
      Vars       : constant Var_List := Get_Vars(T);
      Ivars      : constant Var_List := Get_Ivars(T);
      Lvars      : constant Var_List := Get_Lvars(T);
      Inhib_Mode : Boolean := False;
      Tabs       : Positive := 1;
      Var_Id     : Positive := 1;
      Map        : Var_Mapping(1..Length(Vars)+Length(Ivars)+Length(Lvars));
      Tmp_Map    : Var_Mapping(Map'Range);

      procedure Gen_Evaluation_Code
        (Num    : in Index_Type;
         Defined: in Var_List);

      procedure Next_Item
        (Num    : in Index_Type;
	 Defined: in Var_List) is
      begin
         if Num < Length(Order) then
	    Gen_Evaluation_Code(Num + 1, Defined);
	 else
	    if Inhib_Mode then
	       Plc(L, Tabs, "inhibited = TRUE;");
	    else
	       Gen(T, Tabs + 1, L);
	    end if;
	 end if;
      end;

      procedure Gen_Guard_Evaluation_Code
        (G      : in Guard;
         Num    : in Index_Type;
	 Defined: in Var_List) is
      begin
         Plc(L, Tabs, "if (" & Compile_Evaluation(G, Map) & ") {");
	 Next_Item(Num, Defined);
         Plc(L, Tabs, "}");
      end;

      procedure Gen_Let_Var_Evaluation_Code
        (V      : in Var;
         Num    : in Index_Type;
	 Defined: in Var_List) is
	 Init : constant Ustring := Compile_Evaluation(Get_Init(V), Map);
      begin
         Plc(L, Tabs, Var_Name(V) & " = " & Init & ";");
	 Append(Defined, V);
	 Next_Item(Num, Defined);
      end;

      procedure Gen_Pick_Var_Evaluation_Code
        (V        : in Var;
         Num      : in Index_Type;
	 Defined  : in Var_List) is
         Iv: constant Iter_Var := Iter_Var(V);
      begin
         Compile_Definition(V, Num, Get_Code_File(L).all);
         Compile_Initialization(Iv, Map, Num, L);
         Plc(L, Tabs, "if (" & Compile_Start_Iteration_Check(Iv) & ") {");
         Plc(L, Tabs, "while (TRUE) {");
         Append(Defined, V);
         Plc(L, Tabs, Compile_Access(V, Map) & " = " & Var_Name(V) & ";");
	 Next_Item(Num, Defined);
         Plc(L, Tabs, "if (" & Compile_Is_Last_Check(Iv) & ") break;");
         Compile_Iteration(Iv, Num, L);
         Plc(L, Tabs, "}");
         Plc(L, Tabs, "}");
      end;

      procedure Gen_Tuple_Evaluation_Code
        (Tup    : in Tuple;
         P      : in Place;
         Num    : in Index_Type;
	 Cons   : in String;
         Defined: in Var_List) is

	 P_Dom : constant Dom := Get_Dom(P);
	 Tuples: Tuple_Scheduling := New_Tuple_Scheduling;

	 procedure Gen_Simple_Tuple_Evaluation_Code
	   (Tup_Num: in Index_Type) is
	    Tup        : constant Tuple := Ith(Tuples, Tup_Num);
	    El         : constant Expr_List := Get_Expr_List(Tup);
	    Tup_Guard  : constant Guard := Get_Guard(Tup);
	    F          : constant Mult_Type := Get_Factor(Tup);
	    List       : constant Ustring := "l" & Var_Id;
	    New_Vars   : Var_List := Vars_At_Top(El);
	    Test       : Ustring;
	    Ex         : Expr;
	    V          : Var;
	    Assignments: Ustring;
	    Comp       : Ustring;

	    --===
	    --  generate the statements executed when a token in the place
	    --  matches the tuple
	    --===
	    procedure Put_Matching_Token_Statements is
	    begin
	       Plc(L, Tabs, "if (" & List & ") { " &
		     List & "->" & Cons & " += " & F & "; }");
	       if Tup_Num = Length(Tuples) then
		  Next_Item(Num, Defined);
	       else
		  Gen_Simple_Tuple_Evaluation_Code(Tup_Num + 1);
	       end if;
	       Plc(L, Tabs, "if (" & List & ") { " &
		     List & "->" & Cons & " -= " & F & "; }");
	    end;

	 begin
	    Var_Id := Var_Id + 1;
	    Plc(L, Tabs, Local_State_List_Type(P) & " " & List & " = NULL;");
	    Difference(New_Vars, Defined);
	    if Is_Empty(New_Vars) then

	       --==============================================================
	       --  1st case: if the set of variables unified by the
	       --  tuple is empty => we just have to search for the
	       --  correct token
	       --==============================================================
	       Plc(L, Tabs, "bool_t check_ok = TRUE;");
	       if Tup_Guard /= True_Guard then
		  Plc(L, Tabs,
		      "if (" & Compile_Evaluation(Tup_Guard, Map) & ") {");
	       end if;
	       Plc(L, Tabs, "order_t cmp;");
	       Plc(L, Tabs, Place_Dom_Type(P) & " cp;");
	       for I in 1..Length(El) loop
		  Plc(L, Tabs,
		      "cp." & Dom_Ith_Comp_Name(I) & " = " &
			Compile_Evaluation(Ith(El, I), Map) & ";");
	       end loop;
	       Plc(L, Tabs,
		   "for (" & List & " = s->" & State_Component_Name(P) &
		     ".list; " & List &
		     " && (GREATER == (cmp = " & Place_Dom_Cmp_Func(P) &
		     "(cp, " & List & "->c))); " &
		     List & " = " & List & "->next);");
	       Plc(L, Tabs,
		   "check_ok = " & List & " && (EQUAL == cmp) && (" &
		     List & "->mult - " &
		     List & "->" & Cons & " >= " & F & ");");
	       if Tup_Guard /= True_Guard then
		  Plc(L, Tabs, "}");
	       end if;
	       Plc(L, Tabs, "if (check_ok) {");
	       Put_Matching_Token_Statements;
	       Plc(L, Tabs, "}");
	    else

	       --==============================================================
	       --  2nd case: if the set of variables unified by the
	       --  tuple is not empty => we have to loop on all the
	       --  tokens of the place to find the ones which match
	       --  the tuple
	       --==============================================================
	       Plc(L, Tabs,
		   "for(" & List & " = s->" & State_Component_Name(P) &
		     ".list; " & List & "; " &
		     List & " = " & List & "->next) {");

	       --  check if the token match the tuple: we loop on all
	       --  the expressions of the list and for each expression
	       --  we check that the item at the same position in the
	       --  place color is ok
	       Test := List & "->mult - " & List & "->" & Cons & " >= " & F;
	       Assignments := Null_String;

	       Tmp_Map := Map;
	       for I in 1..Length(El) loop
		  Ex := Ith(El, I);
		  Comp := Dom_Ith_Comp_Name(I);

		  --  if the expression is a non-unified variable =>
		  --  we assign to the transition variable the item at
		  --  the position in the place color.  in this case
		  --  we do not have to check the expression
		  if not
		    (Get_Type(Ex) = A_Var
		       and then Get_Type(Get_Var(Var_Ref(Ex))) = A_Trans_Var
		       and then not Contains(Defined, Get_Var(Var_Ref(Ex))))
		  then
		     Test := Test & " && " &
		       Cls_Bin_Operator_Name(Ith(P_Dom, I), Eq_Op) &
		       "(" & List & "->c." & Comp & ", " &
		       Compile_Evaluation(Ex, Tmp_Map) & ")";
		  else
		     V := Get_Var(Var_Ref(Ex));
		     Assignments := Assignments & (Tabs*Tab) &
		       Compile_Access(V, Tmp_Map) & " = " &
		       List & "->c." & Comp & ";" & Nl;
		     Tmp_Map := Change_Map(Tmp_Map, V, List & "->c." & Comp);
		     Append(Defined, V);
		  end if;
	       end loop;

	       Plc(L, Tabs, "if (" & Test & ") {");
	       Pc(L, Assignments);
	       Put_Matching_Token_Statements;
	       Plc(L, Tabs, "}");
	       Plc(L, Tabs, "}");
	    end if;

	    Free(New_Vars);
	 end;

         procedure Append_Tuple
           (Tup    : in Tuple;
            First  : in Card_Type;
            Last   : in Card_Type;
            Current: in Card_Type) is
	 begin
	    Append(Tuples, Copy(Tup));
         end;

         procedure Unfold_Tuple is
	    new Pn.Mappings.Generic_Unfold(Apply  => Append_Tuple);

      begin
         Unfold_Tuple(Tup);
	 Gen_Simple_Tuple_Evaluation_Code(1);
	 Free(Tuples);
      end;

      procedure Gen_Evaluation_Code
        (Num    : in Index_Type;
         Defined: in Var_List) is
	 Item : constant Evaluation_Item := Ith(Order, Num);
	 Inhib: constant Boolean := Inhib_Mode;
      begin
	 Tabs := Tabs + 1;
	 Nlc(L);
         case Item.K is
            when A_Tuple =>
	       Plc(L, 0, "/*  tuple " & To_Helena(Item.T) & "  */");
	       Gen_Tuple_Evaluation_Code(Item.T, Item.P, Num, "cons", Defined);
            when A_Guard =>
	       Plc(L, 0, "/*  guard " & To_Helena(Item.G) & "  */");
               Gen_Guard_Evaluation_Code(Item.G, Num, Defined);
            when A_Let_Var =>
	       Plc(L, 0, "/*  let var " & To_Helena(Item.Lv) & "  */");
               Gen_Let_Var_Evaluation_Code(Item.Lv, Num, Defined);
            when A_Pick_Var =>
	       Plc(L, 0, "/*  pick var " & To_Helena(Item.Pv) & "  */");
               Gen_Pick_Var_Evaluation_Code(Item.Pv, Num, Defined);
	    when A_Inhib_Tuple =>
	       Plc(L, 0, "/*  inhib tuple " & To_Helena(Item.T) & "  */");
	       Inhib_Mode := True;
	       if not Inhib then
		  Plc(L, Tabs, "{");
		  Plc(L, Tabs, "bool_t inhibited = FALSE;");
	       end if;
	       Gen_Tuple_Evaluation_Code(Item.T, Item.P, Num, "icons", Defined);
	       if not Inhib then
		  Plc(L, Tabs, "if (!inhibited) {");
		  Gen(T, Tabs + 1, L);
		  Plc(L, Tabs, "}");
		  Plc(L, Tabs, "}");
	       end if;
	 end case;
	 Tabs := Tabs - 1;
      end;
      Defined: Var_List := New_Var_List;
      V      : Var;
      Idx    : Natural := 1;
   begin
      Plc(L, 1, Trans_Dom_Type(T) & " ct;");
      for I in 1..Length(Vars) loop
	 Map(Idx) := (V    => Ith(Vars, I),
		      Expr => "ct." & Dom_Ith_Comp_Name(I));
	 Idx := Idx + 1;
      end loop;
      for I in 1..Length(Ivars) loop
	 V := Ith(Ivars, I);
	 Map(Idx) := (V => V, Expr => " " & Var_Name(V));
	 Plc(L, 1, Cls_Name(Get_Cls(V)) & " " & Var_Name(V) & ";");
	 Idx := Idx + 1;
      end loop;
      for I in 1..Length(Lvars) loop
	 V := Ith(Lvars, I);
	 Map(Idx) := (V => V, Expr => Var_Name(V));
	 Plc(L, 1, Cls_Name(Get_Cls(V)) & " " & Var_Name(V) & ";");
	 Idx := Idx + 1;
      end loop;
      if Length(Order) = 0 then
	 Gen(T, 1, L);
      else
	 Gen_Evaluation_Code(1, Defined);
      end if;
      Free(Defined);
      Free(Order);
   end;

   procedure Gen_Check_Priority_Func
     (N  : in Net;
      Lib: in Library) is
      Prototype: constant String :=
	"void mevent_list_check_priority (" & Nl &
        "   list_t l," & Nl &
	"   mstate_t s)";
      Test     : Ustring;
   begin
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");

      --===
      --  compute the maximal priority over all events
      --===
      if False then
      Plc(Lib, 1, "int max = INT_MIN;");
      Plc(Lib, 1, "list_t ptr, next, prev;");
      Plc(Lib, 1, "for(ptr = set->first; ptr; ptr = ptr->next) {");
      Plc(Lib, 2, "mevent_compute_priority (&ptr->e, s);");
      Plc(Lib, 2, "if (max < ptr->e.priority) max = ptr->e.priority;");
      Plc(Lib, 1, "}");

      --===
      --  remove all transitions which do not have the maximal priority
      --===
      Plc(Lib, 1, "prev = NULL;");
      Plc(Lib, 1, "ptr = set->first;");
      Plc(Lib, 1, "while (ptr) {");
      Plc(Lib, 2, "if (max == ptr->e.priority) {");
      Plc(Lib, 3, "prev = ptr;");
      Plc(Lib, 3, "ptr = ptr->next;");
      Plc(Lib, 2, "}");
      Plc(Lib, 2, "else {");
      Plc(Lib, 3, "set->size --;");
      Plc(Lib, 3, "next = ptr->next;");
      Plc(Lib, 3, "if (prev != NULL)");
      Plc(Lib, 4, "prev->next = next;");
      Plc(Lib, 3, "else");
      Plc(Lib, 4, "set->first = next;");
      Plc(Lib, 3, "mevent_free (ptr->e);");
      Plc(Lib, 3, "mem_free (set->heap, ptr);");
      Plc(Lib, 3, "ptr = next;");
      Plc(Lib, 2, "}");
      Plc(Lib, 1, "}");
      end if;
      Plc(Lib, "}");
   end;



   --==========================================================================
   --  Main generation procedure
   --==========================================================================

   procedure Gen_Add_Enabled_Event_Code
     (T   : in Trans;
      Tabs: in Natural;
      L   : in Library) is
   begin
      Plc(L, Tabs, "{");
      Plc(L, Tabs + 1, "order_t cmp;");
      Plc(L, Tabs + 1, "unsigned int k = 0;");
      Plc(L, Tabs + 1,
	  "for (k = 0, cmp = GREATER; k < no && (GREATER == (cmp = " &
	    Trans_Dom_Cmp_Func(T) & " (ct, cols[k]))); k ++);");
      Plc(L, Tabs + 1, "if (EQUAL != cmp) {");
      Plc(L, Tabs + 2, "unsigned int l = k;");
      Plc(L, Tabs + 2, "for (k = no; k != l; k --) { cols[k] = cols[k-1]; }");
      Plc(L, Tabs + 2, "cols[l] = ct;");
      Plc(L, Tabs + 2, "no ++;");
      Plc(L, Tabs + 1, "}");
      Plc(L, Tabs, "}");
   end;

   procedure Post_Get_All_Enabled
     (T   : in Trans;
      Tabs: in Natural;
      L   : in Library) is
   begin
      Plc(L, 1, "for (k = 0; k < no; k ++) {");
      Plc(L, 2, "e.id = id;");
      Plc(L, 2, "e.h = heap;");
      Plc(L, 2, "e.tid = " & Tid(T) & ";");
      Plc(L, 2, "e.c = mem_alloc(heap, sizeof(" &
	    Trans_Dom_Type(T) & "));");
      Plc(L, 2, "(* ((" & Trans_Dom_Type(T) &
	    " *) e.c)) = cols[k];");
      Plc(L, 2, "list_append(result, &e);");
      Plc(L, 2, "id ++;");
      Plc(L, 1, "}");
   end;

   procedure Post_Get_One_Enabled
     (T   : in Trans;
      Tabs: in Natural;
      L   : in Library) is
   begin
      Plc(L, 1, "if (no > id) {");
      Plc(L, 2, "result.tid = " & Tid(T) & ";");
      Plc(L, 2, "result.h = heap;");
      Plc(L, 2, "result.c = (void *) mem_alloc (heap, sizeof (" &
	    Trans_Dom_Type(T) & "));");
      Plc(L, 2, "(* ((" & Trans_Dom_Type(T) & " *) result.c)) = cols[id];");
      Plc(L, 2, "return result;");
      Plc(L, 1, "} else {");
      Plc(L, 2, "id -= no;");
      Plc(L, 1, "}");
   end;

   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      Prototype: Ustring;
      L        : Library;
      Comment  : constant Ustring :=
	To_Ustring("This library implements the enabling test.");

      procedure Gen_Enabled_Events_Check
	(Post_Trans: in Gen_Trans_Code) is
	 T: Trans;
      begin
	 for I in 1..T_Size(N) loop
	    T := Ith_Trans(N, I);
	    Nlc(L);
	    Plc(L, 1, "/*");
	    Plc(L, 1, " *  enabling test of transition " & Get_Name(T));
	    Plc(L, 1, " */");
	    Plc(L, 1, "{");
	    Plc(L, 1, Trans_Dom_Type(T) & " cols[256];");
	    Plc(L, 1, "unsigned int no = 0, k;");
	    Gen_Evaluation_Code(T, N, Gen_Add_Enabled_Event_Code'Access, L);
	    Post_Trans(T, 1, L);
	    Plc(L, 1, "}");
	 end loop;
      end;
   begin
      Init_Library(Enabling_Test_Lib, Comment, Path, L);
      Plh(L, "#include ""mevent.h""");
      Plh(L, "#include ""list.h""");
      Gen_Check_Priority_Func(N, L);
      --=======================================================================
      Prototype := To_Ustring
	("list_t mstate_enabled_events_mem (" & Nl &
	   "   mstate_t s," & Nl &
	   "   heap_t heap)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "list_t result;");
      Plc(L, 1, "uint16_t id = 0;");
      Plc(L, 1, "mevent_t e;");
      Plc(L, 1, "result = list_new(heap, sizeof(mevent_t), NULL);");
      Gen_Enabled_Events_Check(Post_Get_All_Enabled'Access);
      if With_Priority(N) then
	 Plc(L, 1, "mevent_list_check_priority (result, s);");
      end if;
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("list_t mstate_enabled_events (" & Nl &
	   "   mstate_t s)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "return mstate_enabled_events_mem (s, SYSTEM_HEAP);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("mevent_t mstate_enabled_event_mem (" & Nl &
	   "   mstate_t s," & Nl &
	   "   uint16_t id," & Nl &
	   "   heap_t heap)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_t result;");
      if not With_Priority(N) then
	 Gen_Enabled_Events_Check(Post_Get_One_Enabled'Access);
      else
	 Plc(L, 1, "mevent_set_t en = mstate_enabled_events_mem (s, heap);");
	 Plc(L, 1, "result = mevent_copy_mem (mevent_set_nth(en, id), heap);");
	 Plc(L, 1, "mevent_set_free (en);");
	 Plc(L, 1, "return result;");
      end if;
      Plc(L, 1, "fatal_error (""mstate_enabled_event_mem: evt not found"");");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("mevent_t mstate_enabled_event (" & Nl &
	   "   mstate_t s," & Nl &
	   "   uint32_t id)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "return mstate_enabled_event_mem (s, id, SYSTEM_HEAP);");
      Plc(L, "}");
      --=======================================================================
      Prototype := "void " & Lib_Init_Func(Enabling_Test_Lib) & Nl & "()";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {}");
      --=======================================================================
      Prototype := "void " & Lib_Free_Func(Enabling_Test_Lib) & Nl & "()";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {}");
      End_Library(L);
   end;

end Pn.Compiler.Enabling_Test;
