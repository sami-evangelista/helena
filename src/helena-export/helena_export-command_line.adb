with
  Ada.Text_Io,
  Helena;

use
  Ada.Text_Io,
  Helena;

package body Helena_Export.Command_Line is

   function Get_Option
     (Opt: in Option) return Boolean is
   begin
      return Options(Opt);
   end;

   function Get_Argument
     (Opt: in Option) return String is
   begin
      return To_String(Options_Args(Opt));
   end;

   procedure Put_Usage is
   begin
      Put_Line("usage: helena-export [option] ... [option] my_net.lna");
   end;

   procedure Put_Usage_Help is
   begin
      Put_Line("help: helena-export -" & Short_Option_Name(Help));
   end;

   procedure Put_Help is
   begin
      Put_Line("options:");
      Put_Line("   -h, --help");
      Put_Line("   -l, --to-lola=FILE-NAME");
      Put_Line("   -p, --to-prod=FILE-NAME");
      Put_Line("   -t, --to-tina=FILE-NAME");
      Put_Line("   -e, --to-helena=FILE-NAME");
      Put_Line("   -m, --to-pnml=FILE-NAME");
   end;

   procedure Parse_Command_Line is
      Element       : Parser.Command_Line_Element;
      Lna_File_Found: Boolean := False;
      Opt           : Option;
   begin
      --  read the options from the command line
      Parser.Start_Read;
      if not Parser.More_Elements then
         Put_Usage;
         Put_Usage_Help;
         raise Helena_Command_Line_Exception;
      end if;
      while Parser.More_Elements loop
         Parser.Next_Element(Element);
         if Parser.Is_Option(Element) then
            if Parser.Is_Valid_Option(Element) then
               Opt := Parser.Get_Option(Element);
               if Opt = Help then
                  Put_Usage;
                  Put_Help;
                  raise Helena_Terminate_Exception;
               elsif not (Opt in Param_Option) then
                  Options(Opt) := True;
               elsif Parser.Argument_Expected(Element) then
                  Put_Line("argument expected in """ &
			     Parser.Get_Value(Element) & """");
               else
                  Options(Opt) := True;
                  Options_Args(Opt) :=
                    To_Unbounded_String(Parser.Get_Argument(Element));
               end if;
            else
	       Put_Line('"' & Parser.Get_Value(Element) &
			  """ is not a valid option");
            end if;
         else
            if Parser.More_Elements then
               Put_Line('"' & Parser.Get_Value(Element) & """ is ignored");
            else
               Lna_File_Found := True;
               Lna_File := To_Unbounded_String(Parser.Get_Value(Element));
            end if;
         end if;
      end loop;
      if not Lna_File_Found then
         Put_Line("helena file expected");
         raise Helena_Command_Line_Exception;
      end if;
   end;

   function Get_Lna_File return Unbounded_String is
   begin
      return Lna_File;
   end;

   function Short_Option_Name
     (Opt: in Option) return String is
   begin
      case Opt is
         when Help      => return "h";
         when To_Lola   => return "l";
         when To_Prod   => return "p";
         when To_Tina   => return "t";
         when To_Helena => return "e";
         when To_Pnml   => return "m";
      end case;
   end;

   function Long_Option_Name
     (Opt: in Option) return String is
   begin
      case Opt is
         when Help      => return "help";
         when To_Lola   => return "to-lola";
         when To_Prod   => return "to-prod";
         when To_Tina   => return "to-tina";
         when To_Helena => return "to-helena";
         when To_Pnml   => return "to-pnml";
      end case;
   end;

   function With_Argument
     (Opt: in Option) return Boolean is
   begin
      return Opt in Param_Option;
   end;

   function With_Default_Argument
     (Opt: in Option) return Boolean is
   begin
      return False;
   end;

   function Default_Argument
     (Opt: in Option) return String is
   begin
      return "";
   end;

end Helena_Export.Command_Line;
