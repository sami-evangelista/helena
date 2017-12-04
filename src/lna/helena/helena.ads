--=============================================================================
--
--  Package: Helena
--
--  This is the basis package for the Helena model checker.
--
--=============================================================================


package Helena is

   function Unknown_Err_Msg return String;
   --  return the name of the error message which is displayed if an unknown
   --  error occured

   --  an environment exception
   Helena_Environment_Exception,

   --  terminate helena
   Helena_Terminate_Exception,

   --  exception in the command line
   Helena_Command_Line_Exception,

   --  input-output exception
   Helena_Io_Exception: exception;

end Helena;
