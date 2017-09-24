with
  Pn.Bindings,
  Pn.Classes,
  Pn.Exprs.Enum_Consts,
  Pn.Vars;

use
  Pn.Bindings,
  Pn.Classes,
  Pn.Exprs.Enum_Consts,
  Pn.Vars;

package body Pn.Exprs.Var_Refs is

   function New_Var_Ref
     (V: in Var) return Expr is
      Result: constant Var_Ref := new Var_Ref_Record;
   begin
      Initialize(Result, Get_Cls(V));
      Result.V := V;
      return Expr(Result);
   end;

   function Get_Var
     (V: in Var_Ref) return Var is
   begin
      return V.V;
   end;

   procedure Free
     (E: in out Var_Ref_Record) is
   begin
      null;
   end;

   function Copy
     (E: in Var_Ref_Record) return Expr is
      Result: constant Var_Ref := new Var_Ref_Record;
   begin
      Initialize(Result, E.C);
      Result.V := E.V;
      return Expr(Result);
   end;

   function Get_Type
     (E: in Var_Ref_Record) return Expr_Type is
      Result: Expr_Type;
   begin
      if Is_Const(E.V) then
         Result := A_Const;
      else
         Result := A_Var;
      end if;
      return Result;
   end;

   procedure Color_Expr
     (E    : in     Var_Ref_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
   begin
      State := Coloring_Success;
   end;

   function Possible_Colors
     (E: in Var_Ref_Record;
      Cs: in Cls_Set) return Cls_Set is
   begin
      return New_Cls_Set((1 => Get_Cls(E.V)));
   end;

   function Is_Assignable
     (E: in Var_Ref_Record) return Boolean is
   begin
      return not Is_Const(E.V);
   end;

   function Is_Static
     (E: in Var_Ref_Record) return Boolean is
   begin
      return Is_Static(E.V);
   end;

   function Is_Basic
     (E: in Var_Ref_Record) return Boolean is
   begin
      return True;
   end;

   function Get_True_Cls
     (E: in Var_Ref_Record) return Cls is
   begin
      return Get_Cls(E.V);
   end;

   function Can_Overflow
     (E: in Var_Ref_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Var_Ref_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
   begin
      if B /= Null_Binding and then Is_Bound(B, E.V) then
         Result := Copy(Get_Var_Binding(B, E.V));
         State := Evaluation_Success;
      elsif Is_Const(E.V) then
         Evaluate(E      => Get_Init(E.V),
                  B      => B,
                  Check  => True,
                  Result => Result,
                  State  => State);
      else
         State := Evaluation_Unbound_Variable;
      end if;
   end;

   function Static_Equal
     (Left: in Var_Ref_Record;
      Right: in Var_Ref_Record) return Boolean is
   begin
      return Left.V = Right.V;
   end;

   function Compare
     (Left: in Var_Ref_Record;
      Right: in Var_Ref_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in Var_Ref_Record) return Var_List is
      Result: Var_List;
   begin
      if Is_Const(E.V) then
         Result := New_Var_List;
      else
         Result := New_Var_List((1 => E.V));
      end if;
      return Result;
   end;

   procedure Get_Sub_Exprs
     (E: in Var_Ref_Record;
      R: in Expr_List) is
   begin
      null;
   end;

   procedure Get_Observed_Places
     (E     : in     Var_Ref_Record;
      Places: in out String_Set) is
   begin
      null;
   end;

   procedure Assign
     (E  : in Var_Ref_Record;
      B  : in Binding;
      Val: in Expr) is
   begin
      pragma Assert(not Is_Const(E.V));
      if not Is_Const(E.V) then
         Bind_Var(B, E.V, Val);
      end if;
   end;

   function Get_Assign_Expr
     (E  : in Var_Ref_Record;
      Val: in Expr) return Expr is
      Result: Expr;
   begin
      pragma Assert((not Is_Const(E.V)) and Get_Cls(E.V) = Get_Cls(Val));
      Result := Val;
      return Result;
   end;

   function To_Helena
     (E: in Var_Ref_Record) return Ustring is
   begin
      return Get_Name(E.V);
   end;

   function Compile_Evaluation
     (E: in Var_Ref_Record;
      M: in Var_Mapping) return Ustring is
   begin
      return Compile_Access(E.V, M);
   end;

   function Replace_Var
     (E: in Var_Ref_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: Expr;
   begin
      if E.V = V then
         Result := Copy(Ne);
      else
         Result := Copy(E);
      end if;
      return Result;
   end;

end Pn.Exprs.Var_Refs;
