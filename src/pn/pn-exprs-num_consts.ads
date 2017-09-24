--=============================================================================
--
--  Package: Pn.Exprs.Num_Consts
--
--  This package implements numerical constants, e.g., 5787.
--
--=============================================================================


package Pn.Exprs.Num_Consts is

   --=====
   --  Type: Num_Const_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Num_Const_Record is new Expr_Record with private;

   --=====
   --  Type: Num_Const
   --=====
   type Num_Const is access all Num_Const_Record;


   --=====
   --  Function: New_Num_Const
   --  Numerical constant constructor.
   --
   --  Parameters:
   --  Const - the constant
   --  C     - color class of the constant
   --=====
   function New_Num_Const
     (Const: in Num_Type;
      C    : in Cls) return Expr;

   --=====
   --  Function: Get_Const
   --
   --  Return:
   --  the value of the constant
   --=====
   function Get_Const
     (Const: in Num_Const) return Num_Type;


private


   type Num_Const_Record is new Expr_Record with
      record
         Const: Num_Type;  --  value of the constant
      end record;

   procedure Free
     (E: in out Num_Const_Record);

   function Copy
     (E: in Num_Const_Record) return Expr;

   function Get_Type
     (E: in Num_Const_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Num_Const_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Num_Const_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Num_Const_Record) return Boolean;

   function Is_Basic
     (E: in Num_Const_Record) return Boolean;

   function Get_True_Cls
     (E: in Num_Const_Record) return Cls;

   function Can_Overflow
     (E: in Num_Const_Record) return Boolean;

   procedure Evaluate
     (E     : in     Num_Const_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Num_Const_Record;
      Right: in Num_Const_Record) return Boolean;

   function Compare
     (Left: in Num_Const_Record;
      Right: in Num_Const_Record) return Comparison_Result;

   function Vars_In
     (E: in Num_Const_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Num_Const_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Num_Const_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Num_Const_Record) return Ustring;

   function Compile_Evaluation
     (E: in Num_Const_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E : in Num_Const_Record;
      V : in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Num_Consts;
