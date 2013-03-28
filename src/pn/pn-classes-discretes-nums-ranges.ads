--=============================================================================
--
--  Package: Pn.Classes.Discretes.Nums.Ranges
--
--  This package implements range color classes, e.g.,
--  > type small: range 0 .. 255;
--
--=============================================================================


with
  Pn.Ranges;

use
  Pn.Ranges;

package Pn.Classes.Discretes.Nums.Ranges is

   --=====
   --  Type: Range_Cls_Record
   --
   --  See also:
   --  o <Pn>, <Pn.Classes.Discretes> and <Pn.Classes.Discretes.Nums> to see
   --    all the primitive operations overridden by this type
   --=====
   type Range_Cls_Record is new Num_Cls_Record with private;

   --=====
   --  Type: Range_Cls
   --=====
   type Range_Cls is access all Range_Cls_Record;


   --=====
   --  Function: New_Range_Cls
   --  Constructor.
   --
   --  Parameters:
   --  Name - name of the class
   --  R    - range of the class which must be a numerical range statically
   --         evaluable
   --=====
   function New_Range_Cls
     (Name: in Ustring;
      R   : in Range_Spec) return Cls;


private


   type Range_Cls_Record is new Num_Cls_Record with
      record
         R: Range_Spec;  --  range which defines the class
      end record;

   procedure Free
     (C: in out Range_Cls_Record);

   function Colors_Used
     (C: in Range_Cls_Record) return Cls_Set;

   function Get_Low
     (C: in Range_Cls_Record) return Num_Type;

   function Get_High
     (C: in Range_Cls_Record) return Num_Type;

   function Is_Circular
     (C: in Range_Cls_Record) return Boolean;

   function Normalize_Value
     (C: in Range_Cls_Record;
      I: in Num_Type) return Num_Type;

end Pn.Classes.Discretes.Nums.Ranges;
