with
  Pn.Exprs.Enum_Consts,
  Pn.Classes,
  Pn.Vars;

use
  Pn.Exprs.Enum_Consts,
  Pn.Classes,
  Pn.Vars;

package body Pn.Exprs.If_Then_Elses is

   function New_If_Then_Else
     (If_Cond   : in Expr;
      True_Expr: in Expr;
      False_Expr: in Expr) return Expr is
      Result: constant If_Then_Else := new If_Then_Else_Record;
   begin
      Initialize(Result, Bool_Cls);
      Result.If_Cond   := If_Cond;
      Result.True_Expr := True_Expr;
      Result.False_Expr := False_Expr;
      return Expr(Result);
   end;

   procedure Free
     (E: in out If_Then_Else_Record) is
   begin
      Free(E.If_Cond);
      Free(E.True_Expr);
      Free(E.False_Expr);
   end;

   function Copy
     (E: in If_Then_Else_Record) return Expr is
      Result: constant If_Then_Else := new If_Then_Else_Record;
   begin
      Initialize(Result, E.C);
      Result.If_Cond   := Copy(E.If_Cond);
      Result.True_Expr := Copy(E.True_Expr);
      Result.False_Expr := Copy(E.False_Expr);
      return Expr(Result);
   end;

   function Get_Type
     (E: in If_Then_Else_Record) return Expr_Type is
   begin
      return A_If_Then_Else;
   end;

   procedure Color_Expr
     (E    : in     If_Then_Else_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
   begin
      Color_Expr(E.If_Cond, Bool_Cls, Cs, State);
      if Is_Success(State) then
         Color_Expr(E.True_Expr, C, Cs, State);
         if Is_Success(State) then
            Color_Expr(E.False_Expr, C, Cs, State);
         end if;
      end if;
   end;

   function Possible_Colors
     (E: in If_Then_Else_Record;
      Cs: in Cls_Set) return Cls_Set is
      True_Possible: Cls_Set;
      False_Possible: Cls_Set;
      Result        : Cls_Set;
   begin
      True_Possible := Possible_Colors(E.True_Expr, Cs);
      False_Possible := Possible_Colors(E.False_Expr, Cs);
      Result := Intersect(True_Possible, False_Possible);
      free(True_Possible);
      free(False_Possible);
      return Result;
   end;

   function Is_Static
     (E: in If_Then_Else_Record) return Boolean is
   begin
      return (Is_Static(E.If_Cond)   and
              Is_Static(E.True_Expr) and
              Is_Static(E.False_Expr));
   end;

   function Is_Basic
     (E: in If_Then_Else_Record) return Boolean is
   begin
      return (Is_Basic(E.If_Cond)   and
              Is_Basic(E.True_Expr) and
              Is_Basic(E.False_Expr));
   end;

   function Get_True_Cls
     (E: in If_Then_Else_Record) return Cls is
   begin
      return Get_True_Cls(E.True_Expr);
   end;

   function Can_Overflow
     (E: in If_Then_Else_Record) return Boolean is
   begin
      return Can_Overflow(E.True_Expr) or Can_Overflow(E.False_Expr);
   end;

   procedure Evaluate
     (E     : in     If_Then_Else_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
      Cond: Expr;
   begin
      Evaluate(E      => E.If_Cond,
               B      => B,
               Check  => False,
               Result => Cond,
               State  => State);
      if Is_Success(State) then
         pragma Assert(Get_Type(Cond) = A_Enum_Const);
         if Is_True_Const(Enum_Const(Cond)) then
            Evaluate(E      => E.True_Expr,
                     B      => B,
                     Check  => False,
                     Result => Result,
                     State  => State);
         else
            Evaluate(E      => E.False_Expr,
                     B      => B,
                     Check  => False,
                     Result => Result,
                     State  => State);
         end if;
         Free(Cond);
      end if;
   end;

   function Static_Equal
     (Left: in If_Then_Else_Record;
      Right: in If_Then_Else_Record) return Boolean is
   begin
      return (Static_Equal(Left.If_Cond,    Right.If_Cond)   and then
              Static_Equal(Left.True_Expr,  Right.True_Expr) and then
              Static_Equal(Left.False_Expr, Right.False_Expr));
   end;

   function Compare
     (Left: in If_Then_Else_Record;
      Right: in If_Then_Else_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in If_Then_Else_Record) return Var_List is
      Result    : constant Var_List := Vars_In(E.If_Cond);
      True_Vars: Var_List := Vars_In(E.True_Expr);
      False_Vars: Var_List := Vars_In(E.False_Expr);
   begin
      Union(Result, True_Vars);
      Union(Result, False_Vars);
      Free(True_Vars);
      Free(False_Vars);
      return Result;
   end;

   procedure Get_Sub_Exprs
     (E: in If_Then_Else_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.If_Cond, R);
      Get_Sub_Exprs(E.True_Expr, R);
      Get_Sub_Exprs(E.False_Expr, R);
   end;

   procedure Get_Observed_Places
     (E     : in     If_Then_Else_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.If_Cond, Places);
      Get_Observed_Places(E.True_Expr, Places);
      Get_Observed_Places(E.False_Expr, Places);
   end;

   function To_Helena
     (E: in If_Then_Else_Record) return Ustring is
   begin
      return
        To_Helena(E.If_Cond) & " ? " & To_Helena(E.True_Expr) &
        ": " & To_Helena(E.False_Expr);
   end;

   function Compile_Evaluation
     (E: in If_Then_Else_Record;
      M: in Var_Mapping) return Ustring is
   begin
      return
        Compile_Evaluation(E.If_Cond,    M, False) & " ? " &
        Compile_Evaluation(E.True_Expr,  M, False) & ": " &
        Compile_Evaluation(E.False_Expr, M, False);
   end;

   function Replace_Var
     (E: in If_Then_Else_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: Expr;
   begin
      Result := New_If_Then_Else(Replace_Var(E.If_Cond,    V, Ne),
                                 Replace_Var(E.True_Expr,  V, Ne),
                                 Replace_Var(E.False_Expr, V, Ne));
      return Result;
   end;

end Pn.Exprs.If_Then_Elses;
