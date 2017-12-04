--=============================================================================
--
--  Package: Pn.Compiler.Model
--
--=============================================================================


package Pn.Compiler.Model is

   procedure Gen
     (N   : in Net;
      Path: in Ustring);

   procedure Add_Expr
     (E: in Expr);

end;
