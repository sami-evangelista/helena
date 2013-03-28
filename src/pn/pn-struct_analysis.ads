--=============================================================================
--
--  Package: Pn.Struct_Analysis.Utils
--
--  This library contains various procedures of static analysis of the net.
--
--=============================================================================


with
  Pn.Nets;

use
  Pn.Nets;

package Pn.Struct_Analysis is

   procedure Compute_Statically_Safe_Trans
     (N: in Net);

   procedure Compute_Visible_Trans
     (N: in Net);

end Pn.Struct_Analysis;
