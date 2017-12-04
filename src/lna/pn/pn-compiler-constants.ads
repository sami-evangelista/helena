--=============================================================================
--
--  Package: Pn.Compiler.Constants
--
--  This package provides procedure to compile all the constants of a net in a
--  C library.
--
--=============================================================================


package Pn.Compiler.Constants is

   --=====
   --  Procedure: Gen
   --  Main generation procedure.
   --  Compile all the constants of net N in a library.
   --  Path is the absolute path of the directory in which the library must be
   --  generated.
   --=====
   procedure Gen
     (N   : in Net;
      Path: in Ustring);

end Pn.Compiler.Constants;
