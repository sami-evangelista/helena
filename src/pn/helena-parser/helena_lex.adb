


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

function YYLex return Token is
subtype short is integer range -32768..32767;
    yy_act : integer;
    yy_c : short;

-- returned upon end-of-file
YY_END_TOK : constant integer := 0;
YY_END_OF_BUFFER : constant := 42;
subtype yy_state_type is integer;
yy_current_state : yy_state_type;
INITIAL : constant := 0;
yy_accept : constant array(0..54) of short :=
    (   0,
        0,    0,   42,   40,   38,   39,   40,   40,   40,   19,
       31,   29,    3,    4,   17,   15,   14,   16,    9,   18,
       37,   11,    2,   22,   20,   24,   28,   36,    7,    8,
        5,   30,    6,   38,   21,    0,   33,    0,   32,   27,
        1,   10,   35,    0,   37,   12,   13,   26,   23,   25,
       36,    0,   34,    0
    ) ;

yy_ec : constant array(ASCII.NUL..Character'Last) of short :=
    (   0,
        1,    1,    1,    1,    1,    1,    1,    1,    2,    3,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    2,    4,    5,    6,    1,    7,    8,    9,   10,
       11,   12,   13,   14,   15,   16,   17,   18,   18,   18,
       18,   18,   18,   18,   18,   18,   18,   19,   20,   21,
       22,   23,   24,    1,   25,   25,   25,   25,   25,   25,
       25,   25,   25,   25,   25,   25,   25,   25,   25,   25,
       25,   25,   25,   25,   25,   25,   25,   25,   25,   25,
       26,    1,   27,    1,   28,    1,   25,   25,   25,   25,

       25,   25,   25,   25,   25,   25,   25,   25,   25,   25,
       25,   25,   25,   25,   25,   25,   25,   25,   25,   25,
       25,   25,   29,   30,   31,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,

        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1
    ) ;

yy_meta : constant array(0..31) of short :=
    (   0,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1
    ) ;

yy_base : constant array(0..57) of short :=
    (   0,
        0,    0,   66,   67,   30,   67,   43,   59,   60,   67,
       67,   31,   67,   39,   67,   67,   67,   38,   44,   24,
       41,   15,   67,   25,   67,   36,   67,   20,   67,   67,
       67,   67,   67,   40,   67,   52,   67,   53,   67,   67,
       67,   67,   67,   52,   36,   67,   67,   67,   67,   67,
       25,   49,   67,   67,   50,   45,   43
    ) ;

yy_def : constant array(0..57) of short :=
    (   0,
       54,    1,   54,   54,   54,   54,   54,   55,   56,   54,
       54,   54,   54,   54,   54,   54,   54,   54,   54,   54,
       54,   54,   54,   54,   54,   54,   54,   54,   54,   54,
       54,   54,   54,   54,   54,   55,   54,   56,   54,   54,
       54,   54,   54,   57,   54,   54,   54,   54,   54,   54,
       54,   57,   54,    0,   54,   54,   54
    ) ;

yy_nxt : constant array(0..98) of short :=
    (   0,
        4,    5,    6,    7,    8,    9,   10,   11,   12,   13,
       14,   15,   16,   17,   18,   19,   20,   21,   22,   23,
       24,   25,   26,   27,   28,   29,   30,    4,   31,   32,
       33,   34,   34,   46,   48,   43,   47,   51,   34,   34,
       44,   34,   51,   52,   51,   38,   49,   51,   34,   51,
       36,   53,   51,   45,   53,   39,   37,   50,   45,   42,
       41,   40,   39,   37,   35,   54,    3,   54,   54,   54,
       54,   54,   54,   54,   54,   54,   54,   54,   54,   54,
       54,   54,   54,   54,   54,   54,   54,   54,   54,   54,
       54,   54,   54,   54,   54,   54,   54,   54

    ) ;

yy_chk : constant array(0..98) of short :=
    (   0,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    5,   12,   22,   24,   20,   22,   28,    5,   12,
       20,   34,   51,   57,   28,   56,   24,   28,   34,   51,
       55,   52,   51,   45,   44,   38,   36,   26,   21,   19,
       18,   14,    9,    8,    7,    3,   54,   54,   54,   54,
       54,   54,   54,   54,   54,   54,   54,   54,   54,   54,
       54,   54,   54,   54,   54,   54,   54,   54,   54,   54,
       54,   54,   54,   54,   54,   54,   54,   54

    ) ;


-- copy whatever the last rule matched to the standard output

procedure ECHO is
begin
   if (text_io.is_open(user_output_file)) then
     text_io.put( user_output_file, yytext );
   else
     text_io.put( yytext );
   end if;
end ECHO;

-- enter a start condition.
-- Using procedure requires a () after the ENTER, but makes everything
-- much neater.

procedure ENTER( state : integer ) is
begin
     yy_start := 1 + 2 * state;
end ENTER;

-- action number for EOF rule of a given start state
function YY_STATE_EOF(state : integer) return integer is
begin
     return YY_END_OF_BUFFER + state + 1;
end YY_STATE_EOF;

-- return all but the first 'n' matched characters back to the input stream
procedure yyless(n : integer) is
begin
        yy_ch_buf(yy_cp) := yy_hold_char; -- undo effects of setting up yytext
        yy_cp := yy_bp + n;
        yy_c_buf_p := yy_cp;
        YY_DO_BEFORE_ACTION; -- set up yytext again
end yyless;

-- redefine this if you have something you want each time.
procedure YY_USER_ACTION is
begin
        null;
end;

-- yy_get_previous_state - get the state just before the EOB char was reached

function yy_get_previous_state return yy_state_type is
    yy_current_state : yy_state_type;
    yy_c : short;
begin
    yy_current_state := yy_start;

    for yy_cp in yytext_ptr..yy_c_buf_p - 1 loop
	yy_c := yy_ec(yy_ch_buf(yy_cp));
	if ( yy_accept(yy_current_state) /= 0 ) then
	    yy_last_accepting_state := yy_current_state;
	    yy_last_accepting_cpos := yy_cp;
	end if;
	while ( yy_chk(yy_base(yy_current_state) + yy_c) /= yy_current_state ) loop
	    yy_current_state := yy_def(yy_current_state);
	    if ( yy_current_state >= 55 ) then
		yy_c := yy_meta(yy_c);
	    end if;
	end loop;
	yy_current_state := yy_nxt(yy_base(yy_current_state) + yy_c);
    end loop;

    return yy_current_state;
end yy_get_previous_state;

procedure yyrestart( input_file : file_type ) is
begin
   open_input(text_io.name(input_file));
end yyrestart;

begin -- of YYLex
<<new_file>>
        -- this is where we enter upon encountering an end-of-file and
        -- yywrap() indicating that we should continue processing

    if ( yy_init ) then
        if ( yy_start = 0 ) then
            yy_start := 1;      -- first start state
        end if;

        -- we put in the '\n' and start reading from [1] so that an
        -- initial match-at-newline will be true.

        yy_ch_buf(0) := ASCII.LF;
        yy_n_chars := 1;

        -- we always need two end-of-buffer characters.  The first causes
        -- a transition to the end-of-buffer state.  The second causes
        -- a jam in that state.

        yy_ch_buf(yy_n_chars) := YY_END_OF_BUFFER_CHAR;
        yy_ch_buf(yy_n_chars + 1) := YY_END_OF_BUFFER_CHAR;

        yy_eof_has_been_seen := false;

        yytext_ptr := 1;
        yy_c_buf_p := yytext_ptr;
        yy_hold_char := yy_ch_buf(yy_c_buf_p);
        yy_init := false;
    end if; -- yy_init

    loop                -- loops until end-of-file is reached


        yy_cp := yy_c_buf_p;

        -- support of yytext
        yy_ch_buf(yy_cp) := yy_hold_char;

        -- yy_bp points to the position in yy_ch_buf of the start of the
        -- current run.
	yy_bp := yy_cp;
	yy_current_state := yy_start;
	loop
		yy_c := yy_ec(yy_ch_buf(yy_cp));
		if ( yy_accept(yy_current_state) /= 0 ) then
		    yy_last_accepting_state := yy_current_state;
		    yy_last_accepting_cpos := yy_cp;
		end if;
		while ( yy_chk(yy_base(yy_current_state) + yy_c) /= yy_current_state ) loop
		    yy_current_state := yy_def(yy_current_state);
		    if ( yy_current_state >= 55 ) then
			yy_c := yy_meta(yy_c);
		    end if;
		end loop;
		yy_current_state := yy_nxt(yy_base(yy_current_state) + yy_c);
	    yy_cp := yy_cp + 1;
if ( yy_current_state = 54 ) then
    exit;
end if;
	end loop;
	yy_cp := yy_last_accepting_cpos;
	yy_current_state := yy_last_accepting_state;

<<next_action>>
	    yy_act := yy_accept(yy_current_state);
            YY_DO_BEFORE_ACTION;
            YY_USER_ACTION;

        if aflex_debug then  -- output acceptance info. for (-d) debug mode
            text_io.put( Standard_Error, "--accepting rule #" );
            text_io.put( Standard_Error, INTEGER'IMAGE(yy_act) );
            text_io.put_line( Standard_Error, "(""" & yytext & """)");
        end if;


<<do_action>>   -- this label is used only to access EOF actions
            case yy_act is
		when 0 => -- must backtrack
		-- undo the effects of YY_DO_BEFORE_ACTION
		yy_ch_buf(yy_cp) := yy_hold_char;
		yy_cp := yy_last_accepting_cpos;
		yy_current_state := yy_last_accepting_state;
		goto next_action;



when 1 => 
--# line 11 "helena_lex.l"
return proceed_special_token(rarrow_Token);

when 2 => 
--# line 12 "helena_lex.l"
return proceed_special_token(semicolon_Token);

when 3 => 
--# line 13 "helena_lex.l"
return proceed_special_token(lbracket_Token);

when 4 => 
--# line 14 "helena_lex.l"
return proceed_special_token(rbracket_Token);

when 5 => 
--# line 15 "helena_lex.l"
return proceed_special_token(lbrace_token);

when 6 => 
--# line 16 "helena_lex.l"
return proceed_special_token(rbrace_token);

when 7 => 
--# line 17 "helena_lex.l"
return proceed_special_token(lhook_Token);

when 8 => 
--# line 18 "helena_lex.l"
return proceed_special_token(rhook_Token);

when 9 => 
--# line 19 "helena_lex.l"
return proceed_special_token(dot_Token);

when 10 => 
--# line 20 "helena_lex.l"
return proceed_special_token(dot_dot_Token);

when 11 => 
--# line 21 "helena_lex.l"
return proceed_special_token(colon_Token);

when 12 => 
--# line 22 "helena_lex.l"
return proceed_special_token(colon_colon_Token);

when 13 => 
--# line 23 "helena_lex.l"
return proceed_special_token(colon_equal_Token);

when 14 => 
--# line 24 "helena_lex.l"
return proceed_special_token(comma_Token);

when 15 => 
--# line 25 "helena_lex.l"
return proceed_special_token(plus_Token);

when 16 => 
--# line 26 "helena_lex.l"
return proceed_special_token(minus_Token);

when 17 => 
--# line 27 "helena_lex.l"
return proceed_special_token(times_Token);

when 18 => 
--# line 28 "helena_lex.l"
return proceed_special_token(div_Token);

when 19 => 
--# line 29 "helena_lex.l"
return proceed_special_token(mod_Token);

when 20 => 
--# line 30 "helena_lex.l"
return proceed_special_token(eq_Token);

when 21 => 
--# line 31 "helena_lex.l"
return proceed_special_token(neq_Token);

when 22 => 
--# line 32 "helena_lex.l"
return proceed_special_token(inf_Token);

when 23 => 
--# line 33 "helena_lex.l"
return proceed_special_token(inf_eq_Token);

when 24 => 
--# line 34 "helena_lex.l"
return proceed_special_token(sup_Token);

when 25 => 
--# line 35 "helena_lex.l"
return proceed_special_token(sup_eq_Token);

when 26 => 
--# line 36 "helena_lex.l"
return proceed_special_token(ltuple_Token);

when 27 => 
--# line 37 "helena_lex.l"
return proceed_special_token(rtuple_Token);

when 28 => 
--# line 38 "helena_lex.l"
return proceed_special_token(Question_Token);

when 29 => 
--# line 39 "helena_lex.l"
return proceed_special_token(Quote_Token);

when 30 => 
--# line 40 "helena_lex.l"
return proceed_special_token(Pipe_Token);

when 31 => 
--# line 41 "helena_lex.l"
return proceed_special_token(Amp_Token);

when 32 => 
--# line 42 "helena_lex.l"
return proceed_directive;

when 33 => 
--# line 43 "helena_lex.l"
return proceed_string;

when 34 => 
--# line 44 "helena_lex.l"
return proceed_new_line;

when 35 => 
--# line 45 "helena_lex.l"
return proceed_comment;

when 36 => 
--# line 46 "helena_lex.l"
return proceed_alpha;

when 37 => 
--# line 47 "helena_lex.l"
return proceed_num;

when 38 => 
--# line 48 "helena_lex.l"
return proceed_blanks;

when 39 => 
--# line 49 "helena_lex.l"
return proceed_new_line;

when 40 => 
--# line 50 "helena_lex.l"
return proceed_others;

when 41 => 
--# line 52 "helena_lex.l"
ECHO;
when YY_END_OF_BUFFER + INITIAL + 1 => 
    return End_Of_Input;
                when YY_END_OF_BUFFER =>
                    -- undo the effects of YY_DO_BEFORE_ACTION
                    yy_ch_buf(yy_cp) := yy_hold_char;

                    yytext_ptr := yy_bp;

                    case yy_get_next_buffer is
                        when EOB_ACT_END_OF_FILE =>
                            begin
                            if ( yywrap ) then
                                -- note: because we've taken care in
                                -- yy_get_next_buffer() to have set up yytext,
                                -- we can now set up yy_c_buf_p so that if some
                                -- total hoser (like aflex itself) wants
                                -- to call the scanner after we return the
                                -- End_Of_Input, it'll still work - another
                                -- End_Of_Input will get returned.

                                yy_c_buf_p := yytext_ptr;

                                yy_act := YY_STATE_EOF((yy_start - 1) / 2);

                                goto do_action;
                            else
                                --  start processing a new file
                                yy_init := true;
                                goto new_file;
                            end if;
                            end;
                        when EOB_ACT_RESTART_SCAN =>
                            yy_c_buf_p := yytext_ptr;
                            yy_hold_char := yy_ch_buf(yy_c_buf_p);
                        when EOB_ACT_LAST_MATCH =>
                            yy_c_buf_p := yy_n_chars;
                            yy_current_state := yy_get_previous_state;

                            yy_cp := yy_c_buf_p;
                            yy_bp := yytext_ptr;
                            goto next_action;
                        when others => null;
                        end case; -- case yy_get_next_buffer()
                when others =>
                    text_io.put( "action # " );
                    text_io.put( INTEGER'IMAGE(yy_act) );
                    text_io.new_line;
                    raise AFLEX_INTERNAL_ERROR;
            end case; -- case (yy_act)
        end loop; -- end of loop waiting for end of file
end YYLex;
--# line 52 "helena_lex.l"

end Helena_Lex;

