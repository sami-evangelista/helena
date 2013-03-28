with
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Classes;

use
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Classes;

package body Pn.Exprs.Func_Calls is

   function New_Func_Call
     (F: in Func;
      P: in Expr_List) return Expr is
      Result: constant Func_Call := new Func_Call_Record;
   begin
      Initialize(Result, Get_Ret_Cls(F));
      Result.F := F;
      Result.P := P;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Func_Call_Record) is
   begin
      Free_All(E.P);
   end;

   function Copy
     (E: in Func_Call_Record) return Expr is
      Result: constant Func_Call := new Func_Call_Record;
   begin
      Initialize(Result, E.C);
      Result.F := E.F;
      Result.P := Copy(E.P);
      return Expr(Result);
   end;

   function Get_Type
     (E: in Func_Call_Record) return Expr_Type is
   begin
      return A_Func_Call;
   end;

   procedure Color_Expr
     (E    : in     Func_Call_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      F_Dom: Dom;
   begin
      F_Dom := Get_Dom(E.F);
      Color_Expr_List(E.P, F_Dom, Cs, State);
   end;

   function Possible_Colors
     (E: in Func_Call_Record;
      Cs: in Cls_Set) return Cls_Set is
   begin
      return New_Cls_Set((1 => Get_Ret_Cls(E.F)));
   end;

   function Is_Static
     (E: in Func_Call_Record) return Boolean is
   begin
      return False;
   end;

   function Is_Basic
     (E: in Func_Call_Record) return Boolean is
   begin
      return Is_Basic(E.P);
   end;

   function Get_True_Cls
     (E: in Func_Call_Record) return Cls is
   begin
      return Get_Ret_Cls(E.F);
   end;

   function Can_Overflow
     (E: in Func_Call_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Func_Call_Record;
      B     : in     Binding;
      Result:    out Expr;
      State :    out Evaluation_State) is
   begin
      State  := Evaluation_Failure;
      Result := null;
   end;

   function Static_Equal
     (Left: in Func_Call_Record;
      Right: in Func_Call_Record) return Boolean is
   begin
      return Left.F = Right.F and then Static_Equal(Left.P, Right.P);
   end;

   function Compare
     (Left: in Func_Call_Record;
      Right: in Func_Call_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in Func_Call_Record) return Var_List is
   begin
      return Vars_In(E.P);
   end;

   procedure Get_Sub_Exprs
     (E: in Func_Call_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.P, R);
   end;

   procedure Get_Observed_Places
     (E     : in     Func_Call_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.P, Places);
   end;

   function To_Helena
     (E: in Func_Call_Record) return Ustring is
   begin
      return Get_Name(E.F) & "(" & To_Helena(E.P) & ")";
   end;

   function Compile_Evaluation
     (E: in Func_Call_Record;
      M: in Var_Mapping) return Ustring is
   begin
      return Func_Name(E.F) & "(" & Compile_Evaluation(E.P, M, True) & ")";
   end;

   function Replace_Var
     (E: in Func_Call_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: Expr;
   begin
      Result := New_Func_Call(E.F, Replace_Var(E.P, V, Ne));
      return Result;
   end;

   function Get_Func
     (F: in Func_Call) return Func is
   begin
      return F.F;
   end;

end Pn.Exprs.Func_Calls;
