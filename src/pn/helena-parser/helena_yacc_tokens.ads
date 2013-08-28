with  Ada.strings.unbounded;
with  Utils.strings;
with  Generic_Array;
use   Ada.strings.unbounded;
use   Utils.strings;
package Helena_Yacc_Tokens is


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
      Underscore,

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
            Transition_Resets     : Element;
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
         when Underscore => null;
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

    YYLVal, YYVal : YYSType; 
    type Token is
        (End_Of_Input, Error, Assert_Token, And_Token,
         Capacity_Token, Card_Token, Case_Token,
         Constant_Token, Default_Token, Description_Token,
         Dom_Token, Else_Token, Empty_Token,
         Enum_Token, Epsilon_Token, Exists_Token,
         For_Token, Forall_Token, Function_Token,
         Guard_Token, If_Token, Import_Token,
         In_Token, Init_Token, Inhibit_Token,
         Let_Token, List_Token, Max_Token,
         Min_Token, Mod_Token, Mult_Token,
         Not_Token, Of_Token, Or_Token,
         Out_Token, Place_Token, Pick_Token,
         Pred_Token, Print_Token, Priority_Token,
         Product_Token, Proposition_Token, Range_Token,
         Reset_Token, Return_Token, Safe_Token,
         Set_Token, Struct_Token, Subtype_Token,
         Succ_Token, Sum_Token, Transition_Token,
         Type_Token, Vector_Token, While_Token,
         With_Token, Identifier_Token, Number_Token,
         String_Token, Amp_Token, Comma_Token,
         Div_Token, Dot_Dot_Token, Dot_Token,
         Eq_Token, Implies_Token, Inf_Token,
         Inf_Eq_Token, Lbrace_Token, Lbracket_Token,
         Lhook_Token, Ltuple_Token, Minus_Token,
         Neq_Token, Pipe_Token, Plus_Token,
         Question_Token, Quote_Token, Rbrace_Token,
         Rarrow_Token, Rbracket_Token, Rhook_Token,
         Rtuple_Token, Semicolon_Token, Sup_Token,
         Sup_Eq_Token, Times_Token, Colon_Token,
         Colon_Colon_Token, Colon_Equal_Token, Underscore_Token );

    Syntax_Error : exception;

end Helena_Yacc_Tokens;
