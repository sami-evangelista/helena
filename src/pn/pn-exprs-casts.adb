with
  Pn.Classes,
  Pn.Compiler.Names;

use
  Pn.Classes,
  Pn.Compiler.Names;

package body Pn.Exprs.Casts is

   function New_Cast
     (Cls_Cast: in Cls;
      E       : in Expr) return Expr is
      Result: constant Cast := new Cast_Record;
   begin
      Initialize(Result, Cls_Cast);
      Result.E       := E;
      Result.Cls_Cast := Cls_Cast;
      return Expr(Result);
   end;

   function Get_Expr
     (C: in Cast) return Expr is
   begin
      return C.E;
   end;

   procedure Free
     (E: in out Cast_Record) is
   begin
      Free(E.E);
   end;

   function Copy
     (E: in Cast_Record) return Expr is
      Result: constant Expr := New_Cast(E.Cls_Cast, Copy(E.E));
   begin
      return Result;
   end;

   function Get_Type
     (E: in Cast_Record) return Expr_Type is
   begin
      return A_Cast;
   end;

   procedure Color_Expr
     (E    : in     Cast_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Possible: Cls_Set;
      Tmp     : Cls_Set;
      Chosen  : Cls;
      function Pred
        (D: in Cls) return Boolean is
      begin
         return Is_Castable(D, E.Cls_Cast);
      end;
      function Filter is new Generic_Filter(Pred);
   begin
      Tmp := Possible_Colors(E.E, Cs);
      Possible := Filter(Tmp);
      Choose(Possible, Chosen, State);
      Free(Tmp);
      Free(Possible);
      if Is_Success(State) then
         Color_Expr(E.E, Chosen, Cs, State);
      end if;
   end;

   function Possible_Colors
     (E: in Cast_Record;
      Cs: in Cls_Set) return Cls_Set is
   begin
      return New_Cls_Set((1 => E.Cls_Cast));
   end;

   function Is_Static
     (E: in Cast_Record) return Boolean is
   begin
      return Is_Static(E.E);
   end;

   function Is_Basic
     (E: in Cast_Record) return Boolean is
   begin
      return Is_Basic(E.E);
   end;

   function Get_True_Cls
     (E: in Cast_Record) return Cls is
   begin
      return E.Cls_Cast;
   end;

   function Can_Overflow
     (E: in Cast_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Cast_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
   begin
      Evaluate(E      => E.E,
               B      => B,
               Check  => False,
               Result => Result,
               State  => State);
      if not Is_Const_Of_Cls(E.Cls_Cast, Result) then
         State := Evaluation_Cast_Failed;
         Free(Result);
      else
         State := Evaluation_Success;
      end if;
   end;

   function Static_Equal
     (Left: in Cast_Record;
      Right: in Cast_Record) return Boolean is
   begin
      return Static_Equal(Left.E, Right.E);
   end;

   function Compare
     (Left: in Cast_Record;
      Right: in Cast_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in Cast_Record) return Var_List is
   begin
      return Vars_In(E.E);
   end;

   procedure Get_Sub_Exprs
     (E: in Cast_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.E, R);
   end;

   procedure Get_Observed_Places
     (E     : in     Cast_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.E, Places);
   end;

   function To_Helena
     (E: in Cast_Record) return Ustring is
   begin
      return Get_Name(E.Cls_Cast) & "(" & To_Helena(E.E) & ")";
   end;

   function Compile_Evaluation
     (E: in Cast_Record;
      M: in Var_Mapping) return Ustring is
   begin
      return
        Cls_Cast_Func(E.Cls_Cast) &
        "(" & Compile_Evaluation(E.E, M, False) & ")";
   end;

   function Replace_Var
     (E: in Cast_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: Expr;
   begin
      Result := New_Cast(E.Cls_Cast, Replace_Var(E.E, V, Ne));
      Set_Cls(Result, E.C);
      return Result;
   end;

end Pn.Exprs.Casts;
