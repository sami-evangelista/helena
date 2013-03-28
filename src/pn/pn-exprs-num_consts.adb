with
  Pn.Classes,
  Pn.Classes.Discretes,
  Pn.Classes.Discretes.Nums,
  Pn.Vars;

use
  Pn.Classes,
  Pn.Classes.Discretes,
  Pn.Classes.Discretes.Nums,
  Pn.Vars;

package body Pn.Exprs.Num_Consts is

   function New_Num_Const
     (Const: in Num_Type;
      C    : in Cls) return Expr is
      Result: constant Num_Const := new Num_Const_Record;
   begin
      Initialize(Result, C);
      Result.Const := Const;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Num_Const_Record) is
   begin
      null;
   end;

   function Copy
     (E: in Num_Const_Record) return Expr is
      Result: constant Num_Const := new Num_Const_Record;
   begin
      Initialize(Result, E.C);
      Result.Const := E.Const;
      return Expr(Result);
   end;

   function Get_Type
     (E: in Num_Const_Record) return Expr_Type is
   begin
      return A_Num_Const;
   end;

   procedure Color_Expr
     (E    : in     Num_Const_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
   begin
      State := Coloring_Success;
   end;

   function Possible_Colors
     (E : in Num_Const_Record;
      Cs: in Cls_Set) return Cls_Set is
   begin
      --===
      --  accept only numerical colors
      --===
      return Filter_On_Type(Cs, (A_Num_Cls => True, others    => False));
   end;

   function Is_Static
     (E: in Num_Const_Record) return Boolean is
   begin
      return True;
   end;

   function Is_Basic
     (E: in Num_Const_Record) return Boolean is
   begin
      return True;
   end;

   function Get_True_Cls
     (E: in Num_Const_Record) return Cls is
   begin
      return E.C;
   end;

   function Can_Overflow
     (E: in Num_Const_Record) return Boolean is
      C     : constant Num_Cls := Num_Cls(E.C);
      Result: Boolean;
   begin
      Result := not (Is_Circular(Discrete_Cls(C)) or
                     (E.Const >= Get_Low(C) and E.Const <= Get_High(C)));
      return Result;
   end;

   procedure Evaluate
     (E     : in     Num_Const_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
   begin
      Result := Copy(E);
      State := Evaluation_Success;
   end;

   function Static_Equal
     (Left: in Num_Const_Record;
      Right: in Num_Const_Record) return Boolean is
   begin
      return Left.Const = Right.Const;
   end;

   function Compare
     (Left: in Num_Const_Record;
      Right: in Num_Const_Record) return Comparison_Result is
      Result: Comparison_Result;
   begin
      if    Left.Const = Right.Const then
         Result := Cmp_Eq;
      elsif Left.Const > Right.Const then
         Result := Cmp_Sup;
      else
         Result := Cmp_Inf;
      end if;
      return Result;
   end;

   function Vars_In
     (E: in Num_Const_Record) return Var_List is
   begin
      return New_Var_List;
   end;

   procedure Get_Sub_Exprs
     (E: in Num_Const_Record;
      R: in Expr_List) is
   begin
      null;
   end;

   procedure Get_Observed_Places
     (E     : in     Num_Const_Record;
      Places: in out String_Set) is
   begin
      null;
   end;

   function Get_Const
     (Const: in Num_Const) return Num_Type is
   begin
      return Const.Const;
   end;

   function To_Helena
     (E: in Num_Const_Record) return Ustring is
   begin
      return To_Helena(E.Const);
   end;

   function To_Pnml
     (E: in Num_Const_Record) return Ustring is
   begin
      return
	"<useroperator declaration=""C-" &
	Get_Name(Get_True_Cls(E.Me)) & "-" & E.Const & """/>";
   end;

   function Compile_Evaluation
     (E: in Num_Const_Record;
      M: in Var_Mapping) return Ustring is
      Result: Ustring;
   begin
      if Big_Int(E.Const) = Big_Int(Interfaces.C.Int'First) then
         Result := "(" & (E.Const + 1) & " - 1)";
      else
         Result := To_Ustring(E.Const);
      end if;
      return Result;
   end;

   function Replace_Var
     (E: in Num_Const_Record;
      V: in Var;
      Ne: in Expr) return Expr is
   begin
      return Copy(E);
   end;

end Pn.Exprs.Num_Consts;
