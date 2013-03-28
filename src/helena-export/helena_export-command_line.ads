--=============================================================================
--
--  Description:
--
--  This package manages the options that can be passed to helena-export
--  through the command line.
--
--=============================================================================


with
  Ada.Strings.Unbounded,
  Command_Line_Parser;

use
  Ada.Strings.Unbounded;

package Helena_Export.Command_Line is

   type Option is
     (Help,
      To_Lola,
      To_Prod,
      To_Tina,
      To_Helena,
      To_Pnml);

   subtype Non_Param_Option is Option range Option'First .. Help;

   subtype Param_Option is Option range Option'Succ(Help) .. Option'Last;


   function Get_Option
     (Opt: in Option) return Boolean;
   --  check if option Opt has been passed through the command line

   function Get_Argument
     (Opt: in Option) return String;
   --  return the argument of option Opt

   procedure Parse_Command_Line;
   --  read the arguments from command line

   function Get_Lna_File return Unbounded_String;
   --  return the name of the helena file to export


private


   function Short_Option_Name
     (Opt: in Option) return String;

   function Long_Option_Name
     (Opt: in Option) return String;

   function With_Argument
     (Opt: in Option) return Boolean;

   function With_Default_Argument
     (Opt: in Option) return Boolean;

   function Default_Argument
     (Opt: in Option) return String;

   package Parser is new Command_Line_Parser
     (Option                => Option,
      Short_Option_Name     => Short_Option_Name,
      Long_Option_Name      => Long_Option_Name,
      With_Argument         => With_Argument,
      With_Default_Argument => With_Default_Argument,
      Default_Argument      => Default_Argument);

   Options    : array(Option) of Boolean := (others => False);
   Lna_File   : Unbounded_String;
   Options_Args: array(Option) of Unbounded_String :=
     (others => Null_Unbounded_String);

end Helena_Export.Command_Line;
