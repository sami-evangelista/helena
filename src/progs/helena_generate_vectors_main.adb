--=============================================================================
--
--  Program: helena-generate-vectors
--
--=============================================================================


with
  Ada.Command_Line,
  Ada.Text_Io,
  Helena.Exceptions,
  Pn.Compiler.Vectors;

use
  Ada.Command_Line,
  Ada.Text_Io,
  Helena.Exceptions,
  Pn.Compiler.Vectors;

procedure Helena_Generate_Vectors_Main is
begin
   if Argument_Count /= 1 then
      Put_Line("usage: helena-generate-vectors out-dir");
      Set_Exit_Status(Ada.Command_Line.Failure);
   else
      Pn.Compiler.Vectors.Gen("vectors", Argument(1));
      Set_Exit_Status(Ada.Command_Line.Success);
   end if;
exception
   when The_Exception: others =>
      Handle_Exception(The_Exception);
end;
