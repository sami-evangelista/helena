--=============================================================================
--
--  Package: Pn.Compiler.Event_Set
--
--  This package generates the definition of transition set of enabled
--  transitions.
--
--=============================================================================


package Pn.Compiler.Event_Set is

   procedure Gen
     (N   : in Net;
      Path: in Ustring);

end Pn.Compiler.Event_Set;
