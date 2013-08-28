



with
   ada.exceptions,
   ada.text_io,
   Helena_Lex_Dfa,
   Helena_Yacc_Goto,
   Helena_Yacc_Shift_Reduce;

use
   ada.exceptions,
   ada.text_io,
   Helena_Lex_Dfa,
   Helena_Yacc_Goto,
   Helena_Yacc_Shift_Reduce;

package body Helena_Yacc is

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
      error_msg := helena_lex.get_file & ":" & get_Line_Number & ": " & Err;
   end;

   procedure Initialize_Parser
     (File_Name : in Unbounded_String) is
   begin
      Helena_Lex.initialize_lexer(file_name);
   end;

   procedure finalize_Parser is
   begin
      Helena_Lex.finalize_lexer;
   end;

   function get_parsed_element return Yystype is
   begin
      return parser_result;
   end;

   procedure set_pos
     (e : in yystype) is
   begin
      e.line := helena_lex.get_Line_Number;
      e.file := helena_lex.get_file;
   end;

   procedure set_pos
   (e : in yystype;
    f : in yystype) is
   begin
      e.line := f.line;
      e.file := f.file;
   end;

procedure YYParse is

   -- Rename User Defined Packages to Internal Names.
    package yy_goto_tables         renames
      Helena_Yacc_Goto;
    package yy_shift_reduce_tables renames
      Helena_Yacc_Shift_Reduce;
    package yy_tokens              renames
      Helena_Yacc_Tokens;

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
--#line  483

yyval := new Element_Record(Net);

yyval.Net_name := 
yy.value_stack(yy.tos-4);

yyval.net_defs := 
yy.value_stack(yy.tos-1);

yyval.net_params := 
yy.value_stack(yy.tos-3);
set_pos(
yyval, 
yy.value_stack(yy.tos-4));
parser_result := 
yyval;

when  2 =>
--#line  492

yyval := 
yy.value_stack(yy.tos-1);
append(
yyval.List_Elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  3 =>
--#line  496

yyval := new element_record(list);

yyval.List_Elements := empty_element_list;
set_pos(
yyval);

when  4 =>
--#line  502

yyval := 
yy.value_stack(yy.tos);

when  5 =>
--#line  504

yyval := 
yy.value_stack(yy.tos);

when  6 =>
--#line  506

yyval := 
yy.value_stack(yy.tos);

when  7 =>
--#line  508

yyval := 
yy.value_stack(yy.tos);

when  8 =>
--#line  510

yyval := 
yy.value_stack(yy.tos);

when  9 =>
--#line  512

yyval := 
yy.value_stack(yy.tos);

when  10 =>
--#line  522

yyval := new element_record(list);

yyval.List_Elements := empty_element_list;
set_pos(
yyval);

when  11 =>
--#line  527

yyval := 
yy.value_stack(yy.tos-1);

when  12 =>
--#line  531

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  13 =>
--#line  537

yyval := 
yy.value_stack(yy.tos-2);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  14 =>
--#line  543

yyval := new element_record(Net_Param);

yyval.Net_Param_Name := 
yy.value_stack(yy.tos-2);

yyval.Net_Param_Default := 
yy.value_stack(yy.tos);
set_pos(
yyval, 
yy.value_stack(yy.tos-2));

when  15 =>
--#line  556

yyval := 
yy.value_stack(yy.tos);

when  16 =>
--#line  567

yyval := 
yy.value_stack(yy.tos);

when  17 =>
--#line  569

yyval := 
yy.value_stack(yy.tos);

when  18 =>
--#line  573

yyval := new element_record(color);

yyval.cls_name := 
yy.value_stack(yy.tos-3);

yyval.cls_def := 
yy.value_stack(yy.tos-1);
set_pos(
yyval, 
yy.value_stack(yy.tos-3));


when  19 =>
--#line  581

yyval := 
yy.value_stack(yy.tos);

when  20 =>
--#line  583

yyval := 
yy.value_stack(yy.tos);

when  21 =>
--#line  585

yyval := 
yy.value_stack(yy.tos);

when  22 =>
--#line  587

yyval := 
yy.value_stack(yy.tos);

when  23 =>
--#line  589

yyval := 
yy.value_stack(yy.tos);

when  24 =>
--#line  591

yyval := 
yy.value_stack(yy.tos);

when  25 =>
--#line  593

yyval := 
yy.value_stack(yy.tos);

when  26 =>
--#line  597

yyval := new element_record(range_color);

yyval.range_color_range := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  27 =>
--#line  603

yyval := new element_record(mod_color);

yyval.mod_val := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  28 =>
--#line  609

yyval := new element_record(Enum_Color);

yyval.enum_values := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  29 =>
--#line  615

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  30 =>
--#line  621

yyval := 
yy.value_stack(yy.tos-2);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  31 =>
--#line  627

yyval := new element_record(vector_color);

yyval.Vector_Indexes := 
yy.value_stack(yy.tos-3);

yyval.vector_elements := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  32 =>
--#line  634

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  33 =>
--#line  640

yyval := 
yy.value_stack(yy.tos-2);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  34 =>
--#line  646

yyval := new element_record(struct_color);

yyval.struct_components := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  35 =>
--#line  652

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  36 =>
--#line  658

yyval := 
yy.value_stack(yy.tos-1);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  37 =>
--#line  664

yyval := new element_record(Helena_Yacc_tokens.component);

yyval.component_name  := 
yy.value_stack(yy.tos-1);

yyval.component_color := 
yy.value_stack(yy.tos-2);
set_pos(
yyval, 
yy.value_stack(yy.tos-1));

when  38 =>
--#line  672

yyval := new element_record(list_color);

yyval.List_Color_Index:= 
yy.value_stack(yy.tos-6);

yyval.List_Color_Elements := 
yy.value_stack(yy.tos-3);

yyval.List_Color_Capacity := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  39 =>
--#line  680

yyval := new element_record(set_color);

yyval.Set_Color_Elements := 
yy.value_stack(yy.tos-3);

yyval.Set_Color_Capacity := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  40 =>
--#line  688

yyval := new element_record(Helena_Yacc_tokens.sub_color);

yyval.Sub_Cls_Name   := 
yy.value_stack(yy.tos-4);

yyval.Sub_Cls_Parent := 
yy.value_stack(yy.tos-2);

yyval.Sub_Cls_Constraint := 
yy.value_stack(yy.tos-1);
set_pos(
yyval, 
yy.value_stack(yy.tos-4));

when  41 =>
--#line  696

yyval := 
yy.value_stack(yy.tos);

when  42 =>
--#line  697

yyval := null;

when  43 =>
--#line  709

yyval := 
yy.value_stack(yy.tos);

when  44 =>
--#line  711

yyval := 
yy.value_stack(yy.tos);

when  45 =>
--#line  716

yyval := new element_record(func_prot);

yyval.func_prot_name := 
yy.value_stack(yy.tos-6);

yyval.func_prot_params := 
yy.value_stack(yy.tos-4);

yyval.func_prot_ret := 
yy.value_stack(yy.tos-1);
set_pos(
yyval, 
yy.value_stack(yy.tos-6));

when  46 =>
--#line  726

yyval := new element_record(func);

yyval.func_name := 
yy.value_stack(yy.tos-6);

yyval.func_params := 
yy.value_stack(yy.tos-4);

yyval.func_return := 
yy.value_stack(yy.tos-1);

yyval.func_stat := 
yy.value_stack(yy.tos);

yyval.func_imported := false;
set_pos(
yyval, 
yy.value_stack(yy.tos-6));


when  47 =>
--#line  737

yyval := new element_record(func);

yyval.func_name := 
yy.value_stack(yy.tos-6);

yyval.func_params := 
yy.value_stack(yy.tos-4);

yyval.func_return := 
yy.value_stack(yy.tos-1);

yyval.func_stat := null;

yyval.func_imported := true;
set_pos(
yyval, 
yy.value_stack(yy.tos-6));

when  48 =>
--#line  746

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);


when  49 =>
--#line  751

yyval := 
yy.value_stack(yy.tos);

when  50 =>
--#line  755

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  51 =>
--#line  761

yyval := 
yy.value_stack(yy.tos-2);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  52 =>
--#line  767

yyval := new element_record(param);

yyval.param_name := 
yy.value_stack(yy.tos);

yyval.param_color := 
yy.value_stack(yy.tos-1);
set_pos(
yyval, 
yy.value_stack(yy.tos));

when  53 =>
--#line  774

yyval := 
yy.value_stack(yy.tos);

when  54 =>
--#line  778

yyval := 
yy.value_stack(yy.tos);

when  55 =>
--#line  789

yyval := 
yy.value_stack(yy.tos);

when  56 =>
--#line  790

yyval := 
yy.value_stack(yy.tos);

when  57 =>
--#line  791

yyval := 
yy.value_stack(yy.tos);

when  58 =>
--#line  792

yyval := 
yy.value_stack(yy.tos);

when  59 =>
--#line  793

yyval := 
yy.value_stack(yy.tos);

when  60 =>
--#line  794

yyval := 
yy.value_stack(yy.tos);

when  61 =>
--#line  795

yyval := 
yy.value_stack(yy.tos);

when  62 =>
--#line  796

yyval := 
yy.value_stack(yy.tos);

when  63 =>
--#line  797

yyval := 
yy.value_stack(yy.tos);

when  64 =>
--#line  798

yyval := 
yy.value_stack(yy.tos);

when  65 =>
--#line  799

yyval := 
yy.value_stack(yy.tos);

when  66 =>
--#line  800

yyval := 
yy.value_stack(yy.tos);

when  67 =>
--#line  801

yyval := 
yy.value_stack(yy.tos);

when  68 =>
--#line  802

yyval := 
yy.value_stack(yy.tos);

when  69 =>
--#line  803

yyval := 
yy.value_stack(yy.tos);

when  70 =>
--#line  804

yyval := 
yy.value_stack(yy.tos);

when  71 =>
--#line  805

yyval := 
yy.value_stack(yy.tos);

when  72 =>
--#line  806

yyval := 
yy.value_stack(yy.tos);

when  73 =>
--#line  807

yyval := 
yy.value_stack(yy.tos);

when  74 =>
--#line  811

yyval := 
yy.value_stack(yy.tos-1);

when  75 =>
--#line  815

yyval := new element_record(Num_Const);

yyval.num_val := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  76 =>
--#line  820

yyval := 
yy.value_stack(yy.tos);

when  77 =>
--#line  821

yyval := 
yy.value_stack(yy.tos);

when  78 =>
--#line  822

yyval := 
yy.value_stack(yy.tos);

when  79 =>
--#line  826

yyval := new element_record(Vector_Access);

yyval.Vector_Access_Vector := 
yy.value_stack(yy.tos-3);

yyval.Vector_Access_Indexes := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  80 =>
--#line  833

yyval := new element_record(Struct_Access);

yyval.Struct_Access_Struct := 
yy.value_stack(yy.tos-2);

yyval.Struct_Access_component := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  81 =>
--#line  840

yyval := new element_record(Vector_Access);

yyval.Vector_Access_Vector := 
yy.value_stack(yy.tos-3);

yyval.Vector_Access_Indexes := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  82 =>
--#line  847

yyval := new element_record(Struct_Access);

yyval.Struct_Access_Struct := 
yy.value_stack(yy.tos-2);

yyval.Struct_Access_component := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  83 =>
--#line  854

yyval := new element_record(func_call);

yyval.func_call_func := 
yy.value_stack(yy.tos-3);

yyval.func_call_params := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  84 =>
--#line  860

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);


when  85 =>
--#line  865

yyval := 
yy.value_stack(yy.tos);

when  86 =>
--#line  869

yyval := 
yy.value_stack(yy.tos-2);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  87 =>
--#line  874

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  88 =>
--#line  881

yyval := 
yy.value_stack(yy.tos-2);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  89 =>
--#line  886

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  90 =>
--#line  892

yyval := 
yy.value_stack(yy.tos);

when  91 =>
--#line  893

 
yyval := new element_record(Underscore);
 set_pos(
yyval);

when  92 =>
--#line  899

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(plus_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  93 =>
--#line  906

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(minus_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  94 =>
--#line  913

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(mult_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  95 =>
--#line  920

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(div_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  96 =>
--#line  927

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(mod_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  97 =>
--#line  934

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(and_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  98 =>
--#line  941

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(or_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  99 =>
--#line  948

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(sup_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  100 =>
--#line  955

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(sup_eq_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  101 =>
--#line  962

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(inf_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  102 =>
--#line  969

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(inf_eq_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  103 =>
--#line  976

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(eq_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  104 =>
--#line  983

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(neq_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  105 =>
--#line  990

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(amp_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  106 =>
--#line  997

yyval := new element_record(bin_op);

yyval.Bin_Op_Left_Operand := 
yy.value_stack(yy.tos-2);

yyval.Bin_Op_Operator := new element_record(in_op);

yyval.Bin_Op_Right_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  107 =>
--#line  1005

yyval := new element_record(un_op);

yyval.Un_Op_Operator := new element_record(minus_op);

yyval.un_Op_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  108 =>
--#line  1011

yyval := new element_record(un_op);

yyval.Un_Op_Operator := new element_record(plus_op);

yyval.un_Op_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  109 =>
--#line  1017

yyval := new element_record(un_op);

yyval.Un_Op_Operator := new element_record(succ_op);

yyval.un_Op_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  110 =>
--#line  1023

yyval := new element_record(un_op);

yyval.Un_Op_Operator := new element_record(pred_op);

yyval.un_Op_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  111 =>
--#line  1029

yyval := new element_record(un_op);

yyval.Un_Op_Operator := new element_record(not_op);

yyval.un_Op_Operand := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  112 =>
--#line  1036

yyval := new element_record(Vector_Aggregate);

yyval.Vector_Aggregate_Elements := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  113 =>
--#line  1043

yyval := new element_record(vector_assign);

yyval.vector_assign_vector := 
yy.value_stack(yy.tos-8);

yyval.vector_assign_index := 
yy.value_stack(yy.tos-4);

yyval.vector_assign_expr := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  114 =>
--#line  1051

yyval := new element_record(Struct_Aggregate);

yyval.struct_Aggregate_Elements := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  115 =>
--#line  1058

yyval := new element_record(Struct_assign);

yyval.struct_assign_struct := 
yy.value_stack(yy.tos-6);

yyval.struct_assign_component := 
yy.value_stack(yy.tos-3);

yyval.struct_assign_expr := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  116 =>
--#line  1066

yyval := new element_record(if_then_else);

yyval.if_then_else_cond := 
yy.value_stack(yy.tos-4);

yyval.if_then_else_true := 
yy.value_stack(yy.tos-2);

yyval.if_then_else_false := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  117 =>
--#line  1074

yyval := new element_record(Tuple_Access);

yyval.Tuple_Access_Tuple := 
yy.value_stack(yy.tos-2);

yyval.Tuple_Access_component := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  118 =>
--#line  1081

yyval := new element_record(attribute);

yyval.attribute_element := 
yy.value_stack(yy.tos-2);

yyval.attribute_attribute := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  119 =>
--#line  1087

yyval := new element_record(attribute);

yyval.attribute_element := 
yy.value_stack(yy.tos-2);

yyval.attribute_attribute := new element_record(name);

yyval.attribute_attribute.name_name := to_unbounded_string("card");
set_pos(
yyval.attribute_attribute);
set_pos(
yyval);


when  120 =>
--#line  1095

yyval := new element_record(attribute);

yyval.attribute_element := 
yy.value_stack(yy.tos-2);

yyval.attribute_attribute := new element_record(name);

yyval.attribute_attribute.name_name := to_unbounded_string("mult");
set_pos(
yyval.attribute_attribute);
set_pos(
yyval);


when  121 =>
--#line  1103

yyval := new element_record(attribute);

yyval.attribute_element := 
yy.value_stack(yy.tos-2);

yyval.attribute_attribute := new element_record(name);

yyval.attribute_attribute.name_name := to_unbounded_string("empty");
set_pos(
yyval.attribute_attribute);
set_pos(
yyval);

when  122 =>
--#line  1113

yyval := new element_record(iterator);

yyval.iterator_iterator_type := 
yy.value_stack(yy.tos-5);

yyval.iterator_variables := 
yy.value_stack(yy.tos-3);

yyval.iterator_condition := 
yy.value_stack(yy.tos-2);

yyval.iterator_expression := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);


when  123 =>
--#line  1122

yyval := new element_record(iterator);

yyval.iterator_iterator_type := 
yy.value_stack(yy.tos-4);

yyval.iterator_variables := 
yy.value_stack(yy.tos-2);

yyval.iterator_condition := 
yy.value_stack(yy.tos-1);

yyval.iterator_expression := null;
set_pos(
yyval);

when  124 =>
--#line  1131

yyval := 
yy.value_stack(yy.tos);

when  125 =>
--#line  1132

yyval := null;

when  126 =>
--#line  1136

yyval := 
yy.value_stack(yy.tos);

when  127 =>
--#line  1140

yyval := new element_record(forall_iterator);
set_pos(
yyval);


when  128 =>
--#line  1144

yyval := new element_record(max_iterator);
set_pos(
yyval);


when  129 =>
--#line  1148

yyval := new element_record(min_iterator);
set_pos(
yyval);


when  130 =>
--#line  1152

yyval := new element_record(sum_iterator);
set_pos(
yyval);


when  131 =>
--#line  1156

yyval := new element_record(product_iterator);
set_pos(
yyval);

when  132 =>
--#line  1161

yyval := new element_record(Card_iterator);
set_pos(
yyval);


when  133 =>
--#line  1165

yyval := new element_record(Mult_iterator);
set_pos(
yyval);


when  134 =>
--#line  1169

yyval := new element_record(Exists_iterator);
set_pos(
yyval);

when  135 =>
--#line  1174

yyval := new element_record(Container_Aggregate);

yyval.Container_Aggregate_Elements := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  136 =>
--#line  1180

yyval := new element_record(empty);
set_pos(
yyval);

when  137 =>
--#line  1185

yyval := new element_record(List_Slice);

yyval.List_Slice_List  := 
yy.value_stack(yy.tos-5);

yyval.List_Slice_First := 
yy.value_stack(yy.tos-3);

yyval.List_Slice_Last  := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  138 =>
--#line  1200

yyval := 
yy.value_stack(yy.tos);

when  139 =>
--#line  1201

yyval := 
yy.value_stack(yy.tos);

when  140 =>
--#line  1202

yyval := 
yy.value_stack(yy.tos);

when  141 =>
--#line  1203

yyval := 
yy.value_stack(yy.tos);

when  142 =>
--#line  1204

yyval := 
yy.value_stack(yy.tos);

when  143 =>
--#line  1205

yyval := 
yy.value_stack(yy.tos);

when  144 =>
--#line  1206

yyval := 
yy.value_stack(yy.tos);

when  145 =>
--#line  1207

yyval := 
yy.value_stack(yy.tos);

when  146 =>
--#line  1211

yyval := new element_record(assign);

yyval.assign_var := 
yy.value_stack(yy.tos-3);

yyval.assign_val := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  147 =>
--#line  1218

yyval := new element_record(if_then_else);

yyval.If_Then_Else_Cond := 
yy.value_stack(yy.tos-4);

yyval.If_Then_Else_True := 
yy.value_stack(yy.tos-2);

yyval.If_Then_Else_False := 
yy.value_stack(yy.tos);
set_pos(
yyval);


when  148 =>
--#line  1225

yyval := new element_record(if_then_else);

yyval.If_Then_Else_Cond := 
yy.value_stack(yy.tos-2);

yyval.If_Then_Else_True := 
yy.value_stack(yy.tos);

yyval.If_Then_Else_False := null;
set_pos(
yyval);

when  149 =>
--#line  1234

yyval := new element_record(case_stat);

yyval.Case_Stat_expression := 
yy.value_stack(yy.tos-5);

yyval.Case_Stat_Alternatives := 
yy.value_stack(yy.tos-2);

yyval.Case_Stat_default := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  150 =>
--#line  1242

yyval := 
yy.value_stack(yy.tos-1);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  151 =>
--#line  1246

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);

when  152 =>
--#line  1252

yyval := new element_record(Case_Alternative);

yyval.Case_Alternative_Expr := 
yy.value_stack(yy.tos-2);

yyval.Case_Alternative_stat := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  153 =>
--#line  1259

yyval := 
yy.value_stack(yy.tos);

when  154 =>
--#line  1260

yyval := null;

when  155 =>
--#line  1264

yyval := new element_record(while_stat);

yyval.While_Stat_Cond := 
yy.value_stack(yy.tos-2);

yyval.While_Stat_True := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  156 =>
--#line  1271

yyval := new element_record(return_stat);

yyval.return_stat_expr := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  157 =>
--#line  1277

yyval := new element_record(for_stat);

yyval.For_Stat_Vars := 
yy.value_stack(yy.tos-2);

yyval.for_stat_stat := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  158 =>
--#line  1284

yyval := new element_record(block_stat);

yyval.block_stat_vars := 
yy.value_stack(yy.tos-2);

yyval.block_stat_seq := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  159 =>
--#line  1291

yyval := 
yy.value_stack(yy.tos-1);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  160 =>
--#line  1296

yyval := 
yy.value_stack(yy.tos-1);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  161 =>
--#line  1300

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);

when  162 =>
--#line  1305

yyval := 
yy.value_stack(yy.tos);

when  163 =>
--#line  1306

yyval := 
yy.value_stack(yy.tos);

when  164 =>
--#line  1310

yyval := new element_record(var_decl);

yyval.var_decl_color := 
yy.value_stack(yy.tos-2);

yyval.var_decl_name := 
yy.value_stack(yy.tos-1);

yyval.var_decl_init := null;

yyval.var_decl_const := false;
set_pos(
yyval, 
yy.value_stack(yy.tos-1)); 

when  165 =>
--#line  1319

yyval := new element_record(var_decl);

yyval.var_decl_color := 
yy.value_stack(yy.tos-4);

yyval.var_decl_name := 
yy.value_stack(yy.tos-3);

yyval.var_decl_init := 
yy.value_stack(yy.tos-1);

yyval.var_decl_const := false;
set_pos(
yyval, 
yy.value_stack(yy.tos-3)); 

when  166 =>
--#line  1328

yyval := 
yy.value_stack(yy.tos);
 
yyval.var_decl_const := true; 

when  167 =>
--#line  1333

yyval := new element_record(assert);

yyval.assert_cond := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  168 =>
--#line  1339

yyval := 
yy.value_stack(yy.tos-1);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  169 =>
--#line  1344

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  170 =>
--#line  1360

yyval := new element_record(place);

yyval.place_name := 
yy.value_stack(yy.tos-4);

yyval.place_dom := 
yy.value_stack(yy.tos-2);

yyval.place_attributes := 
yy.value_stack(yy.tos-1);
set_pos(
yyval, 
yy.value_stack(yy.tos-4));

when  171 =>
--#line  1368

yyval := 
yy.value_stack(yy.tos-1);

when  172 =>
--#line  1372

yyval := 
yy.value_stack(yy.tos);

when  173 =>
--#line  1374

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);

when  174 =>
--#line  1380

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  175 =>
--#line  1386

yyval := 
yy.value_stack(yy.tos-2);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  176 =>
--#line  1391

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);


when  177 =>
--#line  1396

yyval := 
yy.value_stack(yy.tos-1);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  178 =>
--#line  1402

yyval := 
yy.value_stack(yy.tos);

when  179 =>
--#line  1404

yyval := 
yy.value_stack(yy.tos);

when  180 =>
--#line  1406

yyval := 
yy.value_stack(yy.tos);

when  181 =>
--#line  1410

yyval := new element_record(place_init);

yyval.place_init_mapping := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  182 =>
--#line  1416

yyval := new element_record(place_capacity);

yyval.place_capacity_expr := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  183 =>
--#line  1422

yyval := new element_record(place_type);

yyval.place_type_type := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  184 =>
--#line  1443

yyval := new element_record(transition);

yyval.transition_name := 
yy.value_stack(yy.tos-9);

yyval.transition_inputs := 
yy.value_stack(yy.tos-7);

yyval.transition_outputs := 
yy.value_stack(yy.tos-6);

yyval.transition_inhibits := 
yy.value_stack(yy.tos-5);

yyval.transition_resets := 
yy.value_stack(yy.tos-4);

yyval.transition_pick_vars := 
yy.value_stack(yy.tos-3);

yyval.transition_let_vars := 
yy.value_stack(yy.tos-2);

yyval.transition_attributes := 
yy.value_stack(yy.tos-1);
set_pos(
yyval, 
yy.value_stack(yy.tos-9));

when  185 =>
--#line  1456

yyval := 
yy.value_stack(yy.tos-1);

when  186 =>
--#line  1460

yyval := 
yy.value_stack(yy.tos-1);

when  187 =>
--#line  1464

yyval := 
yy.value_stack(yy.tos-1);

when  188 =>
--#line  1465

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);

when  189 =>
--#line  1471

yyval := 
yy.value_stack(yy.tos-1);

when  190 =>
--#line  1472

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);

when  191 =>
--#line  1478

yyval := 
yy.value_stack(yy.tos-1);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  192 =>
--#line  1482

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);

when  193 =>
--#line  1488

yyval := new element_record(arc);

yyval.arc_place := 
yy.value_stack(yy.tos-3);

yyval.arc_mapping := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  194 =>
--#line  1495

yyval := new element_record(mapping);

yyval.mapping_tuples := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  195 =>
--#line  1501

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  196 =>
--#line  1507

yyval := 
yy.value_stack(yy.tos-2);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  197 =>
--#line  1513

yyval := new element_record(tuple);

yyval.tuple_vars := 
yy.value_stack(yy.tos-2);

yyval.tuple_guard := 
yy.value_stack(yy.tos-1);

yyval.tuple_tuple := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  198 =>
--#line  1521

yyval := 
yy.value_stack(yy.tos-1);

when  199 =>
--#line  1522

yyval := null;

when  200 =>
--#line  1526

yyval := 
yy.value_stack(yy.tos-1);

when  201 =>
--#line  1527

yyval := null;

when  202 =>
--#line  1531

yyval := new element_record(simple_tuple);

yyval.Simple_Tuple_factor := 
yy.value_stack(yy.tos-1);

yyval.Simple_Tuple_tuple := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  203 =>
--#line  1538

yyval := 
yy.value_stack(yy.tos-1);

when  204 =>
--#line  1539

yyval := null;

when  205 =>
--#line  1543

yyval := 
yy.value_stack(yy.tos-1);

when  206 =>
--#line  1545

yyval := new element_record(List);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);

when  207 =>
--#line  1550

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);


when  208 =>
--#line  1555

yyval := 
yy.value_stack(yy.tos-1);

when  209 =>
--#line  1558

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);


when  210 =>
--#line  1563

yyval := 
yy.value_stack(yy.tos-1);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  211 =>
--#line  1569

yyval := new element_record(iter_variable);

yyval.Iter_Variable_Name := 
yy.value_stack(yy.tos-4);

yyval.Iter_Variable_Domain := 
yy.value_stack(yy.tos-2);

yyval.Iter_Variable_Range := 
yy.value_stack(yy.tos-1);
set_pos(
yyval, 
yy.value_stack(yy.tos-4)); 

when  212 =>
--#line  1576

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);


when  213 =>
--#line  1581

yyval := 
yy.value_stack(yy.tos-1);

when  214 =>
--#line  1584

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);


when  215 =>
--#line  1589

yyval := 
yy.value_stack(yy.tos-1);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  216 =>
--#line  1595

yyval := 
yy.value_stack(yy.tos);

when  217 =>
--#line  1597

yyval := 
yy.value_stack(yy.tos);

when  218 =>
--#line  1599

yyval := 
yy.value_stack(yy.tos);

when  219 =>
--#line  1601

yyval := 
yy.value_stack(yy.tos);

when  220 =>
--#line  1604

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);

when  221 =>
--#line  1608

yyval := 
yy.value_stack(yy.tos-1);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  222 =>
--#line  1614

yyval := new element_record(transition_guard);

yyval.transition_guard_def := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  223 =>
--#line  1620

yyval := new element_record(transition_safe);
set_pos(
yyval);

when  224 =>
--#line  1625

yyval := new element_record(transition_priority);

yyval.transition_priority_def := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  225 =>
--#line  1632

yyval := new element_record(transition_description);

yyval.transition_description_desc := 
yy.value_stack(yy.tos-2);

yyval.transition_description_desc_exprs := 
yy.value_stack(yy.tos-1);
set_pos(
yyval);

when  226 =>
--#line  1638

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
set_pos(
yyval);

when  227 =>
--#line  1642

yyval := 
yy.value_stack(yy.tos);

when  228 =>
--#line  1653

yyval := new element_record(proposition);
 
yyval.proposition_name := 
yy.value_stack(yy.tos-3);
 
yyval.proposition_prop := 
yy.value_stack(yy.tos-1);
 set_pos(
yyval, 
yy.value_stack(yy.tos-3)); 

when  229 =>
--#line  1668

yyval := new element_record(name);

yyval.name_name := Helena_Lex.get_token_value;
set_pos(
yyval);

when  230 =>
--#line  1674

yyval := new element_record(a_string);

yyval.string_string := Helena_Lex.get_token_value;

yyval.string_string := to_unbounded_string(Slice(
yyval.string_string, 2,
					      length(
yyval.string_string) - 1));
set_pos(
yyval);

when  231 =>
--#line  1682

yyval := 
yy.value_stack(yy.tos);

when  232 =>
--#line  1686

yyval := 
yy.value_stack(yy.tos);

when  233 =>
--#line  1690

yyval := 
yy.value_stack(yy.tos);

when  234 =>
--#line  1694

yyval := 
yy.value_stack(yy.tos);

when  235 =>
--#line  1698

yyval := 
yy.value_stack(yy.tos);

when  236 =>
--#line  1702

yyval := 
yy.value_stack(yy.tos);

when  237 =>
--#line  1706

yyval := 
yy.value_stack(yy.tos);

when  238 =>
--#line  1710

yyval := 
yy.value_stack(yy.tos);

when  239 =>
--#line  1714

yyval := 
yy.value_stack(yy.tos);

when  240 =>
--#line  1718

yyval := 
yy.value_stack(yy.tos);

when  241 =>
--#line  1722

yyval := 
yy.value_stack(yy.tos);

when  242 =>
--#line  1726

yyval := 
yy.value_stack(yy.tos);

when  243 =>
--#line  1730

yyval := new element_record(number);

yyval.number_number := Helena_Lex.get_token_value;
set_pos(
yyval);

when  244 =>
--#line  1736

yyval := 
yy.value_stack(yy.tos);

when  245 =>
--#line  1740

yyval := new element_record(symbol);

yyval.sym := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  246 =>
--#line  1746

yyval := new element_record(list);

yyval.list_elements := Empty_Element_list;
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);


when  247 =>
--#line  1752

yyval := 
yy.value_stack(yy.tos-2);
append(
yyval.list_elements, 
yy.value_stack(yy.tos));
set_pos(
yyval);

when  248 =>
--#line  1758

yyval := new element_record(iter_variable);

yyval.Iter_Variable_Name := 
yy.value_stack(yy.tos-3);

yyval.Iter_Variable_Domain := 
yy.value_stack(yy.tos-1);

yyval.Iter_Variable_Range := 
yy.value_stack(yy.tos);
set_pos(
yyval);

when  249 =>
--#line  1765

yyval := null;

when  250 =>
--#line  1767

yyval := 
yy.value_stack(yy.tos);

when  251 =>
--#line  1771

yyval := new element_record(Low_High_Range);

yyval.Low_High_Range_Low := 
yy.value_stack(yy.tos-2);

yyval.Low_High_Range_High := 
yy.value_stack(yy.tos);
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

end Helena_Yacc;
