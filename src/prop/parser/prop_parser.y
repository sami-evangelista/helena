--  tokens
%token ACCEPT_TOKEN
%token AND_TOKEN
%token DEADLOCK_TOKEN
%token FALSE_TOKEN
%token LTL_TOKEN
%token NOT_TOKEN
%token OR_TOKEN
%token PROPERTY_TOKEN
%token REJECT_TOKEN
%token STATE_TOKEN
%token TRUE_TOKEN
%token UNTIL_TOKEN

%token IDENTIFIER_TOKEN
%token IMPLIES_TOKEN
%token SEMICOLON_TOKEN
%token COLON_TOKEN
%token GENERALLY_TOKEN
%token FINALLY_TOKEN
%token RBRACKET_TOKEN
%token LBRACKET_TOKEN

%left OR_TOKEN
%left AND_TOKEN
%left IMPLIES_TOKEN
%left EQUIVALENCE_TOKEN
%left UNTIL_TOKEN
%left GENERALLY_TOKEN
%left FINALLY_TOKEN
%left NOT_TOKEN


%with Ada.Strings.Unbounded;
%with Utils.Strings;
%with Generic_Array;
%use  Ada.Strings.Unbounded;
%use Utils.Strings;

{
   subtype Line_Number is Natural;
   subtype Column_Number is Natural;

   type Element_Record;
   type Element is access all Element_Record;
   subtype Yystype is Element;

   package Element_list_Pkg is
      new Generic_Array(Element, null, "=");
   subtype Element_list is Element_list_Pkg.array_type;

   Empty_Element_list :
     constant Element_list := Element_list_Pkg.Empty_Array;

   type Element_Type is
     (Not_Op,
      Finally_Op,
      Generally_Op,
      And_Op,
      Or_Op,
      Implies_Op,
      Equivalence_Op,
      Until_Op,
      Property,
      Deadlock,
      State_Property,
      Ltl_Property,
      Ltl_Un_Op,
      Ltl_Bin_Op,
      Ltl_Prop,
      Name,
      List,
      Ltl_Const);


   type Element_Record(T : Element_Type) is record
      Line : Line_Number;
      Col  : Column_Number;
      case T is
	 when Not_Op => null;
         when And_Op => null;
         when Or_Op => null;
         when Generally_Op => null;
         when Finally_Op => null;
         when Implies_Op => null;
         when equivalence_Op => null;
         when Until_Op => null;
	 when property =>
            property_name     : element;
            property_property : element;
         when State_Property =>
            State_Property_Reject: Element;
            State_Property_Accept: Element;
         when Deadlock => null;
         when Ltl_Const =>
	    Ltl_Constant: Boolean;
         when Ltl_Property =>
	    Ltl_Property_Formula : Element;
         when Ltl_Un_Op =>
	    Ltl_Un_Op_Operator: Element;
            Ltl_Un_Op_Operand : Element;
         when Ltl_Bin_Op =>
	    Ltl_Bin_Op_Left_Operand : Element;
	    Ltl_Bin_Op_Operator     : Element;
	    Ltl_Bin_Op_Right_Operand: Element;
         when Ltl_Prop =>
	    Ltl_Prop_Proposition: Element;
         when Name =>
            Name_Name : Unbounded_String;
         when List =>
            List_Elements : Element_list;
      end case;
   end record;
}

%start properties

%%

properties :
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
set_pos($$);
 parser_result := $$;} |
properties property
{$$ := $1;
append($$.list_elements, $2);
set_pos($$);};

property :
STATE_TOKEN PROPERTY_TOKEN identifier COLON_TOKEN state_property
{$$ := new element_record(Prop_Parser_Tokens.property);
$$.property_name := $3;
$$.property_property := $5;
set_pos($$, $3);} |
LTL_TOKEN PROPERTY_TOKEN identifier COLON_TOKEN ltl_property SEMICOLON_TOKEN
{$$ := new element_record(Prop_Parser_Tokens.property);
$$.property_name := $3;
$$.property_property := $5;
set_pos($$, $3);};

state_property :
REJECT_TOKEN state_property_comp SEMICOLON_TOKEN accept_clauses
{$$ := new element_record(state_property);
$$.state_property_reject := $2;
$$.state_property_accept := $4;
set_pos($$);};

state_property_comp :
DEADLOCK_TOKEN
{$$ := new element_record(deadlock);
set_pos($$);} |
identifier
{$$ := $1;};

accept_clauses :
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
set_pos($$);} |
accept_clauses accept_clause
{$$ := $1;
append($$.list_elements, $2);
set_pos($$);};

accept_clause :
ACCEPT_TOKEN state_property_comp SEMICOLON_TOKEN
{$$ := $2;};

ltl_property :
ltl_formula
{$$ := new element_record(Ltl_Property);
$$.Ltl_Property_Formula := $1;
set_pos($$);};

ltl_formula :
LBRACKET_TOKEN ltl_formula RBRACKET_TOKEN
{$$ := $2;} |
identifier
{$$ := new element_record(Ltl_Prop);
$$.Ltl_Prop_Proposition := $1;
set_pos($$);} |
FALSE_TOKEN
{$$ := new element_record(Ltl_Const);
$$.Ltl_Constant := false;
set_pos($$);} |
TRUE_TOKEN
{$$ := new element_record(Ltl_Const);
$$.Ltl_Constant := true;
set_pos($$);} |
ltl_formula AND_TOKEN ltl_formula
{$$ := new element_record(Ltl_Bin_Op);
$$.Ltl_Bin_Op_Operator := new element_record(and_op);
$$.Ltl_Bin_Op_Left_Operand := $1;
$$.Ltl_Bin_Op_Right_Operand := $3;
set_pos($$);} |
ltl_formula OR_TOKEN ltl_formula
{$$ := new element_record(Ltl_Bin_Op);
$$.Ltl_Bin_Op_Operator := new element_record(or_op);
$$.Ltl_Bin_Op_Left_Operand := $1;
$$.Ltl_Bin_Op_Right_Operand := $3;
set_pos($$);} |
ltl_formula UNTIL_TOKEN ltl_formula
{$$ := new element_record(Ltl_Bin_Op);
$$.Ltl_Bin_Op_Operator := new element_record(until_op);
$$.Ltl_Bin_Op_Left_Operand := $1;
$$.Ltl_Bin_Op_Right_Operand := $3;
set_pos($$);} |
ltl_formula IMPLIES_TOKEN ltl_formula
{$$ := new element_record(Ltl_Bin_Op);
$$.Ltl_Bin_Op_Operator := new element_record(implies_op);
$$.Ltl_Bin_Op_Left_Operand := $1;
$$.Ltl_Bin_Op_Right_Operand := $3;
set_pos($$);} |
ltl_formula EQUIVALENCE_TOKEN ltl_formula
{$$ := new element_record(Ltl_Bin_Op);
$$.Ltl_Bin_Op_Operator := new element_record(equivalence_op);
$$.Ltl_Bin_Op_Left_Operand := $1;
$$.Ltl_Bin_Op_Right_Operand := $3;
set_pos($$);} |
GENERALLY_TOKEN ltl_formula
{$$ := new element_record(Ltl_Un_Op);
$$.Ltl_Un_Op_Operator := new element_record(generally_op);
$$.Ltl_Un_Op_Operand  := $2;
set_pos($$);} |
FINALLY_TOKEN ltl_formula
{$$ := new element_record(Ltl_Un_Op);
$$.Ltl_Un_Op_Operator := new element_record(finally_op);
$$.Ltl_Un_Op_Operand  := $2;
set_pos($$);} |
NOT_TOKEN ltl_formula
{$$ := new element_record(Ltl_Un_Op);
$$.Ltl_Un_Op_Operator := new element_record(not_op);
$$.Ltl_Un_Op_Operand  := $2;
set_pos($$);};

identifier :
IDENTIFIER_TOKEN
{$$ := new element_record(name);
$$.name_name := Prop_Lexer.get_token_value;
set_pos($$);};


%%


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

##

end Prop_Parser;
