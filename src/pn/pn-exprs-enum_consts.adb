with
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Classes,
  Pn.Classes.Discretes.Enums,
  Pn.Vars;

use
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Classes,
  Pn.Classes.Discretes.Enums,
  Pn.Vars;

package body Pn.Exprs.Enum_Consts is

   function New_Enum_Const
     (Const: in Ustring;
      C  : in Cls) return Expr is
      Result: constant Enum_Const := new Enum_Const_Record;
   begin
      Initialize(Result, C);
      Result.Const := Const;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Enum_Const_Record) is
   begin
      null;
   end;

   function Copy
     (E: in Enum_Const_Record) return Expr is
      Result: constant Enum_Const := new Enum_Const_Record;
   begin
      Initialize(Result, E.C);
      Result.Const := E.Const;
      return Expr(Result);
   end;

   function Get_Type
     (E: in Enum_Const_Record) return Expr_Type is
   begin
      return A_Enum_Const;
   end;

   procedure Color_Expr
     (E    : in     Enum_Const_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
   begin
      State := Coloring_Success;
   end;

   function Possible_Colors
     (E: in Enum_Const_Record;
      Cs: in Cls_Set) return Cls_Set is
      function Pred
        (C: in Cls) return Boolean is
      begin
         return Is_Of_Cls(Enum_Cls(C), E.Const);
      end;
      function Filter is new Generic_Filter_On_Type(Pred);
   begin
      return Filter(Cs, (A_Enum_Cls => True, others => False));
   end;

   function Is_Static
     (E: in Enum_Const_Record) return Boolean is
   begin
      return True;
   end;

   function Is_Basic
     (E: in Enum_Const_Record) return Boolean is
   begin
      return True;
   end;

   function Get_True_Cls
     (E: in Enum_Const_Record) return Cls is
   begin
      return E.C;
   end;

   function Can_Overflow
     (E: in Enum_Const_Record) return Boolean is
   begin
      return not Is_Of_Cls(Enum_Cls(E.C), E.Const);
   end;

   procedure Evaluate
     (E     : in     Enum_Const_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
   begin
      Result := Copy(E);
      State := Evaluation_Success;
   end;

   function Static_Equal
     (Left: in Enum_Const_Record;
      Right: in Enum_Const_Record) return Boolean is
   begin
      return Left.Const = Right.Const;
   end;

   function Compare
     (Left : in Enum_Const_Record;
      Right: in Enum_Const_Record) return Comparison_Result is
      Result     : Comparison_Result;
      Values     : Ustring_List;
      Index_Left : Index_Type;
      Index_Right: Index_Type;
   begin
      if Left.Const = Right.Const then
         Result := Cmp_Eq;
      elsif
        Left.C  /= null and then
        Right.C /= null and then
        Get_Root_Cls(Left.C) = Get_Root_Cls(Right.C)
      then
         Values := Get_Root_Values(Enum_Cls(Left.C));
         Index_Left := String_List_Pkg.Index(Values, Left.Const);
         Index_Right := String_List_Pkg.Index(Values, Right.Const);
         if Index_Left > Index_Right then
            Result := Cmp_Sup;
         elsif Index_Left < Index_RIght then
            Result := Cmp_Inf;
         else
            Result := Cmp_Eq;
         end if;
      else
         Result := Cmp_Error;
      end if;
      return Result;
   end;

   function Vars_In
     (E: in Enum_Const_Record) return Var_List is
   begin
      return New_Var_List;
   end;

   procedure Get_Sub_Exprs
     (E: in Enum_Const_Record;
      R: in Expr_List) is
   begin
      null;
   end;

   procedure Get_Observed_Places
     (E     : in     Enum_Const_Record;
      Places: in out String_Set) is
   begin
      null;
   end;

   function To_Helena
     (E: in Enum_Const_Record) return Ustring is
   begin
      return E.Const;
   end;

   function To_Pnml
     (E: in Enum_Const_Record) return Ustring is
   begin
      return
	"<useroperator declaration=""C-" &
	Get_Name(Get_True_Cls(E.Me)) & "-" & E.Const & """/>";
   end;

   function Compile_Evaluation
     (E: in Enum_Const_Record;
      M: in Var_Mapping) return Ustring is
   begin
      return Cls_Enum_Const_Name(E.C, E.Const);
   end;

   function Replace_Var
     (E: in Enum_Const_Record;
      V: in Var;
      Ne: in Expr) return Expr is
   begin
      return Copy(E);
   end;

   function Get_Const
     (Const: in Enum_Const) return Ustring is
   begin
      return Const.Const;
   end;

   function Is_True_Const
     (Const: in Enum_Const) return Boolean is
   begin
      return Const.Const = True_Const_Name;
   end;

   function Is_False_Const
     (Const: in Enum_Const) return Boolean is
   begin
      return Const.Const = False_Const_Name;
   end;

end Pn.Exprs.Enum_Consts;
