--=============================================================================
--
--  Package: Pn.Classes.Discretes.Nums
--
--  This package implements numerical classes which belong to the family of
--  discrete color classes.
--
--=============================================================================


package Pn.Classes.Discretes.Nums is

   --=====
   --  Type: Num_Cls_Record
   --
   --  See also:
   --  o <Pn> and <Pn.Classes.Discretes> to see all the primitive operations
   --    overridden by this type
   --=====
   type Num_Cls_Record is abstract new Discrete_Cls_Record with private;

   --=====
   --  Type: Num_Cls
   --=====
   type Num_Cls is access all Num_Cls_Record'Class;


   --=====
   --  Function: Normalize_Value
   --  Convert numerical constant I to the class C.  For a range type it
   --  directly returns I.  For a modulo type it makes the modulo operation so
   --  that it belongs to C.
   --=====
   function Normalize_Value
     (C: access Num_Cls_Record'Class;
      I: in     Num_Type) return Num_Type;

   --=====
   --  Function: To_Helena
   --  Convert Num_Type N to Helena.
   --=====
   function To_Helena
     (N: in Num_Type) return Ustring;



   --==========================================================================
   --  Group: Primitive operations of type Num_Cls_Record
   --==========================================================================

   --=====
   --  Function: Normalize_Value
   --=====
   function Normalize_Value
     (C: in Num_Cls_Record;
      I: in Num_Type) return Num_Type is abstract;


private


   type Num_Cls_Record is abstract new Discrete_Cls_Record with
      record
         null;
      end record;

   function Get_Type
     (C: in Num_Cls_Record) return Cls_Type;

   procedure Card
     (C     : in     Num_Cls_Record;
      Result:    out Card_Type;
      State :    out Count_State);

   function Low_Value
     (C: in Num_Cls_Record) return Expr;

   function High_Value
     (C: in Num_Cls_Record) return Expr;

   function Ith_Value
     (C: in Num_Cls_Record;
      I: in Card_Type) return Expr;

   function Get_Value_Index
     (C: in     Num_Cls_Record;
      E: access Expr_Record'Class) return Card_Type;

   function Is_Const_Of_Cls
     (C: in     Num_Cls_Record;
      E: access Expr_Record'Class) return Boolean;

   procedure Compile_Constants
     (C  : in Num_Cls_Record;
      Lib: in Library);

   procedure Compile_Operators
     (C  : in Num_Cls_Record;
      Lib: in Library);

   procedure Compile_Io_Functions
     (C  : in Num_Cls_Record;
      Lib: in Library);

   procedure Compile_Others
     (C  : in Num_Cls_Record;
      Lib: in Library);

   function From_Num_Value
     (D: in Num_Cls_Record;
      N: in Num_Type) return Expr;

end Pn.Classes.Discretes.Nums;
