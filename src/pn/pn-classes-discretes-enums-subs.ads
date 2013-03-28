--=============================================================================
--
--  Package: Pn.Classes.Discretes.Enums.Subs
--
--  This package implements sub classes of enumeration color classes, e.g.,
--  > type color: (red, green, blue, yellow, pink);
--  > subtype light_color: color range yellow .. pink;
--  This defines a sub class light_color which contains values yellow and pink.
--
--=============================================================================


with
  Pn.Ranges;

use
  Pn.Ranges;

package Pn.Classes.Discretes.Enums.Subs is

   --=====
   --  Type: Enum_Sub_Cls_Record
   --
   --  See also:
   --  o <Pn>, <Pn.Classes.Discretes> and <Pn.Classes.Discretes.Enums> to see
   --    all the primitive operations overridden by this type
   --=====
   type Enum_Sub_Cls_Record is new Enum_Cls_Record with private;

   --=====
   --  Type: Enum_Sub_Cls
   --=====
   type Enum_Sub_Cls is access all Enum_Sub_Cls_Record;


   --=====
   --  Function: New_Enum_Sub_Cls
   --  Constructor.
   --
   --  Parameters:
   --  Name       - name of the sub class
   --  Parent     - its parent
   --  Constraint - constraint on the parent
   --=====
   function New_Enum_Sub_Cls
     (Name      : in Ustring;
      Parent    : in Cls;
      Constraint: in Range_Spec) return Cls;


private


   type Enum_Sub_Cls_Record is new Enum_Cls_Record with
      record
         Parent    : Cls;        --  parent of the sub class
         Constraint: Range_Spec; --  constraint on the parent
      end record;

   procedure Free
     (C: in out Enum_Sub_Cls_Record);

   function Colors_Used
     (C: in Enum_Sub_Cls_Record) return Cls_Set;

   function Get_Root_Cls
     (C: in Enum_Sub_Cls_Record) return Cls;

   function Get_Root_Values
     (E: in Enum_Sub_Cls_Record) return Ustring_List;

   function Is_Sub_Cls
     (C     : in     Enum_Sub_Cls_Record;
      Parent: access Cls_Record'Class) return Boolean;

   function Get_Low
     (E: in Enum_Sub_Cls_Record) return Num_Type;

   function Get_High
     (E: in Enum_Sub_Cls_Record) return Num_Type;

end Pn.Classes.Discretes.Enums.Subs;
