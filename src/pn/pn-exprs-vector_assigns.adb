with
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Classes.Vectors,
  Pn.Exprs.Vectors,
  Pn.Vars;

use
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Classes.Vectors,
  Pn.Exprs.Vectors,
  Pn.Vars;

package body Pn.Exprs.Vector_Assigns is

   function New_Vector_Assign
     (V: in Expr;
      I: in Expr_List;
      E: in Expr;
      C: in Cls) return Expr is
      Result: constant Vector_Assign := new Vector_Assign_Record;
   begin
      Initialize(Result, C);
      Result.V := V;
      Result.I := I;
      Result.E := E;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Vector_Assign_Record) is
   begin
      Free(E.V);
      Free_All(E.I);
      Free(E.E);
   end;

   function Copy
     (E: in Vector_Assign_Record) return Expr is
   begin
      return New_Vector_Assign(Copy(E.V), Copy(E.I), Copy(E.E), E.C);
   end;

   function Get_Type
     (E: in Vector_Assign_Record) return Expr_Type is
   begin
      return A_Vector_Assign;
   end;

   procedure Color_Expr
     (E    : in     Vector_Assign_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Vc      : constant Vector_Cls := Vector_Cls(C);
      Indexes: constant Dom := Get_Index_Dom(Vc);
      Elements: constant Cls := Get_Elements_Cls(Vc);
   begin
      if Length(E.I) /= Size(Indexes) then
         State := Coloring_Failure;
         return;
      end if;
      Color_Expr(E.V, C, Cs, State);
      if Is_Success(State) then
         for I in 1..Length(E.I) loop
            Color_Expr(Ith(E.I, I), Ith(Indexes, I), Cs, State);
            if not Is_Success(State) then
               return;
            end if;
         end loop;
         Color_Expr(E.E, Elements, Cs, State);
      end if;
   end;

   function Possible_Colors
     (E: in Vector_Assign_Record;
      Cs: in Cls_Set) return Cls_Set is
   begin
      return Possible_Colors(E.V, Cs);
   end;

   function Is_Static
     (E: in Vector_Assign_Record) return Boolean is
   begin
      return Is_Static(E.V) and Is_Static(E.I) and Is_Static(E.E);
   end;

   function Is_Basic
     (E: in Vector_Assign_Record) return Boolean is
   begin
      return Is_Basic(E.V) and Is_Basic(E.I) and Is_Basic(E.E);
   end;

   function Get_True_Cls
     (E: in Vector_Assign_Record) return Cls is
   begin
      return Get_True_Cls(E.V);
   end;

   function Can_Overflow
     (E: in Vector_Assign_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Vector_Assign_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
      Vc      : constant Vector_Cls := Vector_Cls(Get_Cls(E.V));
      Index   : Expr_List;
      Assigned: Expr;
      Pos     : Card_Type;
   begin
      Evaluate(E      => E.V,
               B      => B,
               Check  => False,
               Result => Result,
               State  => State);
      if Is_Success(State) then
         Evaluate(E      => E.I,
                  B      => B,
                  Check  => True,
                  Result => Index,
                  State  => State);
         if Is_Success(State) then
            Evaluate(E      => E.E,
                     B      => B,
                     Check  => True,
                     Result => Assigned,
                     State  => State);
            if Is_Success(State) then
               Pos := Get_Index_Position(Vc, Index);
               Free_All(Index);
               Replace_Element(Vector(Result), Assigned, Natural(Pos));
            else
               Free(Result);
               Free_All(Index);
            end if;
         else
            Free(Result);
         end if;
      end if;
   end;

   function Static_Equal
     (Left: in Vector_Assign_Record;
      Right: in Vector_Assign_Record) return Boolean is
   begin
      return
        Static_Equal(Left.V, Right.V) and Static_Equal(Left.I, Right.I) and
        Static_Equal(Left.E, Right.E);
   end;

   function Compare
     (Left: in Vector_Assign_Record;
      Right: in Vector_Assign_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in Vector_Assign_Record) return Var_List is
      Result   : constant Var_List := Vars_In(E.V);
      Vars_In_I: Var_List := Vars_In(E.I);
      Vars_In_E: Var_List := Vars_In(E.E);
   begin
      Union(Result, Vars_In_I);
      Union(Result, Vars_In_E);
      Free(Vars_In_I);
      Free(Vars_In_E);
      return Result;
   end;

   procedure Get_Sub_Exprs
     (E: in Vector_Assign_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.V, R);
      Get_Sub_Exprs(E.I, R);
      Get_Sub_Exprs(E.E, R);
   end;

   procedure Get_Observed_Places
     (E     : in     Vector_Assign_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.V, Places);
      Get_Observed_Places(E.I, Places);
      Get_Observed_Places(E.E, Places);
   end;

   function To_Helena
     (E: in Vector_Assign_Record) return Ustring is
      Vc    : constant Vector_Cls := Vector_Cls(E.C);
      Result: Ustring;
   begin
      Result := To_Helena(E.V) & " :: ([" & To_Helena(E.I) & "] := " &
        To_Helena(E.E) & ")";
      return Result;
   end;

   function Compile_Evaluation
     (E: in Vector_Assign_Record;
      M: in Var_Mapping) return Ustring is
      Result: Ustring;
      Vc    : constant Vector_Cls := Vector_Cls(E.C);
   begin
      Result :=
        Cls_Assign_Func(E.C) & "(" &
        Compile_Evaluation(E.V, M, False) & ", " &
        Compile_Evaluation(E.E, M, True);
      for I in 1..Length(E.I) loop
         Result := Result & ", " & Compile_Evaluation(Ith(E.I, I), M, True);
      end loop;
      Result := Result & ")";
      return Result;
   end;

   function Replace_Var
     (E: in Vector_Assign_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: Expr;
   begin
      Result := New_Vector_Assign(Replace_Var(E.V, V, Ne),
                                  Replace_Var(E.I, V, Ne),
                                  Replace_Var(E.E, V, Ne),
                                  E.C);
      return Result;
   end;

end Pn.Exprs.Vector_Assigns;
