--=============================================================================
--
--  Package: Utils.Math
--
--  This package contains some basic mathematical functions.
--
--=============================================================================


package Utils.Math is

   --=====
   --  Function: Log2
   --
   --  Return:
   --  log_2(I)
   --=====
   function Log2
     (I: in Big_Nat) return Natural;

   --=====
   --  Function: Bit_Width
   --
   --  Return:
   --  the number of bits required to encode I distinct values
   --=====
   function Bit_Width
     (I: in Big_Nat) return Natural;

end;
