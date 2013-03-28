--=============================================================================
--
--  Package: Pn.Compiler.Util
--
--  This package generates various functions, macros and global variables used
--  everywhere in the generated code.
--
--=============================================================================


package Pn.Compiler.Util is

   procedure Gen
     (N   : in Net;
      Path: in Ustring);
   --  main generation procedure

   function Capacity_Const_Name
     (P: in Place) return Ustring;
   --  name of the constant which correspond to the capacity of place P

   function Pid
     (P: in Place) return Ustring;
   --  return the identifier of place P

   function Tid
     (T: in Trans) return Ustring;
   --  return the identifier of transition T

end Pn.Compiler.Util;
