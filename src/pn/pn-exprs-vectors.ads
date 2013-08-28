--=============================================================================
--
--  Package: Pn.Exprs.Vectors
--
--  This package implements vectors expressions, e.g., [0, 0, 0, 0, 1].
--
--=============================================================================


package Pn.Exprs.Vectors is

   type Vector_Record is new Expr_Record with private;

   type Vector is access all Vector_Record;


   function New_Vector
     (E: in Expr_List;
      C: in Cls) return Expr;

   function Get_Elements
     (V: in Vector) return Expr_List;

   function Get_Element
     (V: in Vector;
      I: in Index_Type) return Expr;

   procedure Replace_Element
     (V: in Vector;
      E: in Expr;
      I: in Index_Type);
   
   procedure Append
     (V: in Vector;
      E: in Expr);


private


   type Vector_Record is new Expr_Record with
      record
         E: Expr_List;  --  expression list in the vector
      end record;

   procedure Free
     (E: in out Vector_Record);

   function Copy
     (E: in Vector_Record) return Expr;

   function Get_Type
     (E: in Vector_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Vector_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Vector_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Vector_Record) return Boolean;

   function Is_Basic
     (E: in Vector_Record) return Boolean;

   function Get_True_Cls
     (E: in Vector_Record) return Cls;

   function Can_Overflow
     (E: in Vector_Record) return Boolean;

   procedure Evaluate
     (E     : in     Vector_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Vector_Record;
      Right: in Vector_Record) return Boolean;

   function Compare
     (Left: in Vector_Record;
      Right: in Vector_Record) return Comparison_Result;

   function Vars_In
     (E: in Vector_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Vector_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Vector_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Vector_Record) return Ustring;

   function Compile_Evaluation
     (E: in Vector_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Vector_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Vectors;
