


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

function YYLex return Token is
subtype short is integer range -32768..32767;
    yy_act : integer;
    yy_c : short;

-- returned upon end-of-file
YY_END_TOK : constant integer := 0;
YY_END_OF_BUFFER : constant := 16;
subtype yy_state_type is integer;
yy_current_state : yy_state_type;
INITIAL : constant := 0;
yy_accept : constant array(0..25) of short :=
    (   0,
        0,    0,   16,   14,   12,   13,    2,    3,   14,   14,
        4,    1,   14,   14,    8,   14,   12,   11,   10,    9,
        5,    7,    8,    6,    0
    ) ;

yy_ec : constant array(ASCII.NUL..Character'Last) of short :=
    (   0,
        1,    1,    1,    1,    1,    1,    1,    1,    2,    3,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    2,    1,    1,    1,    1,    1,    1,    2,    4,
        5,    6,    1,    1,    1,    1,    7,    8,    8,    8,
        8,    8,    8,    8,    8,    8,    8,    9,   10,   11,
       12,   13,    1,    1,   14,   14,   14,   14,   14,   14,
       14,   14,   14,   14,   14,   14,   14,   14,   14,   14,
       14,   14,   14,   14,   14,   14,   14,   14,   14,   14,
       15,    1,   16,    1,    8,    1,   14,   14,   14,   14,

       14,   14,   14,   14,   14,   14,   14,   14,   14,   14,
       14,   14,   14,   14,   14,   14,   14,   14,   14,   14,
       14,   14,    1,    1,    1,    1,    1,    1,    1,    1,
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

yy_meta : constant array(0..16) of short :=
    (   0,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1
    ) ;

yy_base : constant array(0..25) of short :=
    (   0,
        0,    0,   29,   30,   26,   30,   30,   30,   20,   11,
       30,   30,   11,   10,   11,    6,   19,   30,   30,   30,
       30,   30,   12,   30,   30
    ) ;

yy_def : constant array(0..25) of short :=
    (   0,
       25,    1,   25,   25,   25,   25,   25,   25,   25,   25,
       25,   25,   25,   25,   25,   25,   25,   25,   25,   25,
       25,   25,   25,   25,    0
    ) ;

yy_nxt : constant array(0..46) of short :=
    (   0,
        4,    5,    6,    7,    8,    9,   10,    4,   11,   12,
       13,   14,    4,   15,   16,    4,   19,   20,   23,   23,
       17,   24,   22,   21,   23,   23,   18,   17,   25,    3,
       25,   25,   25,   25,   25,   25,   25,   25,   25,   25,
       25,   25,   25,   25,   25,   25
    ) ;

yy_chk : constant array(0..46) of short :=
    (   0,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,   10,   10,   15,   23,
       17,   16,   14,   13,   15,   23,    9,    5,    3,   25,
       25,   25,   25,   25,   25,   25,   25,   25,   25,   25,
       25,   25,   25,   25,   25,   25
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
	    if ( yy_current_state >= 26 ) then
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
		    if ( yy_current_state >= 26 ) then
			yy_c := yy_meta(yy_c);
		    end if;
		end loop;
		yy_current_state := yy_nxt(yy_base(yy_current_state) + yy_c);
	    yy_cp := yy_cp + 1;
if ( yy_current_state = 25 ) then
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
--# line 10 "prop_lexer.l"
return proceed_special_token(semicolon_Token);

when 2 => 
--# line 11 "prop_lexer.l"
return proceed_special_token(lbracket_Token);

when 3 => 
--# line 12 "prop_lexer.l"
return proceed_special_token(rbracket_Token);

when 4 => 
--# line 13 "prop_lexer.l"
return proceed_special_token(colon_Token);

when 5 => 
--# line 14 "prop_lexer.l"
return proceed_special_token(generally_Token);

when 6 => 
--# line 15 "prop_lexer.l"
return proceed_special_token(finally_Token);

when 7 => 
--# line 16 "prop_lexer.l"
return proceed_special_token(Implies_Token);

when 8 => 
--# line 17 "prop_lexer.l"
return proceed_string;

when 9 => 
--# line 18 "prop_lexer.l"
return proceed_start_simple_comment;

when 10 => 
--# line 19 "prop_lexer.l"
return proceed_start_comment;

when 11 => 
--# line 20 "prop_lexer.l"
return proceed_end_comment;

when 12 => 
--# line 21 "prop_lexer.l"
return proceed_blanks;

when 13 => 
--# line 22 "prop_lexer.l"
return proceed_new_line;

when 14 => 
--# line 23 "prop_lexer.l"
return proceed_others;

when 15 => 
--# line 25 "prop_lexer.l"
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
--# line 25 "prop_lexer.l"

end Prop_Lexer;

