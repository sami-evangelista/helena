--=============================================================================
--
--  Program: helena-generate-bit_stream
--
--=============================================================================


with
  Ada.Command_Line,
  Ada.Text_Io,
  Helena.Exceptions,
  Pn.Compiler.Bit_Stream;

use
  Ada.Command_Line,
  Ada.Text_Io,
  Helena.Exceptions,
  Pn.Compiler.Bit_Stream;

procedure Helena_Generate_Bit_Stream_Main is
begin
   if Argument_Count /= 1 then
      Put_Line("usage: helena-generate-bit-stream out-dir");
      Set_Exit_Status(Ada.Command_Line.Failure);
   else
      Pn.Compiler.Bit_Stream.Gen("bit_stream", Argument(1));
      Set_Exit_Status(Ada.Command_Line.Success);
   end if;
exception
   when The_Exception: others =>
      Handle_Exception(The_Exception);
end;
