--=============================================================================
--
--  Package: Command_Line_Parser
--
--  This is a generic package to manage the options that are passed through the
--  command line.
--  o Options can have a short or a long form preceded by a short or long
--    prefix.
--  o Options can take arguments.
--    The syntax is --opt=arg (with no space between opt and arg)
--  o Options can have default arguments.
--    In this case --opt is equivalent to --opt=default_arg
--
--  Example of use of the package:
--  Here we read all the elements passed to our program through the command
--  line and for each option we call the appropriate procedure.
--  If the element is not an option we put an error message.
--  >    E: Command_Line_Element;
--  > begin
--  >    Start_Read;
--  >    while More_Elements loop
--  >       Next_Elements(E);
--  >       if Is_Option(E) then
--  >          case Get_Option(E) is
--  >             when Verbose => Handle_Verbose_Option;
--  >             ...
--  >          end case;
--  >       else
--  >          Put_Line("Error: invalid option:" & Get_Value(E));
--  >       end if;
--  >    end while;
--  >  end;
--
--=============================================================================


with
  Ada.Strings.Unbounded;

use
  Ada.Strings.Unbounded;

generic
   --==========================================================================
   --  Group: Generic parameters of the package
   --==========================================================================

   --=====
   --  Type: Option
   --  The discrete type of options.
   --=====
   type Option is (<>);

   --=====
   --  Function: Short_Option_Name
   --  Get the short form of option O.
   --
   --  Return:
   --  the short form
   --=====
   with function Short_Option_Name
     (Opt: in Option) return String;

   --=====
   --  Function: Long_Option_Name
   --  Get the long form of option O.
   --
   --  Return:
   --  the long form
   --=====
   with function Long_Option_Name
     (Opt: in Option) return String;

   --=====
   --  Function: With_Argument
   --  Check if option Opt takes an argument.
   --
   --  Return:
   --  True if Opt takes an argument, False otherwise
   --=====
   with function With_Argument
     (Opt: in Option) return Boolean;

   --=====
   --  Function: With_Default_Argument
   --  Check if option Opt has a default argument.
   --
   --  Return:
   --  True if Opt has a default argument, False otherwise
   --=====
   with function With_Default_Argument
     (Opt: in Option) return Boolean;

   --=====
   --  Function: Default_Argument
   --  Get the default argument of option Opt.
   --
   --  Return:
   --  the default argument
   --=====
   with function Default_Argument
     (Opt: in Option) return String;

   --=====
   --  Constant: Short_Option_Prefix
   --  The prefix of short form option.
   --=====
   Short_Option_Prefix: String := "-";

   --=====
   --  Constant: Long_Option_Prefix
   --  The prefix of long form option.
   --=====
   Long_Option_Prefix : String := "--";
package Command_Line_Parser is

   --==========================================================================
   --  Group: Types and exceptions
   --==========================================================================

   --=====
   --  Type: Command_Line_Element
   --  An element of the command line.
   --=====
   type Command_Line_Element is limited private;

   --=====
   --  Exception: Element_Not_An_Option_Exception
   --  Raised when an element is not an option.
   --=====
   Element_Not_An_Option_Exception: exception;

   --=====
   --  Exception: No_More_Argument_Exception
   --  Raised when no more argument can be read from the command line.
   --=====
   No_More_Argument_Exception: exception;

   --=====
   --  Exception: Option_Does_Not_Have_Argument_Exception
   --  Raised when an option does not have an argument
   --=====
   Option_Does_Not_Have_Argument_Exception: exception;

   --=====
   --  Exception: Unknown_Option_Exception
   --  Raised when an unknown option has been passed through the command line.
   --=====
   Unknown_Option_Exception: exception;



   --==========================================================================
   --  Group: Sub-Programs
   --==========================================================================

   --=====
   --  Procedure: Start_Read
   --  Start to read the command line elements.
   --=====
   procedure Start_Read;

   --=====
   --  Function: More_Elements
   --  Check if there still are elements passed.
   --
   --  Return:
   --  True if there are still elements, False otherwise
   --=====
   function More_Elements return Boolean;

   --=====
   --  Procedure: Next_Element
   --  Put in Element the next element of the command line.
   --
   --  Raise:
   --  o No_More_Argument_Exception is there are no more elements, i.e.,
   --    More_Arguments = False
   --=====
   procedure Next_Element
     (Element: out Command_Line_Element);

   --=====
   --  Function: Is_Option
   --  Check if Element is an option.
   --  This is true if Element is preceded by the short or long prefix.
   --
   --  Return:
   --- True if Element is an option, False otherwise
   --=====
   function Is_Option
     (Element: in Command_Line_Element) return Boolean;

   --=====
   --  Function:
   --  Check if Element is a valid option.
   --  An option is valid if its name is correct and if it is an option with
   --  argument and with no default argument then it has an argument.
   --
   --  Return:
   --  True if the element is a valid option, False otherwise
   --=====
   function Is_Valid_Option
     (Element: in Command_Line_Element) return Boolean;

   --=====
   --  Function: Get_Value
   --  Get the value of the element.
   --  This is the complete string of the element, e.g., --my_opt=arg.
   --
   --  Return:
   --  the value
   --=====
   function Get_Value
     (Element: in Command_Line_Element) return String;

   --=====
   --  Function: Get_Option
   --  Get the option corresponding to element Element.
   --
   --  Return:
   --  the option
   --
   --  Raise:
   --  o Element_Not_An_Option_Exception if Element is not an option
   --  o Unknown_Option_Exception if Element is not a valid option, e.g., its
   --    name is unrecognized
   --=====
   function Get_Option
     (Element: in Command_Line_Element) return Option;

   --=====
   --  Function: Get_Argument
   --  Get the argument of the option.
   --
   --  Return:
   --  the argument
   --
   --  Raise:
   --  o Element_Not_An_Option_Exception if Element is not an option
   --  o Unknown_Option_Exception if Element is not a valid option
   --  o Option_Does_Not_Have_Argument_Exception if the option does not take
   --    an argument
   --=====
   function Get_Argument
     (Element: in Command_Line_Element) return String;

   --=====
   --  Function: Argument_Expected
   --  Check if an argument was expected for Option and not given.
   --  This is for example true if Element is an option Opt with an argument
   --  and no default argument and --opt has been passed instead of
   --  --opt=arg.
   --
   --  Return:
   --  True if an argument was expected, False otherwise
   --=====
   function Argument_Expected
     (Element: in Command_Line_Element) return Boolean;


private


   type Option_Form is (Short_Form, Long_Form);

   Options          : array (Option) of Boolean := (others => False);
   Options_Arguments: array (Option) of Unbounded_String :=
     (others => Null_Unbounded_String);
   Faulty_Option    : Positive;

   type Command_Line_Element is
      record
         Value       : Unbounded_String;   --  value of the element
         Is_Opt      : Boolean;            --  true if the element is an
                                            --  option
         Is_Valid_Opt: Boolean;            --  true if the element is a valid
                                            --  option
         Opt         : Option;             --  option of the element
         Arg         : Unbounded_String;   --  argument of the option
         Arg_Expected: Boolean;            --  is an argument expected
      end record;

   Current_Element_No: Natural := 1;

end Command_Line_Parser;
