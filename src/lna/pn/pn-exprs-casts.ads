--=============================================================================
--
--  Package: Pn.Exprs.Casts
--
--  This package implements cast expressions, e.g., int(i).
--
--=============================================================================


package Pn.Exprs.Casts is

   --=====
   --  Type: Cast_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Cast_Record is new Expr_Record with private;

   --=====
   --  Type: Cast
   --=====
   type Cast is access all Cast_Record;


   --=====
   --  Function: New_Cast
   --  Cast constructor.
   --
   --  Parameters:
   --  Cls_Cast - color class in which the expression is casted
   --  E        - expression casted
   --=====
   function New_Cast
     (Cls_Cast: in Cls;
      E       : in Expr) return Expr;

   --=====
   --  Function: Get_Expr
   --
   --  Return:
   --  the casted expression of cast C
   --=====
   function Get_Expr
     (C: in Cast) return Expr;


private


   type Cast_Record is new Expr_Record with
      record
         Cls_Cast: Cls;   --  color in which the expression is casted
         E       : Expr;  --  the expression which is casted
      end record;

   procedure Free
     (E: in out Cast_Record);

   function Copy
     (E: in Cast_Record) return Expr;

   function Get_Type
     (E: in Cast_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Cast_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Cast_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Cast_Record) return Boolean;

   function Is_Basic
     (E: in Cast_Record) return Boolean;

   function Get_True_Cls
     (E: in Cast_Record) return Cls;

   function Can_Overflow
     (E: in Cast_Record) return Boolean;

   procedure Evaluate
     (E     : in     Cast_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Cast_Record;
      Right: in Cast_Record) return Boolean;

   function Compare
     (Left: in Cast_Record;
      Right: in Cast_Record) return Comparison_Result;

   function Vars_In
     (E: in Cast_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Cast_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Cast_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Cast_Record) return Ustring;

   function Compile_Evaluation
     (E: in Cast_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Cast_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Casts;
