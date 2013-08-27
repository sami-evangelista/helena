with
  Helena_Parser.Errors,
  Helena_Parser.Exprs,
  Helena_Parser.Main,
  Pn.Classes,
  Pn.Stats.Assigns,
  Pn.Stats.Asserts,
  Pn.Stats.Blocks,
  Pn.Stats.Returns,
  Pn.Stats.Fors,
  Pn.Stats.Ifs,
  Pn.Stats.Whiles,
  Pn.Vars;

use
  Helena_Parser.Errors,
  Helena_Parser.Exprs,
  Helena_Parser.Main,
  Pn.Classes,
  Pn.Stats.Assigns,
  Pn.Stats.Asserts,
  Pn.Stats.Blocks,
  Pn.Stats.Returns,
  Pn.Stats.Fors,
  Pn.Stats.Ifs,
  Pn.Stats.Whiles,
  Pn.Vars;

package body Helena_Parser.Stats is

   use Element_List_Pkg;
   package VLLP renames Var_List_List_Pkg;
   package HYT  renames Helena_Yacc_Tokens;

   procedure Parse_Assign
     (E   : in     Element;
      F   : in     Pn.Funcs.Func;
      Vars: in out Var_List_List;
      S   :    out Stat;
      Ok  :    out Boolean) is
      Assign_Var: Expr;
      Assign_Val: Expr;
      Possible  : Cls_Set;
      C         : Cls;
   begin
      Check_Type(E, HYT.Assign);
      Parse_Basic_Expr(E.Assign_Var, Vars, Assign_Var, Ok);
      if Ok then
         if Is_Assignable(Assign_Var) then
            Parse_Basic_Expr(E.Assign_Val, Vars, Assign_Val, Ok);
            if Ok then
               Possible := Possible_Colors(Assign_Var, Get_Cls(N));
               if not (Card(Possible) = 1) then
                  Free(Possible);
                  S := null;
                  Ok := False;
                  return;
               end if;
               C := Ith(Possible, 1);
               Free(Possible);
               Color_Expr(E.Assign_Var, Assign_Var, C, Ok);
               if not Ok then
                  S := null;
                  Ok := False;
                  return;
               end if;
               Color_Expr(E.Assign_Val, Assign_Val, C, Ok);
               if Ok then
                  S := New_Assign_Stat(Assign_Var, Assign_Val);
                  Ok := True;
               else
                  Free(Assign_Var);
                  Free(Assign_Val);
               end if;
            else
               Free(Assign_Var);
            end if;
         else
            Add_Error
              (E.Assign_Var,
               "Expression is not a valid assignable expression");
            Free(Assign_Var);
         end if;
      end if;
   end;

   procedure Parse_If_Then_Else
     (E   : in     Element;
      F   : in     Pn.Funcs.Func;
      Vars: in out Var_List_List;
      S   :    out Stat;
      Ok  :    out Boolean) is
      Cond_Expr : Expr;
      True_Stat : Stat;
      False_Stat: Stat;
   begin
      Check_Type(E, If_Then_Else);

      --===
      --  parse the condition
      --===
      Parse_Basic_Expr(E.If_Then_Else_Cond, Bool_Cls, Vars, Cond_Expr, Ok);
      if not Ok then
         return;
      end if;

      --===
      --  parse the statement of the true part
      --===
      Parse_Stat(E.If_Then_Else_True, F, Vars, True_Stat, Ok);
      if not Ok then
         Free(Cond_Expr);
         return;
      end if;

      if E.If_Then_Else_False /= null then
         Parse_Stat(E.If_Then_Else_False, F, Vars, False_Stat, Ok);
         if Ok then
            S := New_If_Stat(Cond_Expr  => Cond_Expr,
                             True_Stat  => True_Stat,
                             False_Stat => False_Stat);
         else
            Free(True_Stat);
            Free(Cond_Expr);
         end if;
      else
         S := New_If_Stat(Cond_Expr  => Cond_Expr,
                          True_Stat  => True_Stat);
      end if;
   end;

   procedure Parse_Case_Alternative
     (E   : in     Element;
      C   : in     Cls;
      F   : in     Pn.Funcs.Func;
      Vars: in out Var_List_List;
      Alt :    out Pn.Stats.Cases.Case_Stat_Alternative;
      Ok  :    out Boolean) is
      Static   : Expr;
      Case_Ex  : Expr;
      Case_Stat: Stat;
      State    : Evaluation_State;
   begin
      Check_Type(E, HYT.Case_Alternative);
      Parse_Basic_Expr(E.Case_Alternative_Expr, C, Vars, Case_Ex, Ok);
      if Ok then
         if Is_Static(Case_Ex) then
            Evaluate_Static(E      => Case_Ex,
                            Check  => True,
                            Result => Static,
                            State  => State);
            if Is_Success(State) then
               if Is_Const_Of_Cls(C, Static) then
                  Parse_Stat
                    (E.Case_Alternative_Stat, F, Vars, Case_Stat, Ok);
                  if Ok then
                     Alt := New_Case_Stat_Alternative(Static, Case_Stat);
                  else
                     Free(Static);
                  end if;
               else
                  Add_Error(E.Case_Alternative_Expr,
                            "Invalid alternative expression");
                  Free(Static);
                  Ok := False;
               end if;
            else
               Add_Error(E.Case_Alternative_Expr,
                         "Error in alternative expression");
               Ok := False;
            end if;
            Free(Case_Ex);
         else
            Add_Error(E.Case_Alternative_Expr,
                      "Alternative expression cannot be evaluated statically");
            Free(Case_Ex);
            Ok := False;
         end if;
      end if;
   end;

   procedure Parse_Case_Alternatives
     (E   : in     Element;
      C   : in     Cls;
      F   : in     Pn.Funcs.Func;
      Vars: in out Var_List_List;
      Alts:    out Case_Stat_Alternative_List;
      Ok  :    out Boolean) is
      Alt: Pn.Stats.Cases.Case_Stat_Alternative;
   begin
      Alts := New_Case_Stat_Alternative_List;
      Check_Type(E, HYT.List);
      Ok := True;
      for I in 1..Length(E.List_Elements) loop
         Parse_Case_Alternative(Ith(E.List_Elements, I), C, F, Vars, Alt, Ok);
         if Ok then
            if not Contains(Alts, Get_Expr(Alt)) then
               Append(Alts, Alt);
            else
               Add_Error
                 (Ith(E.List_Elements, I), "Alternative redefinition");
               Free(Alt);
               Free(Alts);
               return;
            end if;
         end if;
      end loop;
   end;

   procedure Parse_Case
     (E   : in     Element;
      F   : in     Pn.Funcs.Func;
      Vars: in out Var_List_List;
      S   :    out Stat;
      Ok  :    out Boolean) is
      Case_Ex     : Expr;
      Possible    : Cls_Set;
      Alternatives: Case_Stat_Alternative_List;
      C           : Cls;
      Default     : Stat;
   begin
      Check_Type(E, HYT.Case_Stat);
      Parse_Basic_Expr(E.Case_Stat_Expression, Vars, Case_Ex, Ok);
      if Ok then
         Possible := Possible_Colors(Case_Ex, Get_Cls(N));
         if Card(Possible) = 1 then
            C := Ith(Possible, 1);
            Free(Possible);
            if Is_Discrete(C) then
               Color_Expr(E.Case_Stat_Expression, Case_Ex, C, Ok);
               if Ok then
                  Parse_Case_Alternatives(E.Case_Stat_Alternatives,
                                          C, F, Vars, Alternatives, Ok);
                  if Ok then
                     if E.Case_Stat_Default /= null then
                        Parse_Stat(E.Case_Stat_Default, F, Vars, Default,
                                   Ok);
                        if Ok then
                           S := New_Case_Stat(Case_Ex, Alternatives, Default);
                        end if;
                     else
                        S := New_Case_Stat(Case_Ex, Alternatives);
                     end if;
                  end if;
               end if;
            else
               Add_Error(E.Case_Stat_Expression,
                                "Case expression must be of discrete type");
               Ok := False;
            end if;
         else
            Add_Error(E.Case_Stat_Expression,
                             "Case expression has ambiguous type");
            Free(Possible);
            Ok := False;
         end if;
      end if;
   end;

   procedure Parse_While
     (E   : in     Element;
      F   : in     Pn.Funcs.Func;
      Vars: in out Var_List_List;
      S   :    out Stat;
      Ok  :    out Boolean) is
      Cond_Expr: Expr;
      True_Stat: Stat;
   begin
      Check_Type(E, HYT.While_Stat);
      Parse_Basic_Expr(E.While_Stat_Cond, Bool_Cls, Vars, Cond_Expr, Ok);
      if Ok then
         Parse_Stat(E.While_Stat_True, F, Vars, True_Stat, Ok);
         if Ok then
            S := New_While_Stat(Cond_Expr  => Cond_Expr,
                                True_Stat  => True_Stat);
         else
            Free(Cond_Expr);
         end if;
      end if;
   end;

   procedure Parse_Return
     (E   : in     Element;
      F   : in     Pn.Funcs.Func;
      Vars: in out Var_List_List;
      S   :    out Stat;
      Ok  :    out Boolean) is
      Ret_Expr: Expr;
      Ret_Cls : constant Cls := Get_Ret_Cls(F);
   begin
      Check_Type(E, HYT.Return_Stat);
      Parse_Basic_Expr(E.Return_Stat_Expr, Ret_Cls, Vars, Ret_Expr, Ok);
      if Ok then
         S := New_Return_Stat(Ret_Expr => Ret_Expr);
      end if;
   end;

   procedure Parse_For
     (E   : in     Element;
      F   : in     Pn.Funcs.Func;
      Vars: in out Var_List_List;
      S   :    out Stat;
      Ok  :    out Boolean) is
      It_Vars : Var_List;
      For_Stat: Stat;
      Types   : constant Var_Type_Set := (A_Discrete_Cls_Iter_Var => True,
                                          A_Container_Iter_Var    => True,
                                          others                  => False);
   begin
      Check_Type(E, HYT.For_Stat);
      It_Vars := New_Var_List;
      Parse_Iter_Var_List(E.For_Stat_Vars, False, Types, Vars, It_Vars, Ok);
      if not Ok then
	 Free_All(It_Vars);
      else
         VLLP.Append(Vars, It_Vars);
         Parse_Stat(E.For_Stat_Stat, F, Vars, For_Stat, Ok);
         VLLP.Delete_Last(Vars);
         if Ok then
            S := New_For_Stat(It_Vars, For_Stat);
         else
            Free(It_Vars);
         end if;
      end if;
   end;

   procedure Parse_Func_Var
     (E   : in     Element;
      Vars: in out Var_List_List;
      V   :    out Var;
      Ok  :    out Boolean) is
      C    : Cls;
      Name : Ustring;
      Init : Expr;
      Const: Boolean;
   begin
      Parse_Var_Items(E, Vars, Const, Name, C, Init, Ok);
      if Ok then
         V := New_Func_Var(Name, C, Init, E.Var_Decl_Const);
      end if;
   end;

   procedure Parse_Func_Vars
     (E    : in     Element;
      Vars : in out Var_List_List;
      Nvars: in out Var_List;
      Ok   :    out Boolean) is
      V: Var;
   begin
      Ok := True;
      Check_Type(E, HYT.List);
      for I in 1..Length(E.List_Elements) loop
	 VLLP.Append(Vars, Nvars);
         Parse_Func_Var(Ith(E.List_Elements, I), Vars, V, Ok);
	 VLLP.Delete_Last(Vars);
	 if not Ok then
            return;
	 else
	    Ok := not Contains(Nvars, Get_Name(V));
            if Ok then
               Append(Nvars, V);
            else
               Redefinition(E, To_Ustring("Variable"), Get_Name(V));
               return;
            end if;
         end if;
      end loop;
   end;

   procedure Parse_Block
     (E   : in     Element;
      F   : in     Pn.Funcs.Func;
      Vars: in out Var_List_List;
      S   :    out Stat;
      Ok  :    out Boolean) is
      procedure Parse_Stat_List
        (E   : in     Element;
         Vars: in out Var_List_List;
         S   :    out Stat_List;
         Ok  :    out Boolean) is
         Ith_Stat: Stat;
      begin
         Check_Type(E, HYT.List);
         S := New_Stat_List;
         for I in 1..Length(E.List_Elements) loop
            Parse_Stat(Ith(E.List_Elements, I), F, Vars, Ith_Stat, Ok);
            if Ok then
               Append(S, Ith_Stat);
            else
               Free(S);
               return;
            end if;
         end loop;
         Ok := True;
      end;
      Block_Vars: Var_List;
      Block_Stat: Stat_List;
   begin
      Check_Type(E, HYT.Block_Stat);
      Block_Vars := New_Var_List;
      Parse_Func_Vars(E.Block_Stat_Vars, Vars, Block_Vars, Ok);
      if not Ok then
	 Free_All(Block_Vars);
      else
	 VLLP.Append(Vars, Block_Vars);
         Parse_Stat_List(E.Block_Stat_Seq, Vars, Block_Stat, Ok);
         VLLP.Delete_Last(Vars);
         if Ok then
            S := New_Block_Stat(Block_Vars, Block_Stat);
         else
            Free_All(Block_Vars);
         end if;
      end if;
   end;

   procedure Parse_Assert
     (E   : in     Element;
      F   : in     Pn.Funcs.Func;
      Vars: in out Var_List_List;
      S   :    out Stat;
      Ok  :    out Boolean) is
      Cond: Expr;
   begin
      Check_Type(E, HYT.Assert);
      Parse_Basic_Expr(E.Assert_Cond, Bool_Cls, Vars, Cond, Ok);
      if Ok then
         S := New_Assert_Stat(New_Guard(Cond), F);
      end if;
   end;

   procedure Parse_Stat
     (E   : in     Element;
      F   : in     Pn.Funcs.Func;
      Vars: in out Var_List_List;
      S   :    out Stat;
      Ok  :    out Boolean) is
   begin
      case E.T is
         when HYT.Assign       => Parse_Assign      (E, F, Vars, S, Ok);
         when HYT.If_Then_Else => Parse_If_Then_Else(E, F, Vars, S, Ok);
         when HYT.Case_Stat    => Parse_Case        (E, F, Vars, S, Ok);
         when HYT.While_Stat   => Parse_While       (E, F, Vars, S, Ok);
         when HYT.Return_Stat  => Parse_Return      (E, F, Vars, S, Ok);
         when HYT.For_Stat     => Parse_For         (E, F, Vars, S, Ok);
         when HYT.Block_Stat   => Parse_Block       (E, F, Vars, S, Ok);
         when HYT.Assert       => Parse_Assert      (E, F, Vars, S, Ok);
         when others           => pragma Assert(False); null;
      end case;
   end;

end Helena_Parser.Stats;
