alpha_char     [a-zA-Z]
alpha_num_char [a-zA-Z0-9]
num_char       [0-9]
blank          [' '\t]
id_char        [a-zA-Z0-9_]
new_line       [\n]

%%

";"  {return proceed_special_token(semicolon_Token);}
"("  {return proceed_special_token(lbracket_Token);}
")"  {return proceed_special_token(rbracket_Token);}
":"  {return proceed_special_token(colon_Token);}
"<>" {return proceed_special_token(generally_Token);}
"[]" {return proceed_special_token(finally_Token);}
"=>" {return proceed_special_token(Implies_Token);}
{alpha_char}({id_char}*) {return proceed_string;}
"//" {return proceed_start_simple_comment;}
"/*" {return proceed_start_comment;}
"*/" {return proceed_end_comment;}
{blank}+ {return proceed_blanks;}
{new_line} {return proceed_new_line;}
. {return proceed_others;}

%%


with
  Ada.Strings.Unbounded,
  Prop_Parser_Tokens,
  Prop,
  Utils.Strings;

use
  Ada.Strings.Unbounded, 
  Prop_Parser_Tokens,
  Prop,
  Utils.Strings;

package Prop_Lexer is

   function Yylex return Token;

   function get_line_number return natural;

   function get_column_number return natural;

   function get_token_value return Unbounded_String;

   procedure initialize_lexer
     (file_name : in Unbounded_String);

   procedure finalize_lexer;

   procedure raise_lexer_exception
     (err : in string);

   function Get_Error_Msg return Unbounded_String;

   lexical_exception : exception;

private


   file_name : Unbounded_String;
   Error_Msg : Unbounded_String;

end Prop_Lexer;



with
   ada.exceptions,
   generic_set,
   Prop_Parser;

use
   ada.exceptions,
   Prop_Parser;

package body Prop_Lexer is

   function Get_Error_Msg return Unbounded_String is
   begin
      return Error_Msg;
   end;



   Reserved : constant array(ACCEPT_TOKEN..UNTIL_TOKEN) of Unbounded_String :=
     (ACCEPT_TOKEN      => To_Unbounded_String("accept"),
      AND_TOKEN         => To_Unbounded_String("and"),
      DEADLOCK_TOKEN    => To_Unbounded_String("deadlock"),
      FALSE_TOKEN       => To_Unbounded_String("false"),
      LTL_TOKEN         => To_Unbounded_String("ltl"),
      NOT_TOKEN         => To_Unbounded_String("not"),
      OR_TOKEN          => To_Unbounded_String("or"),
      PROPERTY_TOKEN    => To_Unbounded_String("property"),
      REJECT_TOKEN      => To_Unbounded_String("reject"),
      STATE_TOKEN       => To_Unbounded_String("state"),
      TRUE_TOKEN        => To_Unbounded_String("true"),
      UNTIL_TOKEN       => To_Unbounded_String("until"));

   Line_Number         : Natural := 1;
   Column_Number       : Natural := 1;
   Column_Number_After : Natural := 1;
   comment_level       : integer := 0;
   in_simple_comment   : Boolean := False;
   token_value         : Unbounded_String := null_unbounded_string;

   function is_in_comment return boolean is
   begin
      return comment_level > 0 or in_simple_comment;
   end;

   function get_line_number return natural is
   begin
      return line_number;
   end;

   function get_column_number return natural is
   begin
      return column_number;
   end;

   procedure set_error_msg
     (err : in Unbounded_String) is
   begin
      error_msg :=
         File_Name & ":" & get_Line_Number & ":" & get_column_Number & ": " &
         err;
   end;

   procedure initialize_lexer
     (file_name : in Unbounded_String) is
   begin
      Prop_Lexer.file_name := file_name;
      Line_Number := 1;
      Column_Number := 1;
      Column_Number_After := 1;
      comment_level := 0;
      in_simple_comment := False;
      error_msg := null_string;
      token_value := null_string;
   end;

   procedure finalize_lexer is
   begin
      if comment_level > 0 then
         raise_lexer_exception("missing '*/'");
      end if;
   end;

   function get_token_value return Unbounded_String is
      result : Unbounded_String;
   begin
      if token_value = null_string then
         result := to_Unbounded_String(yytext);
      else
         result := token_value;
         token_value := null_string;
      end if;
      return result;
   end;

   function is_valid_symbol
     (sym : in Unbounded_String) return boolean is
      s : constant string := to_string(sym);
   begin
      if length(sym) < 1 then
         return false;
      end if;
      if not (s(1) in 'a'..'z') and not (s(1) in 'A'..'Z') then
         return false;
      end if;
      for i in 2..s'last loop
         if not (s(i) in 'a'..'z') and not (s(i) in 'A'..'Z') and
            not (s(i) in '0'..'9') and not (s(i) = '_')
         then
            return false;
         end if;
      end loop;
      return true;
   end;

   procedure move_line is
   begin
      line_number := line_number + 1;
   end;

   procedure move_column is
   begin
      column_number := column_number_after;
      column_number_After := column_number + Yytext'Last - Yytext'First + 1;
   end;

   function proceed_special_token
     (t : in token) return token is
      err : Unbounded_String;
   begin
      if Is_In_Comment then
         move_column;
         return yylex;
      else
         return t;
      end if;
   end;

   function proceed_string return token is
   begin
      if Is_In_Comment then
         move_column;
         return Yylex;
      else
         move_column;
         for I in Reserved'range loop
            if To_String(Reserved(I)) = Yytext then
               return I;
            end if;
         end loop;
         return Identifier_Token;
      end if;
   end;

   function proceed_start_simple_comment return token is
   begin
      if not Is_In_Comment then
         In_simple_Comment := True;
      end if;
      move_column;
      return Yylex;
   end;

   function proceed_start_comment return token is
   begin
      if not In_simple_Comment then
         Comment_level := comment_level + 1;
      end if;
      move_column;
      return Yylex;
   end;

   function proceed_end_comment return token is
   begin
      if not In_simple_Comment then
         if comment_level = 0 then
            raise_lexer_exception("no '/*' for this '*/'");
         end if;
         Comment_level := comment_level - 1;
      end if;
      move_column;
      return Yylex;
   end;

   function proceed_blanks return token is
   begin
      move_column;
      return Yylex;
   end;

   function proceed_new_line return token is
   begin
      In_simple_Comment := False;
      move_line;
      Column_Number := 1;
      Column_Number_After := 1;
      return Yylex;
   end;

   function proceed_others return token is
   begin
      if not is_in_comment then
         raise_lexer_exception("unrecognized string " & yytext);
      end if;
      return yylex;
   end;

   procedure raise_lexer_exception
     (err : in string) is
   begin
      set_error_msg(To_Unbounded_String(Err));
      raise lexical_exception;
   end;

##

end Prop_Lexer;
