with
  Pn.Vars;

use
  Pn.Vars;

package body Pn.Exprs.Anys is

   function New_Any
     (C: in Cls) return Expr is
      Result: constant Any := new Any_Record;
   begin
      Initialize(Result, C);
      return Expr(Result);
   end;

   procedure Free
     (E: in out Any_Record) is
   begin
      null;
   end;

   function Copy
     (E: in Any_Record) return Expr is
      Result: constant Any := new Any_Record;
   begin
      Initialize(Result, E.C);
      return Expr(Result);
   end;

   function Get_Type
     (E: in Any_Record) return Expr_Type is
   begin
      return A_Any;
   end;

   procedure Color_Expr
     (E    : in     Any_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
   begin
      State := Coloring_Success;
   end;

   function Possible_Colors
     (E : in Any_Record;
      Cs: in Cls_Set) return Cls_Set is
   begin
      return Cs;
   end;

   function Is_Static
     (E: in Any_Record) return Boolean is
   begin
      return True;
   end;

   function Is_Basic
     (E: in Any_Record) return Boolean is
   begin
      return True;
   end;

   function Get_True_Cls
     (E: in Any_Record) return Cls is
   begin
      return E.C;
   end;

   function Can_Overflow
     (E: in Any_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Any_Record;
      B     : in     Binding;
      Result:    out Expr;
      State :    out Evaluation_State) is
   begin
      Result := null;
      State := Evaluation_Failure;
   end;

   function Static_Equal
     (Left : in Any_Record;
      Right: in Any_Record) return Boolean is
   begin
      return False;
   end;

   function Compare
     (Left : in Any_Record;
      Right: in Any_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in Any_Record) return Var_List is
   begin
      return New_Var_List;
   end;

   procedure Get_Sub_Exprs
     (E: in Any_Record;
      R: in Expr_List) is
   begin
      null;
   end;

   procedure Get_Observed_Places
     (E     : in     Any_Record;
      Places: in out String_Set) is
   begin
      null;
   end;

   function To_Helena
     (E: in Any_Record) return Ustring is
   begin
      return To_Ustring("_");
   end;

   function Compile_Evaluation
     (E: in Any_Record;
      M: in Var_Mapping) return Ustring is
   begin
      pragma Assert(False);
      return Null_String;
   end;

   function Replace_Var
     (E : in Any_Record;
      V : in Var;
      Ne: in Expr) return Expr is
   begin
      return New_Any(E.C);
   end;

end;
