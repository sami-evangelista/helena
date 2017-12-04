--=============================================================================
--
--  Package: Pn.Classes.Containers.Sets
--
--  This package implements set color classes.  A set class is declared as
--  follows:
--  > type int_set: set of int with capacity 10;
--  This declares a set class int_set which elements are int.  Any set of type
--  int_set cannot contain more than 10 items.
--
--=============================================================================


package Pn.Classes.Containers.Sets is

   type Set_Cls_Record is new Container_Cls_Record with private;

   type Set_Cls is access all Set_Cls_Record'Class;


   function New_Set_Cls
     (Name    : in Ustring;
      Elements: in Cls;
      Capacity: in Expr) return Cls;


private


   type Set_Cls_Record is new Container_Cls_Record with
      record
         null;
      end record;

   function Get_Type
     (C: in Set_Cls_Record) return Cls_Type;

   function Colors_Used
     (C: in Set_Cls_Record) return Cls_Set;

   procedure Compile_Operators
     (C  : in Set_Cls_Record;
      Lib: in Library);

   procedure Compile_Others
     (C  : in Set_Cls_Record;
      Lib: in Library);

end Pn.Classes.Containers.Sets;
