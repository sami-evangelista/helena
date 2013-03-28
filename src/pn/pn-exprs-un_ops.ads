--=============================================================================
--
--  Package: Pn.Exprs.Un_Ops
--
--  This package implements unary operation expressions, e.g. not b, - i.
--
--=============================================================================


package Pn.Exprs.Un_Ops is

   type Un_Op_Record is new Expr_Record with private;

   type Un_Op is access all Un_Op_Record;


   --=====
   --  Function: New_Un_Op
   --  Unary operation constructor.
   --
   --  Parameters:
   --  Op    - Operator of the operation
   --  Right - Operand of the operation
   --  C     - color class of the expression constructed
   --=====
   function New_Un_Op
     (Op   : in Un_Operator;
      Right: in Expr;
      C    : in Cls) return Expr;

   function To_Helena
     (Op: in Un_Operator) return String;

   function Compile
     (Op: in Un_Operator) return String;


private


   type Un_Op_Record is new Expr_Record with
      record
         Op   : Un_Operator;  --  operator
         Right: Expr;         --  operand
      end record;

   procedure Free
     (E: in out Un_Op_Record);

   function Copy
     (E: in Un_Op_Record) return Expr;

   function Get_Type
     (E: in Un_Op_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Un_Op_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Un_Op_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Un_Op_Record) return Boolean;

   function Is_Basic
     (E: in Un_Op_Record) return Boolean;

   function Get_True_Cls
     (E: in Un_Op_Record) return Cls;

   function Can_Overflow
     (E: in Un_Op_Record) return Boolean;

   procedure Evaluate
     (E     : in     Un_Op_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Un_Op_Record;
      Right: in Un_Op_Record) return Boolean;

   function Compare
     (Left: in Un_Op_Record;
      Right: in Un_Op_Record) return Comparison_Result;

   function Vars_In
     (E: in Un_Op_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Un_Op_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Un_Op_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Un_Op_Record) return Ustring;

   function To_Pnml
     (E: in Un_Op_Record) return Ustring;

   function Compile_Evaluation
     (E: in Un_Op_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Un_Op_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Un_Ops;
