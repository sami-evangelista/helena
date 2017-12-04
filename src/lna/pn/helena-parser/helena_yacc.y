--  keywords
%token ASSERT_TOKEN
%token AND_TOKEN
%token CAPACITY_TOKEN
%token CARD_TOKEN
%token CASE_TOKEN
%token CONSTANT_TOKEN
%token DEFAULT_TOKEN
%token DESCRIPTION_TOKEN
%token DOM_TOKEN
%token ELSE_TOKEN
%token EMPTY_TOKEN
%token ENUM_TOKEN
%token EPSILON_TOKEN
%token EXISTS_TOKEN
%token FOR_TOKEN
%token FORALL_TOKEN
%token FUNCTION_TOKEN
%token GUARD_TOKEN
%token IF_TOKEN
%token IMPORT_TOKEN
%token IN_TOKEN
%token INIT_TOKEN
%token INHIBIT_TOKEN
%token LET_TOKEN
%token LIST_TOKEN
%token MAX_TOKEN
%token MIN_TOKEN
%token MOD_TOKEN
%token MULT_TOKEN
%token NOT_TOKEN
%token OF_TOKEN
%token OR_TOKEN
%token OUT_TOKEN
%token PLACE_TOKEN
%token PICK_TOKEN
%token PRED_TOKEN
%token PRINT_TOKEN
%token PRIORITY_TOKEN
%token PRODUCT_TOKEN
%token PROPOSITION_TOKEN
%token RANGE_TOKEN
%token RETURN_TOKEN
%token SAFE_TOKEN
%token SET_TOKEN
%token STRUCT_TOKEN
%token SUBTYPE_TOKEN
%token SUCC_TOKEN
%token SUM_TOKEN
%token TRANSITION_TOKEN
%token TYPE_TOKEN
%token VECTOR_TOKEN
%token WHILE_TOKEN
%token WITH_TOKEN

%token IDENTIFIER_TOKEN
%token NUMBER_TOKEN
%token STRING_TOKEN

%token AMP_TOKEN
%token COMMA_TOKEN
%token DIV_TOKEN
%token DOT_DOT_TOKEN
%token DOT_TOKEN
%token EQ_TOKEN
%token IMPLIES_TOKEN
%token INF_TOKEN
%token INF_EQ_TOKEN
%token LBRACE_TOKEN
%token LBRACKET_TOKEN
%token LHOOK_TOKEN
%token LTUPLE_TOKEN
%token MOD_TOKEN
%token MINUS_TOKEN
%token NEQ_TOKEN
%token PIPE_TOKEN
%token PLUS_TOKEN
%token QUESTION_TOKEN
%token QUOTE_TOKEN
%token RBRACE_TOKEN
%token RARROW_TOKEN
%token RBRACKET_TOKEN
%token RHOOK_TOKEN
%token RTUPLE_TOKEN
%token SEMICOLON_TOKEN
%token SUP_TOKEN
%token SUP_EQ_TOKEN
%token STRUCT_TOKEN
%token TIMES_TOKEN
%token COLON_TOKEN
%token COLON_COLON_TOKEN
%token COLON_EQUAL_TOKEN

%right QUESTION_TOKEN COLON_TOKEN
%left OR_TOKEN
%left AND_TOKEN
%left IN_TOKEN
%left EQ_TOKEN NEQ_TOKEN
%left INF_TOKEN INF_EQ_TOKEN SUP_TOKEN SUP_EQ_TOKEN
%left PLUS_TOKEN MINUS_TOKEN
%left TIMES_TOKEN DIV_TOKEN MOD_TOKEN
%left AMP_TOKEN
%left PRED_TOKEN SUCC_TOKEN NOT_TOKEN
%left COLON_COLON_TOKEN
%left DOT_TOKEN
%left LHOOK_TOKEN QUOTE_TOKEN


%with Ada.Strings.Unbounded;
%with Utils.Strings;
%with Generic_Array;
%use  Ada.Strings.Unbounded;
%use Utils.Strings;

{
   subtype Line_Number is Natural;

   type Element_Record;
   type Element is access all Element_Record;
   subtype Yystype is Element;

   package Element_list_Pkg is
      new Generic_Array(Element, null, "=");
   subtype Element_list is Element_list_Pkg.array_type;

   Empty_Element_list :
     constant Element_list := Element_list_Pkg.Empty_Array;

   type Element_Type is
     (--  nets
      Net,

      --  parameters
      Net_Param,

      --  colors
      Color,
      Range_Color,
      Mod_Color,
      Enum_Color,
      Vector_Color,
      Struct_Color,
      Component,
      List_Color,
      Set_Color,
      Sub_Color,

      --  functions
      Func_Prot,
      Func,
      Param,
      Var_Decl,

      --  expressions
      Num_Const,
      Func_Call,
      Vector_Access,
      Struct_Access,
      Bin_Op,
      Un_Op,
      Vector_Aggregate,
      Vector_Assign,
      Struct_Aggregate,
      Struct_Assign,
      Symbol,
      Iterator,
      Tuple_Access,
      Attribute,
      Container_Aggregate,
      Empty,
      List_Slice,

      --  iterator types
      card_iterator,
      mult_iterator,
      forall_iterator,
      exists_iterator,
      max_iterator,
      min_iterator,
      sum_iterator,
      product_iterator,
      
      --  unary operators
      Pred_Op,
      Succ_Op,
      Plus_Op,
      Minus_Op,
      Not_Op,

      --  binary operators
      Mult_Op,
      Div_Op,
      Mod_Op,
      And_Op,
      Or_Op,
      Sup_Op,
      Sup_Eq_Op,
      Inf_Op,
      Inf_Eq_Op,
      Eq_Op,
      Neq_Op,
      Amp_Op,
      In_Op,

      --  statements
      Assign,
      If_Then_Else,
      Case_Stat,
      Case_Alternative,
      While_Stat,
      Print_Stat,
      Return_Stat,
      For_Stat,
      Block_Stat,

      --  places
      Place,
      Place_Init,
      Place_Capacity,
      Place_Type,
      
      --  transitions
      Transition,
      Transition_Description,
      Transition_Guard,
      Transition_Priority,
      Transition_Safe,

      --  mappings
      Arc,
      Mapping,
      Tuple,
      Simple_Tuple,

      --  propositions
      Proposition,

      --  others
      Assert,
      Iter_Variable,
      Low_High_Range,
      Name,
      A_String,
      Number,
      List);


   type Element_Record(T : Element_Type) is record
      Line : Line_Number;
      File : Ustring;
      case T is
         when Net =>
            Net_Name   : Element;
            Net_Params : Element;
            Net_Defs   : Element;
         when Net_Param =>
	    Net_Param_Name    : Element;
            Net_Param_Default : Element;
         when Color =>
            Cls_Name : Element;
            Cls_Def  : Element;
         when Range_Color =>
            Range_Color_Range  : Element;
         when Mod_Color =>
            Mod_Val : Element;
         when Enum_Color =>
            ENum_Values : Element;
         when Vector_Color =>
            Vector_Indexes  : Element;
            Vector_Elements : Element;
         when Struct_Color =>
            Struct_Components : Element;
         when Component =>
            Component_Name  : Element;
            Component_Color : Element;
         when List_Color =>
            List_Color_Index    : Element;
            List_Color_Elements : Element;
	    List_Color_Capacity : Element;
         when Set_Color =>
            Set_Color_Elements : Element;
	    Set_Color_Capacity : Element;
         when Sub_Color =>
            Sub_Cls_Name       : Element;
            Sub_Cls_Parent     : Element;
            Sub_Cls_Constraint : Element;
         when Func_Prot =>
            Func_Prot_Name   : Element;
            Func_Prot_Params : Element;
            Func_Prot_Ret    : Element;
         when Func =>
            Func_Name    : Element;
            Func_Params  : Element;
            Func_Return  : Element;
            Func_Stat    : Element;
            Func_Imported: Boolean;
         when Param =>
            Param_Name  : Element;
            Param_Color : Element;
         when Var_Decl =>
            Var_Decl_Name : Element;
            Var_Decl_Color: Element;
            Var_Decl_Init : Element;
            Var_Decl_Const: Boolean;
         when Num_Const =>
            Num_Val : Element;
         when Func_Call =>
            Func_Call_Func   : Element;
            Func_Call_Params : Element;
         when Vector_Access =>
            Vector_Access_Vector  : Element;
            Vector_Access_Indexes : Element;
         when Struct_Access =>
            Struct_Access_Struct    : Element;
            Struct_Access_Component : Element;
         when Bin_Op =>
            Bin_Op_Left_Operand  : Element;
            Bin_Op_Operator      : Element;
            Bin_Op_Right_Operand : Element;
         when Un_Op =>
            Un_Op_Operator : Element;
            Un_Op_Operand  : Element;
         when Vector_Aggregate =>
            Vector_Aggregate_Elements : Element;
         when Vector_Assign =>
            Vector_Assign_Vector : Element;
            Vector_Assign_Index  : Element;
            Vector_Assign_Expr   : Element;
         when Struct_Aggregate =>
            Struct_Aggregate_Elements : Element;
         when Struct_Assign =>
	    Struct_Assign_Struct    : Element;
            Struct_Assign_Component : Element;
            Struct_Assign_Expr      : Element;
         when Iterator =>
            Iterator_Iterator_Type : Element;
	    Iterator_Variables     : Element;
            Iterator_Condition     : Element;
            Iterator_Expression    : Element;
         when Tuple_Access =>
            Tuple_Access_Tuple     : Element;
            Tuple_Access_Component : Element;
         when Container_Aggregate =>
            Container_Aggregate_Elements : Element;
         when Attribute =>
            Attribute_Element   : Element;
            Attribute_Attribute : Element;
         when Symbol =>
            Sym : Element;
         when Empty =>
	     null;
	 when List_Slice =>
	     List_Slice_List  : Element;
   	     List_Slice_First : Element;
	     List_Slice_Last  : Element;
         when Assign =>
            Assign_Var : Element;
            Assign_Val : Element;
         when If_Then_Else =>
            If_Then_Else_Cond  : Element;
            If_Then_Else_True  : Element;
            If_Then_Else_False : Element;
         when Case_Stat =>
            Case_Stat_Expression   : Element;
            Case_Stat_Alternatives : Element;
            Case_Stat_Default      : Element;
         when Case_Alternative =>
            Case_Alternative_Expr : Element;
            Case_Alternative_Stat : Element;
         when While_Stat =>
            While_Stat_Cond : Element;
            While_Stat_True : Element;
         when Print_Stat =>
            Print_Stat_With_Str : Boolean;
            Print_Stat_Str      : Element;
            Print_Stat_Exprs    : Element;
         when Return_Stat =>
            Return_Stat_Expr : Element;
         when For_Stat =>
            For_Stat_Vars : Element;
            For_Stat_Stat : Element;
         when Block_Stat =>
            Block_Stat_Vars : Element;
            Block_Stat_Seq  : Element;
         when Place =>
            Place_Name       : Element;
            Place_Dom        : Element;
            Place_Attributes : Element;
         when Place_Init =>
            Place_Init_Mapping : Element;
         when Place_Capacity =>
            Place_Capacity_Expr : Element;
         when Place_Type =>
  	    place_type_type : element;
         when Transition =>
            Transition_Name       : Element;
            Transition_Inputs     : Element;
            Transition_Outputs    : Element;
            Transition_Inhibits   : Element;
            Transition_Pick_Vars  : Element;
            Transition_Let_Vars   : Element;
            Transition_Attributes : Element;
         when Transition_Guard =>
            Transition_Guard_Def : Element;
         when Transition_Priority =>
            Transition_Priority_Def : Element;
         when Transition_Safe =>
	    null;
	 when Transition_Description =>
	    Transition_Description_Desc       : Element;
	    Transition_Description_Desc_Exprs : Element;
         when Arc =>
            Arc_Place   : Element;
            Arc_Mapping : Element;
         when Mapping =>
            Mapping_Tuples : Element;
         when Tuple =>
            Tuple_Vars  : Element;
            Tuple_Guard : Element;
            Tuple_Tuple : Element;
         when Simple_Tuple =>
            Simple_Tuple_Factor : Element;
            Simple_Tuple_Tuple  : Element;
	 when Proposition =>
	    Proposition_Name: Element;
            Proposition_Prop: Element;
         when assert =>
	    assert_cond : element;
         when Iter_Variable =>
            Iter_Variable_Name   : Element;
            Iter_Variable_Domain : Element;
            Iter_Variable_Range  : Element;
         when Low_High_Range =>
            Low_High_Range_Low  : Element;
            Low_High_Range_High : Element;
         when Name =>
            Name_Name : Unbounded_String;
         when a_string =>
            string_string : Unbounded_String;
         when Number =>
            Number_Number : Unbounded_String;
	 when mult_iterator => null;
         when card_iterator => null;
	 when forall_iterator => null;
	 when exists_iterator => null;
	 when max_iterator => null;
	 when min_iterator => null;
	 when sum_iterator => null;
	 when product_iterator => null;
         when Pred_Op => null;
         when Succ_Op => null;
         when Not_Op => null;
         when Plus_Op => null;
         when Minus_Op => null;
         when Mult_Op => null;
         when Div_Op => null;
         when Mod_Op => null;
         when And_Op => null;
         when Or_Op => null;
         when Sup_Op => null;
         when Sup_Eq_Op => null;
         when Inf_Op => null;
         when Inf_Eq_Op => null;
         when Eq_Op => null;
         when Neq_Op => null;
         when Amp_Op => null;
         when In_Op => null;
         when List =>
            List_Elements : Element_list;
      end case;
   end record;
}

%start net

%%

--===========================================================================--
--                                     Net                                   --
--===========================================================================--

net :
net_name net_parameters LBRACE_TOKEN def_list RBRACE_TOKEN
{$$ := new Element_Record(Net);
$$.Net_name := $1;
$$.net_defs := $4;
$$.net_params := $2;
set_pos($$, $1);
parser_result := $$;};

def_list :
def_list def
{$$ := $1;
append($$.List_Elements, $2);
set_pos($$);
} |
{$$ := new element_record(list);
$$.List_Elements := empty_element_list;
set_pos($$);};

def :
colors
{$$ := $1;} |
transition
{$$ := $1;} |
place
{$$ := $1;} |
function
{$$ := $1;} |
net_const
{$$ := $1;} |
proposition
{$$ := $1;};




--===========================================================================--
--                                Net parameters                             --
--===========================================================================--

net_parameters :
{$$ := new element_record(list);
$$.List_Elements := empty_element_list;
set_pos($$);}
|
LBRACKET_TOKEN net_parameter_list RBRACKET_TOKEN
{$$ := $2;};

net_parameter_list :
net_parameter_def
{$$ := new element_record(List);
$$.list_elements := Empty_Element_list;
append($$.list_elements, $1);
set_pos($$);}
|
net_parameter_list COMMA_TOKEN net_parameter_def
{$$ := $1;
append($$.list_elements, $3);
set_pos($$);};

net_parameter_def :
net_parameter_name COLON_EQUAL_TOKEN number
{$$ := new element_record(Net_Param);
$$.Net_Param_Name := $1;
$$.Net_Param_Default := $3;
set_pos($$, $1);};



--===========================================================================--
--                                Net constants                              --
--===========================================================================--

net_const :
const_decl
{$$ := $1;};




--===========================================================================--
--                                    Colors                                 --
--===========================================================================--

colors :
color
{$$ := $1;} |
sub_color
{$$ := $1;};

color :
TYPE_TOKEN color_name COLON_TOKEN color_def SEMICOLON_TOKEN
{$$ := new element_record(color);
$$.cls_name := $2;
$$.cls_def := $4;
set_pos($$, $2);
};

color_def :
range_color
{$$ := $1;} |
mod_color
{$$ := $1;} |
enumerate_color
{$$ := $1;} |
vector_color
{$$ := $1;} |
struct_color
{$$ := $1;} |
list_color
{$$ := $1;} |
set_color
{$$ := $1;};

range_color :
range_spec
{$$ := new element_record(range_color);
$$.range_color_range := $1;
set_pos($$);};

mod_color :
MOD_TOKEN expr
{$$ := new element_record(mod_color);
$$.mod_val := $2;
set_pos($$);};

enumerate_color :
ENUM_TOKEN LBRACKET_TOKEN enum_const_list RBRACKET_TOKEN
{$$ := new element_record(Enum_Color);
$$.enum_values := $3;
set_pos($$);};

enum_const_list :
enum_const
{$$ := new element_record(List);
$$.list_elements := Empty_Element_list;
append($$.list_elements, $1);
set_pos($$);
} |
enum_const_list COMMA_TOKEN enum_const
{$$ := $1;
append($$.list_elements, $3);
set_pos($$);};

vector_color :
VECTOR_TOKEN LHOOK_TOKEN color_list RHOOK_TOKEN OF_TOKEN color_name
{$$ := new element_record(vector_color);
$$.Vector_Indexes := $3;
$$.vector_elements := $6;
set_pos($$);};

color_list :
color_name
{$$ := new element_record(List);
$$.list_elements := Empty_Element_list;
append($$.list_elements, $1);
set_pos($$);
} |
color_list COMMA_TOKEN color_name
{$$ := $1;
append($$.list_elements, $3);
set_pos($$);};

struct_color :
STRUCT_TOKEN LBRACE_TOKEN component_list RBRACE_TOKEN
{$$ := new element_record(struct_color);
$$.struct_components := $3;
set_pos($$);};

component_list :
component
{$$ := new element_record(List);
$$.list_elements := Empty_Element_list;
append($$.list_elements, $1);
set_pos($$);
} |
component_list component
{$$ := $1;
append($$.list_elements, $2);
set_pos($$);};

component :
color_name component_name SEMICOLON_TOKEN
{$$ := new element_record(Helena_Yacc_tokens.component);
$$.component_name  := $2;
$$.component_color := $1;
set_pos($$, $2);};

list_color :
LIST_TOKEN LHOOK_TOKEN color_name RHOOK_TOKEN OF_TOKEN color_name
WITH_TOKEN CAPACITY_TOKEN expr
{$$ := new element_record(list_color);
$$.List_Color_Index:= $3;
$$.List_Color_Elements := $6;
$$.List_Color_Capacity := $9;
set_pos($$);};

set_color :
SET_TOKEN OF_TOKEN color_name WITH_TOKEN CAPACITY_TOKEN expr
{$$ := new element_record(set_color);
$$.Set_Color_Elements := $3;
$$.Set_Color_Capacity := $6;
set_pos($$);};

sub_color :
SUBTYPE_TOKEN sub_color_name COLON_TOKEN color_name color_constraint
SEMICOLON_TOKEN
{$$ := new element_record(Helena_Yacc_tokens.sub_color);
$$.Sub_Cls_Name   := $2;
$$.Sub_Cls_Parent := $4;
$$.Sub_Cls_Constraint := $5;
set_pos($$, $2);};

color_constraint :
range_spec
{$$ := $1;} |
{$$ := null;};





--===========================================================================--
--                                  Functions                                --
--===========================================================================--

function :
function_prototype
{$$ := $1;} |
function_body
{$$ := $1;};

function_prototype :
FUNCTION_TOKEN func_name LBRACKET_TOKEN func_params RBRACKET_TOKEN
RARROW_TOKEN func_ret_color SEMICOLON_TOKEN
{$$ := new element_record(func_prot);
$$.func_prot_name := $2;
$$.func_prot_params := $4;
$$.func_prot_ret := $7;
set_pos($$, $2);};

function_body :
FUNCTION_TOKEN func_name
LBRACKET_TOKEN func_params RBRACKET_TOKEN
RARROW_TOKEN func_ret_color func_stat
{$$ := new element_record(func);
$$.func_name := $2;
$$.func_params := $4;
$$.func_return := $7;
$$.func_stat := $8;
$$.func_imported := false;
set_pos($$, $2);
} |
IMPORT_TOKEN FUNCTION_TOKEN func_name
LBRACKET_TOKEN func_params RBRACKET_TOKEN
RARROW_TOKEN func_ret_color SEMICOLON_TOKEN
{$$ := new element_record(func);
$$.func_name := $3;
$$.func_params := $5;
$$.func_return := $8;
$$.func_stat := null;
$$.func_imported := true;
set_pos($$, $3);};

func_params :
{$$ := new element_record(List);
$$.list_elements := Empty_Element_list;
set_pos($$);
} |
non_empty_parameters_spec
{$$ := $1;};

non_empty_parameters_spec :
parameter_spec
{$$ := new element_record(List);
$$.list_elements := Empty_Element_list;
append($$.list_elements, $1);
set_pos($$);
} |
non_empty_parameters_spec COMMA_TOKEN parameter_spec
{$$ := $1;
append($$.list_elements, $3);
set_pos($$);};

parameter_spec :
color_name var_name
{$$ := new element_record(param);
$$.param_name := $2;
$$.param_color := $1;
set_pos($$, $2);};

func_ret_color :
color_name
{$$ := $1;};

func_stat :
stat
{$$ := $1;};





--===========================================================================--
--                                 Expressions                               --
--===========================================================================--

expr :
num_const {$$ := $1;} |
func_call {$$ := $1;} |
bin_op {$$ := $1;} |
un_op {$$ := $1;} |
if_then_else {$$ := $1;} |
iterator {$$ := $1;} |
attribute {$$ := $1;} |
brackets_expr {$$ := $1;} |
symbol {$$ := $1;} |
token_component_access {$$ := $1;} |
vector_aggregate {$$ := $1;} |
vector_assign {$$ := $1;} |
vector_access {$$ := $1;} |
struct_aggregate {$$ := $1;} |
struct_assign {$$ := $1;} |
struct_access {$$ := $1;} |
container {$$ := $1;} |
empty {$$ := $1;} |
list_slice {$$ := $1;};

brackets_expr :
LBRACKET_TOKEN expr RBRACKET_TOKEN
{$$ := $2;};

num_const :
number
{$$ := new element_record(Num_Const);
$$.num_val := $1;
set_pos($$);};

var :
symbol {$$ := $1;} |
simple_vector_access {$$ := $1;} |
simple_struct_access {$$ := $1;};

vector_access :
expr LHOOK_TOKEN non_empty_expr_list RHOOK_TOKEN
{$$ := new element_record(Vector_Access);
$$.Vector_Access_Vector := $1;
$$.Vector_Access_Indexes := $3;
set_pos($$);};

struct_access :
expr DOT_TOKEN var_name
{$$ := new element_record(Struct_Access);
$$.Struct_Access_Struct := $1;
$$.Struct_Access_component := $3;
set_pos($$);};

simple_vector_access :
var LHOOK_TOKEN non_empty_expr_list RHOOK_TOKEN
{$$ := new element_record(Vector_Access);
$$.Vector_Access_Vector := $1;
$$.Vector_Access_Indexes := $3;
set_pos($$);};

simple_struct_access :
var DOT_TOKEN var_name
{$$ := new element_record(Struct_Access);
$$.Struct_Access_Struct := $1;
$$.Struct_Access_component := $3;
set_pos($$);};

func_call :
func_name LBRACKET_TOKEN expr_list RBRACKET_TOKEN
{$$ := new element_record(func_call);
$$.func_call_func := $1;
$$.func_call_params := $3;
set_pos($$);};

expr_list :
{$$ := new element_record(List);
$$.list_elements := Empty_Element_list;
set_pos($$);
} |
non_empty_expr_list
{$$ := $1;};

non_empty_expr_list :
non_empty_expr_list COMMA_TOKEN expr
{$$ := $1;
append($$.list_elements, $3);
set_pos($$);
} |
expr
{$$ := new element_record(List);
$$.list_elements := Empty_Element_list;
append($$.list_elements, $1);
set_pos($$);};

bin_op :
expr PLUS_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(plus_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr MINUS_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(minus_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr TIMES_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(mult_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr DIV_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(div_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr MOD_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(mod_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr AND_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(and_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr OR_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(or_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr SUP_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(sup_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr SUP_EQ_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(sup_eq_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr INF_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(inf_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr INF_EQ_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(inf_eq_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr EQ_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(eq_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr NEQ_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(neq_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr AMP_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(amp_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);
} |
expr IN_TOKEN expr
{$$ := new element_record(bin_op);
$$.Bin_Op_Left_Operand := $1;
$$.Bin_Op_Operator := new element_record(in_op);
$$.Bin_Op_Right_Operand := $3;
set_pos($$);};

un_op :
MINUS_TOKEN expr
{$$ := new element_record(un_op);
$$.Un_Op_Operator := new element_record(minus_op);
$$.un_Op_Operand := $2;
set_pos($$);
} |
PLUS_TOKEN expr
{$$ := new element_record(un_op);
$$.Un_Op_Operator := new element_record(plus_op);
$$.un_Op_Operand := $2;
set_pos($$);
} |
SUCC_TOKEN expr
{$$ := new element_record(un_op);
$$.Un_Op_Operator := new element_record(succ_op);
$$.un_Op_Operand := $2;
set_pos($$);
} |
PRED_TOKEN expr
{$$ := new element_record(un_op);
$$.Un_Op_Operator := new element_record(pred_op);
$$.un_Op_Operand := $2;
set_pos($$);
} |
NOT_TOKEN expr
{$$ := new element_record(un_op);
$$.Un_Op_Operator := new element_record(not_op);
$$.un_Op_Operand := $2;
set_pos($$);};

vector_aggregate :
LHOOK_TOKEN non_empty_expr_list RHOOK_TOKEN
{$$ := new element_record(Vector_Aggregate);
$$.Vector_Aggregate_Elements := $2;
set_pos($$);};

vector_assign :
expr COLON_COLON_TOKEN LBRACKET_TOKEN LHOOK_TOKEN non_empty_expr_list
RHOOK_TOKEN COLON_EQUAL_TOKEN expr RBRACKET_TOKEN
{$$ := new element_record(vector_assign);
$$.vector_assign_vector := $1;
$$.vector_assign_index := $5;
$$.vector_assign_expr := $8;
set_pos($$);};

struct_aggregate :
LBRACE_TOKEN non_empty_expr_list RBRACE_TOKEN
{$$ := new element_record(Struct_Aggregate);
$$.struct_Aggregate_Elements := $2;
set_pos($$);};

struct_assign :
expr COLON_COLON_TOKEN LBRACKET_TOKEN component_name COLON_EQUAL_TOKEN
expr RBRACKET_TOKEN
{$$ := new element_record(Struct_assign);
$$.struct_assign_struct := $1;
$$.struct_assign_component := $4;
$$.struct_assign_expr := $6;
set_pos($$);};

if_then_else :
expr QUESTION_TOKEN expr COLON_TOKEN expr
{$$ := new element_record(if_then_else);
$$.if_then_else_cond := $1;
$$.if_then_else_true := $3;
$$.if_then_else_false := $5;
set_pos($$);};

token_component_access :
symbol RARROW_TOKEN number
{$$ := new element_record(Tuple_Access);
$$.Tuple_Access_Tuple := $1;
$$.Tuple_Access_component := $3;
set_pos($$);};

attribute :
expr QUOTE_TOKEN attribute_name
{$$ := new element_record(attribute);
$$.attribute_element := $1;
$$.attribute_attribute := $3;
set_pos($$);
} |
expr QUOTE_TOKEN CARD_TOKEN
{$$ := new element_record(attribute);
$$.attribute_element := $1;
$$.attribute_attribute := new element_record(name);
$$.attribute_attribute.name_name := to_unbounded_string("card");
set_pos($$.attribute_attribute);
set_pos($$);
} |
expr QUOTE_TOKEN MULT_TOKEN
{$$ := new element_record(attribute);
$$.attribute_element := $1;
$$.attribute_attribute := new element_record(name);
$$.attribute_attribute.name_name := to_unbounded_string("mult");
set_pos($$.attribute_attribute);
set_pos($$);
} |
expr QUOTE_TOKEN EMPTY_TOKEN
{$$ := new element_record(attribute);
$$.attribute_element := $1;
$$.attribute_attribute := new element_record(name);
$$.attribute_attribute.name_name := to_unbounded_string("empty");
set_pos($$.attribute_attribute);
set_pos($$);};

iterator :
iterator_type_with_expr
LBRACKET_TOKEN iteration_vars iterator_cond iterator_expr RBRACKET_TOKEN
{$$ := new element_record(iterator);
$$.iterator_iterator_type := $1;
$$.iterator_variables := $3;
$$.iterator_condition := $4;
$$.iterator_expression := $5;
set_pos($$);
} |
iterator_type_without_expr
LBRACKET_TOKEN iteration_vars iterator_cond RBRACKET_TOKEN
{$$ := new element_record(iterator);
$$.iterator_iterator_type := $1;
$$.iterator_variables := $3;
$$.iterator_condition := $4;
$$.iterator_expression := null;
set_pos($$);};

iterator_cond :
PIPE_TOKEN expr
{$$ := $2;} |
{$$ := null;};

iterator_expr :
COLON_TOKEN expr
{$$ := $2;};

iterator_type_with_expr :
FORALL_TOKEN
{$$ := new element_record(forall_iterator);
set_pos($$);
} |
MAX_TOKEN
{$$ := new element_record(max_iterator);
set_pos($$);
} |
MIN_TOKEN
{$$ := new element_record(min_iterator);
set_pos($$);
} |
SUM_TOKEN
{$$ := new element_record(sum_iterator);
set_pos($$);
} |
PRODUCT_TOKEN
{$$ := new element_record(product_iterator);
set_pos($$);};

iterator_type_without_expr :
CARD_TOKEN
{$$ := new element_record(Card_iterator);
set_pos($$);
} |
MULT_TOKEN
{$$ := new element_record(Mult_iterator);
set_pos($$);
} |
EXISTS_TOKEN
{$$ := new element_record(Exists_iterator);
set_pos($$);};

container :
PIPE_TOKEN non_empty_expr_list PIPE_TOKEN
{$$ := new element_record(Container_Aggregate);
$$.Container_Aggregate_Elements := $2;
set_pos($$);};

empty :
EMPTY_TOKEN
{$$ := new element_record(empty);
set_pos($$);};

list_slice :
expr LHOOK_TOKEN expr DOT_DOT_TOKEN expr RHOOK_TOKEN
{$$ := new element_record(List_Slice);
$$.List_Slice_List  := $1;
$$.List_Slice_First := $3;
$$.List_Slice_Last  := $5;
set_pos($$);};





--===========================================================================--
--                                  Statement                               --
--===========================================================================--

stat :
assign_stat {$$ := $1;} |
block_stat {$$ := $1;} |
case_stat {$$ := $1;} |
while_stat {$$ := $1;} |
return_stat {$$ := $1;} |
for_stat {$$ := $1;} |
if_stat {$$ := $1;} |
print_stat {$$ := $1;} |
assert_stat {$$ := $1;};

assign_stat :
var COLON_EQUAL_TOKEN expr SEMICOLON_TOKEN
{$$ := new element_record(assign);
$$.assign_var := $1;
$$.assign_val := $3;
set_pos($$);};

if_stat :
IF_TOKEN LBRACKET_TOKEN expr RBRACKET_TOKEN stat ELSE_TOKEN stat
{$$ := new element_record(if_then_else);
$$.If_Then_Else_Cond := $3;
$$.If_Then_Else_True := $5;
$$.If_Then_Else_False := $7;
set_pos($$);
} |
IF_TOKEN LBRACKET_TOKEN expr RBRACKET_TOKEN stat
{$$ := new element_record(if_then_else);
$$.If_Then_Else_Cond := $3;
$$.If_Then_Else_True := $5;
$$.If_Then_Else_False := null;
set_pos($$);};

case_stat :
CASE_TOKEN LBRACKET_TOKEN expr RBRACKET_TOKEN LBRACE_TOKEN
case_alternative_list default_alternative RBRACE_TOKEN
{$$ := new element_record(case_stat);
$$.Case_Stat_expression := $3;
$$.Case_Stat_Alternatives := $6;
$$.Case_Stat_default := $7;
set_pos($$);};

case_alternative_list :
case_alternative_list case_alternative
{$$ := $1;
append($$.list_elements, $2);
set_pos($$);
} |
{$$ := new element_record(List);
$$.list_elements := Empty_Element_list;
set_pos($$);};

case_alternative :
expr COLON_TOKEN stat
{$$ := new element_record(Case_Alternative);
$$.Case_Alternative_Expr := $1;
$$.Case_Alternative_stat := $3;
set_pos($$);};

default_alternative :
DEFAULT_TOKEN COLON_TOKEN stat
{$$ := $3;} |
{$$ := null;};

while_stat :
WHILE_TOKEN LBRACKET_TOKEN expr RBRACKET_TOKEN stat
{$$ := new element_record(while_stat);
$$.While_Stat_Cond := $3;
$$.While_Stat_True := $5;
set_pos($$);};

return_stat :
RETURN_TOKEN expr SEMICOLON_TOKEN
{$$ := new element_record(return_stat);
$$.return_stat_expr := $2;
set_pos($$);};

for_stat :
FOR_TOKEN LBRACKET_TOKEN iteration_vars RBRACKET_TOKEN stat
{$$ := new element_record(for_stat);
$$.For_Stat_Vars := $3;
$$.for_stat_stat := $5;
set_pos($$);};

print_stat :
PRINT_TOKEN non_empty_expr_list SEMICOLON_TOKEN
{$$ := new element_record(print_stat);
 $$.Print_Stat_With_Str := False;
 $$.Print_Stat_Str      := null;
 $$.Print_Stat_Exprs    := $2;
 set_pos($$);
} |
PRINT_TOKEN string COMMA_TOKEN non_empty_expr_list SEMICOLON_TOKEN
{$$ := new element_record(print_stat);
 $$.Print_Stat_With_Str := True;
 $$.Print_Stat_Str      := $2;
 $$.Print_Stat_Exprs    := $4;
 set_pos($$);
} |
PRINT_TOKEN string SEMICOLON_TOKEN
{$$ := new element_record(print_stat);
 $$.Print_Stat_With_Str := True;
 $$.Print_Stat_Str      := $2;
 $$.Print_Stat_Exprs    := new element_record(list);
 $$.Print_Stat_Exprs.list_elements := Empty_Element_list;
 set_pos($$);
};

assert_stat :
ASSERT_TOKEN COLON_TOKEN expr SEMICOLON_TOKEN
{$$ := new element_record(assert);
$$.assert_cond := $3;
set_pos($$);};

block_stat :
LBRACE_TOKEN var_decl_list stat_list RBRACE_TOKEN
{$$ := new element_record(block_stat);
$$.block_stat_vars := $2;
$$.block_stat_seq := $3;
set_pos($$);};

var_decl_list :
var_decl_list var_decl
{$$ := $1;
append($$.list_elements, $2);
set_pos($$);
} |
var_decl_list const_decl
{$$ := $1;
append($$.list_elements, $2);
set_pos($$);
} |
{$$ := new element_record(List);
$$.list_elements := Empty_Element_list;
set_pos($$);};

var_decl :
non_init_var_decl {$$ := $1;}
| init_var_decl   {$$ := $1;};

non_init_var_decl :
color_name var_name SEMICOLON_TOKEN
{$$ := new element_record(var_decl);
$$.var_decl_color := $1;
$$.var_decl_name := $2;
$$.var_decl_init := null;
$$.var_decl_const := false;
set_pos($$, $2); };

init_var_decl :
color_name var_name COLON_EQUAL_TOKEN expr SEMICOLON_TOKEN
{$$ := new element_record(var_decl);
$$.var_decl_color := $1;
$$.var_decl_name := $2;
$$.var_decl_init := $4;
$$.var_decl_const := false;
set_pos($$, $2); };

const_decl :
CONSTANT_TOKEN init_var_decl
{$$ := $2;
 $$.var_decl_const := true; };

stat_list :
stat_list stat
{$$ := $1;
append($$.list_elements, $2);
set_pos($$);
} |
stat
{$$ := new element_record(List);
$$.list_elements := Empty_Element_list;
append($$.list_elements, $1);
set_pos($$);};





--===========================================================================--
--                                    Places                                 --
--===========================================================================--

place :
PLACE_TOKEN place_name
LBRACE_TOKEN domain place_attribute_list RBRACE_TOKEN
{$$ := new element_record(place);
$$.place_name := $2;
$$.place_dom := $4;
$$.place_attributes := $5;
set_pos($$, $2);};

domain :
DOM_TOKEN COLON_TOKEN domain_def SEMICOLON_TOKEN
{$$ := $3;};

domain_def :
colors_product
{$$ := $1;} |
EPSILON_TOKEN
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
set_pos($$);};

colors_product :
color_name
{$$ := new element_record(List);
$$.list_elements := Empty_Element_list;
append($$.list_elements, $1);
set_pos($$);
} |
colors_product TIMES_TOKEN color_name
{$$ := $1;
append($$.list_elements, $3);
set_pos($$);};

place_attribute_list :
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
set_pos($$);
} |
place_attribute_list place_attribute
{$$ := $1;
append($$.list_elements, $2);
set_pos($$);};

place_attribute :
marking
{$$ := $1;} |
capacity
{$$ := $1;} |
place_type
{$$ := $1;};

marking :
INIT_TOKEN COLON_TOKEN mapping SEMICOLON_TOKEN
{$$ := new element_record(place_init);
$$.place_init_mapping := $3;
set_pos($$);};

capacity :
CAPACITY_TOKEN COLON_TOKEN expr SEMICOLON_TOKEN
{$$ := new element_record(place_capacity);
$$.place_capacity_expr := $3;
set_pos($$);};

place_type :
TYPE_TOKEN COLON_TOKEN type_name SEMICOLON_TOKEN
{$$ := new element_record(place_type);
$$.place_type_type := $3;
set_pos($$);};




--===========================================================================--
--                                 Transitions                               --
--===========================================================================--

transition :
TRANSITION_TOKEN trans_name LBRACE_TOKEN
transition_inputs
transition_outputs
transition_inhibs
transition_pick_vars
transition_let_vars
transition_attribute_list
RBRACE_TOKEN
{$$ := new element_record(transition);
$$.transition_name := $2;
$$.transition_inputs := $4;
$$.transition_outputs := $5;
$$.transition_inhibits := $6;
$$.transition_pick_vars := $7;
$$.transition_let_vars := $8;
$$.transition_attributes := $9;
set_pos($$, $2);};

transition_inputs :
IN_TOKEN LBRACE_TOKEN arc_list RBRACE_TOKEN
{$$ := $3;};

transition_outputs :
OUT_TOKEN LBRACE_TOKEN arc_list RBRACE_TOKEN
{$$ := $3;};

transition_inhibs :
INHIBIT_TOKEN LBRACE_TOKEN arc_list RBRACE_TOKEN
{$$ := $3;} |
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
set_pos($$);};

arc_list :
arc_list arc
{$$ := $1;
append($$.list_elements, $2);
set_pos($$);
} |
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
set_pos($$);};

arc :
place_name COLON_TOKEN mapping SEMICOLON_TOKEN
{$$ := new element_record(arc);
$$.arc_place := $1;
$$.arc_mapping := $3;
set_pos($$);};

mapping :
tuples_combination
{$$ := new element_record(mapping);
$$.mapping_tuples := $1;
set_pos($$);};

tuples_combination :
tuple
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
append($$.list_elements, $1);
set_pos($$);
} |
tuples_combination PLUS_TOKEN tuple
{$$ := $1;
append($$.list_elements, $3);
set_pos($$);};

tuple :
tuple_vars tuple_guard simple_tuple
{$$ := new element_record(tuple);
$$.tuple_vars := $1;
$$.tuple_guard := $2;
$$.tuple_tuple := $3;
set_pos($$);};

tuple_vars :
FOR_TOKEN LBRACKET_TOKEN iteration_vars RBRACKET_TOKEN
{$$ := $3;} |
{$$ := null;};

tuple_guard :
IF_TOKEN LBRACKET_TOKEN expr RBRACKET_TOKEN
{$$ := $3;} |
{$$ := null;};

simple_tuple :
simple_tuple_factor simple_tuple_tuple
{$$ := new element_record(simple_tuple);
$$.Simple_Tuple_factor := $1;
$$.Simple_Tuple_tuple := $2;
set_pos($$);};

simple_tuple_factor :
expr TIMES_TOKEN
{$$ := $1;} |
{$$ := null;};

simple_tuple_tuple :
LTUPLE_TOKEN non_empty_expr_list RTUPLE_TOKEN
{$$ := $2;} |
EPSILON_TOKEN
{$$ := new element_record(List);
$$.list_elements := Empty_Element_list;
set_pos($$);};

transition_pick_vars :
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
set_pos($$);
} |
PICK_TOKEN LBRACE_TOKEN transition_pick_var_list RBRACE_TOKEN
{$$ := $3;};

transition_pick_var_list :
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
set_pos($$);
} |
transition_pick_var_list transition_pick_var
{$$ := $1;
append($$.list_elements, $2);
set_pos($$);};

transition_pick_var :
var_name IN_TOKEN expr iteration_var_range SEMICOLON_TOKEN
{$$ := new element_record(iter_variable);
$$.Iter_Variable_Name := $1;
$$.Iter_Variable_Domain := $3;
$$.Iter_Variable_Range := $4;
set_pos($$, $1); };

transition_let_vars :
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
set_pos($$);
} |
LET_TOKEN LBRACE_TOKEN transition_let_var_list RBRACE_TOKEN
{$$ := $3;};

transition_let_var_list :
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
set_pos($$);
} |
transition_let_var_list init_var_decl
{$$ := $1;
append($$.list_elements, $2);
set_pos($$);};

transition_attribute :
transition_guard
{$$ := $1;} |
transition_safe
{$$ := $1;} |
transition_priority
{$$ := $1;} |
transition_description
{$$ := $1;};

transition_attribute_list :
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
set_pos($$);} |
transition_attribute_list transition_attribute
{$$ := $1;
append($$.list_elements, $2);
set_pos($$);};

transition_guard :
GUARD_TOKEN COLON_TOKEN expr SEMICOLON_TOKEN 
{$$ := new element_record(transition_guard);
$$.transition_guard_def := $3;
set_pos($$);};

transition_safe :
SAFE_TOKEN SEMICOLON_TOKEN
{$$ := new element_record(transition_safe);
set_pos($$);};

transition_priority :
PRIORITY_TOKEN COLON_TOKEN expr SEMICOLON_TOKEN
{$$ := new element_record(transition_priority);
$$.transition_priority_def := $3;
set_pos($$);};

transition_description :
DESCRIPTION_TOKEN COLON_TOKEN string
transition_description_exprs SEMICOLON_TOKEN
{$$ := new element_record(transition_description);
$$.transition_description_desc := $3;
$$.transition_description_desc_exprs := $4;
set_pos($$);};

transition_description_exprs :
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
set_pos($$);} |
COMMA_TOKEN non_empty_expr_list
{$$ := $2;};




--===========================================================================--
--                               Propositions                                --
--===========================================================================--

proposition :
PROPOSITION_TOKEN identifier COLON_TOKEN expr SEMICOLON_TOKEN
{$$ := new element_record(proposition);
 $$.proposition_name := $2;
 $$.proposition_prop := $4;
 set_pos($$, $2); };





--===========================================================================--
--                                    Others                                 --
--===========================================================================--

identifier :
IDENTIFIER_TOKEN
{$$ := new element_record(name);
$$.name_name := Helena_Lex.get_token_value;
set_pos($$);};

string :
STRING_TOKEN
{$$ := new element_record(a_string);
$$.string_string := Helena_Lex.get_token_value;
$$.string_string := to_unbounded_string(Slice($$.string_string, 2,
					      length($$.string_string) - 1));
set_pos($$);};

net_name :
identifier
{$$ := $1;};

net_parameter_name :
identifier
{$$ := $1;};

property_name :
identifier
{$$ := $1;};

color_name :
identifier
{$$ := $1;};

sub_color_name :
identifier
{$$ := $1;};

type_name :
identifier
{$$ := $1;};

component_name :
identifier
{$$ := $1;};

func_name :
identifier
{$$ := $1;};

var_name :
identifier
{$$ := $1;};

place_name :
identifier
{$$ := $1;};

trans_name :
identifier
{$$ := $1;};

attribute_name :
identifier
{$$ := $1;};

number :
NUMBER_TOKEN
{$$ := new element_record(number);
$$.number_number := Helena_Lex.get_token_value;
set_pos($$);};

enum_const :
identifier
{$$ := $1;};

symbol :
identifier
{$$ := new element_record(symbol);
$$.sym := $1;
set_pos($$);};

iteration_vars :
iteration_var
{$$ := new element_record(list);
$$.list_elements := Empty_Element_list;
append($$.list_elements, $1);
set_pos($$);
} |
iteration_vars COMMA_TOKEN iteration_var
{$$ := $1;
append($$.list_elements, $3);
set_pos($$);};

iteration_var :
var_name IN_TOKEN expr iteration_var_range
{$$ := new element_record(iter_variable);
$$.Iter_Variable_Name := $1;
$$.Iter_Variable_Domain := $3;
$$.Iter_Variable_Range := $4;
set_pos($$);};

iteration_var_range :
{$$ := null;} |
range_spec
{$$ := $1;};

range_spec :
RANGE_TOKEN expr DOT_DOT_TOKEN expr
{$$ := new element_record(Low_High_Range);
$$.Low_High_Range_Low := $2;
$$.Low_High_Range_High := $4;
set_pos($$);};


%%


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

##

end Helena_Yacc;
