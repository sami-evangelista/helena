with
  Ada.Command_Line,
  Ada.Strings.Unbounded,
  Ada.Text_Io,
  Helena_Parser,
  Pn,
  Utils.Strings;

use
  Ada.Command_Line,
  Ada.Strings.Unbounded,
  Ada.Text_Io,
  Helena_Parser,
  Pn,
  Utils.Strings;

package body Helena.Exceptions is

   procedure Handle_Exception
     (E : in Exception_Occurrence) is
      Id: constant Exception_Id := Exception_Identity(E);
   begin
         --===
         --  terminate helena
         --===
      if Id = Helena_Terminate_Exception'Identity then
         Set_Exit_Status(Success);

         --===
         --  environment exception
         --===
      elsif Id = Helena_Environment_Exception'Identity then
         Set_Exit_Status(Failure);

         --===
         --  command line exception
         --===
      elsif Id = Helena_Command_Line_Exception'Identity then
         Set_Exit_Status(Failure);

         --===
         --  parser exception
         --===
      elsif Id = Helena_Parser.Parse_Exception'Identity then
         Put_Line(To_String(Helena_Parser.Get_Error_Msg));
         Set_Exit_Status(Failure);

         --===
         --  IO exception
         --===
      elsif Id = Helena_Io_Exception'Identity or
	Id = Helena_Parser.Io_Exception'Identity
      then
         Put_Line(Exception_Message(E));
         Set_Exit_Status(Failure);

         --===
         --  net compilation exception
         --===
      elsif Id = Compilation_Exception'Identity then
         Put_Line("error: " & Exception_Message(E));
         Set_Exit_Status(Failure);

         --===
         --  unknown exception
         --===
      else
         Put_Line(To_String(80 * '*'));
         Put_Line("*");
         Put_Line("*  " & Replace(Unknown_Err_Msg,
                                  To_String_Mapping((1 => Ascii.Lf),
                                                    Ascii.Lf & "*  ")));
         Put_Line("*  exception:");
         Put_Line("*     name: " & Exception_Name(E));
         Put_Line("*     message: " & Exception_Message(E));
         Put_Line("*");
         Put_Line(To_String(80 * '*'));
         Set_Exit_Status(Failure);
      end if;
   end;

end Helena.Exceptions;
