--=============================================================================
--
--  Package: Pn.Classes.Discretes.Nums.Subs
--
--  This package implements sub classes of numerical classes, e.g.,
--  > type small: range 0..65535;
--  > subtype positive_small: small range 1 .. small'last;
--
--=============================================================================


with
  Pn.Ranges;

use
  Pn.Ranges;

package Pn.Classes.Discretes.Nums.Subs is

   --=====
   --  Type: Num_Sub_Cls_Record
   --
   --  See also:
   --  o <Pn>, <Pn.Classes.Discretes> and <Pn.Classes.Discretes.Nums> to see
   --    all the primitive operations overridden by this type
   --=====
   type Num_Sub_Cls_Record is new Num_Cls_Record with private;

   --=====
   --  Type: Num_Sub_Cls
   --=====
   type Num_Sub_Cls is access all Num_Sub_Cls_Record;


   --=====
   --  Function: New_Num_Sub_Cls
   --  Constructor.
   --
   --  Parameters:
   --  Name       - name of the color class
   --  Parent     - parent of the color class
   --  Constraint - constraint on the parent class, a numerical range which
   --               must be statically evaluable
   --=====
   function New_Num_Sub_Cls
     (Name      : in Ustring;
      Parent    : in Cls;
      Constraint: in Range_Spec) return Cls;


private


   type Num_Sub_Cls_Record is new Num_Cls_Record with
      record
         Parent    : Cls;         --  the parent class of the sub class
         Constraint: Range_Spec;  --  constraint on the parent
      end record;

   procedure Free
     (C: in out Num_Sub_Cls_Record);

   function Colors_Used
     (C: in Num_Sub_Cls_Record) return Cls_Set;

   function Get_Root_Cls
     (C: in Num_Sub_Cls_Record) return Cls;

   function Is_Sub_Cls
     (C     : in     Num_Sub_Cls_Record;
      Parent: access Cls_Record'Class) return Boolean;

   function Get_Low
     (C: in Num_Sub_Cls_Record) return Num_Type;

   function Get_High
     (C: in Num_Sub_Cls_Record) return Num_Type;

   function Is_Circular
     (C: in Num_Sub_Cls_Record) return Boolean;

   function Normalize_Value
     (C: in Num_Sub_Cls_Record;
      I: in Num_Type) return Num_Type;

end Pn.Classes.Discretes.Nums.Subs;
