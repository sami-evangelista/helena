with
  Pn.Classes,
  Pn.Compiler,
  Pn.Compiler.Model,
  Pn.Compiler.State,
  Pn.Compiler.Names,
  Pn.Nodes,
  Pn.Nodes.Places,
  Pn.Vars,
  Pn.Vars.Iter;

use
  Pn.Classes,
  Pn.Compiler,
  Pn.Compiler.Model,
  Pn.Compiler.State,
  Pn.Compiler.Names,
  Pn.Nodes,
  Pn.Nodes.Places,
  Pn.Vars,
  Pn.Vars.Iter;

package body Pn.Exprs.Iterators is

   --==========================================================================
   --  an iterator type
   --==========================================================================

   function To_Helena
     (T: in Iterator_Type) return String is
   begin
      case T is
         when A_Forall  => return "forall";
         when A_Exists  => return "exists";
         when A_Card    => return "card";
         when A_Mult    => return "mult";
         when A_Sum     => return "sum";
         when A_Product => return "product";
         when A_Max     => return "max";
         when A_Min     => return "min";
      end case;
   end;



   --==========================================================================
   --  an iterator
   --==========================================================================

   function New_Iterator
     (V   : in Var_List;
      Iv  : in Var_List;
      T   : in Iterator_Type;
      Cond: in Expr;
      E   : in Expr;
      C   : in Cls) return Expr is
      Result: constant Iterator := new Iterator_Record;
   begin
      Initialize(Result, C);
      Result.V    := V;
      Result.Iv   := Iv;
      Result.T    := T;
      Result.Cond := Cond;
      Result.E    := E;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Iterator_Record) is
   begin
      Free_All(E.V);
      Free(E.Iv);
      if E.Cond /= null then
         Free(E.Cond);
      end if;
      if E.E /= null then
         Free(E.E);
      end if;
   end;

   function Copy
     (E: in Iterator_Record) return Expr is
      Result: constant Iterator := new Iterator_Record;
   begin
      Result.V := Copy(E.V);
      Result.T := E.T;
      if E.Cond /= null then
         Result.Cond := Copy(E.Cond);
         Map_Vars(Result.Cond, E.V, Result.V);
      else
         Result.Cond := null;
      end if;
      if E.E /= null then
         Result.E := Copy(E.E);
         Map_Vars(Result.E, E.V, Result.V);
      else
         Result.E := null;
      end if;
      return Expr(Result);
   end;

   function Get_Type
     (E: in Iterator_Record) return Expr_Type is
   begin
      return A_Iterator;
   end;

   procedure Color_Expr
     (E    : in     Iterator_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
   begin
      State := Coloring_Success;
      if E.Cond /= null then
         Color_Expr(E.Cond, Bool_Cls, Cs, State);
         if not Is_Success(State) then
            return;
         end if;
      end if;
      if E.E /= null then
         Color_Expr(E.E, C, Cs, State);
      end if;
   end;

   function Possible_Colors
     (E: in Iterator_Record;
      Cs: in Cls_Set) return Cls_Set is
      Result: Cls_Set;
   begin
      case E.T is

            --===
            --  forall or exists =>
            --    return the boolean class
            --===
         when A_Forall
           |  A_Exists =>
            Result := New_Cls_Set((1 => Bool_Cls));

            --===
            --  card or mult =>
            --    only keep the numerical colors of Cs
            --===
         when A_Card
           |  A_Mult =>
            Result := Copy(Cs);
            Filter_On_Type(Result, (A_Num_Cls  => True,
                                    others     => False));

            --===
            --  min or max =>
            --    get the potential colors of the expression of the iterator
            --    and only keep the numerical or enumerate ones
            --===
         when A_Min
           |  A_Max =>
            Result := Possible_Colors(E.E, Cs);
            Filter_On_Type(Result, (A_Num_Cls  => True,
                                    A_Enum_Cls => True,
                                    others     => False));

            --===
            --  sum or product =>
            --    get the potential colors of the expression of the iterator
            --    and only keep the numerical ones
            --===
         when A_Sum
           |  A_Product =>
            Result := Possible_Colors(E.E, Cs);
            Filter_On_Type(Result, (A_Num_Cls => True,
                                    others    => False));
      end case;
      return Result;
   end;

   function Is_Static
     (E: in Iterator_Record) return Boolean is
   begin
      return False;
   end;

   function Is_Basic
     (E: in Iterator_Record) return Boolean is
      V: Var;
   begin
      if False then
         for I in 1..Length(E.V) loop
            V := Ith(E.V, I);
            if Get_Type(V) = A_Place_Iter_Var then
               return False;
            end if;
         end loop;
         return ((E.Cond = null or else Is_Basic(E.Cond)) and
                 (E.E    = null or else Is_Basic(E.E)));
      else

         --===
         --  an iterator is currently not a complex expressions
         --===
         return False;
      end if;
   end;

   function Get_True_Cls
     (E: in Iterator_Record) return Cls is
      Result: Cls;
   begin
      case E.T is
         when A_Forall
           |  A_Exists =>
            Result := Bool_Cls;
         when A_Card
           |  A_Mult =>
            Result := Int_Cls;
         when A_Min
           |  A_Max
           |  A_Sum
           |  A_Product =>
            Result := Get_True_Cls(E.E);
      end case;
      return Result;
   end;

   function Can_Overflow
     (E: in Iterator_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Iterator_Record;
      B     : in     Binding;
      Result:    out Expr;
      State :    out Evaluation_State) is
   begin
      pragma Assert(False, "expression cannot be evaluated");
      Result := null;
      State := Evaluation_Failure;
   end;

   function Static_Equal
     (Left : in Iterator_Record;
      Right: in Iterator_Record) return Boolean is
   begin
      return False;
   end;

   function Compare
     (Left : in Iterator_Record;
      Right: in Iterator_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in Iterator_Record) return Var_List is
      Result: constant Var_List := New_Var_List;
      Tmp   : Var_List;
   begin
      if E.Cond /= null then
         Tmp := Vars_In(E.Cond);
         Union(Result, Tmp);
         Free(Tmp);
      end if;
      if E.E /= null then
         Tmp := Vars_In(E.E);
         Union(Result, Tmp);
         Free(Tmp);
      end if;
      return Result;
   end;

   procedure Get_Sub_Exprs
     (E: in Iterator_Record;
      R: in Expr_List) is
   begin
      if E.Cond /= null then
         Get_Sub_Exprs(E.Cond, R);
      end if;
      if E.E /= null then
         Get_Sub_Exprs(E.E, R);
      end if;
   end;

   procedure Get_Observed_Places
     (E     : in     Iterator_Record;
      Places: in out String_Set) is
      V: Var;
      P: Place;
   begin
      for I in 1..Length(E.V) loop
         V := Ith(E.V, I);
         P := Get_Dom_Place(Iter_Var(V));
         if P /= null then
            String_Set_Pkg.Insert(Places, Get_Name(P));
         end if;
      end loop;
      if E.Cond /= null then
         Get_Observed_Places(E.Cond, Places);
      end if;
      if E.E /= null then
         Get_Observed_Places(E.E, Places);
      end if;
   end;

   function To_Helena
     (E: in Iterator_Record) return Ustring is
      Result: Ustring := Null_String;
   begin
      Result := To_Helena(E.T) & "(" & To_Helena(E.V);
      if E.Cond /= null then
         Result := Result & " | " & To_Helena(E.Cond);
      end if;
      if E.E /= null then
         Result := Result & ": " & To_Helena(E.E);
      end if;
      Result := Result & ")";
      return Result;
   end;

   function Compile_Evaluation
     (E: in Iterator_Record;
      M: in Var_Mapping) return Ustring is
      Result: Ustring;
   begin
      Result := Expr_Name(E.Me) & " (prop_state";
      for I in 1..Length(E.Iv) loop
	 Result := Result & ", " & Var_Name(Ith(E.Iv, I));
      end loop;
      Result := Result & ")";
      Pn.Compiler.Model.Add_Expr(E.Me);
      return Result;
   end;

   procedure Compile_Definition
     (E  : in Iterator_Record;
      R  : in Var_Mapping;
      Lib: in Library) is

      Func_Name: constant Ustring := Expr_Name(E.Me);
      Cls_Name : constant Ustring := Names.Cls_Name(E.C);
      Prototype: Ustring;
      Init_Val : Ustring;
      V        : Var;
      Inherited: Var_List := Copy(E.Iv);

      function Gen_Inherited_Var_Defs return Ustring is
	 Result: Ustring := Null_String;
	 V     : Var;
      begin
	 for I in 1..Length(Inherited) loop
	    V := Ith(Inherited, I);
	    Result := Result & "," & Nl &
	      "   " & Names.Cls_Name(Get_Cls(V)) & " " & Var_Name(V);
	 end loop;
	 return Result;
      end;

      function Gen_Inherited_Vars return Ustring is
	 Result: Ustring := Null_String;
	 V     : Var;
      begin
	 for I in 1..Length(Inherited) loop
	    V := Ith(Inherited, I);
	    Result := Result & ", " & Var_Name(V);
	 end loop;
	 return Result;
      end;

      --===
      --  handler generic to any iteration variable
      --===
      procedure Handle_Var
        (Pos : in Index_Type;
         Tabs: in Natural) is
      begin
         if Pos /= Length(E.V) then

            --===
            --  this is not the last variable of the iteration =>
            --    we simply call the next function
            --===
            Plc(Lib, Tabs,
                Func_Name & "_" & (Pos + 1) & " (prop_state" &
		  Gen_Inherited_Vars & ", stop, result);");
            Plc(Lib, Tabs, "if (*stop) break;");

         else

            --===
            --  this is the last variable of the iteration =>
            --    we check the condition if there is one
            --===
            if E.Cond /= null then
               Plc(Lib, Tabs, "if (" & Compile_Evaluation(E.Cond, R) & ")");
            end if;
            Plc(Lib, Tabs, "{");
            case E.T is
               when A_Forall =>
                  Plc(Lib, Tabs + 1,
                      "if (!(" & Compile_Evaluation(E.E, R) & ")) {");
                  Plc(Lib, Tabs + 2, "*result = FALSE;");
                  Plc(Lib, Tabs + 2, "*stop = TRUE;");
                  Plc(Lib, Tabs + 1, "}");
               when A_Exists =>
                  Plc(Lib, Tabs + 1, "*result = TRUE;");
                  Plc(Lib, Tabs + 1, "*stop = TRUE;");
               when A_Card =>
                  Plc(Lib, Tabs + 1, "(*result) ++;");
               when A_Sum =>
                  Plc(Lib, Tabs + 1,
                      "(*result) += " & Compile_Evaluation(E.E, R) & ";");
               when A_Product =>
                  Plc(Lib, Tabs + 1,
                      "(*result) *= " & Compile_Evaluation(E.E, R) & ";");
               when A_Max =>
                  Plc(Lib, Tabs + 1, Cls_Name & " tmp =" &
                      Compile_Evaluation(E.E, R) & ";");
                  Plc(Lib, Tabs + 1,
                      "if (" & Cls_Bin_Operator_Name(E.C, Sup_Op) &
                      "(tmp, (*result))) {");
                  Plc(Lib, Tabs + 2, "*result = tmp;");
                  Plc(Lib, Tabs + 1, "}");
               when A_Min =>
                  Plc(Lib, Tabs + 1, Cls_Name & " tmp =" &
                      Compile_Evaluation(E.E, R) & ";");
                  Plc(Lib, Tabs + 1,
                      "if (" & Cls_Bin_Operator_Name(E.C, Sup_Op) &
                      "(*result, tmp)) {");
                  Plc(Lib, Tabs + 2, "*result = tmp;");
                  Plc(Lib, Tabs + 1, "}");
               when A_Mult =>
                  Plc(Lib, Tabs + 1, "(*result) += list->mult;");
            end case;
            Plc(Lib, Tabs, "}");
         end if;
      end;

      --===
      --  handler for an iteration variable that does not loop over the
      --  content of a place
      --===
      procedure Handle_Non_Place_Var
        (V: in Iter_Var;
         I: in Index_Type) is
         F_Name: constant Ustring := Func_Name & "_" & I;
      begin
         Prototype :=
           "void " & F_Name & " (" & Nl &
           "   mstate_t prop_state" &
	   Gen_Inherited_Var_Defs & "," & Nl &
           "   bool_t * stop," & Nl &
	   "   " & Cls_Name & " * result)";
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype & " {");
	 Compile_Definition(V, 1, Get_Code_File(Lib).all);
         Compile_Initialization(V, 1, Lib);
         Plc(Lib, 1, "if (" & Compile_Start_Iteration_Check(V) & ")");
         Plc(Lib, 2, "while (!(*stop)) {");
	 Append(Inherited, Var(V));
         Handle_Var(I, 3);
         Plc(Lib, 3, "if (" & Compile_Is_Last_Check(V) & ") break;");
         Compile_Iteration(V, 3, Lib);
         Plc(Lib, 2, "}");
	 Plc(Lib, "}");
      end;

      --===
      --  handler for an iteration variable that loop over the content of a
      --  place
      --===
      procedure Handle_Place_Iter_Var
        (V: in Iter_Var;
         I: in Index_Type) is
         C        : constant Cls    := Get_Cls(V);
         P        : constant Place  := Get_Dom_Place(V);
         Comp     : constant Ustring := State_Component_Name(P);
         V_Name   : constant Ustring := Var_Name(Var(V));
         C_Name   : constant Ustring := Names.Cls_Name(C);
         F_Name   : constant Ustring := Func_Name & "_" & I;
         Prototype: constant Ustring :=
           "void " & F_Name & " (" & Nl &
           "   mstate_t prop_state" &
	   Gen_Inherited_Var_Defs & "," & Nl &
           "   bool_t * stop," & Nl &
           "   " & Cls_Name & " * result)";
      begin
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype & " {");
	 Compile_Definition(V, 1, Get_Code_File(Lib).all);
         Plc(Lib, 1, Local_State_List_Type(P) & " list = " &
	       "prop_state->" & Comp & ".list;");
         Plc(Lib, 1, "for(; list && !(*stop); list=list->next) {");
         Plc(Lib, 2, V_Name & " = list->c;");
	 Append(Inherited, Var(V));
         Handle_Var(I, 2);
         Plc(Lib, 1, "}");
         Plc(Lib, "}");
      end;

   begin
      --===
      --  for each variable of the list we declare a variable and according to
      --  its type we call the appropriate handler
      --===
      for I in 1..Length(E.V) loop
         V := Ith(E.V, I);
         case Iter_Var_Type(Get_Type(V)) is
            when A_Place_Iter_Var  =>
	       Handle_Place_Iter_Var(Iter_Var(V), I);
	    when others =>
               Handle_Non_Place_Var(Iter_Var(V), I);
         end case;
      end loop;
      Free(Inherited);
      Inherited := E.Iv;

      --===
      --  initialize the result according to the iterator type
      --===
      case E.T is
         when A_Forall  => Init_Val := To_Ustring("TRUE");
         when A_Exists  => Init_Val := To_Ustring("FALSE");
         when A_Card    => Init_Val := To_Ustring("0");
         when A_Mult    => Init_Val := To_Ustring("0");
         when A_Max     => Init_Val := Cls_First_Const_Name(E.C);
         when A_Min     => Init_Val := Cls_Last_Const_Name(E.C);
         when A_Sum     => Init_Val := To_Ustring("0");
         when A_Product => Init_Val := To_Ustring("1");
      end case;

      Prototype := Cls_Name & " " & Expr_Name(E.Me) & " (" & Nl &
	"   mstate_t prop_state" &
	Gen_Inherited_Var_Defs & ")";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "bool_t stop = FALSE;");
      Plc(Lib, 1, Cls_Name & " result = " & Init_Val & ";");
      Plc(Lib, 1, Func_Name & "_1 (prop_state" &
		  Gen_Inherited_Vars & ", &stop, &result);");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
   end;

   function Replace_Var
     (E: in Iterator_Record;
      V: in Var;
      Ne: in Expr) return Expr is
   begin
      pragma Assert(False);
      return null;
   end;

end Pn.Exprs.Iterators;
