with
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Exprs.Var_Refs,
  Pn.Classes,
  Pn.Vars;

use
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Exprs.Var_Refs,
  Pn.Classes,
  Pn.Vars;

package body Pn.Exprs is

   --==========================================================================
   --  Expression
   --==========================================================================

   procedure Deallocate is
      new Ada.Unchecked_Deallocation(Expr_Record'Class, Expr);

   procedure Initialize
     (E: access Expr_Record'Class;
      C: in     Cls) is
   begin
      E.C := C;
      E.Me := Expr(E);
   end;

   procedure Free
     (E: in out Expr) is
   begin
      Free(E.all);
      Deallocate(E);
      E := null;
   end;

   function Copy
     (E: in Expr) return Expr is
      Result: Expr;
   begin
      Result := Copy(E.all);
      Initialize(Result, E.C);
      return Result;
   end;

   function Get_Cls
     (E: access Expr_Record'Class) return Cls is
   begin
      return E.C;
   end;

   procedure Set_Cls
     (E: access Expr_Record'Class;
      C: in     Cls) is
   begin
      E.C := C;
   end;

   function Get_Type
     (E: access Expr_Record'Class) return Expr_Type is
   begin
      return Get_Type(E.all);
   end;

   procedure Color_Expr
     (E    : access Expr_Record'Class;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Possible: Cls_Set := Possible_Colors(E, Cs);
      Error   : constant Boolean := not Contains(Possible, Get_Root_Cls(C));
   begin
      Free(Possible);
      if Error then
         State := Coloring_Failure;
      else
         Set_Cls(E, C);
         Color_Expr(E.all, C, Cs, State);
      end if;
   end;

   function Possible_Colors
     (E: access Expr_Record'Class;
      Cs: in     Cls_Set) return Cls_Set is
      Tmp   : Cls_Set := Possible_Colors(E.all, Cs);
      Result: constant Cls_Set := Get_Root_Cls(Tmp);
   begin
      Free(Tmp);
      return Result;
   end;

   function Is_Assignable
     (E: access Expr_Record'Class) return Boolean is
   begin
      return Is_Assignable(E.all);
   end;

   function Is_Static
     (E: access Expr_Record'Class) return Boolean is
   begin
      return Is_Static(E.all);
   end;

   function Is_Basic
     (E: access Expr_Record'Class) return Boolean is
   begin
      return Is_Basic(E.all);
   end;

   function Get_True_Cls
     (E: access Expr_Record'Class) return Cls is
   begin
      return Get_True_Cls(E.all);
   end;

   function Can_Overflow
     (E: access Expr_Record'Class) return Boolean is
   begin
      return not Is_Sub_Cls(Get_True_Cls(E), E.C) or else Can_Overflow(E.all);
   end;

   procedure Evaluate
     (E     : access Expr_Record'Class;
      B     : in     Binding;
      Check: in     Boolean;
      Result:    out Expr;
      State:    out Evaluation_State) is
   begin
      Evaluate(E.all, B, Result, State);
      if Is_Success(State) then
         if Check and then not Is_Const_Of_Cls(E.C, Result) then
            Free(Result);
            Result := null;
            State := Evaluation_Out_Of_Range;
         end if;
      else
         Result := null;
      end if;
   end;

   procedure Evaluate_Static
     (E     : access Expr_Record'Class;
      Check : in     Boolean;
      Result:    out Expr;
      State :    out Evaluation_State) is
   begin
      Evaluate(E, Null_Binding, Check, Result, State);
   end;

   function Is_Bool_Expr
     (E: access Expr_Record'Class) return Boolean is
   begin
      return Get_Root_Cls(E.C) = Bool_Cls;
   end;

   function Static_Equal
     (Left : access Expr_Record'Class;
      Right: access Expr_Record'Class) return Boolean is
      Result   : Boolean;
      Left_Val: Expr;
      Right_Val: Expr;
      State    : Evaluation_State;
   begin
      if
        Left.C /= null  and Right.C /= null and
        Is_Static(Left) and Is_Static(Right)
      then
         Evaluate_Static(Left, False, Left_Val, State);
         if not Is_Success(State) then
            return False;
         end if;
         Evaluate_Static(Right, False, Right_Val, State);
         if not Is_Success(State) then
            Free(Left_Val);
            return False;
         end if;
         pragma Assert(Get_Type(Left_Val) = Get_Type(Right_Val));
         Result := Compare(Left_Val.all, Right_Val.all) = Cmp_Eq;
         Free(Left_Val);
         Free(Right_Val);
      else
         if Get_Type(Left) /= Get_Type(Right) then
            Result := False;
         else
            Result := Static_Equal(Left.all, Right.all);
         end if;
      end if;
      return Result;
   end;

   function Compare
     (Left : access Expr_Record'Class;
      Right: access Expr_Record'Class) return Comparison_Result is
      Result: Comparison_Result;
   begin
      if Get_Type(Left) /= Get_Type(Right) then
         Result := Cmp_Error;
      else
         Result := Compare(Left.all, Right.all);
      end if;
      return Result;
   end;

   function Vars_In
     (E: access Expr_Record'Class) return Var_List is
   begin
      return Vars_In(E.all);
   end;

   procedure Map_Vars
     (E    : in out Expr;
      Vars : in     Var_List;
      Nvars: in     Var_List) is
      V: Var;
      Nv: Var;
      Ex: Expr;
   begin
      for I in 1..Length(Vars) loop
         V := Ith(Vars, I);
         Nv := Ith(Nvars, I);
         Ex := New_Var_Ref(Nv);
         Replace_Var(E, V, Ex);
         Free(Ex);
      end loop;
   end;

   procedure Get_Sub_Exprs
     (E: access Expr_Record'Class;
      R: in     Expr_List) is
   begin
      Append(R, Expr(E));
      Get_Sub_Exprs(E.all, R);
   end;

   function Get_Sub_Exprs
     (E: access Expr_Record'Class) return Expr_List is
      Result: constant Expr_List := New_Expr_List;
   begin
      Get_Sub_Exprs(E, Result);
      return Result;
   end;

   function Get_Observed_Places
     (E: access Expr_Record'Class) return String_Set is
      Result: String_Set := String_Set_Pkg.Empty_Set;
   begin
      Get_Observed_Places(E.all, Result);
      return Result;
   end;

   procedure Get_Observed_Places
     (E     : access Expr_Record'Class;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.all, Places);
   end;

   function Is_Sub_Expr
     (E  : access Expr_Record'Class;
      Sub: access Expr_Record'Class) return Boolean is
      Result: Boolean  := False;
      Subs  : Expr_List := Get_Sub_Exprs(E);
   begin
      for I in 1..Length(Subs) loop
         if Ith(Subs, I) = Expr(Sub) then
            Result := True;
         end if;
      end loop;
      Free(Subs);
      return Result;
   end;

   function Get_Valid_Sub_Exprs
     (E: access Expr_Record'Class;
      P: in     Expr_Predicate_Func) return Expr_List is
      Result   : constant Expr_List := New_Expr_List;
      Sub_Exprs: Expr_List := Get_Sub_Exprs(E);
      Ith_Expr: Expr;
   begin
      for I in 1..Length(Sub_Exprs) loop
         Ith_Expr := Ith(Sub_Exprs, I);
         if P.all(Ith_Expr) then
            Append(Result, Ith_Expr);
         end if;
         Ith_Expr := Ith(Sub_Exprs, I);
      end loop;
      Free(Sub_Exprs);
      return Result;
   end;

   procedure Assign
     (E  : access Expr_Record'Class;
      B  : in     Binding;
      Val: in     Expr) is
   begin
      Assign(E.all, B, Val);
   end;

   function Get_Assign_Expr
     (E  : access Expr_Record'Class;
      Val: in     Expr) return Expr is
      Result: constant Expr := Get_Assign_Expr(E.all, Val);
   begin
      return Result;
   end;

   function To_Helena
     (E: access Expr_Record'Class) return Ustring is
      Result: Ustring := To_Helena(E.all);
   begin
      case Get_Type(E) is
         when A_Bin_Op
           |  A_Un_Op
           |  A_If_Then_Else =>
            Result := "(" & Result & ")";
         when others =>
            null;
      end case;
      return Result;
   end;

   function Compile_Evaluation
     (E    : access Expr_Record'Class;
      R    : in     Var_Mapping;
      Check: in     Boolean) return Ustring is
      Replaced_By: Ustring;
      Result     : Ustring;
   begin
      Result := Compile_Evaluation(E.all, R);

      --===
      --  add additional test which check that the expression is correct
      --===
      if Check and then Can_Overflow(E) then
         Result := Cls_Check_Func(E.C) & "(" & Result & ")";
      end if;
      Result := "(" & Result & ")";
      return Result;
   end;

   function Compile_Evaluation
     (E: access Expr_Record'Class) return Ustring is
   begin
      return Compile_Evaluation(E, Empty_Var_Mapping);
   end;

   function Compile_Evaluation
     (E: access Expr_Record'Class;
      M: in     Var_Mapping) return Ustring is
   begin
      return Compile_Evaluation(E, M, True);
   end;

   procedure Compile_Definition
     (E  : access Expr_Record'Class;
      Lib: in     Library) is
   begin
      Compile_Definition(E.all, Empty_Var_Mapping, Lib);
   end;

   procedure Compile_Definition
     (E  : access Expr_Record'Class;
      R  : in     Var_Mapping;
      Lib: in     Library) is
   begin
      Compile_Definition(E.all, R, Lib);
   end;

   function Replace_Var
     (E: access Expr_Record'Class;
      V: in     Var;
      Ne: in     Expr) return Expr is
      Result: Expr;
   begin
      Result  := Replace_Var(E.all, V, Ne);
      Result.C := E.C;
      return Result;
   end;

   procedure Replace_Var
     (E: in out Expr;
      V: in     Var;
      Ne: in     Expr) is
      Tmp: Expr;
   begin
      Tmp := Replace_Var(E, V, Ne);
      Free(E);
      E := Tmp;
   end;



   --==========================================================================
   --  Expression list
   --==========================================================================

   package EAP renames Expr_Array_Pkg;

   function New_Expr_List return Expr_List is
      Result: constant Expr_List := new Expr_List_Record;
   begin
      Result.Exprs := EAP.Empty_Array;
      return Result;
   end;

   function New_Expr_List
     (E: in Expr_Array) return Expr_List is
      Result: constant Expr_List := new Expr_List_Record;
   begin
      Result.Exprs := EAP.New_Array(EAP.Element_Array(E));
      return Result;
   end;

   procedure Free
     (E: in out Expr_List) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Expr_List_Record, Expr_List);
   begin
      Deallocate(E);
      E := null;
   end;

   procedure Free_All
     (E: in out Expr_List) is
      procedure Free is new EAP.Generic_Apply(Free);
   begin
      Free(E.Exprs);
      Free(E);
   end;

   function Length
     (E: in Expr_List) return Count_Type is
   begin
      return EAP.Length(E.Exprs);
   end;

   function Ith
     (E: in Expr_List;
      I: in Index_Type) return Expr is
   begin
      return EAP.Ith(E.Exprs, I);
   end;

   function Copy
     (E: in Expr_List) return Expr_List is
      Result: constant Expr_List := New_Expr_List;
      function Copy_All is new EAP.Generic_Map(Copy);
   begin
      Result.Exprs := Copy_All(E.Exprs);
      return Result;
   end;

   procedure Append
     (E: in Expr_List;
      Ex: in Expr) is
   begin
      EAP.Append(E.Exprs, Ex);
   end;

   procedure Append
     (E: in Expr_List;
      F: in Expr_List) is
   begin
      EAP.Append(E.Exprs, F.Exprs);
   end;

   procedure Insert
     (E: in Expr_List;
      Ex: in Expr;
      I: in Index_Type) is
   begin
      EAP.Insert(E.Exprs, Ex, I);
   end;

   procedure Delete
     (E   : in Expr_List;
      I   : in Index_Type;
      Free: in Boolean) is
      Ex: Expr := Ith(E, I);
   begin
      EAP.Delete(E.Exprs, I);
      if Free then
         Pn.Exprs.Free(Ex);
      end if;
   end;

   procedure Delete_Last
     (E   : in Expr_List;
      Free: in Boolean) is
      Ex: Expr;
   begin
      if Free then
         Ex := EAP.Last(E.Exprs);
         Pn.Exprs.Free(Ex);
      end if;
      EAP.Delete_Last(E.Exprs);
   end;

   procedure Replace
     (E   : in Expr_List;
      I   : in Index_Type;
      Ex  : in Expr;
      Free: in Boolean) is
      Old: Expr := EAP.Ith(E.Exprs, I);
   begin
      if Free then
         Pn.Exprs.Free(Old);
      end if;
      EAP.Replace(E.Exprs, Ex, I);
   end;

   procedure Color_Expr_List
     (E    : in     Expr_List;
      D    : in     Dom;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
   begin
      if Size(D) /= Length(E) then
         State := Coloring_Failure;
      else
         State := Coloring_Success;
         for I in 1..Length(E) loop
            Color_Expr(Ith(E, I), Ith(D, I), Cs, State);
            if not Is_Success(State) then
               return;
            end if;
         end loop;
      end if;
   end;

   function Is_Static
     (E: in Expr_List) return Boolean is
   begin
      for I in 1..Length(E) loop
         if not Is_Static(Ith(E, I)) then
            return False;
         end if;
      end loop;
      return True;
   end;

   function Is_Basic
     (E: in Expr_List) return Boolean is
   begin
      for I in 1..Length(E) loop
         if not Is_Basic(Ith(E, I)) then
            return False;
         end if;
      end loop;
      return True;
   end;

   procedure Evaluate
     (E     : in     Expr_List;
      B     : in     Binding;
      Check: in     Boolean;
      Result:    out Expr_List;
      State:    out Evaluation_State) is
      Tmp: Expr;
   begin
      Result := New_Expr_List;
      State := Evaluation_Success;
      for I in 1..Length(E) loop
         Evaluate(Ith(E, I), B, Check, Tmp, State);
         if Is_Success(State) then
            Append(Result, Tmp);
         else
            Free_All(Result);
            Result := null;
            return;
         end if;
      end loop;
   end;

   function Static_Equal
     (Left: in Expr_List;
      Right: in Expr_List) return Boolean is
   begin
      if Length(Left) /= Length(Right) then
         return False;
      else
         for I in 1..Length(Left) loop
            if not Static_Equal(Ith(Left, I), Ith(Right, I)) then
               return False;
            end if;
         end loop;
         return True;
      end if;
   end;

   function Compare
     (Left: in Expr_List;
      Right: in Expr_List) return Comparison_Result is
      Result: Comparison_Result;
   begin
      if    Length(Left) > Length(Right) then
         Result := Cmp_Sup;
      elsif Length(Left) < Length(Right) then
         Result := Cmp_Inf;
      else
         Result := Cmp_Eq;
         for I in 1..Length(Left) loop
            Result := Compare(Ith(Left, I), Ith(Right, I));
            if Result /= Cmp_Eq then
               exit;
            end if;
         end loop;
      end if;
      return Result;
   end;

   function Vars_In
     (E: in Expr_List) return Var_List is
      procedure Add_Var
        (E   : in     Expr;
         Vars: in out Var_List) is
         Tmp: Var_List := Vars_In(E);
      begin
         Union(Vars, Tmp);
         Free(Tmp);
      end;
      procedure Compute_Vars is new EAP.Generic_Compute(Var_List, Add_Var);
      Result: Var_List := New_Var_List;
   begin
      Compute_Vars(E.Exprs, Result);
      return Result;
   end;

   function Vars_At_Top
     (E: in Expr_List) return Var_List is
      procedure Add_Var
        (E   : in     Expr;
         Vars: in out Var_List) is
         V: Var_Ref;
      begin
         if Get_Type(E) = A_Var then
            V := Var_Ref(E);
            if not Contains(Vars, Get_Var(V)) then
               Append(Vars, Get_Var(V));
            end if;
         end if;
      end;
      procedure Compute_Vars is new EAP.Generic_Compute(Var_List, Add_Var);
      Result: Var_List := New_Var_List;
   begin
      Compute_Vars(E.Exprs, Result);
      return Result;
   end;

   procedure Map_Vars
     (E    : in Expr_List;
      Vars: in Var_List;
      Nvars: in Var_List) is
      Tmp: EAP.Array_Type := EAP.Empty_Array;
      Ex: Expr;
   begin
      for I in 1..Length(E) loop
         Ex := Ith(E, I);
         Map_Vars(Ex, Vars, Nvars);
         EAP.Append(Tmp, Ex);
      end loop;
      E.Exprs := Tmp;
   end;

   procedure Get_Sub_Exprs
     (E: in Expr_List;
      R: in Expr_List) is
   begin
      for I in 1..Length(E) loop
         Get_Sub_Exprs(Ith(E, I), R);
      end loop;
   end;

   procedure Get_Observed_Places
     (E     : in     Expr_List;
      Places: in out String_Set) is
   begin
      for I in 1..Length(E) loop
         Get_Observed_Places(Ith(E, I), Places);
      end loop;
   end;

   function Is_Sub_Expr
     (E  : in     Expr_List;
      Sub: access Expr_Record'Class) return Boolean is
      function Is_Sub_Expr
        (E: in Expr) return Boolean is
      begin
         return Is_Sub_Expr(E, Sub);
      end;
      function Is_Sub_Expr is new EAP.Generic_Exists(Is_Sub_Expr);
   begin
      return Is_Sub_Expr(E.Exprs);
   end;

   function Get_Valid_Sub_Exprs
     (E: in Expr_List;
      P: in Expr_Predicate_Func) return Expr_List is
      Result: constant Expr_List := New_Expr_List;
      Sub   : Expr_List;
   begin
      for I in 1..Length(E) loop
         Sub := Get_Valid_Sub_Exprs(Ith(E, I), P);
         for J in 1..Length(Sub) loop
            Append(Result, Ith(Sub, J));
         end loop;
         Free(Sub);
      end loop;
      return Result;
   end;

   function To_Helena
     (E  : in Expr_List;
      Sep: in Ustring) return Ustring is
      function To_Helena
        (E: in Expr) return String is
      begin
         return To_String(To_Helena(E));
      end;
      function To_Helena is
	 new EAP.Generic_To_String(To_String => To_Helena,
				   Separator => To_String(Sep),
				   Empty     => "");
   begin
      return To_Ustring(To_Helena(E.Exprs));
   end;

   function To_Helena
     (E  : in Expr_List) return Ustring is
   begin
      return To_Helena(E, To_Ustring(", "));
   end;

   function Compile_Evaluation
     (E    : in Expr_List;
      R    : in Var_Mapping;
      Check: in Boolean) return Ustring is
      function Compile
        (E: in Expr) return String is
      begin
         return To_String(Compile_Evaluation(E, R, Check));
      end;
      function Compile is new EAP.Generic_To_String(To_String => Compile,
                                                    Separator => ", ",
                                                    Empty     => "");
   begin
      return To_Ustring(Compile(E.Exprs));
   end;

   function Replace_Var
     (E: in Expr_List;
      V: in Var;
      Ne: in Expr) return Expr_List is
      Result: constant Expr_List := New_Expr_List;
   begin
      for I in 1..Length(E) loop
         Append(Result, Replace_Var(Ith(E, I), V, Ne));
      end loop;
      return Result;
   end;

   procedure Replace_Var
     (E : in Expr_List;
      V : in Var;
      Ne: in Expr) is
      Tmp: EAP.Array_Type := EAP.Empty_Array;
      Ex: Expr;
   begin
      for I in 1..Length(E) loop
         Ex := Ith(E, I);
         Replace_Var(Ex, V, Ne);
         EAP.Append(Tmp, Ex);
      end loop;
      E.Exprs := Tmp;
   end;

end Pn.Exprs;
