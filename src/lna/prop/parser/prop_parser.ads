

with
   Ada.Strings.Unbounded,
   Prop_Lexer,
   Prop_Parser_Tokens,
   prop,
   Utils.Strings;

use
   Ada.Strings.Unbounded,
   Prop_Lexer,
   Prop_Parser_Tokens,
   prop,
   Utils.Strings;

package Prop_Parser is

   procedure YYParse;

   procedure Initialize_Parser
     (File_Name : in Unbounded_String);

   procedure finalize_Parser;

   function get_parsed_element return Yystype;

   function Get_Error_Msg return Unbounded_String;

   syntax_exception : exception;
   
private

   file_name     : Unbounded_String;
   error_msg     : Unbounded_String;
   parser_result : Yystype;

   procedure set_error_msg
     (err : in Unbounded_String);

end;
