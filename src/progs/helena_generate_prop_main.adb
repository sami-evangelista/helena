--=============================================================================
--
--  Program: helena-generate
--
--  This is the main file of the helena-generate-prop program that
--  transforms a set of properties in a set of C files.
--
--=============================================================================


with
  Ada.Command_Line,
  Ada.Exceptions,
  Ada.Strings.Unbounded,
  Ada.Text_Io,
  Gnat.Directory_Operations,
  Gnat.Os_Lib,
  Libraries,
  Prop,
  Prop_Parser,
  Prop_Parser.Analyser,
  Utils.Strings;

use
  Ada.Command_Line,
  Ada.Exceptions,
  Ada.Strings.Unbounded,
  Ada.Text_Io,
  Gnat.Directory_Operations,
  Gnat.Os_Lib,
  Libraries,
  Prop,
  Prop_Parser,
  Prop_Parser.Analyser,
  Utils.Strings;

procedure Helena_Generate_Prop_Main is
   P       : Property_List;
   Pr      : Property;
   In_File : Ustring;
   Out_Dir : Ustring;
   Prop    : Ustring;
   F       : File_Type;
   Props   : Ustring_List;
   L       : Library;
   procedure Put_Usage is
   begin
      Put_Line
	("usage: helena-generate-property property property-file directory");
   end;
begin
   if Argument_Count /= 3 then
      Put_Usage;
      Set_Exit_Status(Failure);
   else
      Prop := To_Ustring(Argument(1));
      In_File := To_Ustring(Argument(2));
      Out_Dir := To_Ustring(Argument(3));
      Parse_Properties(In_File, P);

      --  generate the C code for the property and put the name of
      --  propositions appearing in the property in file PROPERTY
      if not Contains(P, Prop) then
	 Put_Line(To_String("error: property '" & Prop & "' is undefined"));
	 Set_Exit_Status(Failure);
      else
	 Pr := Get(P, Prop);
	 Create(F, Out_File,
		Normalize_Pathname
		  (To_String(Out_Dir) & Dir_Separator & "PROPERTY"));
	 case Get_Type(Pr) is
	    when A_Ltl_Property      => Put_Line(F, "LTL");
	    when A_State_Property    => Put_Line(F, "STATE");
	    when A_Deadlock_Property => Put_Line(F, "DEADLOCK");
	 end case;
	 Props := Get_Propositions(Pr);
	 for I in 1..String_List_Pkg.Length(Props) loop
	    Put_Line(F, To_String(String_List_Pkg.Ith(Props, I)));
	 end loop;
	 Close (F);
	 Init_Library("prop", "definition of the property checked",
		      To_String(Out_Dir), L,
		      (1 => To_Ustring("model"),
		       2 => To_Ustring("common")));
	 Compile_Definition(Pr, L, To_String(Out_Dir));
	 End_Library(L);
      end if;
   end if;
exception
   when The_Exception: others =>
      Put_Line("error: " & Exception_Message(The_Exception));
      Set_Exit_Status(Failure);
end Helena_Generate_Prop_Main;
