--=============================================================================
--
--  Package: Helena.Exceptions
--
--  This package manages exceptions that can occur in Helena.
--
--=============================================================================


with
  Ada.Exceptions;

use
  Ada.Exceptions;

package Helena.Exceptions is

   procedure Handle_Exception
     (E: in Exception_Occurrence);
   --  handle exception E

end Helena.Exceptions;
