with
  Ada.Io_Exceptions,
  Ada.Unchecked_Deallocation,
  Helena_Parser.Errors,
  Helena_Parser.Main,
  Helena_Lex,
  Helena_Lex_Io,
  Helena_Yacc;

use
  Ada.Io_Exceptions,
  Helena_Parser.Errors,
  Helena_Parser.Main,
  Helena_Lex,
  Helena_Lex_Io,
  Helena_Yacc;

package body Helena_Parser is

   use Element_List_Pkg;

   package HYT renames Helena_Yacc_Tokens;

   procedure Deallocate is
      new Ada.Unchecked_Deallocation(Element_Record, Element);

   procedure Free
     (E: in out Element) is
      procedure Free_All is
         new Element_List_Pkg.Generic_Apply(Free);
   begin
      if E /= null then
         case E.T is
            when HYT.Net =>
               Free(E.Net_Name);
               Free(E.Net_Defs);
               Free(E.Net_Params);
            when HYT.Net_Param =>
               Free(E.Net_Param_Name);
               Free(E.Net_Param_Default);
	    when HYT.Color =>
               Free(E.Cls_Name);
               Free(E.Cls_Def);
            when HYT.Range_Color =>
               Free(E.Range_Color_Range);
            when HYT.Mod_Color =>
               Free(E.Mod_Val);
            when HYT.Enum_Color =>
               Free(E.Enum_Values);
            when HYT.Vector_Color =>
               Free(E.Vector_Indexes);
               Free(E.Vector_Elements);
            when HYT.Struct_Color =>
               Free(E.Struct_Components);
            when HYT.Component =>
               Free(E.Component_Name);
               Free(E.Component_Color);
            when HYT.List_Color =>
               Free(E.List_Color_Elements);
               Free(E.List_Color_Index);
               Free(E.List_Color_Capacity);
            when HYT.Set_Color =>
               Free(E.Set_Color_Elements);
               Free(E.Set_Color_Capacity);
            when HYT.Sub_Color =>
               Free(E.Sub_Cls_Name);
               Free(E.Sub_Cls_Parent);
               Free(E.Sub_Cls_Constraint);
            when HYT.Func_Prot =>
               Free(E.Func_Prot_Name);
               Free(E.Func_Prot_Params);
               Free(E.Func_Prot_Ret);
            when HYT.Func =>
               Free(E.Func_Name);
               Free(E.Func_Params);
               Free(E.Func_Return);
               Free(E.Func_Stat);
            when HYT.Param =>
               Free(E.Param_Name  );
               Free(E.Param_Color );
            when HYT.Var_Decl =>
               Free(E.Var_Decl_Name);
               Free(E.Var_Decl_Color);
               Free(E.Var_Decl_Init);
            when HYT.Num_Const =>
               Free(E.Num_Val);
            when HYT.Func_Call =>
               Free(E.Func_Call_Func);
               Free(E.Func_Call_Params);
            when HYT.Vector_Access =>
               Free(E.Vector_Access_Vector);
               Free(E.Vector_Access_Indexes);
            when HYT.Struct_Access =>
               Free(E.Struct_Access_Struct);
               Free(E.Struct_Access_Component);
            when HYT.Bin_Op =>
               Free(E.Bin_Op_Operator);
               Free(E.Bin_Op_Left_Operand);
               Free(E.Bin_Op_Right_Operand);
            when HYT.Un_Op =>
               Free(E.Un_Op_Operator);
               Free(E.Un_Op_Operand);
            when HYT.Vector_Aggregate =>
               Free(E.Vector_Aggregate_Elements);
            when HYT.Vector_Assign =>
               Free(E.Vector_Assign_Vector);
               Free(E.Vector_Assign_Index);
               Free(E.Vector_Assign_Expr);
            when HYT.Struct_Aggregate =>
               Free(E.Struct_Aggregate_Elements);
            when HYT.Struct_Assign =>
               Free(E.Struct_Assign_Struct);
               Free(E.Struct_Assign_Component);
               Free(E.Struct_Assign_Expr);
            when HYT.Iterator =>
               Free(E.Iterator_Iterator_Type);
               Free(E.Iterator_Variables);
               Free(E.Iterator_Condition);
               Free(E.Iterator_Expression);
            when HYT.Container_Aggregate =>
               Free(E.Container_Aggregate_Elements);
            when HYT.Symbol =>
               Free(E.Sym);
            when HYT.List_Slice =>
               Free(E.List_Slice_List);
               Free(E.List_Slice_First);
               Free(E.List_Slice_Last);
            when HYT.Assign =>
               Free(E.Assign_Var);
               Free(E.Assign_Val);
            when HYT.If_Then_Else =>
               Free(E.If_Then_Else_Cond);
               Free(E.If_Then_Else_True);
               Free(E.If_Then_Else_False);
            when HYT.Case_Stat =>
               Free(E.Case_Stat_Expression);
               Free(E.Case_Stat_Alternatives);
               Free(E.Case_Stat_Default);
            when HYT.Case_Alternative =>
               Free(E.Case_Alternative_Expr);
               Free(E.Case_Alternative_Stat);
            when HYT.While_Stat =>
               Free(E.While_Stat_Cond);
               Free(E.While_Stat_True);
            when HYT.Return_Stat =>
               Free(E.Return_Stat_Expr);
            when HYT.For_Stat =>
               Free(E.For_Stat_Vars);
               Free(E.For_Stat_Stat);
            when HYT.Block_Stat =>
               Free(E.Block_Stat_Vars);
               Free(E.Block_Stat_Seq);
            when HYT.Place =>
               Free(E.Place_Name);
               Free(E.Place_Dom);
               Free(E.Place_Attributes);
            when HYT.Place_Init =>
               Free(E.Place_Init_Mapping);
            when HYT.Place_Capacity =>
               Free(E.Place_Capacity_Expr);
            when HYT.Place_Type =>
               Free(E.Place_Type_Type);
            when HYT.Transition =>
               Free(E.Transition_Name);
               Free(E.Transition_Inputs);
               Free(E.Transition_Outputs);
               Free(E.Transition_Inhibits);
               Free(E.Transition_Attributes);
            when HYT.Transition_Guard =>
               Free(E.Transition_Guard_Def);
            when HYT.Transition_Priority =>
               Free(E.Transition_Priority_Def);
            when HYT.Transition_Description =>
               Free(E.Transition_Description_Desc);
               Free(E.Transition_Description_Desc_Exprs);
            when HYT.Arc =>
               Free(E.Arc_Place);
               Free(E.Arc_Mapping);
            when HYT.Mapping =>
               Free(E.Mapping_Tuples);
            when HYT.Tuple =>
               Free(E.Tuple_Vars);
               Free(E.Tuple_Tuple);
               Free(E.Tuple_Guard);
            when HYT.Simple_Tuple =>
               Free(E.Simple_Tuple_Factor);
               Free(E.Simple_Tuple_Tuple);
	    when HYT.Proposition =>
               Free(E.Proposition_Name);
               Free(E.Proposition_Prop);
	    when HYT.Tuple_Access =>
               Free(E.Tuple_Access_Tuple);
               Free(E.Tuple_Access_Component);
            when HYT.Attribute =>
               Free(E.Attribute_Element);
               Free(E.Attribute_Attribute);
            when HYT.Assert =>
               Free(E.Assert_Cond);
            when HYT.Iter_Variable =>
               Free(E.Iter_Variable_Name);
               Free(E.Iter_Variable_Domain);
               Free(E.Iter_Variable_Range);
            when HYT.Low_High_Range =>
               Free(E.Low_High_Range_Low);
               Free(E.Low_High_Range_High);
	    when HYT.List =>
               Free_All(E.List_Elements);
            when others =>
               null;
         end case;
         Deallocate(E);
         E := null;
      end if;
   end;

   procedure Parse_Net
     (File_Name: in     Ustring;
      N        :    out Pn.Nets.Net) is
      Ok        : Boolean;
      Parsed_Net: Element;
   begin
      Initialize_Parser(File_Name);
      Helena_Lex_Io.Open_Input(To_String(File_Name));
      Yyparse;
      Helena_Lex_Io.Close_Input;
      Parsed_Net := Get_Parsed_Element;
      Parse_Net(Parsed_Net, Ok);
      Free(Parsed_Net);
      if Get_Error_Msg /= Null_String then
         N := null;
         raise Parse_Exception;
      end if;
      N := Helena_Parser.N;
      Helena_Yacc.Finalize_Parser;
   exception
      when Ada.Io_Exceptions.Name_Error
        |  Ada.Io_Exceptions.Use_Error
        |  Ada.Io_Exceptions.Device_Error
        |  Ada.Io_Exceptions.Status_Error =>
         raise Io_Exception with
           To_String("could not open file '" & File_Name & "'");
      when Helena_Lex.Lexical_Exception =>
         Set_Error_Msg(To_String(Helena_Lex.Get_Error_Msg));
         raise Parse_Exception;
      when Helena_Yacc.Syntax_Exception =>
         Set_Error_Msg(To_String(Helena_Yacc.Get_Error_Msg));
         raise Parse_Exception;
   end;

   procedure Check_Type
     (E: in Element;
      T: in Element_Type) is
   begin
      pragma Assert(E.T = T);
      null;
   end;

   function Get_Error_Msg return Ustring is
   begin
      return Helena_Parser.Errors.Get_Error_Msg;
   end;

   function Pos_To_String
     (E: in Element) return Ustring is
   begin
      return E.File & ":" & E.Line;
   end;

end Helena_Parser;
