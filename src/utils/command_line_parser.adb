with
  Ada.Command_Line;

use
  Ada.Command_Line;

package body Command_Line_Parser is

   procedure Handle_Option
     (F      : in Option_Form;
      Str    : in String;
      Element: in out Command_Line_Element) is
      Ok: Boolean := False;
      function Get_Opt_Str
        (Opt: in Option) return String is
      begin
         case F is
            when Long_Form  => return Long_Option_Name(Opt);
            when Short_Form => return Short_Option_Name(Opt);
         end case;
      end;
   begin
      Element.Is_Opt := True;
      Element.Is_Valid_Opt := False;
      for Opt in Option loop
         declare
            Opt_Str: constant String := Get_Opt_Str(Opt);
         begin
            if not With_Argument(Opt) then
               --  an option without argument
               if Str = Opt_Str then
                  Ok := True;
                  Element.Arg_Expected := False;
               end if;
            else
               --  an option with argument
               if (Str'Length > Opt_Str'Length and then
                   Str(Str'First .. Opt_Str'Length + Str'First) =
                   Opt_Str & '=')
               then
                  --  the option is "opt=arg"
                  Element.Arg :=
                    To_Unbounded_String(Str(1 + Str'First + Opt_Str'Length ..
                                            Str'Last));
                  Element.Arg_Expected := False;
                  Ok := True;
               elsif Str = Opt_Str then
                  --  the option is "opt" => the option must have a default
                  --  argument
                  if not With_Default_Argument(Opt) then
                     Element.Arg_Expected := True;
                     Ok := True;
                  else
                     Element.Arg := To_Unbounded_String(Default_Argument(Opt));
                     Element.Arg_Expected := False;
                     Ok := True;
                  end if;
               end if;
            end if;
            if Ok then
               Element.Is_Valid_Opt := True;
               Element.Opt := Opt;
               return;
            end if;
         end;
      end loop;
   end;

   procedure Handle_Element
     (Element: in out Command_Line_Element) is
      Val    : constant String := To_String(Element.Value);
      Lprefix: constant String := Long_Option_Prefix;
      Sprefix: constant String := Short_Option_Prefix;
      Lg     : constant Natural := Val'Length;
   begin
      if (Lg >= Lprefix'Length and then
          Val(Val'First .. Lprefix'Length + Val'First - 1) = Lprefix)
      then
         --  option is preceded by the short options prefix
         Handle_Option(Long_Form,
                       Val(Val'First + Lprefix'Length .. Val'Last),
                       Element);
      elsif (Lg >= Sprefix'Length and then
             Val(Val'First .. Sprefix'Length + Val'First - 1) = Sprefix)
      then
         --  option is preceded by the long options prefix
         Handle_Option(Short_Form,
                       Val(Val'First + Sprefix'Length .. Val'Last),
                       Element);
      else
         Element.Is_Opt := False;
      end if;
   end;

   procedure Start_Read is
   begin
      Current_Element_No := 1;
   end;

   function More_Elements return Boolean is
   begin
      return Current_Element_No <= Argument_Count;
   end;

   procedure Next_Element
     (Element: out Command_Line_Element) is
   begin
      if Current_Element_No not in 1..Argument_Count then
         raise No_More_Argument_Exception;
      end if;
      Element.Value := To_Unbounded_String(Argument(Current_Element_No));
      Handle_Element(Element);
      Current_Element_No := Current_Element_No + 1;
   end;

   function Is_Option
     (Element: in Command_Line_Element) return Boolean is
   begin
      return Element.Is_Opt;
   end;

   function Is_Valid_Option
     (Element: in Command_Line_Element) return Boolean is
   begin
      return Element.Is_Valid_Opt;
   end;

   function Get_Value
     (Element: in Command_Line_Element) return String is
   begin
      return To_String(Element.Value);
   end;

   function Get_Option
     (Element: in Command_Line_Element) return Option is
   begin
      if not Element.Is_Opt then
         raise Element_Not_An_Option_Exception;
      elsif not Element.Is_Valid_Opt then
         raise Unknown_Option_Exception;
      else
         return Element.Opt;
      end if;
   end;

   function Get_Argument
     (Element: in Command_Line_Element) return String is
   begin
      if not Element.Is_Opt then
         raise Element_Not_An_Option_Exception;
      elsif not Element.Is_Valid_Opt then
         raise Unknown_Option_Exception;
      elsif not With_Argument(Element.Opt) then
         raise Option_Does_Not_Have_Argument_Exception;
      else
         return To_String(Element.Arg);
      end if;
   end;

   function Argument_Expected
     (Element: in Command_Line_Element) return Boolean is
   begin
      return Element.Arg_Expected;
   end;

end Command_Line_Parser;
