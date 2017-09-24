--=============================================================================
--
--  Package: Pn.Classes.Discretes.Enums.Roots
--
--  This package implements enumeration color classes, e.g.,
--  > type color: enum (red, green, blue)
--
--=============================================================================


package Pn.Classes.Discretes.Enums.Roots is

   --=====
   --  Type: Enum_Root_Cls_Record
   --
   --  See also:
   --  o <Pn>, <Pn.Classes.Discretes> and <Pn.Classes.Discretes.Enums> to see
   --    all the primitive operations overridden by this type
   --=====
   type Enum_Root_Cls_Record is new Enum_Cls_Record with private;

   --=====
   --  Type: Enum_Root_Cls
   --=====
   type Enum_Root_Cls is access all Enum_Root_Cls_Record;

   --=====
   --  Type: String_Array
   --  an array of strings
   --=====
   type String_Array is array(Positive range <>) of Ustring;


   --=====
   --  Function: New_Enum_Cls
   --  Constructor.
   --
   --  Parameters:
   --  Name   - name of the color class
   --  Values - array of strings which contains the values of the
   --           enumeration class
   --
   --  Pre-Conditions:
   --  o a value cannot appear twice in Values
   --=====
   function New_Enum_Cls
     (Name  : in Ustring;
      Values: in String_Array) return Cls;


private


   type Enum_Root_Cls_Record is new Enum_Cls_Record with
      record
         Values: Ustring_List; --  values which compose the enumeration
      end record;

   procedure Free
     (C: in out Enum_Root_Cls_Record);

   function Colors_Used
     (C: in Enum_Root_Cls_Record) return Cls_Set;

   function Get_Root_Values
     (E: in Enum_Root_Cls_Record) return Ustring_List;

   function Get_Low
     (E: in Enum_Root_Cls_Record) return Num_Type;

   function Get_High
     (E: in Enum_Root_Cls_Record) return Num_Type;

end Pn.Classes.Discretes.Enums.Roots;
