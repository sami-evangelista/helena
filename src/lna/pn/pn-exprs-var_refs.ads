--=============================================================================
--
--  Package: Pn.Exprs.Var_Refs
--
--  This package implements variable references, e.g. i, j.
--
--=============================================================================


package Pn.Exprs.Var_Refs is

   --=====
   --  Type: Var_Ref_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Var_Ref_Record is new Expr_Record with private;

   --=====
   --  Type: Var_Ref
   --=====
   type Var_Ref is access all Var_Ref_Record;


   --=====
   --  Function: New_Var_Ref
   --  Variable reference constructor.
   --
   --  Parameters:
   --  V - the variable referenced
   --=====
   function New_Var_Ref
     (V: in Var) return Expr;

   --=====
   --  Function: Get_Var
   --  Return the variable referenced of the expression.
   --=====
   function Get_Var
     (V: in Var_Ref) return Var;


private


   type Var_Ref_Record is new Expr_Record with
      record
         V: Var;  --  the variable of the expression
      end record;

   procedure Free
     (E: in out Var_Ref_Record);

   function Copy
     (E: in Var_Ref_Record) return Expr;

   function Get_Type
     (E: in Var_Ref_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Var_Ref_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Var_Ref_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Assignable
     (E: in Var_Ref_Record) return Boolean;

   function Is_Static
     (E: in Var_Ref_Record) return Boolean;

   function Is_Basic
     (E: in Var_Ref_Record) return Boolean;

   function Get_True_Cls
     (E: in Var_Ref_Record) return Cls;

   function Can_Overflow
     (E: in Var_Ref_Record) return Boolean;

   procedure Evaluate
     (E     : in     Var_Ref_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Var_Ref_Record;
      Right: in Var_Ref_Record) return Boolean;

   function Compare
     (Left: in Var_Ref_Record;
      Right: in Var_Ref_Record) return Comparison_Result;

   function Vars_In
     (E: in Var_Ref_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Var_Ref_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Var_Ref_Record;
      Places: in out String_Set);

   procedure Assign
     (E  : in Var_Ref_Record;
      B  : in Binding;
      Val: in Expr);

   function Get_Assign_Expr
     (E  : in Var_Ref_Record;
      Val: in Expr) return Expr;

   function To_Helena
     (E: in Var_Ref_Record) return Ustring;

   function Compile_Evaluation
     (E: in Var_Ref_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Var_Ref_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Var_Refs;
