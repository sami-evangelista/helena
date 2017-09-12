--=============================================================================
--
--  Package: Pn.Compiler.Vectors
--
--  This package implements the bit vector type.  A bit vector is represented
--  as an array of slots.  The type of slot is given by constant
--  Checker.Slot_Type.  Four additional fields are used:
--  o pos: slot number of the current position
--  o shift: shift (in bits) in the slot number of the current position
--  o bit_size: size in bits of the vector
--  o slot_size: size in slots of the vector
--
--  Two main macros are provided to manipulate bit vector:
--    - get(v, val, N):
--      put in val (any unsigned long long int) the value encoded at the
--      current position in vector v of N bits. Also update the pos and shift
--      fields of the vector
--    - set(v, val, N):
--      set in vector V the value of val on the N next bits of v. Also update
--      the pos and shift fields of the vector
--
--=============================================================================


package Pn.Compiler.Vectors is

   --==========================================================================
   --  Group: Constants
   --==========================================================================

   --=====
   --  Constant: Slot_Type
   --  Name of the type of the slots in a bit vector.
   --=====
   Slot_Type: constant String := "char";

   --=====
   --  Constant: Bits_Per_Char
   --  Number of bits in the C char type.
   --=====
   Bits_Per_Char: constant Natural := Char_Bit;

   --=====
   --  Constant: Bits_Per_Slot
   --  Number of bits in a slot of a bit vector.
   --=====
   Bits_Per_Slot: constant Natural := Bits_Per_Char;

   --=====
   --  Constant: Max_Width
   --  Maximal size in bits of a basic object that can be encoded in a bit
   --  vector.
   --=====
   Max_Width: constant Natural := 64;

   --=====
   --  Subtype: Item_Width
   --  width of an item that can be encoded in a bit vector
   --=====
   subtype Item_Width is Natural range 0 .. Max_Width;

   procedure Gen
     (Lib : in String;
      Path: in String);
   --  main generation procedure



   --==========================================================================
   --  some useful functions
   --==========================================================================

   function Get_Division_Expr
     (Expr: in Unbounded_String;
      Div : in Natural) return Unbounded_String;
   --  return the expression corresponding to Expr / Div: if Div=2^N, this
   --  will do Expr >> N instead of Expr / Div

   function Get_Mult_Expr
     (Expr: in Unbounded_String;
      Mult: in Natural) return Unbounded_String;
   --  return the expression corresponding to Expr * Div: if Div=2^N, this
   --  will do Expr << N instead of Expr * Div

   function Get_Modulo_Expr
     (Expr  : in Unbounded_String;
      Modulo: in Natural) return Unbounded_String;
   --  return the expression corresponding to Expr % Div: if Div=2^N, this
   --  will do Expr & (N-1) instead of Expr % Div

   function Slots_For_Bits
     (Bits: in Natural) return Natural;
   --  return the number of slots needed to store Bits binary digits

   function Get_Mask
     (Low: in Natural;
      Up : in Natural) return Unbounded_String;
   --  return the mask which enables to get the bits between low and up

   type A_Range is
      record
         Low: Natural;
         Up : Natural;
      end record;
   type Ranges is array(Positive range <>) of A_Range;

   function Get_Mask
     (R: in Ranges) return Unbounded_String;
   --  same with a set of ranges

   function Slots_For_Bits_Func return Unbounded_String;
   --  return the name of the function which compute the number of slots
   --  needed to encode a certain number of bits



   --==========================================================================
   --  vector of bits
   --==========================================================================

   function Vector_Get_Func
     (Size: in Item_Width) return Unbounded_String;
   --  return the name of the function which gets the bits from a vector. The
   --  size is known by the caller

   function Vector_Get_Back_Func
     (Size: in Item_Width) return Unbounded_String;
   --  return the name of the function which gets the bits of a vector
   --  backwardly. The size is known by the caller

   function Vector_Set_Func
     (Size: in Item_Width) return Unbounded_String;
   --  return the name of the function which set the bits of a vector. The
   --  size is known by the caller

end Pn.Compiler.Vectors;
