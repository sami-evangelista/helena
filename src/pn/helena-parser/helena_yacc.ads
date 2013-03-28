

with
   Ada.Strings.Unbounded,
   helena_lex,
   helena_yacc_Tokens,
   Pn,
   Utils.Strings;

use
   Ada.Strings.Unbounded,
   helena_lex,
   helena_yacc_Tokens,
   Pn,
   Utils.Strings;

package Helena_Yacc is

   procedure YYParse;

   procedure Initialize_Parser
     (File_Name : in Unbounded_String);

   procedure finalize_Parser;

   function get_parsed_element return Yystype;

   function Get_Error_Msg return Unbounded_String;

   syntax_exception : exception;
   
private

   error_msg     : Unbounded_String;
   parser_result : Yystype;

   procedure set_error_msg
     (err : in Unbounded_String);

end Helena_Yacc;
