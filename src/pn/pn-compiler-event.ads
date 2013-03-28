--=============================================================================
--
--  Package: Pn.Compiler.Event
--
--  This package generates the definition of event type list and set
--  of enabled transitions. It also generates various functions
--  related to events, e.g., event execution functions.
--
--=============================================================================


with
  Pn.Mappings;

use
  Pn.Mappings;

package Pn.Compiler.Event is

   procedure Gen
     (N   : in Net;
      Path: in Ustring);

   function Trans_Exec_Func
     (T: in Trans;
      F: in Firing_Mode) return Ustring;

end Pn.Compiler.Event;
