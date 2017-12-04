--=============================================================================
--
--  Package: Utils
--
--  This package contains some useful stuffs.
--
--=============================================================================


with
  System;

use
  System;

package Utils is

   --=====
   --  Type: Big_Int
   --  A value of type Big_Int can take all the integer values allowed by the
   --  system.
   --=====
   type Big_Int is range System.Min_Int .. System.Max_Int;

   --=====
   --  Subtype: Big_Int
   --  A value of type Big_Nat can take all the positive integer values
   --  allowed by the system.
   --=====
   subtype Big_Nat is Big_Int range 0 .. Big_Int'Last;

   --=====
   --  Subtype: Big_Pos
   --  A value of type Big_Pos can take all the strictly positive integer
   --  values allowed by the system.
   --=====
   subtype Big_Pos is Big_Nat range 1 .. Big_Int'Last;

end Utils;
