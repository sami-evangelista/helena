with
  Ada.Characters.Handling,
  Ada.Strings.Unbounded.Text_IO,
  Ada.Directories,
  Ada.Text_Io,
  Helena_Lex,
  Pn,
  Pn.Compiler.Config,
  Pn.Nodes.Places,
  Gnat.Os_Lib;

use
  Ada.Characters.Handling,
  Ada.Strings.Unbounded.Text_IO,
  Ada.Directories,
  Ada.Text_Io,
  Helena_Lex,
  Pn,
  Pn.Compiler.Config,
  Pn.Nodes.Places,
  Gnat.Os_Lib;

package body Helena.Command_Line is

   function Get_Lna_File return Unbounded_String is
   begin
      return To_Unbounded_String(Full_Name(To_String(Lna_File)));
   end;

   function Get_Output_Dir return Unbounded_String is
   begin
      return To_Unbounded_String(Full_Name(To_String(Src_Dir)));
   end;

   function Get_Propositions return Ustring_List is
   begin
      return Propositions;
   end;

   function Short_Name
     (O: in Option) return String is
   begin
      case O is
	 when Run_Time_Checks => return "r";
	 when Capacity        => return "a";
         when Define          => return "d";
         when Proposition     => return "p";
         when Parameter       => return "m";
      end case;
   end;

   function Long_Name
     (O: in Option) return String is
   begin
      case O is
	 when Run_Time_Checks => return "run-time-checks";
         when Capacity        => return "capacity";
	 when Define          => return "define";
	 when Proposition     => return "proposition";
         when Parameter       => return "parameter";
      end case;
   end;

   function Get_Option
     (O: in Option) return Boolean is
   begin
      return Options(O);
   end;

   function Get_Argument
     (O: in Option) return Unbounded_String is
   begin
      return Options_Args(O);
   end;

   function Is_With_Argument
     (O: in Option) return Boolean is
   begin
      return True;
   end;

   function Has_Default_Argument
     (O: in Option) return Boolean is
   begin
      return False;
   end;

   function Default_Argument
     (O: in Option) return String is
   begin
      return Null_String;
   end;

   procedure Put_Usage is
   begin
      Put_Line
	("usage: helena-generate [option] ... [option] my-net.lna out-dir");
   end;



   --==========================================================================
   --  options handlers
   --==========================================================================

   procedure Incorrect_Value
     (O: in Option) is
   begin
      Put_Line(Get_Argument(O) &
		 ": incorrect argument for option " & Long_Name(O));
   end;

   procedure Handle_Option
     (Opt: in     Option;
      Arg: in     String;
      Ok :    out Boolean) is
   begin
      case Opt is
         when Run_Time_Checks =>
	    Ok := True;
	    if Arg = "0" then
	       Set_Run_Time_Checks(False);
	    elsif Arg = "1" then
	       Set_Run_Time_Checks(True);
	    else
	       Ok := False;
	    end if;
	 when Define =>
	    Ok := True;
	    if Arg = Null_String then
	       Put_Line("symbol name expected in symbol definition");
	       Ok := False;
	    elsif not Is_Valid_Symbol(To_Unbounded_String(Arg)) then
	       Put_Line(Arg & " is not a valid symbol name");
	       Ok := False;
	    else
	       Define_Symbol(To_Unbounded_String(Arg));
	    end if;
         when Proposition =>
	    String_List_Pkg.Append(Propositions, To_Ustring(Arg));
         when Capacity =>
	    begin
	       Ok := True;
	       Set_Capacity(Mult_Type'Value(Arg));
	    exception
	       when others => Ok := False;
	    end;
         when Parameter =>
	    declare
	       Idx  : Natural;
	       Param: Ustring;
	       Value: Num_Type;
	    begin
	       Idx := Index(To_Ustring(Arg), "=");
	       Ok := Idx > 0;
	       if Ok then
		  Param := To_Ustring(Arg(Arg'First .. Idx - 1));
		  Value := Num_Type'Value(Arg(Idx + 1 .. Arg'Last));
		  Set_Parameter(Param, Value);
	       end if;
	    exception
	       when others => Ok := False;
	    end;
      end case;
   end;



   --==========================================================================
   --  read arguments from the command line
   --==========================================================================

   procedure Parse_Command_Line is
      Element       : Parser.Command_Line_Element;
      Lna_File_Found: Boolean := False;
      Src_Dir_Found : Boolean := False;
      Opt           : Option;
      Ok            : Boolean;
   begin
      Parser.Start_Read;
      if not Parser.More_Elements then
         Put_Usage;
         raise Helena_Command_Line_Exception;
      end if;
      while Parser.More_Elements loop
         Parser.Next_Element(Element);
         if Parser.Is_Option(Element) then
            if Parser.Is_Valid_Option(Element) then
               Opt := Parser.Get_Option(Element);
               if Parser.Argument_Expected(Element) then
                  Put_Line("argument expected in """ &
			     Parser.Get_Value(Element) & """");
               else
                  Options_Args(Opt) :=
                    To_Unbounded_String(Parser.Get_Argument(Element));
                  Handle_Option(Opt, To_String(Options_Args(Opt)), Ok);
                  Options(Opt) := Ok;
               end if;
            else
               null;
            end if;
         else
	    Lna_File_Found := True;
	    Lna_File := To_Unbounded_String(Parser.Get_Value(Element));
	    if Parser.More_Elements then
	       Parser.Next_Element(Element);
	       Src_Dir_Found := True;
	       Src_Dir := To_Unbounded_String(Parser.Get_Value(Element));
	    end if;
         end if;
      end loop;
      if not Lna_File_Found then
         Put_Line("helena file expected");
         raise Helena_Command_Line_Exception;
      elsif not Src_Dir_Found then
         Put_Line("output directory expected");
         raise Helena_Command_Line_Exception;
      end if;
   end;

   procedure Check_Command_Line is
      Element: Parser.Command_Line_Element;
      Opt    : Option;
   begin
      Parser.Start_Read;
      while Parser.More_Elements loop
         Parser.Next_Element(Element);
         if
           Parser.Is_Option(Element)       and then
           Parser.Is_Valid_Option(Element) and then
           not Parser.Argument_Expected(Element)
         then
            Opt := Parser.Get_Option(Element);
            Options(Opt) := True;
	    Options_Args(Opt) :=
	      To_Unbounded_String(Parser.Get_Argument(Element));
	 end if;
      end loop;
   end;

end Helena.Command_Line;
