--=============================================================================
--
--  Program: helena-generate
--
--  This is the main file of the helena-generate program that
--  transforms a net in a set of C files.
--
--=============================================================================


with
  Ada.Calendar,
  Ada.Command_Line,
  Ada.Directories,
  Ada.Strings,
  Ada.Strings.Unbounded,
  Ada.Text_Io,
  Gnat.Directory_Operations,
  Gnat.Os_Lib,
  Helena,
  Helena.Command_Line,
  Helena.Exceptions,
  Helena_Parser,
  Pn,
  Pn.Compiler,
  Pn.Nets,
  Pn.Propositions,
  Utils.Strings;

use
  Ada.Calendar,
  Ada.Command_Line,
  Ada.Directories,
  Ada.Strings,
  Ada.Strings.Unbounded,
  Ada.Text_Io,
  Gnat.Directory_Operations,
  Gnat.Os_Lib,
  Helena,
  Helena.Command_Line,
  Helena.Exceptions,
  Helena_Parser,
  Pn,
  Pn.Compiler,
  Pn.Nets,
  Pn.Propositions,
  Utils.Strings;

procedure Helena_Generate_Main is
   N   : Pn.Nets.Net;
   F   : File_Type;
   Prop: Unbounded_String;
begin
   Check_Command_Line;
   Parse_Command_Line;
   Parse_Net(Helena.Command_Line.Get_Lna_File, N);
   for I in 1..String_List_Pkg.Length(Get_Propositions) loop
      Prop := String_List_Pkg.Ith(Get_Propositions, I);
      if Is_Proposition(N, Prop) then
	 Set_Observed(Get_Proposition(N, Prop), True);
      else
	 Put_Line(To_String("error: proposition " & Prop & " is undefined"));
	 Set_Exit_Status(Ada.Command_Line.Failure);
	 return;
      end if;
   end loop;
   Pn.Compiler.Gen(N           => N,
		   Net_Path    => Command_Line.Get_Output_Dir,
		   Helena_File => Command_Line.Get_Lna_File);

   --  put the name of the net in file MODEL
   Create(F, Out_File,
	  Normalize_Pathname(To_String(Command_Line.Get_Output_Dir) &
			       Dir_Separator & "MODEL"));
   Put_Line(F, To_String(Get_Name(N)));
   Close(F);
   Set_Exit_Status(Ada.Command_Line.Success);

exception

   when The_Exception: others =>
      Handle_Exception(The_Exception);

end Helena_Generate_Main;
