--=============================================================================
--
--  Package: Pn.Classes.Vectors
--
--  This package implements vector classes.  For example:
--  > type my_vector_type: vector [bool, bool] of int;
--  The index of this vector class is the domain bool * bool and its element
--  class is int.
--
--=============================================================================


package Pn.Classes.Vectors is

   --=====
   --  Type: Vector_Cls_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Vector_Cls_Record is new Cls_Record with private;

   --=====
   --  Type: Vector_Cls
   --=====
   type Vector_Cls is access all Vector_Cls_Record'Class;

   --=====
   --  Subtype: Vector_Index
   --  since vectors may be indexed by multiple values we define an index as
   --  domain, i.e., a product of classes
   --=====
   subtype Vector_Index is Dom;


   --=====
   --  Function: New_Vector_Cls
   --  Constructor.
   --
   --  Parameters:
   --  Name     - name of the class
   --  Index    - domain of the index of the class
   --  Elements - class of the elements in the vector class
   --=====
   function New_Vector_Cls
     (Name    : in Ustring;
      Index   : in Vector_Index;
      Elements: in Cls) return Cls;

   --=====
   --  Function: Get_Index_Position
   --  Get the position of list I in the index domain of class V.  For example
   --  if the index is [bool, {1..3}] we will have:
   --  > (false, 1) -> 1
   --  > (false, 2) -> 2
   --  > (false, 3) -> 3
   --  > (true,  1) -> 4
   --  > (true,  2) -> 5
   --  > (true,  3) -> 6
   --
   --  Pre-Conditions:
   --  o I belongs to the index domain of V
   --=====
   function Get_Index_Position
     (V: in Vector_Cls;
      I: in Expr_List) return Card_Type;

   --=====
   --  Function: Get_Elements_Cls
   --  Get the class of the return the color of the elements of the vector
   --=====
   function Get_Elements_Cls
     (V: in Vector_Cls) return Cls;

   --=====
   --  Function: Get_Index_Dom
   --  Get the domain corresponding to the index of the vector class.
   --=====
   function Get_Index_Dom
     (V: in Vector_Cls) return Vector_Index;


private


   type Vector_Cls_Record is new Cls_Record with
      record
         Index   : Vector_Index;  --  index
         Elements: Cls;           --  element class
      end record;

   procedure Free
     (C: in out Vector_Cls_Record);

   function Get_Type
     (C: in Vector_Cls_Record) return Cls_Type;

   procedure Card
     (C     : in     Vector_Cls_Record;
      Result:    out Card_Type;
      State:    out Count_State);

   function Low_Value
     (C: in Vector_Cls_Record) return Expr;

   function High_Value
     (C: in Vector_Cls_Record) return Expr;

   function Ith_Value
     (C: in Vector_Cls_Record;
      I: in Card_Type) return Expr;

   function Get_Value_Index
     (C: in     Vector_Cls_Record;
      E: access Expr_Record'Class) return Card_Type;

   function Elements_Size
     (C: in Vector_Cls_Record) return Natural;

   function Basic_Elements_Size
     (C: in Vector_Cls_Record) return Natural;

   function Is_Const_Of_Cls
     (C: in     Vector_Cls_Record;
      E: access Expr_Record'Class) return Boolean;

   function Colors_Used
     (C: in Vector_Cls_Record) return Cls_Set;

   function Has_Constant_Bit_Width
     (C: in Vector_Cls_Record) return Boolean;

   function Bit_Width
     (C: in Vector_Cls_Record) return Natural;

   procedure Compile_Type_Definition
     (C  : in Vector_Cls_Record;
      Lib: in Library);

   procedure Compile_Constants
     (C  : in Vector_Cls_Record;
      Lib: in Library);

   procedure Compile_Operators
     (C  : in Vector_Cls_Record;
      Lib: in Library);

   procedure Compile_Encoding_Functions
     (C  : in Vector_Cls_Record;
      Lib: in Library);

   procedure Compile_Io_Functions
     (C  : in Vector_Cls_Record;
      Lib: in Library);

   procedure Compile_Hash_Function
     (C  : in Vector_Cls_Record;
      Lib: in Library);

   procedure Compile_Others
     (C  : in Vector_Cls_Record;
      Lib: in Library);

end Pn.Classes.Vectors;
