--=============================================================================
--
--  Package: Pn.Classes.Products
--
--  This package implements product classes.  A product class is a cartesian
--  product of basic types.  A product class is declared for each place.
--  These classes are hidden and cannot be used by user.  They are only used in
--  iterators.  For example:
--  > place p { dom: int * short; }
--  > forall(token in my_place: token->1 > 10 and token->2 < 5)
--  The class of the iteration variable token is the product class int * short,
--  token->1 is an int expression and token->2 is a short expression.
--
--=============================================================================


package Pn.Classes.Products is

   --=====
   --  Type: Product_Cls_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Product_Cls_Record is new Cls_Record with private;

   --=====
   --  Type: Product_Cls
   --=====
   type Product_Cls is access all Product_Cls_Record;


   --=====
   --  Function: New_Product_Cls
   --  Constructor.
   --
   --  Parameters:
   --  D - domain of the product class
   --=====
   function New_Product_Cls
     (D: in Dom) return Cls;

   --=====
   --  Function: Get_Product_Cls_Name
   --  Get the name of the class which corresponds to color domain D.
   --=====
   function Get_Product_Cls_Name
     (D: in Dom) return Ustring;

   --=====
   --  Function: Get_Dom
   --  Get the domain of the product class P.
   --=====
   function Get_Dom
     (P: in Product_Cls) return Dom;


private


   type Product_Cls_Record is new Cls_Record with
      record
         D: Dom; --  corresponding color domain
      end record;

   procedure Free
     (C: in out Product_Cls_Record);

   function Get_Type
     (C: in Product_Cls_Record) return Cls_Type;

   function Low_Value
     (C: in Product_Cls_Record) return Expr;

   function High_Value
     (C: in Product_Cls_Record) return Expr;

   procedure Card
     (C     : in     Product_Cls_Record;
      Result:    out Card_Type;
      State:    out Count_State);

   function Ith_Value
     (C: in Product_Cls_Record;
      I: in Card_Type) return Expr;

   function Get_Value_Index
     (C: in     Product_Cls_Record;
      E: access Expr_Record'Class) return Card_Type;

   function Elements_Size
     (C: in Product_Cls_Record) return Natural;

   function Basic_Elements_Size
     (C: in Product_Cls_Record) return Natural;

   function Is_Const_Of_Cls
     (C: in     Product_Cls_Record;
      E: access Expr_Record'Class) return Boolean;

   function Colors_Used
     (C: in Product_Cls_Record) return Cls_Set;

   function Has_Constant_Bit_Width
     (C: in Product_Cls_Record) return Boolean;

   function Bit_Width
     (C: in Product_Cls_Record) return Natural;

   procedure Compile_Type_Definition
     (C  : in Product_Cls_Record;
      Lib: in Library);

   procedure Compile_Constants
     (C  : in Product_Cls_Record;
      Lib: in Library);

   procedure Compile_Operators
     (C  : in Product_Cls_Record;
      Lib: in Library);

   procedure Compile_Encoding_Functions
     (C  : in Product_Cls_Record;
      Lib: in Library);

   procedure Compile_Io_Functions
     (C  : in Product_Cls_Record;
      Lib: in Library);

   procedure Compile_Hash_Function
     (C  : in Product_Cls_Record;
      Lib: in Library);

   procedure Compile_Others
     (C  : in Product_Cls_Record;
      Lib: in Library);

end Pn.Classes.Products;
