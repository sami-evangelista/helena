--=============================================================================
--
--  Package: Pn.Compiler.Funcs
--
--  This package enables to compile the functions which appear in the net in
--  a C library.
--
--=============================================================================


package Pn.Compiler.Funcs is

   --=====
   --  Procedure: Gen
   --  The generation procedure.
   --  Compile all the functions of net N in C functions.
   --  Path is the absolute path of the directory in which the generated
   --  library will be placed.
   --=====
   procedure Gen
     (N   : in Net;
      Path: in Ustring);

end Pn.Compiler.Funcs;
