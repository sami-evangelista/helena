--=============================================================================
--
--  Package: Pn.Exprs.Attributes
--
--  This package implements ada-like attributes.
--
--=============================================================================


package Pn.Exprs.Attributes is

   --=====
   --  Type: Attribute_Record
   --=====
   type Attribute_Record is abstract new Expr_Record with private;

   --=====
   --  Type: Attribute
   --=====
   type Attribute is access all Attribute_Record'Class;

   --=====
   --  Type: Attribute_Type
   --  type of attribute
   --=====
   type Attribute_Type is
     (A_Capacity,
      A_Card,
      A_Empty,
      A_First,
      A_First_Index,
      A_Full,
      A_Last,
      A_Last_Index,
      A_Prefix,
      A_Size,
      A_Suffix,
      A_Mult,
      A_Space);


   --=====
   --  Procedure: Get_Attribute
   --  Get attribute which has name Att_Name.  Success specifies if the
   --  attribute has been found.
   --=====
   procedure Get_Attribute
     (Att_Name: in     String;
      Attribute:    out Attribute_Type;
      Success  :    out Boolean);


private


   type Attribute_Record is abstract new Expr_Record with
      record
         Attribute: Attribute_Type;  --  attribute
      end record;

   procedure Initialize
     (A        : access Attribute_Record'Class;
      Attribute: in     Attribute_Type;
      C        : in     Cls);

   function Get_Type
     (E: in Attribute_Record) return Expr_Type;

   function Compare
     (Left: in Attribute_Record;
      Right: in Attribute_Record) return Comparison_Result;

   function To_Helena
     (A: in Attribute_Type) return String;

end Pn.Exprs.Attributes;
