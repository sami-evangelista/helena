--=============================================================================
--
--  Package: Pn.Exprs.Enum_Consts
--
--  This package implements enumeration constants, e.g., true, green.
--
--=============================================================================


package Pn.Exprs.Enum_Consts is

   --=====
   --  Type: Enum_Const_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Enum_Const_Record is new Expr_Record with private;

   --=====
   --  Type: Enum_Const
   --=====
   type Enum_Const is access all Enum_Const_Record;


   --=====
   --  Function: New_Enum_Const
   --  Enumeration constant constructor.
   --
   --  Parameters:
   --  Const - the constant
   --  C     - color class of the expression constructed
   --=====
   function New_Enum_Const
     (Const: in Ustring;
      C    : in Cls) return Expr;

   --=====
   --  Function: Get_Const
   --
   --  Return:
   --  the value of the constant
   --=====
   function Get_Const
     (Const: in Enum_Const) return Ustring;

   --=====
   --  Function: Is_True_Const
   --
   --  Return:
   --  True if Const is the true constant, False otherwise
   --=====
   function Is_True_Const
     (Const: in Enum_Const) return Boolean;

   --=====
   --  Function: Is_False_Const
   --
   --  Return:
   --  True if Const is the false constant, False otherwise
   --=====
   function Is_False_Const
     (Const: in Enum_Const) return Boolean;


private


   type Enum_Const_Record is new Expr_Record with
      record
         Const: Ustring;  --  value of the constant
      end record;

   procedure Free
     (E: in out Enum_Const_Record);

   function Copy
     (E: in Enum_Const_Record) return Expr;

   function Get_Type
     (E: in Enum_Const_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Enum_Const_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Enum_Const_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Enum_Const_Record) return Boolean;

   function Is_Basic
     (E: in Enum_Const_Record) return Boolean;

   function Get_True_Cls
     (E: in Enum_Const_Record) return Cls;

   function Can_Overflow
     (E: in Enum_Const_Record) return Boolean;

   procedure Evaluate
     (E     : in     Enum_Const_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Enum_Const_Record;
      Right: in Enum_Const_Record) return Boolean;

   function Compare
     (Left: in Enum_Const_Record;
      Right: in Enum_Const_Record) return Comparison_Result;

   function Vars_In
     (E: in Enum_Const_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Enum_Const_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Enum_Const_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Enum_Const_Record) return Ustring;

   function Compile_Evaluation
     (E: in Enum_Const_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E : in Enum_Const_Record;
      V : in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Enum_Consts;
