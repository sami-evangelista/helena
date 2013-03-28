--=============================================================================
--
--  Package: Pn.Classes.Containers
--
--  This package implements container classes.  A container can be a
--  list or a set.  List and set classes have in common a capacity
--  which specifies the maximal number of items that can be stored in
--  the container and an element class that is the class of the
--  elements that can be stored in the container.
--
--=============================================================================


package Pn.Classes.Containers is

   type Container_Cls_Record is abstract new Cls_Record with private;

   type Container_Cls is access all Container_Cls_Record'Class;


   procedure Initialize
     (C       : access Container_Cls_Record'Class;
      Name    : in     Ustring;
      Elements: in     Cls;
      Capacity: in     Expr);

   function Get_Elements_Cls
     (C: access Container_Cls_Record) return Cls;

   function Get_Capacity_Value
     (C: access Container_Cls_Record) return Num_Type;


private


   type Container_Cls_Record is abstract new Cls_Record with
      record
         Elements: Cls;       --  class of the elements of the list
         Capacity: Expr;      --  capacity of the list class
      end record;

   procedure Free
     (C: in out Container_Cls_Record);

   function Low_Value
     (C: in Container_Cls_Record) return Expr;

   function High_Value
     (C: in Container_Cls_Record) return Expr;

   procedure Card
     (C     : in     Container_Cls_Record;
      Result:    out Card_Type;
      State :    out Count_State);

   function Ith_Value
     (C: in Container_Cls_Record;
      I: in Card_Type) return Expr;

   function Get_Value_Index
     (C: in     Container_Cls_Record;
      E: access Expr_Record'Class) return Card_Type;

   function Elements_Size
     (C: in Container_Cls_Record) return Natural;

   function Basic_Elements_Size
     (C: in Container_Cls_Record) return Natural;

   function Is_Const_Of_Cls
     (C: in     Container_Cls_Record;
      E: access Expr_Record'Class) return Boolean;

   function Colors_Used
     (C: in Container_Cls_Record) return Cls_Set;

   function Has_Constant_Bit_Width
     (C: in Container_Cls_Record) return Boolean;

   function Bit_Width
     (C: in Container_Cls_Record) return Natural;

   procedure Compile_Type_Definition
     (C  : in Container_Cls_Record;
      Lib: in Library);

   procedure Compile_Constants
     (C  : in Container_Cls_Record;
      Lib: in Library);

   procedure Compile_Operators
     (C  : in Container_Cls_Record;
      Lib: in Library);

   procedure Compile_Encoding_Functions
     (C  : in Container_Cls_Record;
      Lib: in Library);

   procedure Compile_Io_Functions
     (C  : in Container_Cls_Record;
      Lib: in Library);

   procedure Compile_Hash_Function
     (C  : in Container_Cls_Record;
      Lib: in Library);

   procedure Compile_Others
     (C  : in Container_Cls_Record;
      Lib: in Library);

end Pn.Classes.Containers;
