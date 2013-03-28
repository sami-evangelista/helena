--=============================================================================
--
--  Package: Pn.Exprs.Attributes.Classes
--
--  This package implements color classes attributes. There are three kinds of
--  attributes:
--    o C'first returns the first value of color C
--    o C'last returns the last value of color C
--    o C'card returns the cardinal of color C
--  These three attributes only apply to discrete colors.
--
--=============================================================================


package Pn.Exprs.Attributes.Classes is

   --=====
   --  Type: Cls_Attribute_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Cls_Attribute_Record is new Attribute_Record with private;

   --=====
   --  Type: Cls_Attribute
   --=====
   type Cls_Attribute is access all Cls_Attribute_Record;


   --=====
   --  Function: New_Cls_Attribute
   --  Color class attribute constructor.
   --
   --  Parameters:
   --  Cl        - color class on which the attribute is applied
   --  Attribute - the attribute
   --  C         - color class of the expression constructed
   --=====
   function New_Cls_Attribute
     (Cl       : in Cls;
      Attribute: in Attribute_Type;
      C        : in Cls) return Expr;


private


   type Cls_Attribute_Record is new Attribute_Record with
      record
         Cl: Cls;  --  class of the attribute
      end record;

   procedure Free
     (E: in out Cls_Attribute_Record);

   function Copy
     (E: in Cls_Attribute_Record) return Expr;

   procedure Color_Expr
     (E    : in     Cls_Attribute_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Cls_Attribute_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Cls_Attribute_Record) return Boolean;

   function Is_Basic
     (E: in Cls_Attribute_Record) return Boolean;

   function Get_True_Cls
     (E: in Cls_Attribute_Record) return Cls;

   function Can_Overflow
     (E: in Cls_Attribute_Record) return Boolean;

   procedure Evaluate
     (E     : in     Cls_Attribute_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Cls_Attribute_Record;
      Right: in Cls_Attribute_Record) return Boolean;

   function Vars_In
     (E: in Cls_Attribute_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Cls_Attribute_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Cls_Attribute_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Cls_Attribute_Record) return Ustring;

   function Compile_Evaluation
     (E: in Cls_Attribute_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Cls_Attribute_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Attributes.Classes;
