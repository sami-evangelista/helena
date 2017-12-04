--=============================================================================
--
--  Package: Helena.Command_Line
--
--  This package manages the options that can be passed to Helena through the
--  command line.
--
--=============================================================================


with
  Ada.Strings.Unbounded,
  Command_Line_Parser,
  Utils.Strings;

use
  Ada.Strings.Unbounded,
  Utils.Strings;

package Helena.Command_Line is

   type Option is
     (--  parametrized options with predefined possible values
      Run_Time_Checks,

      --  parametrized options without predefined possible values
      Define,
      Parameter,
      Proposition,
      Capacity);

   subtype Static_Option is Option
     range Option'First .. Run_Time_Checks;

   subtype Dynamic_Option is Option
     range Option'Succ(Static_Option'Last) .. Option'Last;

   type Options_Set is array(Option) of Boolean;

   Short_Prefix: constant String := "-";
   Long_Prefix : constant String := "--";

   procedure Parse_Command_Line;

   procedure Check_Command_Line;

   function Get_Option
     (O: in Option) return Boolean;

   function Short_Name
     (O: in Option) return String;

   function Long_Name
     (O: in Option) return String;

   function Is_With_Argument
     (O: in Option) return Boolean;

   function Has_Default_Argument
     (O: in Option) return Boolean;

   function Default_Argument
     (O: in Option) return String;

   function Get_Argument
     (O: in Option) return Unbounded_String;

   function Get_Lna_File return Unbounded_String;

   function Get_Output_Dir return Unbounded_String;

   function Get_Propositions return Ustring_List;

   package Parser is new
     Command_Line_Parser
     (Option                => Option,
      Short_Option_Name     => Short_Name,
      Long_Option_Name      => Long_Name,
      With_Argument         => Is_With_Argument,
      With_Default_Argument => Has_Default_Argument,
      Default_Argument      => Default_Argument);


private


   type Param_Options_Str is array(Option) of Unbounded_String;
   Nl          : constant String := (1 => Ascii.Lf);
   Tab         : constant String := "   ";
   Null_String : constant String := "";
   Options     : Options_Set := (others => False);
   Options_Args: Param_Options_Str := (others => Null_Unbounded_String);
   Lna_File    : Unbounded_String;
   Src_Dir     : Unbounded_String;
   Propositions: Ustring_List := String_List_Pkg.Empty_Array;

end Helena.Command_Line;
