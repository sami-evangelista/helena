with
  Ada.Directories,
  Gnat.Directory_Operations,
  Gnat.Io_Aux,
  Gnat.Os_Lib,
  Pn.Struct_Analysis,
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Classes,
  Pn.Compiler.Config,
  Pn.Compiler.Constants,
  Pn.Compiler.Domains,
  Pn.Compiler.Enabling_Test,
  Pn.Compiler.Event,
  Pn.Compiler.Funcs,
  Pn.Compiler.Graph,
  Pn.Compiler.Interfaces,
  Pn.Compiler.Mappings,
  Pn.Compiler.Model,
  Pn.Compiler.Por,
  Pn.Compiler.Util,
  Pn.Compiler.State;

use
  Ada.Directories,
  Gnat.Directory_Operations,
  Gnat.Io_Aux,
  Gnat.Os_Lib,
  Pn.Struct_Analysis,
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Classes,
  Pn.Compiler.Config,
  Pn.Compiler.Constants,
  Pn.Compiler.Domains,
  Pn.Compiler.Enabling_Test,
  Pn.Compiler.Event,
  Pn.Compiler.Funcs,
  Pn.Compiler.Graph,
  Pn.Compiler.Interfaces,
  Pn.Compiler.Mappings,
  Pn.Compiler.Model,
  Pn.Compiler.Por,
  Pn.Compiler.Util,
  Pn.Compiler.State;

package body Pn.Compiler is


   --==========================================================================
   --  Main generation procedure
   --==========================================================================

   procedure Gen
     (N          : in Net;
      Net_Path   : in Ustring;
      Helena_File: in Ustring) is
      Path: constant Ustring := Net_Path;
      F   : File_Type;
   begin

      --===
      --  initialize some global variables
      --===
      Compiler.Helena_File := Helena_File;
      Compiler.Net_Path := Path;

      --===
      --  set the parameters of the net that were changed via command line
      --===
      Set_Net_Parameters(N);

      --===
      --  static analysis of the net:
      --    1 - compute visible transitions
      --    2 - compute statically safe transitions
      --===
      Pn.Struct_Analysis.Compute_Visible_Trans(N);
      Pn.Struct_Analysis.Compute_Statically_Safe_Trans(N);

      --===
      --  generate all libraries
      --===
      Bit_Stream.Gen("bit_stream", To_String(Path));
      Interfaces.Gen(N, Path);
      Util.Gen(N, Path);
      Classes.Gen(N, Path);
      Constants.Gen(N, Path);
      Funcs.Gen(N, Path);
      State.Gen(N, Path);
      Event.Gen(N, Path);
      Mappings.Gen(N, Path);
      Enabling_Test.Gen(N, Path);
      Por.Gen(N, Path);
      Domains.Gen(N, Path);
      Model.Gen(N, Path);
      Graph.Gen(N, Path);
      Create(F, Out_File, To_String(Net_Path & Dir_Separator & "SRC_FILES"));
      Put_Line(F, Util_Lib);
      Put_Line(F, Colors_Lib);
      Put_Line(F, Constants_Lib);
      Put_Line(F, Domains_Lib);
      Put_Line(F, Funcs_Lib);
      Put_Line(F, State_Lib);
      Put_Line(F, Mappings_Lib);
      Put_Line(F, Event_Lib);
      Put_Line(F, Enabling_Test_Lib);
      Put_Line(F, Por_Lib);
      Put_Line(F, Model_Lib);
      Put_Line(F, Graph_Lib);
      Put_Line(F, Interfaces_File);
      Close(F);
   end;

   procedure Gen_Interfaces
     (N        : in Net;
      File_Path: in Ustring) is
      Prefix : constant Ustring := Interfaces_File;
      C_File : constant Ustring := Prefix & "." & Code_Extension;
      H_File : constant Ustring := Prefix & "." & Header_Extension;
      Success: Boolean;
   begin
      Interfaces.Gen(N, To_Ustring("."));
      Rename_File(To_String(H_File), To_String(File_Path), Success);
      Delete_File(To_String(C_File), Success);
   end;



   --==========================================================================
   --  Useful functions
   --==========================================================================

   function Get_Printable_String
     (Str: in Ustring) return Ustring is
      Result: Ustring := Str;
   begin
      --===
      --  replace
      --    \ by \\
      --    " by \"
      --===
      Result := To_Ustring(Replace(To_String(Result),
                                   To_String_Mapping("\",  "\\")));
      Result := To_Ustring(Replace(To_String(Result),
                                   To_String_Mapping("""", "\""")));
      return Result;
   end;

   function Const_Name
     (Const: in String) return Ustring is
   begin
      return To_Upper(Const_Prefix & Const);
   end;

   function Lib_Init_Func
     (Lib_Name: in Ustring) return Ustring is
   begin
      return "init_" & Lib_Name;
   end;

   function Lib_Free_Func
     (Lib_Name: in Ustring) return Ustring is
   begin
      return "free_" & Lib_Name;
   end;

   procedure Init_Library
     (Name   : in     Ustring;
      Comment: in     Ustring;
      Path   : in     Ustring;
      Lib    :    out Library) is
   begin
      Libraries.Init_Library(Name     => To_String(Name),
                             Comment  => To_String(Comment),
                             Path     => To_String(Path),
                             Lib      => Lib,
                             Included => (1 => To_Ustring("includes"),
					  2 => To_Ustring("interfaces"),
					  3 => To_Ustring("heap"),
					  4 => Util_Lib,
					  5 => To_Ustring("common"),
					  6 => To_Ustring("bit_stream")));
   end;

   procedure Init_Library
     (Name    : in     Ustring;
      Comment : in     Ustring;
      Path    : in     Ustring;
      Included: in     Libraries.String_Array;
      Lib     :    out Library) is
   begin
      Libraries.Init_Library(Name     => To_String(Name),
                             Comment  => To_String(Comment),
                             Path     => To_String(Path),
                             Lib      => Lib,
                             Included => Included);
   end;

   function Get_Net_Path return Ustring is
   begin
      return Net_Path;
   end;

end Pn.Compiler;
