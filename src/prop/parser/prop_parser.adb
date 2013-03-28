



with
   ada.exceptions,
   ada.text_io,
   Prop_Lexer_Dfa,
   Prop_Parser_Goto,
   Prop_Parser_Shift_Reduce;

use
   ada.exceptions,
   ada.text_io,
   Prop_Lexer_Dfa,
   Prop_Parser_Goto,
   Prop_Parser_Shift_Reduce;

package body Prop_Parser is

   use Element_List_Pkg;
   package Text_Io renames Ada.Text_Io;

   procedure Yyerror
     (s : in string) is
   begin
      set_error_msg(to_Unbounded_String(s));
      raise Syntax_Exception;
   end;

   function Get_Error_Msg return Unbounded_String is
   begin
      return Error_Msg;
   end;

   procedure set_error_msg
     (err : in Unbounded_String) is
   begin
      error_msg := File_Name & ":" & get_Line_Number & ": " & Err;
   end;

   procedure Initialize_Parser
     (File_Name : in Unbounded_String) is
   begin
      Prop_Parser.file_name := file_name;
      Prop_Lexer.initialize_lexer(file_name);
   end;

   procedure finalize_Parser is
   begin
      Prop_Lexer.finalize_lexer;
   end;

   function get_parsed_element return Yystype is
   begin
      return parser_result;
   end;

   procedure set_pos
     (e : in yystype) is
   begin
      e.line := Prop_Lexer.get_Line_Number;
      e.col := Prop_Lexer.get_column_Number;   
   end;

   procedure set_pos
   (e : in yystype;
    f : in yystype) is
   begin
      e.line := f.line;
      e.col := f.col;
   end;

procedure YYParse is

   -- Rename User Defined Packages to Internal Names.
    package yy_goto_tables         renames
      Prop_Parser_Goto;
    package yy_shift_reduce_tables renames
      Prop_Parser_Shift_Reduce;
    package yy_tokens              renames
      Prop_Parser_Tokens;

   use yy_tokens, yy_goto_tables, yy_shift_reduce_tables;

   procedure yyerrok;
   procedure yyclearin;


   package yy is

       -- the size of the value and state stacks
       stack_size : constant Natural := 300;

       -- subtype rule         is natural;
       subtype parse_state  is natural;
       -- subtype nonterminal  is integer;

       -- encryption constants
       default           : constant := -1;
       first_shift_entry : constant :=  0;
       accept_code       : constant := -3001;
       error_code        : constant := -3000;

       -- stack data used by the parser
       tos                : natural := 0;
       value_stack        : array(0..stack_size) of yy_tokens.yystype;
       state_stack        : array(0..stack_size) of parse_state;

       -- current input symbol and action the parser is on
       action             : integer;
       rule_id            : rule;
       input_symbol       : yy_tokens.token;


       -- error recovery flag
       error_flag : natural := 0;
          -- indicates  3 - (number of valid shifts after an error occurs)

       look_ahead : boolean := true;
       index      : integer;

       -- Is Debugging option on or off
        DEBUG : constant boolean := FALSE;

    end yy;


    function goto_state
      (state : yy.parse_state;
       sym   : nonterminal) return yy.parse_state;

    function parse_action
      (state : yy.parse_state;
       t     : yy_tokens.token) return integer;

    pragma inline(goto_state, parse_action);


    function goto_state(state : yy.parse_state;
                        sym   : nonterminal) return yy.parse_state is
        index : integer;
    begin
        index := goto_offset(state);
        while  integer(goto_matrix(index).nonterm) /= sym loop
            index := index + 1;
        end loop;
        return integer(goto_matrix(index).newstate);
    end goto_state;


    function parse_action(state : yy.parse_state;
                          t     : yy_tokens.token) return integer is
        index      : integer;
        tok_pos    : integer;
        default    : constant integer := -1;
    begin
        tok_pos := yy_tokens.token'pos(t);
        index   := shift_reduce_offset(state);
        while integer(shift_reduce_matrix(index).t) /= tok_pos and then
              integer(shift_reduce_matrix(index).t) /= default
        loop
            index := index + 1;
        end loop;
        return integer(shift_reduce_matrix(index).act);
    end parse_action;

-- error recovery stuff

    procedure handle_error is
      temp_action : integer;
    begin

      if yy.error_flag = 3 then -- no shift yet, clobber input.
      if yy.debug then
          text_io.put_line("Ayacc.YYParse: Error Recovery Clobbers " &
                   yy_tokens.token'image(yy.input_symbol));
      end if;
        if yy.input_symbol = yy_tokens.end_of_input then  -- don't discard,
        if yy.debug then
            text_io.put_line("Ayacc.YYParse: Can't discard END_OF_INPUT, quiting...");
        end if;
        raise yy_tokens.syntax_error;
        end if;

            yy.look_ahead := true;   -- get next token
        return;                  -- and try again...
    end if;

    if yy.error_flag = 0 then -- brand new error
        yyerror("Syntax Error");
    end if;

    yy.error_flag := 3;

    -- find state on stack where error is a valid shift --

    if yy.debug then
        text_io.put_line("Ayacc.YYParse: Looking for state with error as valid shift");
    end if;

    loop
        if yy.debug then
          text_io.put_line("Ayacc.YYParse: Examining State " &
               yy.parse_state'image(yy.state_stack(yy.tos)));
        end if;
        temp_action := parse_action(yy.state_stack(yy.tos), error);

            if temp_action >= yy.first_shift_entry then
                if yy.tos = yy.stack_size then
                    text_io.put_line(" Stack size exceeded on state_stack");
                    raise yy_Tokens.syntax_error;
                end if;
                yy.tos := yy.tos + 1;
                yy.state_stack(yy.tos) := temp_action;
                exit;
            end if;

        Decrement_Stack_Pointer :
        begin
          yy.tos := yy.tos - 1;
        exception
          when Constraint_Error =>
            yy.tos := 0;
        end Decrement_Stack_Pointer;

        if yy.tos = 0 then
          if yy.debug then
            text_io.put_line("Ayacc.YYParse: Error recovery popped entire stack, aborting...");
          end if;
          raise yy_tokens.syntax_error;
        end if;
    end loop;

    if yy.debug then
        text_io.put_line("Ayacc.YYParse: Shifted error token in state " &
              yy.parse_state'image(yy.state_stack(yy.tos)));
    end if;

    end handle_error;

   -- print debugging information for a shift operation
   procedure shift_debug(state_id: yy.parse_state; lexeme: yy_tokens.token) is
   begin
       text_io.put_line("Ayacc.YYParse: Shift "& yy.parse_state'image(state_id)&" on input symbol "&
               yy_tokens.token'image(lexeme) );
   end;

   -- print debugging information for a reduce operation
   procedure reduce_debug(rule_id: rule; state_id: yy.parse_state) is
   begin
       text_io.put_line("Ayacc.YYParse: Reduce by rule "&rule'image(rule_id)&" goto state "&
               yy.parse_state'image(state_id));
   end;

   -- make the parser believe that 3 valid shifts have occured.
   -- used for error recovery.
   procedure yyerrok is
   begin
       yy.error_flag := 0;
   end yyerrok;

   -- called to clear input symbol that caused an error.
   procedure yyclearin is
   begin
       -- yy.input_symbol := yylex;
       yy.look_ahead := true;
   end yyclearin;


begin
    -- initialize by pushing state 0 and getting the first input symbol
    yy.state_stack(yy.tos) := 0;


    loop

        yy.index := shift_reduce_offset(yy.state_stack(yy.tos));
        if integer(shift_reduce_matrix(yy.index).t) = yy.default then
            yy.action := integer(shift_reduce_matrix(yy.index).act);
        else
            if yy.look_ahead then
                yy.look_ahead   := false;

                yy.input_symbol := yylex;
            end if;
            yy.action :=
             parse_action(yy.state_stack(yy.tos), yy.input_symbol);
        end if;


        if yy.action >= yy.first_shift_entry then  -- SHIFT

            if yy.debug then
                shift_debug(yy.action, yy.input_symbol);
            end if;

            -- Enter new state
            if yy.tos = yy.stack_size then
                text_io.put_line(" Stack size exceeded on state_stack");
                raise yy_Tokens.syntax_error;
            end if;
            yy.tos := yy.tos + 1;
            yy.state_stack(yy.tos) := yy.action;
              yy.value_stack(yy.tos) := yylval;

        if yy.error_flag > 0 then  -- indicate a valid shift
            yy.error_flag := yy.error_flag - 1;
        end if;

            -- Advance lookahead
            yy.look_ahead := true;

        elsif yy.action = yy.error_code then       -- ERROR

            handle_error;

        elsif yy.action = yy.accept_code then
            if yy.debug then
                text_io.put_line("Ayacc.YYParse: Accepting Grammar...");
            end if;
            exit;

        else -- Reduce Action

            -- Convert action into a rule
            yy.rule_id  := -1 * yy.action;

            -- Execute User Action
            -- user_action(yy.rule_id);


                case yy.rule_id is

when  1 =>
--#line  118

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);
 parser_result := 
yyval;

when  2 =>
--#line  123

yyval := 
yy.value_stack(yy.tos-1);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  3 =>
--#line  129

yyval := new element_record(Prop_Parser_Tokens.property);

yyval.property_name := 
yy.value_stack(yy.tos-2);

yyval.property_property := 
yy.value_stack(yy.tos);
set_pos(
yyval, 
yy.value_stack(yy.tos-2));

when  4 =>
--#line  134

yyval := new element_record(Prop_Parser_Tokens.property);

yyval.property_name := 
yy.value_stack(yy.tos-3);

yyval.property_property := 
yy.value_stack(yy.tos-1);
set_pos(
yyval, 
yy.value_stack(yy.tos-3));

when  5 =>
--#line  141

yyval := new element_record(state_property);

yyval.state_property_reject := 
yy.value_stack(yy.tos-2);

yyval.state_property_accept := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  6 =>
--#line  148

yyval := new element_record(deadlock);
set_pos(
yyval);

when  7 =>
--#line  151

yyval := 
yy.value_stack(yy.tos);

when  8 =>
--#line  154

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);

when  9 =>
--#line  158

yyval := 
yy.value_stack(yy.tos-1);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  10 =>
--#line  164

yyval := 
yy.value_stack(yy.tos-1);

when  11 =>
--#line  168

yyval := new element_record(Ltl_Property);

yyval.Ltl_Property_Formula := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  12 =>
--#line  174

yyval := 
yy.value_stack(yy.tos-1);

when  13 =>
--#line  176

yyval := new element_record(Ltl_Prop);

yyval.Ltl_Prop_Proposition := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  14 =>
--#line  180

yyval := new element_record(Ltl_Const);

yyval.Ltl_Constant := false;
set_pos(
yyval);

when  15 =>
--#line  184

yyval := new element_record(Ltl_Const);

yyval.Ltl_Constant := true;
set_pos(
yyval);

when  16 =>
--#line  188

yyval := new element_record(Ltl_Bin_Op);

yyval.Ltl_Bin_Op_Operator := new element_record(and_op);

yyval.Ltl_Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Ltl_Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  17 =>
--#line  194

yyval := new element_record(Ltl_Bin_Op);

yyval.Ltl_Bin_Op_Operator := new element_record(or_op);

yyval.Ltl_Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Ltl_Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  18 =>
--#line  200

yyval := new element_record(Ltl_Bin_Op);

yyval.Ltl_Bin_Op_Operator := new element_record(until_op);

yyval.Ltl_Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Ltl_Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  19 =>
--#line  206

yyval := new element_record(Ltl_Bin_Op);

yyval.Ltl_Bin_Op_Operator := new element_record(implies_op);

yyval.Ltl_Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Ltl_Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  20 =>
--#line  212

yyval := new element_record(Ltl_Un_Op);

yyval.Ltl_Un_Op_Operator := new element_record(generally_op);

yyval.Ltl_Un_Op_Operand  := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  21 =>
--#line  217

yyval := new element_record(Ltl_Un_Op);

yyval.Ltl_Un_Op_Operator := new element_record(finally_op);

yyval.Ltl_Un_Op_Operand  := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  22 =>
--#line  222

yyval := new element_record(Ltl_Un_Op);

yyval.Ltl_Un_Op_Operator := new element_record(not_op);

yyval.Ltl_Un_Op_Operand  := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  23 =>
--#line  229

yyval := new element_record(name);

yyval.name_name := Prop_Lexer.get_token_value;
set_pos(
yyval);

                    when others => null;
                end case;


            -- Pop RHS states and goto next state
            yy.tos      := yy.tos - rule_length(yy.rule_id) + 1;
            if yy.tos > yy.stack_size then
                text_io.put_line(" Stack size exceeded on state_stack");
                raise yy_Tokens.syntax_error;
            end if;
            yy.state_stack(yy.tos) := goto_state(yy.state_stack(yy.tos-1) ,
                                 get_lhs_rule(yy.rule_id));

              yy.value_stack(yy.tos) := yyval;

            if yy.debug then
                reduce_debug(yy.rule_id,
                    goto_state(yy.state_stack(yy.tos - 1),
                               get_lhs_rule(yy.rule_id)));
            end if;

        end if;


    end loop;


end yyparse;

end Prop_Parser;
