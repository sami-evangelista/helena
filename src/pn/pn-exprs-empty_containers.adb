with
  Pn.Compiler.Names,
  Pn.Classes,
  Pn.Classes.Containers.Lists,
  Pn.Exprs.Containers,
  Pn.Vars;

use
  Pn.Compiler.Names,
  Pn.Classes,
  Pn.Classes.Containers.Lists,
  Pn.Exprs.Containers,
  Pn.Vars;

package body Pn.Exprs.Empty_Containers is

   function New_Empty_Container
     (C: in Cls) return Expr is
      Result: constant Empty_Container := new Empty_Container_Record;
   begin
      Initialize(Result, C);
      return Expr(Result);
   end;

   procedure Free
     (E: in out Empty_Container_Record) is
   begin
      null;
   end;

   function Copy
     (E: in Empty_Container_Record) return Expr is
   begin
      return New_Empty_Container(E.C);
   end;

   function Get_Type
     (E: in Empty_Container_Record) return Expr_Type is
   begin
      return A_Empty_Container;
   end;

   procedure Color_Expr
     (E    : in     Empty_Container_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
   begin
      State := Coloring_Success;
   end;

   function Possible_Colors
     (E : in Empty_Container_Record;
      Cs: in Cls_Set) return Cls_Set is
      function Is_Container_Cls
        (C: in Cls) return Boolean is
      begin
         return Pn.Classes.Is_Container_Cls(C);
      end;
      function Filter is new Generic_Filter(Is_Container_Cls);
   begin
      return Filter(Cs);
   end;

   function Is_Static
     (E: in Empty_Container_Record) return Boolean is
   begin
      return True;
   end;

   function Is_Basic
     (E: in Empty_Container_Record) return Boolean is
   begin
      return True;
   end;

   function Get_True_Cls
     (E: in Empty_Container_Record) return Cls is
   begin
      return E.C;
   end;

   function Can_Overflow
     (E: in Empty_Container_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Empty_Container_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
   begin
      pragma Assert(Is_Container_Cls(E.C));
      Result := New_Container(New_Expr_List, E.C);
      State := Evaluation_Success;
   end;

   function Static_Equal
     (Left: in Empty_Container_Record;
      Right: in Empty_Container_Record) return Boolean is
   begin
      return True;
   end;

   function Compare
     (Left: in Empty_Container_Record;
      Right: in Empty_Container_Record) return Comparison_Result is
   begin
      return Cmp_Eq;
   end;

   function Vars_In
     (E: in Empty_Container_Record) return Var_List is
   begin
      return New_Var_List;
   end;

   procedure Get_Sub_Exprs
     (E: in Empty_Container_Record;
      R: in Expr_List) is
   begin
      null;
   end;

   procedure Get_Observed_Places
     (E     : in     Empty_Container_Record;
      Places: in out String_Set) is
   begin
      null;
   end;

   function To_Helena
     (E: in Empty_Container_Record) return Ustring is
   begin
      return To_Ustring("empty");
   end;

   function Compile_Evaluation
     (E: in Empty_Container_Record;
      M: in Var_Mapping) return Ustring is
   begin
      return Cls_Empty_Const_Name(E.C);
   end;

   function Replace_Var
     (E: in Empty_Container_Record;
      V: in Var;
      Ne: in Expr) return Expr is
   begin
      return Copy(E);
   end;

end Pn.Exprs.Empty_Containers;
