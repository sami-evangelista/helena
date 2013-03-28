--=============================================================================
--
--  Program: helena-generate-interface
--
--=============================================================================


with
  Ada.Command_Line,
  Ada.Text_Io,
  Helena.Exceptions,
  Helena_Parser,
  Pn,
  Pn.Compiler,
  Pn.Nets,
  Utils.Strings;

use
  Ada.Command_Line,
  Ada.Text_Io,
  Helena.Exceptions,
  Helena_Parser,
  Pn,
  Pn.Compiler,
  Pn.Nets,
  Utils.Strings;

procedure Helena_Generate_Interface_Main is
   N: Pn.Nets.Net;
begin

   if Argument_Count /= 2 then
      Put_Line("usage: helena-generate-interface my_net.lna interface.h");
      Set_Exit_Status(Ada.Command_Line.Failure);
   else
      Parse_Net(To_Ustring(Argument(1)), N);
      Pn.Compiler.Gen_Interfaces(N, To_Ustring(Argument(2)));
      Set_Exit_Status(Ada.Command_Line.Success);
   end if;

exception

   when The_Exception: others =>
      Handle_Exception(The_Exception);
end;
