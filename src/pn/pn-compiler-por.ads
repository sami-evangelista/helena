--=============================================================================
--
--  Package: Pn.Compiler.Por
--
--  This package and its children are used to generate the partial
--  order reduction (POR) algorithm of Helena.
--
--=============================================================================


package Pn.Compiler.Por is

   procedure Gen
     (N   : in Net;
      Path: in Ustring);

end Pn.Compiler.Por;
