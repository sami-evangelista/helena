alpha_char     [a-zA-Z]
alpha_num_char [a-zA-Z0-9]
num_char       [0-9]
blank          [' '\t]
id_char        [a-zA-Z0-9_]
new_line       [\n]
quote          [\"]

%%

"->" {return proceed_special_token(rarrow_Token);}
";"  {return proceed_special_token(semicolon_Token);}
"("  {return proceed_special_token(lbracket_Token);}
")"  {return proceed_special_token(rbracket_Token);}
"{"  {return proceed_special_token(lbrace_token);}
"}"  {return proceed_special_token(rbrace_token);}
"["  {return proceed_special_token(lhook_Token);}
"]"  {return proceed_special_token(rhook_Token);}
"."  {return proceed_special_token(dot_Token);}
".." {return proceed_special_token(dot_dot_Token);}
":"  {return proceed_special_token(colon_Token);}
"::" {return proceed_special_token(colon_colon_Token);}
":=" {return proceed_special_token(colon_equal_Token);}
","  {return proceed_special_token(comma_Token);}
"+"  {return proceed_special_token(plus_Token);}
"-"  {return proceed_special_token(minus_Token);}
"*"  {return proceed_special_token(times_Token);}
"/"  {return proceed_special_token(div_Token);}
"%"  {return proceed_special_token(mod_Token);}
"="  {return proceed_special_token(eq_Token);}
"!=" {return proceed_special_token(neq_Token);}
"<"  {return proceed_special_token(inf_Token);}
"<=" {return proceed_special_token(inf_eq_Token);}
">"  {return proceed_special_token(sup_Token);}
">=" {return proceed_special_token(sup_eq_Token);}
"<(" {return proceed_special_token(ltuple_Token);}
")>" {return proceed_special_token(rtuple_Token);}
"?"  {return proceed_special_token(Question_Token);}
"'"  {return proceed_special_token(Quote_Token);}
"|"  {return proceed_special_token(Pipe_Token);}
"&"  {return proceed_special_token(Amp_Token);}
"#"[^\n]*"\n" {return proceed_directive;}
"\""[^\"]*"\"" {return proceed_string;}
"//"[^\n]*"\n" {return proceed_new_line;}
"/*" {return proceed_comment;}
{alpha_char}({id_char}*) {return proceed_alpha;}
{num_char}+ {return proceed_num;}
{blank}+ {return proceed_blanks;}
{new_line} {return proceed_new_line;}
. {return proceed_others;}

%%


with
  Ada.Strings.Unbounded,
  Helena_Yacc_Tokens,
  Pn,
  Utils.Strings;

use
  Ada.Strings.Unbounded, 
  Helena_Yacc_Tokens,
  Pn,
  Utils.Strings;

package Helena_Lex is

   function Yylex return Token;

   function get_line_number return natural;

   function get_file return unbounded_string;

   function get_token_value return Unbounded_String;

   function is_valid_symbol
     (sym : in Unbounded_String) return boolean;

   procedure initialize_lexer
     (file_name : in Unbounded_String);

   procedure finalize_lexer;

   subtype sym is Unbounded_String;

   procedure define_symbol
     (s : in sym);

   procedure undefine_symbol
     (s : in sym);

   procedure raise_lexer_exception
     (err : in string);

   function Get_Error_Msg return Unbounded_String;

   lexical_exception : exception;

private


   file_name : Unbounded_String;
   Error_Msg : Unbounded_String;

end Helena_Lex;



with
   ada.exceptions,
   generic_set,
   Helena_Yacc;

use
   ada.exceptions,
   Helena_Yacc;

package body Helena_Lex is

   --===
   --
   --  symbols
   --
   --===

   --  a set of symbol
   package syms_set_pkg is new Generic_Set(sym, null_unbounded_string, "=");

   --  the set of defined symbols
   defined_symbols : syms_set_pkg.Set_type := syms_set_pkg.empty_set;

   procedure define_symbol
     (s : in sym) is
   begin
      syms_set_pkg.insert(defined_symbols, s);
   end;

   procedure undefine_symbol
     (s : in sym) is
   begin
      syms_set_pkg.delete(defined_symbols, s);
   end;

   function is_defined
     (s : in sym) return boolean is
   begin
      return syms_set_pkg.contains(defined_symbols, s);
   end;

   function Get_Error_Msg return Unbounded_String is
   begin
      return Error_Msg;
   end;



   Reserved : constant array(ASSERT_TOKEN .. WITH_TOKEN) of Unbounded_String :=
     (ASSERT_TOKEN      => To_Unbounded_String("assert"),
      AND_TOKEN         => To_Unbounded_String("and"),
      CAPACITY_TOKEN    => To_Unbounded_String("capacity"),
      CARD_TOKEN        => To_Unbounded_String("card"),
      CASE_TOKEN        => To_Unbounded_String("case"),
      CONSTANT_TOKEN    => To_Unbounded_String("constant"),
      DEFAULT_TOKEN     => To_Unbounded_String("default"),
      DESCRIPTION_TOKEN => To_Unbounded_String("description"),
      DOM_TOKEN         => To_Unbounded_String("dom"),
      ELSE_TOKEN        => To_Unbounded_String("else"),
      EMPTY_TOKEN       => To_Unbounded_String("empty"),
      ENUM_TOKEN        => To_Unbounded_String("enum"),
      EPSILON_TOKEN     => To_Unbounded_String("epsilon"),
      EXISTS_TOKEN      => To_Unbounded_String("exists"),
      FOR_TOKEN         => To_Unbounded_String("for"),
      FORALL_TOKEN      => To_Unbounded_String("forall"),
      FUNCTION_TOKEN    => To_Unbounded_String("function"),
      GUARD_TOKEN       => To_Unbounded_String("guard"),
      IF_TOKEN          => To_Unbounded_String("if"),
      IMPORT_TOKEN      => To_Unbounded_String("import"),
      IN_TOKEN          => To_Unbounded_String("in"),
      INIT_TOKEN        => To_Unbounded_String("init"),
      INHIBIT_TOKEN     => To_Unbounded_String("inhibit"),
      LET_TOKEN         => To_Unbounded_String("let"),
      LIST_TOKEN        => To_Unbounded_String("list"),
      MAX_TOKEN         => To_Unbounded_String("max"),
      MIN_TOKEN         => To_Unbounded_String("min"),
      MOD_TOKEN         => To_Unbounded_String("mod"),
      MULT_TOKEN        => To_Unbounded_String("mult"),
      NOT_TOKEN         => To_Unbounded_String("not"),
      OF_TOKEN          => To_Unbounded_String("of"),
      OR_TOKEN          => To_Unbounded_String("or"),
      OUT_TOKEN         => To_Unbounded_String("out"),
      PICK_TOKEN        => To_Unbounded_String("pick"),
      PLACE_TOKEN       => To_Unbounded_String("place"),
      PRED_TOKEN        => To_Unbounded_String("pred"),
      PRINT_TOKEN       => To_Unbounded_String("print"),
      PRIORITY_TOKEN    => To_Unbounded_String("priority"),
      PROPOSITION_TOKEN => To_Unbounded_String("proposition"),
      PRODUCT_TOKEN     => To_Unbounded_String("product"),
      RANGE_TOKEN       => To_Unbounded_String("range"),
      RETURN_TOKEN      => To_Unbounded_String("return"),
      STRUCT_TOKEN      => To_Unbounded_String("struct"),
      SAFE_TOKEN        => To_Unbounded_String("safe"),
      SET_TOKEN         => To_Unbounded_String("set"),
      SUBTYPE_TOKEN     => To_Unbounded_String("subtype"),
      SUCC_TOKEN        => To_Unbounded_String("succ"),
      SUM_TOKEN         => To_Unbounded_String("sum"),
      TRANSITION_TOKEN  => To_Unbounded_String("transition"),
      TYPE_TOKEN        => To_Unbounded_String("type"),
      VECTOR_TOKEN      => To_Unbounded_String("vector"),
      WHILE_TOKEN       => To_Unbounded_String("while"),
      WITH_TOKEN        => To_Unbounded_String("with"));

   --  type of directive
   type directive is
     (define,
      undef,
      ifdef,
      ifndef,
      els,
      endif,
      set);

   --  global variables
   Line_Number         : Natural := 1;
   token_value         : Unbounded_String := null_unbounded_string;

   --  global variables related to the preprocessor directives
   ifdef_depth : natural := 0;
   ignore_depth: natural := 0;
   directives  : constant array(directive) of Unbounded_String :=
      (define => to_Unbounded_String("define"),
       undef  => to_Unbounded_String("undef"),
       ifdef  => to_Unbounded_String("ifdef"),
       ifndef => to_Unbounded_String("ifndef"),
       els    => to_Unbounded_String("else"),
       endif  => to_Unbounded_String("endif"),
       set    => to_Unbounded_String("set"));

   function is_ignored return boolean is
   begin return ignore_depth > 0; end;

   function get_line_number return natural is
   begin return line_number; end;

   function get_file return unbounded_string is
   begin return file_name; end;

   procedure set_error_msg
     (err : in Unbounded_String) is
   begin
      error_msg :=
         File_Name & ":" & get_Line_Number & ": " &
         err;
   end;

   procedure initialize_lexer
     (file_name : in Unbounded_String) is
   begin
      Helena_Lex.file_name := file_name;
      Line_Number := 1;
      error_msg := null_string;
      token_value := null_string;
      ifdef_depth := 0;
      ignore_depth := 0;
   end;

   procedure finalize_lexer is
   begin
      if ifdef_depth > 0 then
         raise_lexer_exception("missing directive '#endif'");
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

   function proceed_directive return Token is
      function get_line return string is
         line : constant string := Yytext;
      begin
         if line(line'last) = Ascii.LF then
            return line(line'first .. line'last - 1);
         else
            return line;
         end if;
      end;
      line  : constant string := get_line;
      Sep   : constant Char_Set := (' ' => True, ASCII.HT => True,
                                    others => False);
      L     : constant Unbounded_String_Array :=
        Utils.Strings.Split(line, Sep);
   begin
      if to_string(l(l'first)) = "#define" then
         if ignore_depth = 0 then
            define_symbol(l(l'first + 1));
         end if;
      elsif to_string(l(l'first)) = "#undef" then
         if ignore_depth = 0 then
            undefine_symbol(l(l'first + 1));
         end if;
      elsif to_string(l(l'first)) = "#ifdef" then
         ifdef_depth := ifdef_depth + 1;
         if ignore_depth = 0 then
            if not is_defined(l(l'first + 1)) then
               ignore_depth := 1;
            end if;
         else
            ignore_depth := ignore_depth + 1;
         end if;
      elsif to_string(l(l'first)) = "#ifndef" then
         ifdef_depth := ifdef_depth + 1;
         if ignore_depth = 0 then
            if is_defined(l(l'first + 1)) then
               ignore_depth := 1;
            end if;
         else
            ignore_depth := ignore_depth + 1;
         end if;
      elsif to_string(l(l'first)) = "#else" then
         if ignore_depth = 1 then
            ignore_depth := 0;
         else
            ignore_depth := 1;
         end if;
      elsif to_string(l(l'first)) = "#endif" then
         if ifdef_depth = 0 then
            raise_lexer_exception("no '#if' for this '#endif'");
         end if;
         ifdef_depth := ifdef_depth - 1;
         if ignore_depth > 0 then
            ignore_depth := ignore_depth - 1;
         end if;
      elsif to_string(l(l'first)) = "#set" then
         if to_string(l(l'first + 1)) = "file" then
            helena_lex.file_name := l(l'first + 2);
         elsif to_string(l(l'first + 1)) = "line" then
            line_number := natural'value(to_string(l(l'first + 2)));
         end if;
      else
         raise Constraint_Error;
      end if;
      line_number := line_number + 1;
      return yylex;
   exception
      when Constraint_Error =>
         raise_lexer_exception("unrecognized directive");
   end;

   function proceed_special_token
     (t : in token) return token is
      err : Unbounded_String;
   begin
      if Is_ignored then
         return yylex;
      end if;
      return t;
   end;

   function proceed_alpha return token is
   begin
      if Is_ignored then
         return Yylex;
      else
         for I in Reserved'range loop
            if To_String(Reserved(I)) = Yytext then
               return I;
            end if;
         end loop;
         return Identifier_Token;
      end if;
   end;

   function proceed_num return token is
      result : token;
   begin
      if Is_ignored then
         return Yylex;
      end if;
      return number_token;
   end;

   function proceed_comment return token is
      c     : character;
      start : constant integer := line_number;
   begin
      loop
         loop
            c := input;
            if c = ASCII.NUL then
               line_number := start;
               raise_lexer_exception("unterminated comment");
            elsif c = ASCII.LF then
               line_number := line_number + 1;
            end if;
            exit when c = '*';
         end loop;
         c := input;
         if c = '/' then
            return yylex;
         else
            unput(c);
         end if;
      end loop;
   end;

   function proceed_blanks return token is
   begin
      return Yylex;
   end;

   function proceed_string return token is
   begin
      return string_token;
   end;

   function proceed_new_line return token is
   begin
      move_line;
      return Yylex;
   end;

   function proceed_others return token is
   begin
      if not is_ignored then
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

end Helena_Lex;
