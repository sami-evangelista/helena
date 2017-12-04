--=============================================================================
--
--  Package: Pn.Exprs.Attributes.Places
--
--  This package implements places attributes. There are two kinds of
--  attributes:
--    - P'card is the number of tokens present in place P
--    - P'mult is the cumulated multiplicities of the tokens present in place P
--
--=============================================================================


with
  Pn.Nodes.Places;

use
  Pn.Nodes.Places;

package Pn.Exprs.Attributes.Places is

   --=====
   --  Type: Place_Attribute_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Place_Attribute_Record is new Attribute_Record with private;

   --=====
   --  Type: Place_Attribute
   --=====
   type Place_Attribute is access all Place_Attribute_Record;


   --=====
   --  Function: New_Place_Attribute
   --  Place attribute constructor.
   --
   --  Parameters:
   --  P         - place on which the attribute is applied
   --  Attribute - the attribute
   --  C         - color class of the expression constructed
   --=====
   function New_Place_Attribute
     (P        : in Place;
      Attribute: in Attribute_Type;
      C        : in Cls) return Expr;


private


   type Place_Attribute_Record is new Attribute_Record with
      record
         P: Place;  --  place of the attribute
      end record;

   procedure Free
     (E: in out Place_Attribute_Record);

   function Copy
     (E: in Place_Attribute_Record) return Expr;

   procedure Color_Expr
     (E    : in     Place_Attribute_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Place_Attribute_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Place_Attribute_Record) return Boolean;

   function Is_Basic
     (E: in Place_Attribute_Record) return Boolean;

   function Get_True_Cls
     (E: in Place_Attribute_Record) return Cls;

   function Can_Overflow
     (E: in Place_Attribute_Record) return Boolean;

   procedure Evaluate
     (E     : in     Place_Attribute_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Place_Attribute_Record;
      Right: in Place_Attribute_Record) return Boolean;

   function Vars_In
     (E: in Place_Attribute_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Place_Attribute_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Place_Attribute_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Place_Attribute_Record) return Ustring;

   function Compile_Evaluation
     (E: in Place_Attribute_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Place_Attribute_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Attributes.Places;
