--=============================================================================
--
--  Package: Pn.Classes.Discretes
--
--  This package implements discrete color classes.
--
--=============================================================================


package Pn.Classes.Discretes is

   --=====
   --  Type: Discrete_Cls_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Discrete_Cls_Record is abstract new Cls_Record with private;

   --=====
   --  Type: Discrete_Cls
   --=====
   type Discrete_Cls is access all Discrete_Cls_Record'Class;


   --=====
   --  Procedure: Get_Values_Range
   --  Get the range of values of color E with respect to the root class
   --  of E.
   --  o for enumeration color classes, the range starts at 0 and ends at the
   --    length of the constant list which defines the type (- 1)
   --  o for numerical color classes, the range starts at the first value of
   --    the type and ends at the last value of the type
   --
   --  For example, if we consider
   --  > type small_int            : range -100..100;
   --  > subtype unsigned_small_int: small_int range 0..100;
   --  > type color                : enum (R, G, B);
   --  > subtype gb_color          : color range G..B;
   --  then
   --  >            D         |  Low | High
   --  >  ==================================
   --  >   small_int          | -100 |  100
   --  >   unsigned_small_int |    0 |  100
   --  >   color              |    0 |    2
   --  >   rg_color           |    1 |    2
   --=====
   procedure Get_Values_Range
     (D   : access Discrete_Cls_Record'Class;
      Low :    out Num_Type;
      High:    out Num_Type);

   --=====
   --  Function: Get_Low
   --  Get the low value of the range of D.  See <Get_Values_Range> for
   --  explanations.
   --=====
   function Get_Low
     (D: access Discrete_Cls_Record'Class) return Num_Type;

   --=====
   --  Function: Get_High
   --  Get the high value of the range of D.  See <Get_Values_Range> for
   --  explanations.
   --=====
   function Get_High
     (D: access Discrete_Cls_Record'Class) return Num_Type;

   --=====
   --  Function: Is_Circular
   --  Check if the discrete class D is circular.  Enumeration and modulo
   --  classes.  Range classes are not.
   --=====
   function Is_Circular
     (D: access Discrete_Cls_Record'Class) return Boolean;

   --=====
   --  Function: Convert_Num_Value
   --  Convert a numerical value to the corresponding constant of class D.
   --  See <Get_Values_Range> for explanations on how this conversion is done.
   --=====
   function From_Num_Value
     (D: access Discrete_Cls_Record'Class;
      N: in     Num_Type) return Expr;



   --==========================================================================
   --  Group: Primitive operations of type Discrete_Cls_Record
   --==========================================================================

   --=====
   --  Function: Get_Low
   --=====
   function Get_Low
     (D: in Discrete_Cls_Record) return Num_Type is abstract;

   --=====
   --  Function: Get_High
   --=====
   function Get_High
     (D: in Discrete_Cls_Record) return Num_Type is abstract;

   --=====
   --  Function: Is_Circular
   --=====
   function Is_Circular
     (D: in Discrete_Cls_Record) return Boolean is abstract;

   --=====
   --  Function: From_Num_Value
   --=====
   function From_Num_Value
     (D: in Discrete_Cls_Record;
      N: in Num_Type) return Expr is abstract;



private


   type Discrete_Cls_Record is abstract new Cls_Record with
      record
         null;
      end record;

   function Elements_Size
     (C: in Discrete_Cls_Record) return Natural;

   function Basic_Elements_Size
     (C: in Discrete_Cls_Record) return Natural;

   function Has_Constant_Bit_Width
     (C: in Discrete_Cls_Record) return Boolean;

   function Bit_Width
     (C: in Discrete_Cls_Record) return Natural;

   procedure Compile_Type_Definition
     (C  : in Discrete_Cls_Record;
      Lib: in Library);

   procedure Compile_Operators
     (C  : in Discrete_Cls_Record;
      Lib: in Library);

   procedure Compile_Encoding_Functions
     (C  : in Discrete_Cls_Record;
      Lib: in Library);

   procedure Compile_Hash_Function
     (C  : in Discrete_Cls_Record;
      Lib: in Library);

end Pn.Classes.Discretes;
