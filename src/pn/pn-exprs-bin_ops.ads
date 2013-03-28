--=============================================================================
--
--  Package: Pn.Exprs.Bin_Ops
--
--  This package implements binary operation expressions, e.g., a + 1,
--  f(b) or c.
--
--=============================================================================


package Pn.Exprs.Bin_Ops is

   --=====
   --  Type: Bin_Op_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Bin_Op_Record is new Expr_Record with private;

   --=====
   --  Type: Bin_Op
   --=====
   type Bin_Op is access all Bin_Op_Record;


   --=====
   --  Function: New_Bin_Op
   --  Binary operation constructor.
   --
   --  Parameters:
   --  Op    - the binary operator
   --  Left  - the left operand
   --  Right - the right operand
   --  C     - color class of the constructed expression
   --=====
   function New_Bin_Op
     (Op   : in Bin_Operator;
      Left: in Expr;
      Right: in Expr;
      C    : in Cls) return Expr;

   --=====
   --  Function: To_Helena
   --
   --  Return:
   --  a string which corresponds to operator Op in Helena input language
   --=====
   function To_Helena
     (Op: in Bin_Operator) return String;

   --=====
   --  Function: Compile
   --
   --  Return:
   --  a string which corresponds to operator Op in the C language
   --=====
   function Compile
     (Op: in Bin_Operator) return String;


private


   type Bin_Op_Record is new Expr_Record with
      record
         Op   : Bin_Operator;  --  the operator
         Left : Expr;          --  left operand
         Right: Expr;          --  right operand
      end record;

   procedure Free
     (E: in out Bin_Op_Record);

   function Copy
     (E: in Bin_Op_Record) return Expr;

   function Get_Type
     (E: in Bin_Op_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Bin_Op_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Bin_Op_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Bin_Op_Record) return Boolean;

   function Is_Basic
     (E: in Bin_Op_Record) return Boolean;

   function Get_True_Cls
     (E: in Bin_Op_Record) return Cls;

   function Can_Overflow
     (E: in Bin_Op_Record) return Boolean;

   procedure Evaluate
     (E     : in     Bin_Op_Record;
      B     : in     Binding;
      Result:    out Expr;
      State :    out Evaluation_State);

   function Static_Equal
     (Left : in Bin_Op_Record;
      Right: in Bin_Op_Record) return Boolean;

   function Compare
     (Left : in Bin_Op_Record;
      Right: in Bin_Op_Record) return Comparison_Result;

   function Vars_In
     (E: in Bin_Op_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Bin_Op_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Bin_Op_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Bin_Op_Record) return Ustring;

   function To_Pnml
     (E: in Bin_Op_Record) return Ustring;

   function Compile_Evaluation
     (E: in Bin_Op_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E : in Bin_Op_Record;
      V : in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Bin_Ops;
