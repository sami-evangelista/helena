with
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Classes.Structs,
  Pn.Exprs.Structs,
  Pn.Vars;

use
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Classes.Structs,
  Pn.Exprs.Structs,
  Pn.Vars;

package body Pn.Exprs.Struct_Assigns is

   function New_Struct_Assign
     (Struct: in Expr;
      Comp  : in Ustring;
      Value : in Expr;
      C     : in Cls) return Expr is
      Result: constant Struct_Assign := new Struct_Assign_Record;
   begin
      Initialize(Result, C);
      Result.Struct := Struct;
      Result.Comp  := Comp;
      Result.Value := Value;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Struct_Assign_Record) is
   begin
      Free(E.Struct);
      Free(E.Value);
   end;

   function Copy
     (E: in Struct_Assign_Record) return Expr is
   begin
      return New_Struct_Assign(Copy(E.Struct), E.Comp, Copy(E.Value), E.C);
   end;

   function Get_Type
     (E: in Struct_Assign_Record) return Expr_Type is
   begin
      return A_Struct_Assign;
   end;

   procedure Color_Expr
     (E    : in     Struct_Assign_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Sc      : constant Struct_Cls := Struct_Cls(C);
      Comp    : constant Struct_Comp := Get_Component(Sc, E.Comp);
      Comp_Cls: constant Cls := Get_Cls(Comp);
   begin
      Color_Expr(E.Struct, C, Cs, State);
      if Is_Success(State) then
         Color_Expr(E.Value, Comp_Cls, Cs, State);
      end if;
   end;

   function Possible_Colors
     (E: in Struct_Assign_Record;
      Cs: in Cls_Set) return Cls_Set is
   begin
      return Possible_Colors(E.Struct, Cs);
   end;

   function Is_Static
     (E: in Struct_Assign_Record) return Boolean is
   begin
      return Is_Static(E.Struct) and Is_Static(E.Value);
   end;

   function Is_Basic
     (E: in Struct_Assign_Record) return Boolean is
   begin
      return Is_Basic(E.Struct) and Is_Basic(E.Value);
   end;

   function Get_True_Cls
     (E: in Struct_Assign_Record) return Cls is
   begin
      return Get_True_Cls(E.Struct);
   end;

   function Can_Overflow
     (E: in Struct_Assign_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Struct_Assign_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
      Assigned: Expr;
   begin
      Evaluate(E      => E.Struct,
               B      => B,
               Check  => False,
               Result => Result,
               State  => State);
      if Is_Success(State) then
         Evaluate(E      => E.Value,
                  B      => B,
                  Check  => True,
                  Result => Assigned,
                  State  => State);
         if Is_Success(State) then
            Replace_Component(Struct(Result), E.Comp, Assigned);
         else
            Free(Result);
         end if;
      end if;
   end;

   function Static_Equal
     (Left: in Struct_Assign_Record;
      Right: in Struct_Assign_Record) return Boolean is
   begin
      return
        Left.Comp = Right.Comp                  and then
        Static_Equal(Left.Struct, Right.Struct) and then
        Static_Equal(Left.Value, Right.Value);
   end;

   function Compare
     (Left: in Struct_Assign_Record;
      Right: in Struct_Assign_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in Struct_Assign_Record) return Var_List is
      Result   : constant Var_List := Vars_In(E.Struct);
      Vars_In_E: Var_List := Vars_In(E.Value);
   begin
      Union(Result, Vars_In_E);
      Free(Vars_In_E);
      return Result;
   end;

   procedure Get_Sub_Exprs
     (E: in Struct_Assign_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.Struct, R);
      Get_Sub_Exprs(E.Value, R);
   end;

   procedure Get_Observed_Places
     (E     : in     Struct_Assign_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.Struct, Places);
      Get_Observed_Places(E.Value, Places);
   end;

   function To_Helena
     (E: in Struct_Assign_Record) return Ustring is
      Sc    : constant Struct_Cls := Struct_Cls(E.C);
      F     : constant Struct_Comp := Get_Component(Sc, E.Comp);
      Result: Ustring;
   begin
      Result := To_Helena(E.Struct) & " :: (" & Get_Name(F) & " := " &
        To_Helena(E.Value) & ")";
      return Result;
   end;

   function Compile_Evaluation
     (E: in Struct_Assign_Record;
      M: in Var_Mapping) return Ustring is
      Result   : Ustring;
      Sc       : constant Struct_Cls := Struct_Cls(E.C);
      Component: constant Struct_Comp := Get_Component(Sc, E.Comp);
   begin
      Result := Cls_Assign_Comp_Func(E.C, Get_Name(Component)) & "(" &
        Compile_Evaluation(E.Struct, M, False) & ", " &
        Compile_Evaluation(E.Value,  M, True) & ")";
      return Result;
   end;

   function Replace_Var
     (E: in Struct_Assign_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: Expr;
   begin
      Result := New_Struct_Assign(Replace_Var(E.Struct, V, Ne),
                                  E.Comp,
                                  Replace_Var(E.Value, V, Ne),
                                  E.C);
      return Result;
   end;

end Pn.Exprs.Struct_Assigns;
