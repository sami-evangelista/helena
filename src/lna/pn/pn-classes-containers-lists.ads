--=============================================================================
--
--  Package: Pn.Classes.Containers.Lists
--
--  This package implements list color classes.  A list class is
--  declared as follows:
--  > type int_list: list[nat] of int with capacity 10;
--  This declares a list class int_list which elements are int that
--  can be accessed via an index of type nat.  Any list of type
--  int_list cannot contain more than 10 items.
--
--=============================================================================


package Pn.Classes.Containers.Lists is

   type List_Cls_Record is new Container_Cls_Record with private;

   type List_Cls is access all List_Cls_Record'Class;


   function New_List_Cls
     (Name    : in Ustring;
      Elements: in Cls;
      Index   : in Cls;
      Capacity: in Expr) return Cls;

   function Get_Index_Cls
     (L: in List_Cls) return Cls;


private


   type List_Cls_Record is new Container_Cls_Record with
      record
         Index: Cls;
      end record;

   function Get_Type
     (C: in List_Cls_Record) return Cls_Type;

   function Colors_Used
     (C: in List_Cls_Record) return Cls_Set;

   procedure Compile_Operators
     (C   : in List_Cls_Record;
      Lib: in Library);

   procedure Compile_Others
     (C   : in List_Cls_Record;
      Lib: in Library);

end Pn.Classes.Containers.Lists;
