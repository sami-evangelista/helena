--=============================================================================
--
--  Package: Pn.Exprs.Anys
--
--  This package implements "_" expressions that can appear in reset arcs.
--
--=============================================================================


package Pn.Exprs.Anys is

   type Any_Record is new Expr_Record with private;

   type Any is access all Any_Record;

   function New_Any
     (C: in Cls) return Expr;

private

   type Any_Record is new Expr_Record with null record;

   procedure Free
     (E: in out Any_Record);

   function Copy
     (E: in Any_Record) return Expr;

   function Get_Type
     (E: in Any_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Any_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E : in Any_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Any_Record) return Boolean;

   function Is_Basic
     (E: in Any_Record) return Boolean;

   function Get_True_Cls
     (E: in Any_Record) return Cls;

   function Can_Overflow
     (E: in Any_Record) return Boolean;

   procedure Evaluate
     (E     : in     Any_Record;
      B     : in     Binding;
      Result:    out Expr;
      State :    out Evaluation_State);

   function Static_Equal
     (Left : in Any_Record;
      Right: in Any_Record) return Boolean;

   function Compare
     (Left : in Any_Record;
      Right: in Any_Record) return Comparison_Result;

   function Vars_In
     (E: in Any_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Any_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Any_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Any_Record) return Ustring;

   function Compile_Evaluation
     (E: in Any_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E : in Any_Record;
      V : in Var;
      Ne: in Expr) return Expr;
end;
