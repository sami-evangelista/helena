--=============================================================================
--
--  Package: Pn.Classes.Discretes.Enums
--
--  This is the basis package which implements enumeration classes.
--
--=============================================================================


package Pn.Classes.Discretes.Enums is

   --=====
   --  Type: Enum_Cls_Record
   --
   --  See also:
   --  o <Pn> and <Pn.Classes.Discretes> to see all the primitive operations
   --    overridden by this type
   --=====
   type Enum_Cls_Record is abstract new Discrete_Cls_Record with private;

   --=====
   --  Type: Enum_Cls
   --=====
   type Enum_Cls is access all Enum_Cls_Record;


   --=====
   --  Function: Is_Of_Cls
   --  Check if Str is in the enumeration constants of class E.
   --=====
   function Is_Of_Cls
     (E  : access Enum_Cls_Record'Class;
      Str: in     Ustring) return Boolean;

   --=====
   --  Function: Is_Of_Cls
   --  Get the list of enumeration constants which defines the root class of
   --  class E.
   --=====
   function Get_Root_Values
     (E: access Enum_Cls_Record'Class) return Ustring_List;



   --==========================================================================
   --  Group: Primitive operations of type Enum_Cls_Record
   --==========================================================================

   --=====
   --  Function: Get_Root_Values
   --=====
   function Get_Root_Values
     (E: in Enum_Cls_Record) return Ustring_List is abstract;


private


   type Enum_Cls_Record is abstract new Discrete_Cls_Record with
      record
         null;
      end record;

   function Get_Type
     (C: in Enum_Cls_Record) return Cls_Type;

   procedure Card
     (C     : in     Enum_Cls_Record;
      Result:    out Card_Type;
      State:    out Count_State);

   function Low_Value
     (C: in Enum_Cls_Record) return Expr;

   function High_Value
     (C: in Enum_Cls_Record) return Expr;

   function Ith_Value
     (C: in Enum_Cls_Record;
      I: in Card_Type) return Expr;

   function Get_Value_Index
     (C: in     Enum_Cls_Record;
      E: access Expr_Record'Class) return Card_Type;

   function Is_Const_Of_Cls
     (C: in     Enum_Cls_Record;
      E: access Expr_Record'Class) return Boolean;

   procedure Compile_Type_Definition
     (C  : in Enum_Cls_Record;
      Lib: in Library);

   procedure Compile_Constants
     (C  : in Enum_Cls_Record;
      Lib: in Library);

   procedure Compile_Operators
     (C  : in Enum_Cls_Record;
      Lib: in Library);

   procedure Compile_Io_Functions
     (C  : in Enum_Cls_Record;
      Lib: in Library);

   procedure Compile_Others
     (C  : in Enum_Cls_Record;
      Lib: in Library);

   function Is_Circular
     (D: in Enum_Cls_Record) return Boolean;

   function From_Num_Value
     (D: in Enum_Cls_Record;
      N: in Num_Type) return Expr;

end Pn.Classes.Discretes.Enums;
