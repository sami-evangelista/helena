with
  Pn.Classes,
  Pn.Classes.Containers,
  Pn.Classes.Containers.Lists,
  Pn.Classes.Products,
  Pn.Classes.Vectors,
  Pn.Exprs.Bin_Ops,
  Pn.Exprs.Casts,
  Pn.Exprs.Attributes,
  Pn.Exprs.Attributes.Classes,
  Pn.Exprs.Attributes.Places,
  Pn.Exprs.Attributes.Containers,
  Pn.Exprs.Attributes.Lists,
  Pn.Exprs.Containers,
  Pn.Exprs.Empty_Containers,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Func_Calls,
  Pn.Exprs.If_Then_Elses,
  Pn.Exprs.Iterators,
  Pn.Exprs.List_Accesses,
  Pn.Exprs.List_Assigns,
  Pn.Exprs.List_Slices,
  Pn.Exprs.Num_Consts,
  Pn.Exprs.Struct_Assigns,
  Pn.Exprs.Struct_Accesses,
  Pn.Exprs.Tuple_Accesses,
  Pn.Exprs.Un_Ops,
  Pn.Exprs.Structs,
  Pn.Exprs.Var_Refs,
  Pn.Exprs.Vector_Assigns,
  Pn.Exprs.Vector_Accesses,
  Pn.Exprs.Vectors,
  Pn.Nodes,
  Pn.Vars,
  Helena_Parser.Errors,
  Helena_Parser.Main,
  Utils;

use
  Pn.Classes,
  Pn.Classes.Containers,
  Pn.Classes.Containers.Lists,
  Pn.Classes.Products,
  Pn.Classes.Vectors,
  Pn.Exprs.Bin_Ops,
  Pn.Exprs.Casts,
  Pn.Exprs.Attributes,
  Pn.Exprs.Attributes.Classes,
  Pn.Exprs.Attributes.Places,
  Pn.Exprs.Attributes.Containers,
  Pn.Exprs.Attributes.Lists,
  Pn.Exprs.Containers,
  Pn.Exprs.Empty_Containers,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Func_Calls,
  Pn.Exprs.If_Then_Elses,
  Pn.Exprs.Iterators,
  Pn.Exprs.List_Accesses,
  Pn.Exprs.List_Assigns,
  Pn.Exprs.List_Slices,
  Pn.Exprs.Num_Consts,
  Pn.Exprs.Structs,
  Pn.Exprs.Struct_Assigns,
  Pn.Exprs.Struct_Accesses,
  Pn.Exprs.Tuple_Accesses,
  Pn.Exprs.Un_Ops,
  Pn.Exprs.Var_Refs,
  Pn.Exprs.Vector_Assigns,
  Pn.Exprs.Vector_Accesses,
  Pn.Exprs.Vectors,
  Pn.Nodes,
  Pn.Vars,
  Helena_Parser.Errors,
  Helena_Parser.Main,
  Utils;

package body Helena_Parser.Exprs is

   use Element_List_Pkg;
   package VLLP renames Var_List_List_Pkg;
   package HYT  renames Helena_Yacc_Tokens;

   procedure Parse_Num_Const
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      Num: Big_Int;
   begin
      Check_Type(E, HYT.Num_Const);
      Parse_Number(E.Num_Val, Num, Ok);
      if Ok then
         Ok := Num in Big_Int(Num_Type'First) .. Big_Int(Num_Type'Last);
         if Ok then
            Ex := New_Num_Const(Num_Type(Num), null);
         else
            Add_Error
              (E,
               To_Ustring("Numerical constant must be in range ") &
               Num_Type'First & ".." & Num_Type'Last);
         end if;
      end if;
   end;

   procedure Parse_Var_Ref
     (E   : in     Element;
      Vars: in out Var_List_List;
      V   :    out Var;
      Ok  :    out Boolean) is
      V_Name: Ustring;
      Vs : Var_List;
   begin
      Parse_Name(E.Sym, V_Name);
      Ok := False;
      for I in reverse 1..VLLP.Length(Vars) loop
         Vs := VLLP.Ith(Vars, I);
         if Contains(Vs, V_Name) then
            V := Get(Vs, V_Name);
            Ok := True;
            exit;
         end if;
      end loop;
   end;

   procedure Parse_Func_Call
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      Name  : Ustring;
      F     : Pn.Funcs.Func;
      F_Dom : Dom;
      Params: Expr_List;
      Msg   : Ustring;
   begin
      Parse_Name(E.Func_Call_Func, Name);
      Check_Type(E.Func_Call_Params, HYT.List);
      F  := Get_Func(N, Name);
      F_Dom := Get_Dom(F);
      if Size(F_Dom) = Length(E.Func_Call_Params.List_Elements) then
         Parse_Expr_List
           (E.Func_Call_Params, Vars, F_Dom, True, Params, Ok);
         if Ok then
            Ex := New_Func_Call(F, Params);
         end if;
      else
         if Size(F_Dom) > Length(E.Func_Call_Params.List_Elements) then
            Msg := To_Ustring("few");
         else
            Msg := To_Ustring("many");
         end if;
         Msg := "Too " & Msg & " parameters in call to function " &
           Name & " (" & Size(F_Dom) & " parameters expected)";
         Add_Error(E.Func_Call_Func, Msg);
         Ok := False;
      end if;
   end;

   procedure Parse_Cast
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      Name     : Ustring;
      Cls_Cast : Cls;
      Cast_Expr: Expr;
      Possible : Cls_Set;
      Castable : Cls_Set;
      Expr_El  : Element;
      State    : Coloring_State;
      C        : Cls;
      function Is_Castable
        (D: in Cls) return Boolean is
      begin
         return Is_Castable(D, Cls_Cast);
      end;
      function Filter is new Generic_Filter(Is_Castable);
   begin
      --===
      --  check that exactly one expression is casted
      --===
      if Length(E.Func_Call_Params.List_Elements) /= 1 then
         if Length(E.Func_Call_Params.List_Elements) = 0 then
            Add_Error(E.Func_Call_Func, "Missing cast expression");
         else
            Add_Error(E.Func_Call_Func,
                      "Cannot cast more than one expression");
         end if;
         Ok := False;
         return;
      end if;

      --===
      --  parse the class in which the expression is casted
      --===
      Parse_Name(E.Func_Call_Func, Name);
      Cls_Cast := Get_Cls(N, Name);

      --===
      --  parse the expression casted
      --===
      Expr_El := Ith(E.Func_Call_Params.List_Elements, 1);
      Parse_Expr(Expr_El, Vars, Cast_Expr, Ok);
      if not Ok then return; end if;

      --===
      --  check that the type of the expression in the type in which the cast
      --  is done are compatible
      --===
      Possible := Possible_Colors(Cast_Expr, Get_Cls(N));
      Castable := Filter(Possible);
      Free(Possible);
      if Is_Empty(Castable) then
         Add_Error(Expr_El, "Invalid cast");
         Free(Castable);
         Free(Cast_Expr);
         Ok := False;
         return;
      end if;

      --===
      --  cast the expression
      --===
      Choose(Castable, C, State);
      Free(Castable);
      case State is
         when Coloring_Ambiguous_Expression =>
            Add_Error(E, "Cast expression has ambiguous type");
            Free(Cast_Expr);
            Ok := False;
         when Coloring_Failure =>
            Add_Error(E, "Cast expression has undefined type");
            Free(Cast_Expr);
            Ok := False;
         when Coloring_Success =>
            Ex := New_Cast(Cls_Cast, Cast_Expr);
      end case;
   end;

   procedure Parse_Func_Call_Or_Cast
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      Name: Ustring;
   begin
      Check_Type(E, HYT.Func_Call);
      Parse_Name(E.Func_Call_Func, Name);
      Check_Type(E.Func_Call_Params, HYT.List);
      if    Is_Func(N, Name) then
         Parse_Func_Call(E, Vars, Ex, Ok);
      elsif Is_Cls(N, Name)  then
         Parse_Cast(E, Vars, Ex, Ok);
      else
         Undefined(E.Func_Call_Func, To_Ustring("Function"), Name);
         Ok := False;
      end if;
   end;

   procedure Parse_Vector_Or_List_Access
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      Container : Expr;
      Indexes   : Expr_List;
      Possible  : Cls_Set;
      C         : Cls;
      D         : Dom;
      Msg       : Ustring;
      Index     : Expr;
      Index_Elem: Element;
   begin
      Check_Type(E, HYT.Vector_Access);
      Check_Type(E.Vector_Access_Indexes, HYT.List);

      --===
      --  parse the accessed vector or list
      --===
      Parse_Expr(E.Vector_Access_Vector, Vars, Container, Ok);
      if not Ok then
         return;
      end if;

      --===
      --  filter the possible colors to get only vector or list colors
      --===
      Possible := Possible_Colors(Container, Get_Cls(N));
      Filter_On_Type(Possible, (A_Vector_Cls => True,
                                A_List_Cls   => True,
                                others       => False));

      --===
      --  there must be only one possible type for the vector or list accessed
      --===
      if Card(Possible) /= 1 then
         if Card(Possible) > 1 then
            Add_Error(E.Vector_Access_Vector,
                      "Accessed vector has ambiguous type");
         else
            Add_Error
              (E.Vector_Access_Vector,
               "Vector or list required in indexed component");
         end if;
         Free(Container);
         Free(Possible);
         Ok := False;
         return;
      end if;

      C := Ith(Possible, 1);
      Free(Possible);
      if Get_Type(C) = A_List_Cls then

         --===
         --  access to a list element
         --===
         if Length(E.Vector_Access_Indexes.List_Elements) /= 1 then
            Add_Error(E, "Invalid arguments in list reference");
            Free(Container);
            Ok := False;
            return;
         end if;
         Index_Elem := Ith(E.Vector_Access_Indexes.List_Elements, 1);
         Parse_Expr
           (Index_Elem, Get_Index_Cls(List_Cls(C)), Vars, Index, Ok);
         if not Ok then Free(Container); return; end if;
         Ex := New_List_Access(L => Container,
                               I => Index,
                               C => null);

      elsif Get_Type(C) = A_Vector_Cls then

         --===
         --  access to a vector element
         --===
         D := Get_Index_Dom(Vector_Cls(C));
         if Size(D) /= Length(E.Vector_Access_Indexes.List_Elements) then
            if Size(D) < Length(E.Vector_Access_Indexes.List_Elements) then
               Msg := To_Ustring("many");
            else
               Msg := To_Ustring("few");
            end if;
            Msg := "Too " & Msg & " arguments in vector reference";
            Add_Error(E, Msg);
            Free(Container);
            Ok := False;
            return;
         end if;
         Parse_Expr_List
           (E.Vector_Access_Indexes, Vars, D, True, Indexes, Ok);
         if not Ok then Free(Container); return; end if;
         Ex := New_Vector_Access(V => Container,
                                 I => Indexes,
                                 C => null);

      else
         pragma Assert(False);
         null;
      end if;
   end;

   procedure Parse_Struct_Access
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      Struct        : Expr;
      Component_Name: Ustring;
      Possible      : Cls_Set;
      C             : Pn.Classes.Structs.Struct_Cls;
      Component     : Struct_Comp;
      Has_Color     : Boolean;
      Msg           : Ustring;
   begin
      Check_Type(E, HYT.Struct_Access);

      --===
      --  parse the component and the struct
      --===
      Parse_Name(E.Struct_Access_Component, Component_Name);
      Parse_Expr(E.Struct_Access_Struct, Vars, Struct, Ok);
      if not Ok then return; end if;

      Possible := Possible_Colors(Struct, Get_Cls(N));
      Has_Color := not Is_Empty(Possible);
      Filter_On_Type(Possible, (A_Struct_Cls => True,
                                others       => False));
      if Card(Possible) = 1 then
         C := Pn.Classes.Structs.Struct_Cls(Ith(Possible, 1));
         if Contains_Component(C, Component_Name) then
            Ex := New_Struct_Access(Struct, Component_Name, null);
            Ok := True;
         else
            Add_Error
              (E.Struct_Access_Component,
               Component_Name & " is not a component of struct type " &
               Get_Name(Cls(C)));
            Free(Struct);
            Ok := False;
         end if;
         Free(Possible);
      else
         if Card(Possible) > 1 or not Has_Color then
            Msg := To_Ustring("Accessed struct has undefined type");
         else
            Msg := "Invalid prefix for component " & Component_Name;
         end if;
         Add_Error(E.Struct_Access_Struct, Msg);
         Free(Struct);
         Free(Possible);
         Ok := False;
      end if;
   end;

   procedure Parse_Bin_Op
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      procedure Parse_Bin_Operator
        (E : in     Element;
         Op:    out Bin_Operator) is
      begin
         case E.T is
            when Minus_Op  => Op := Minus_Op;
            when Plus_Op   => Op := Plus_Op;
            when Mult_Op   => Op := Mult_Op;
            when Div_Op    => Op := Div_Op;
            when Mod_Op    => Op := Mod_Op;
            when And_Op    => Op := And_Op;
            when Or_Op     => Op := Or_Op;
            when Sup_Op    => Op := Sup_Op;
            when Sup_Eq_Op => Op := Sup_Eq_Op;
            when Inf_Op    => Op := Inf_Op;
            when Inf_Eq_Op => Op := Inf_Eq_Op;
            when Eq_Op     => Op := Eq_Op;
            when Neq_Op    => Op := Neq_Op;
            when Amp_Op    => Op := Concat_Op;
            when In_Op     => Op := In_Op;
            when others    => pragma Assert(False); null;
         end case;
      end;
      Lo            : Expr;
      Ro            : Expr;
      Possible      : Cls_Set;
      Left_Possible : Cls_Set;
      Right_Possible: Cls_Set;
      Op            : Bin_Operator;
   begin
      Check_Type(E, HYT.Bin_Op);

      --===
      --  parse the operands and the operator
      --===
      Parse_Expr(E.Bin_Op_Left_Operand, Vars, Lo, Ok);
      if not Ok then           return; end if;
      Parse_Expr(E.Bin_Op_Right_Operand, Vars, Ro, Ok);
      if not Ok then Free(Lo); return; end if;
      Parse_Bin_Operator(E.Bin_Op_Operator, Op);

      Ex := New_Bin_Op(Op, Lo, Ro, null);

      --===
      --  check that the operator is defined for the operand
      --===
      Possible := Possible_Colors(Ex, Get_Cls(N));
      Ok    := not Is_Empty(Possible);
      Free(Possible);
      if not Ok then
         Left_Possible := Possible_Colors(Lo, Get_Cls(N));
         Right_Possible := Possible_Colors(Ro, Get_Cls(N));
         Add_Error
           (E, "Wrong operands for operator '" & To_Helena(Op) & "'.");
         Add_Error
           (E, "Left operand has type in " & To_String(Left_Possible));
         Add_Error
           (E, "Right operand has type in " & To_String(Right_Possible));
         Free(Left_Possible);
         Free(Right_Possible);
         Free(Ex);
      end if;
   end;

   procedure Parse_Un_Op
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      procedure Parse_Un_Operator
        (E : in     Element;
         Op:    out Un_Operator) is
      begin
         case E.T is
            when HYT.Pred_Op  => Op := Pred_Op;
            when HYT.Succ_Op  => Op := Succ_Op;
            when HYT.Plus_Op  => Op := Plus_Uop;
            when HYT.Minus_Op => Op := Minus_Uop;
            when HYT.Not_Op   => Op := Not_Op;
            when others       => pragma Assert(False); null;
         end case;
      end;
      Possible: Cls_Set;
      Operand : Cls_Set;
      O       : Expr;
      Op      : Un_Operator;
   begin
      Check_Type(E, HYT.Un_Op);

      --===
      --  parse the operand and the operator
      --===
      Parse_Expr(E.Un_Op_Operand, Vars, O, Ok);
      if not Ok then return; end if;
      Parse_Un_Operator(E.Un_Op_Operator, Op);

      Ex := New_Un_Op(Op, O, null);

      --===
      --  check that the operator is defined for the operand
      --===
      Possible := Possible_Colors(Ex, Get_Cls(N));
      Ok    := not Is_Empty(Possible);
      Free(Possible);
      if not Ok then
         Operand := Possible_Colors(O, Get_Cls(N));
         Add_Error(E,
                   "Wrong operand for operator '" & To_Helena(Op) & "'.");
         Add_Error(E,
                   "Operand has type in " & To_String(Operand));
         Free(Operand);
         Free(Ex);
      end if;
   end;

   procedure Parse_Vector_Aggregate
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      Ith_Possible: Cls_Set;
      New_Possible: Cls_Set;
      Possible    : Cls_Set;
      El          : Expr_List;
      Ith_Expr    : Expr;
   begin
      Check_Type(E, HYT.Vector_Aggregate);

      --===
      --  parse the expression list in the aggregate
      --===
      Parse_Expr_List
        (E.Vector_Aggregate_Elements, Vars, Null_Dom, False, El, Ok);
      if not Ok then return; end if;

      --===
      --  expressions in the aggregate must be of the same type
      --===
      for I in 1..Length(El) loop
         Ith_Expr := Ith(El, I);
         Ith_Possible := Possible_Colors(Ith_Expr, Get_Cls(N));
         if I = 1 then
            Possible := Ith_Possible;
         else
            New_Possible := Intersect(Possible, Ith_Possible);
            Free(Possible);
            Free(Ith_Possible);
            Possible := New_Possible;
         end if;
         if Is_Empty(Possible) then
            Add_Error(E, "Elements in aggregate have different types");
            Ok := False;
            return;
         end if;
      end loop;

      Ex    := New_Vector(El, null);
      Possible := Possible_Colors(Ex, Get_Cls(N));
      Ok    := not Is_Empty(Possible);
      Free(Possible);
      if not Ok then
         Add_Error(E, "Vector has undefined type");
         Free(Ex);
         Ok := False;
      end if;
   end;

   procedure Parse_Struct_Aggregate
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      El      : Expr_List;
      Possible: Cls_Set;
   begin
      Check_Type(E, HYT.Struct_Aggregate);

      --===
      --  parse the expression list of the aggregate
      --===
      Parse_Expr_List
        (E.Struct_Aggregate_Elements, Vars, Null_Dom, False, El, Ok);
      if not Ok then return; end if;

      Ex := New_Struct(El, null);
      Possible := Possible_Colors(Ex, Get_Cls(N));

      --===
      --  the set of potential colors must not be empty
      --===
      Ok := not Is_Empty(Possible);
      Free(Possible);
      if not Ok then
         Add_Error(E, "Struct has undefined type");
         Free(Ex);
      end if;
   end;

   procedure Parse_Container_Aggregate
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      Ith_Possible: Cls_Set;
      New_Possible: Cls_Set;
      Possible    : Cls_Set;
      El          : Expr_List;
      Ith_Expr    : Expr;
   begin
      Check_Type(E, HYT.Container_Aggregate);

      --===
      --  parse the expression list
      --===
      Parse_Expr_List
        (E.Container_Aggregate_Elements, Vars, Null_Dom, False, El, Ok);
      if not Ok then
         return;
      end if;

      --===
      --  each expression of the container must be of the same type
      --===
      for I in 1..Length(El) loop
         Ith_Expr  := Ith(El, I);
         Ith_Possible := Possible_Colors(Ith_Expr, Get_Cls(N));
         if I = 1 then
            Possible := Ith_Possible;
         else
            New_Possible := Intersect(Possible, Ith_Possible);
            Free(Possible);
            Free(Ith_Possible);
            Possible := New_Possible;
         end if;
         if Is_Empty(Possible) then
            Add_Error(E, "Elements in container have different types");
            Ok := False;
            Free(Possible);
            return;
         end if;
      end loop;
      Free(Possible);

      Ex := New_Container(El, null);
      Possible := Possible_Colors(Ex, Get_Cls(N));
      if Is_Empty(Possible) then
         Add_Error(E, "Container has undefined type");
         Free(Ex);
         Ok := False;
      else
         Ok := True;
      end if;
      Free(Possible);
   end;

   procedure Parse_Vector_Or_List_Assign
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      C       : Cls;
      Possible: Cls_Set := null;
      V       : Expr := null;
      Vi      : Expr_List := null;
      Li      : Expr := null;
      Assigned: Expr := null;

      procedure Free is
      begin
         if Possible /= null then Free(Possible); end if;
         if Assigned /= null then Free(Assigned); end if;
         if V        /= null then Free(V);        end if;
         if Vi       /= null then Free_All(Vi);   end if;
         if Li       /= null then Free(Li);       end if;
      end;

   begin
      Check_Type(E, HYT.Vector_Assign);

      --===
      --  parse the vector or list
      --===
      Parse_Expr(E.Vector_Assign_Vector, Vars, V, Ok);
      if not Ok then Free; return; end if;

      --===
      --  get the potential colors of the vector or list
      --===
      Possible := Possible_Colors(V, Get_Cls(N));
      Filter_On_Type(Possible, (A_Vector_Cls => True,
                                A_List_Cls   => True,
                                others       => False));
      if Is_Empty(Possible) then
         Add_Error(E, "Vector or list expression expected");
         Free;
         Ok := False;
         return;
      end if;

      C := Ith(Possible, 1);
      Free(Possible);

      if Get_Type(C) = A_Vector_Cls then  --  assignment to vector

         --===
         --  parse the index
         --===
         Parse_Expr_List
           (E.Vector_Assign_Index, Vars,
            Get_Index_Dom(Vector_Cls(C)), True, Vi, Ok);
         if not Ok then Free; return; end if;

         --===
         --  parse the expression assigned
         --===
         Parse_Expr
           (E.Vector_Assign_Expr,
            Get_Elements_Cls(Vector_Cls(C)), Vars, Assigned, Ok);
         if not Ok then Free; return; end if;

         Ex := New_Vector_Assign(V, Vi, Assigned, null);

      else  --  assignment to list

         --===
         --  check that there is only one index
         --===
         Check_Type(E.Vector_Assign_Index, List);
         if Length(E.Vector_Assign_Index.List_Elements) /= 1 then
            Add_Error(E.Vector_Assign_Index, "Invalid list index");
            Free;
            Ok := False;
            return;
         end if;

         --===
         --  parse the index
         --===
         Parse_Expr
           (First(E.Vector_Assign_Index.List_Elements),
            Get_Index_Cls(List_Cls(C)), Vars, Li, Ok);
         if not Ok then Free; return; end if;

         --===
         --  parse the expression assigned
         --===
         Parse_Expr
           (E.Vector_Assign_Expr,
            Get_Elements_Cls(Container_Cls(C)), Vars, Assigned, Ok);
         if not Ok then Free; return; end if;

         Ex := New_List_Assign(V, Li, Assigned, null);

      end if;
   end;

   procedure Parse_Struct_Assign
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      Struct        : Expr;
      Value         : Expr;
      Component_Name: Ustring;
      Possible      : Cls_Set;
      C             : Pn.Classes.Structs.Struct_Cls;
      Component     : Struct_Comp;
      Component_Cls : Cls;
      Has_Color     : Boolean;
      Msg           : Ustring;
   begin
      Check_Type(E, HYT.Struct_Assign);

      --===
      --  parse the name of the Component and the struct assigned
      --===
      Parse_Name(E.Struct_Assign_Component, Component_Name);
      Parse_Expr(E.Struct_Assign_Struct, Vars, Struct, Ok);
      if not Ok then return; end if;

      --===
      --  get the potential colors of the structure
      --===
      Possible := Possible_Colors(Struct, Get_Cls(N));
      Has_Color := not Is_Empty(Possible);
      Filter_On_Type(Possible, (A_Struct_Cls => True,
                                others       => False));
      if Card(Possible) /= 1 then
         if Card(Possible) > 1 or not Has_Color then
            Msg := To_Ustring("Accessed struct has undefined type");
         else
            Msg := "Invalid prefix for component " & Component_Name;
         end if;
         Add_Error(E.Struct_Assign_Struct, Msg);
         Free(Struct);
         Free(Possible);
         Ok := False;
         return;
      end if;

      C := Pn.Classes.Structs.Struct_Cls(Ith(Possible, 1));
      Free(Possible);

      --===
      --  check that the component belongs to the structure
      --===
      if not Contains_Component(C, Component_Name) then
         Add_Error
           (E.Struct_Assign_Component,
            Component_Name & " is not a component of struct type " &
            Get_Name(Cls(C)));
         Free(Struct);
         Ok := False;
         return;
      end if;

      Component  := Get_Component(C, Component_Name);
      Component_Cls := Get_Cls(Component);

      --===
      --  parse the assigned expression
      --===
      Parse_Expr
        (E.Struct_Assign_Expr, Component_Cls, Vars, Value, Ok);
      if Ok then
         Ex := New_Struct_Assign(Struct, Component_Name, Value, null);
      else
         Free(Struct);
      end if;
   end;

   procedure Parse_If_Then_Else
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      Cond_Expr     : Expr;
      True_Expr     : Expr;
      False_Expr    : Expr;
      Possible      : Cls_Set;
      True_Possible : Cls_Set;
      False_Possible: Cls_Set;
   begin
      Check_Type(E, HYT.If_Then_Else);

      --===
      --  parse the condition and check it is a boolean expression
      --===
      Parse_Expr(E.If_Then_Else_Cond, Bool_Cls, Vars, Cond_Expr, Ok);
      if not Ok then
         return;
      end if;

      --===
      --  parse the true part
      --===
      Parse_Expr(E.If_Then_Else_True, Vars, True_Expr, Ok);
      if not Ok then
         Free(Cond_Expr);
         return;
      end if;

      --===
      --  parse the false part
      --===
      Parse_Expr(E.If_Then_Else_False, Vars, False_Expr, Ok);
      if not Ok then
         Free(True_Expr);
         Free(Cond_Expr);
         return;
      end if;

      Ex := New_If_Then_Else(If_Cond    => Cond_Expr,
                             True_Expr  => True_Expr,
                             False_Expr => False_Expr);

      --===
      --  check that the resulting expression is valid
      --===
      Possible := Possible_Colors(Ex, Get_Cls(N));
      Ok := not Is_Empty(Possible);
      Free(Possible);
      if not Ok then
         True_Possible := Possible_Colors(True_Expr,  Get_Cls(N));
         False_Possible := Possible_Colors(False_Expr, Get_Cls(N));
         Add_Error(E, "Wrong operands for operator ':'.");
         Add_Error(E, "Left operand has type in " &
                   To_String(True_Possible));
         Add_Error(E, "Right operand has type in " &
                   To_String(False_Possible));
         Free(Ex);
         Free(True_Possible);
         Free(False_Possible);
         Ok := False;
      end if;
   end;

   procedure Parse_Iterator
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      T      : Iterators.Iterator_Type;
      V      : Var;
      Vl     : Var_List;
      Ivl    : Var_List;
      It_Cond: Expr;
      It_Expr: Expr;
      Types  : Var_Type_Set;
   begin
      Ok := False;
      Check_Type(E, HYT.Iterator);

      --===
      --  get the iterator type
      --===
      case E.Iterator_Iterator_Type.T is
         when Forall_Iterator  => T := A_Forall;
         when Exists_Iterator  => T := A_Exists;
         when Min_Iterator     => T := A_Min;
         when Max_Iterator     => T := A_Max;
         when Sum_Iterator     => T := A_Sum;
         when Product_Iterator => T := A_Product;
         when Card_Iterator    => T := A_Card;
         when Mult_Iterator    => T := A_Mult;
         when others           => pragma Assert(False); null;
      end case;

      --===
      --  create the list of iteration variables inherited from enclosing
      --  iterators
      --===
      Ivl := New_Var_List;
      for I in 1..VLLP.Length(Vars) loop
	 Vl := VLLP.Ith(Vars, I);
	 for J in 1..Length(Vl) loop
	    V := Ith(Vl, J);
	    if
	      Get_Type(V) = A_Discrete_Cls_Iter_Var or
	      Get_Type(V) = A_Place_Iter_Var or
	      Get_Type(V) = A_Container_Iter_Var
	    then
	       Append(Ivl, V);
	    end if;
	 end loop;
      end loop;

      --===
      --  only place iteration variables are allowed for the mult operator
      --===
      if T = A_Mult then
         Types := (A_Place_Iter_Var => True,
                   others           => False);
      else
         Types := (A_Discrete_Cls_Iter_Var => True,
                   A_Place_Iter_Var        => True,
                   A_Container_Iter_Var    => True,
                   others                  => False);
      end if;

      --===
      --  parse the iteration variables
      --===
      Vl := New_Var_List;
      Parse_Iter_Var_List(E.Iterator_Variables, False, Types, Vars, Vl, Ok);
      if not Ok then
	 Free_All(Vl);
         return;
      end if;

      --===
      --  if the iterator is mult then a single iteration variable is
      --  allowed
      --===
      if T = A_Mult and then Length(Vl) > 1 then
         Ok := False;
         Add_Error
           (E.Tuple_Access_Tuple,
            "A single iteration variable is allowed for iterator mult");
         return;
      end if;

      --===
      --  parse the condition of the iterator
      --===
      VLLP.Append(Vars, Vl);
      if E.Iterator_Condition /= null then
         Parse_Expr(E.Iterator_Condition, Bool_Cls, Vars, It_Cond, Ok);
         if not Ok then
            VLLP.Delete_Last(Vars);
            return;
         end if;
      else
         Ok   := True;
         It_Cond := null;
      end if;

      --===
      --  parse the expression of the iterator
      --===
      if E.Iterator_Expression /= null then
         Parse_Expr(E.Iterator_Expression, Vars, It_Expr, Ok);
         if Ok then
            case T is
               when A_Forall =>
                  Ensure_Bool(E.Iterator_Expression, It_Expr, Ok);
               when A_Min
                 |  A_Max =>
                  Ensure_Discrete(E.Iterator_Expression, It_Expr, Ok);
               when A_Sum
                 |  A_Product =>
                  Ensure_Num(E.Iterator_Expression, It_Expr, Ok);
               when A_Card
                 |  A_Mult
                 |  A_Exists =>
                  null;
            end case;
            if not Ok then
               Free(It_Expr);
            end if;
         end if;
      else
         Ok   := True;
         It_Expr := null;
      end if;
      VLLP.Delete_Last(Vars);

      if Ok then
         Ex := New_Iterator(Vl, Ivl, T, It_Cond, It_Expr, null);
      else
         Free(Vl);
         if It_Cond /= null then
            Free(It_Cond);
         end if;
      end if;
   end;

   procedure Parse_Tuple_Access
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      Token    : Var;
      Component: Big_Int;
      C        : Pn.Classes.Products.Product_Cls;
   begin
      Check_Type(E, HYT.Tuple_Access);

      --===
      --  parse the tuple
      --===
      Parse_Var_Ref(E.Tuple_Access_Tuple, Vars, Token, Ok);
      if not Ok then
         Add_Error(E.Tuple_Access_Tuple, "Undefined variable");
         return;
      end if;

      --===
      --  check the variable has a product type
      --===
      Ok := Get_Type(Get_Cls(Token)) = A_Product_Cls;
      if not Ok then
         Add_Error(E.Tuple_Access_Tuple,
                   Get_Name(Token) & " has not a product type");
         return;
      end if;
      C := Pn.Classes.Products.Product_Cls(Get_Cls(Token));

      --===
      --  parse the number of the accessed component
      --===
      Parse_Number(E.Tuple_Access_Component, Component, Ok);
      if not Ok then
         return;
      end if;

      --===
      --  check that component number is valid
      --===
      Ok := Component in 1..Big_Int(Size(Get_Dom(C)));
      if not Ok then
         Add_Error
           (E.Tuple_Access_Tuple, "Invalid component reference");
         Add_Error
           (E.Tuple_Access_Tuple,
            "Component must be in range [1.." & Size(Get_Dom(C)) & "]");
         return;
      end if;

      Ex := New_Tuple_Access(New_Var_Ref(Token), Integer(Component), null);
   end;

   procedure Parse_Attribute
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      C             : Cls;
      P             : Pn.Nodes.Places.Place;
      Attribute     : Pn.Exprs.Attributes.Attribute_Type;
      Element_Name  : Ustring;
      Attribute_Name: Ustring;
      Error         : Ustring;
      Sc            : Card_Type;
      State         : Count_State;
      Ex_Attribute  : Expr;
      Possible      : Cls_Set;
      Is_Place      : Boolean := False;
      Is_Cls        : Boolean := False;
   begin
      Check_Type(E, HYT.Attribute);

      --===
      --  get the attribute
      --===
      Parse_Name(E.Attribute_Attribute, Attribute_Name);
      Get_Attribute(To_String(Attribute_Name), Attribute, Ok);
      if not Ok then
         Undefined(E.Attribute_Attribute, To_Ustring("Attribute"),
                   Attribute_Name);
         return;
      end if;

      --===
      --  get the element of the attribute. check if it is a place, a class,
      --  or an expression
      --===
      if E.Attribute_Element.T = Symbol then
         Parse_Name(E.Attribute_Element.Sym, Element_Name);
         Is_Place := Pn.Nets.Is_Place(N, Element_Name);
         Is_Cls := Pn.Nets.Is_Cls  (N, Element_Name);
      end if;

      if Is_Place then

         --===
         --  the attribute is applied on a place
         --===
         P := Get_Place(N, Element_Name);
         case Attribute is
            when A_Mult
              |  A_Card =>
               Ex := New_Place_Attribute(P, Attribute, null);
               Ok := True;
               return;
            when others =>
               if not Is_Cls then
                  Add_Error(E.Attribute_Attribute,
                            Attribute_Name &
                            ": invalid attribute for place " & Get_Name(P));
                  Ok := False;
                  return;
               end if;
         end case;
      end if;

      if Is_Cls then

         --===
         --  the attribute is applied on a color class
         --===
         C := Get_Cls(N, Element_Name);
         case Attribute is
            when A_First
              |  A_Last
              |  A_Card =>
               Ok := True;
            when others =>
               Add_Error(E.Attribute_Attribute,
                         Attribute_Name &
                         ": invalid attribute for type " & Get_Name(C));
               Ok := False;
         end case;
         if not Ok then return; end if;
         Ensure_Discrete(E.Attribute_Element, C, Ok);
         if not Ok then return; end if;
         if Attribute = A_Card then
            Card(C, Sc, State);
            Ok := Is_Success(State) or else Sc > Card_Type(Num_Type'Last);
            if not Ok then
               Add_Error
                 (E.Attribute_Element,
                  "Type " & Element_Name & " is too large to be enumerated");
            end if;
         end if;
         if not Ok then return; end if;
         Ex := New_Cls_Attribute(C, Attribute, null);
      end if;

      if not Is_Cls and not Is_Place then

         --===
         --  the attribute is applied on an expression
         --===
         Parse_Expr(E.Attribute_Element, Vars, Ex_Attribute, Ok);
         if not Ok then return; end if;
         Possible := Possible_Colors(Ex_Attribute, Get_Cls(N));
         if Card(Possible) = 0 then
            Add_Error
              (E.Attribute_Element,
               "Prefix of attribute " & Attribute_Name &
               " has undefined type");
            Free(Ex_Attribute);
            Free(Possible);
            Ok := False;
            return;
         end if;
         declare
            procedure Check_Prefix
              (Types: in     Cls_Type_Set;
               Ok   :    out Boolean) is
            begin
               Filter_On_Type(Possible, Types);
               Ok := Card(Possible) = 1;
               if not Ok then
                  if Card(Possible) > 1 then
                     Add_Error
                       (E.Attribute_Element,
                        "Prefix of attribute " & Attribute_Name &
                        " has ambiguous type");
                  else
                     Add_Error
                       (E.Attribute_Element,
                        "Invalid prefix for attribute " & Attribute_Name);
                  end if;
                  Free(Ex_Attribute);
               end if;
            end;
         begin
            case Attribute is
               when A_First
                 |  A_First_Index
                 |  A_Last
                 |  A_Last_Index
                 |  A_Prefix
                 |  A_Suffix =>
                  Check_Prefix((A_List_Cls => True,
                                others     => False), Ok);
                  Free(Possible);
                  if not Ok then return; end if;
                  Ex := New_List_Attribute(Ex_Attribute, Attribute, null);

               when A_Capacity
                 |  A_Full
                 |  A_Empty
                 |  A_Space
                 |  A_Size =>
                  Check_Prefix((A_List_Cls => True,
                                A_Set_Cls  => True,
                                others     => False), Ok);
                  Free(Possible);
                  if not Ok then return; end if;
                  Ex := New_Container_Attribute(Ex_Attribute, Attribute, null);

               when others =>
                  Add_Error
                    (E.Attribute_Element,
                     "Invalid prefix for attribute " & Attribute_Name);
                  Ok := False;
            end case;
         end;
      end if;
   end;

   procedure Parse_Empty_Container
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
   begin
      Ex := New_Empty_Container(null);
      Ok := True;
   end;

   procedure Parse_List_Slice
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      L       : Expr := null;
      First   : Expr := null;
      Last    : Expr := null;
      Possible: Cls_Set;
      C       : Cls;

      procedure Free is
      begin
         if L     /= null then Free(L);     end if;
         if First /= null then Free(First); end if;
         if Last  /= null then Free(Last);  end if;
      end;

   begin
      Check_Type(E, HYT.List_Slice);

      --===
      --  parse the list
      --===
      Parse_Expr(E.List_Slice_List, Vars, L, Ok);
      if not Ok then
         return;
      end if;

      --===
      --  filter the possible colors to get only list colors
      --===
      Possible := Possible_Colors(L, Get_Cls(N));
      Filter_On_Type(Possible, (A_Vector_Cls => True,
                                A_List_Cls   => True,
                                others       => False));

      --===
      --  there must be only one possible type for the list
      --===
      if Card(Possible) /= 1 then
         if Card(Possible) > 1 then
            Add_Error(E.Vector_Access_Vector, "List has ambiguous type");
         else
            Add_Error(E.Vector_Access_Vector, "List required in slice");
         end if;
         Free;
         Ok := False;
         return;
      end if;
      C := Get_Index_Cls(List_Cls(Ith(Possible, 1)));
      Free(Possible);

      --===
      --  parse the first index and color it in the index color
      --===
      Parse_Expr(E.List_Slice_First, C, Vars, First, Ok);
      if not Ok then
         Free;
         return;
      end if;

      --===
      --  parse the last index and color it in the index color
      --===
      Parse_Expr(E.List_Slice_Last, C, Vars, Last, Ok);
      if not Ok then
         Free;
         return;
      end if;

      Ex := New_List_Slice(L, First, Last, null);
      Ok := True;
   end;

   procedure Parse_Symbol
     (E    : in     Element;
      Vars : in out Var_List_List;
      Error: in     Boolean;
      Ex   :    out Expr;
      Ok   :    out Boolean) is
      Possible: Cls_Set;
      Name    : Ustring;
      V       : Var;
   begin
      Check_Type(E, HYT.Symbol);
      Parse_Name(E.Sym, Name);

      --===
      --  first look in the variables
      --===
      Parse_Var_Ref(E, Vars, V, Ok);
      if Ok then
         Ex := New_Var_Ref(V);
         return;
      end if;

      --===
      --  then in the constants of the net
      --===
      if Is_Const(N, Name) then
         Ex := New_Var_Ref(Get_Const(N, Name));
         Ok := True;
         return;
      end if;

      --===
      --  at last in the enumerations colors of the net
      --===
      Ex := New_Enum_Const(Name, null);
      Possible := Possible_Colors(Ex, Get_Cls(N));
      Ok := not Is_Empty(Possible);
      Free(Possible);
      if not Ok then
         Free(Ex);
         if Error then
            Undefined(E, Null_String, Name);
         end if;
      end if;
   end;

   procedure Parse_Expr
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      Possible: Cls_Set;
   begin
      case E.T is
         when HYT.Num_Const =>
            Parse_Num_Const(E, Vars, Ex, Ok);
         when HYT.Func_Call =>
            Parse_Func_Call_Or_Cast(E, Vars, Ex, Ok);
         when HYT.Vector_Access =>
            Parse_Vector_Or_List_Access(E, Vars, Ex, Ok);
         when HYT.Struct_Access =>
            Parse_Struct_Access(E, Vars, Ex, Ok);
         when HYT.Bin_Op =>
            Parse_Bin_Op(E, Vars, Ex, Ok);
         when HYT.Un_Op =>
            Parse_Un_Op(E, Vars, Ex, Ok);
         when HYT.Vector_Aggregate =>
            Parse_Vector_Aggregate(E, Vars, Ex, Ok);
         when HYT.Struct_Aggregate =>
            Parse_Struct_Aggregate(E, Vars, Ex, Ok);
         when HYT.If_Then_Else =>
            Parse_If_Then_Else(E, Vars, Ex, Ok);
         when HYT.Symbol =>
            Parse_Symbol(E, Vars, True, Ex, Ok);
         when HYT.Iterator =>
            Parse_Iterator(E, Vars, Ex, Ok);
         when HYT.Tuple_Access =>
            Parse_Tuple_Access(E, Vars, Ex, Ok);
         when HYT.Struct_Assign =>
            Parse_Struct_Assign(E, Vars, Ex, Ok);
         when HYT.Vector_Assign =>
            Parse_Vector_Or_List_Assign(E, Vars, Ex, Ok);
         when HYT.Attribute =>
            Parse_Attribute(E, Vars, Ex, Ok);
         when HYT.Container_Aggregate =>
            Parse_Container_Aggregate(E, Vars, Ex, Ok);
         when HYT.Empty =>
            Parse_Empty_Container(E, Vars, Ex, Ok);
         when HYT.List_Slice =>
            Parse_List_Slice(E, Vars, Ex, Ok);
         when others =>
            pragma Assert(False); null;
      end case;
      if Ok then
         Possible := Possible_Colors(Ex, Get_Cls(N));
	 Ok := not Is_Empty(Possible);
         Free(Possible);
         if not Ok then
            Add_Error(E, "Expression has undefined type");
            Free(Ex);
            Ok := False;
            return;
         end if;
      end if;
   end;

   procedure Parse_Expr
     (E   : in     Element;
      C   : in     Cls;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
   begin
      Parse_Expr(E, Vars, Ex, Ok);
      if not Ok then
         return;
      end if;
      Color_Expr(E, Ex, C, Ok);
      if not Ok then
         Free(Ex);
      end if;
   end;

   procedure Parse_Basic_Expr
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
   begin
      Parse_Expr(E, Vars, Ex, Ok);
      if Ok and then not Is_Basic(Ex) then
         Add_Error(E, "Basic expression expected");
         Free(Ex);
         Ok := False;
      end if;
   end;

   procedure Parse_Basic_Expr
     (E   : in     Element;
      C   : in     Cls;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
   begin
      Parse_Basic_Expr(E, Vars, Ex, Ok);
      if Ok then
         Color_Expr(E, Ex, C, Ok);
         if not Ok then
            Free(Ex);
         end if;
      end if;
   end;

   procedure Parse_Static_Expr
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
   begin
      Parse_Expr(E, Vars, Ex, Ok);
      if Ok then
         if not Is_Static(Ex) then
            Add_Error(E, "Expression is not statically evaluable");
            Ok := False;
         end if;
      end if;
   end;

   procedure Parse_Expr_List
     (E     : in     Element;
      Vars  : in out Var_List_List;
      D     : in     Dom;
      Check : in     Boolean;
      El    :    out Expr_List;
      Ok    :    out Boolean;
      Uscore: in     Boolean := False) is
      Ith_Expr: Element;
      Ex      : Expr;
   begin
      Check_Type(E, HYT.List);
      if Check and then Length(E.List_Elements) /= Size(D) then
         Add_Error(E, Size(D) & " expression(s) expected. Found " &
                   Length(E.List_Elements) & " expression(s)");
         Ok := False;
         return;
      end if;
      El := New_Expr_List;
      Ok := True;
      for I in 1..Length(E.List_Elements) loop
         Ith_Expr := Ith(E.List_Elements, I);
         Parse_Expr(Ith_Expr, Vars, Ex, Ok);
         if Ok then
            if not Check then
               Append(El, Ex);
            else
               Color_Expr(Ith_Expr, Ex, Ith(D, I), Ok);
               if Ok then
                  Append(El, Ex);
               else
                  Free(Ex);
                  Free_All(El);
                  exit;
               end if;
            end if;
         else
            Free_All(El);
            exit;
         end if;
      end loop;
   end;

   procedure Parse_Discrete_Expr_List
     (E   : in     Element;
      Vars: in out Var_List_List;
      El  :    out Expr_List;
      Ok  :    out Boolean) is
      Ith_Expr: Element;
      Possible: Cls_Set;
      Ex      : Expr;
   begin
      Check_Type(E, HYT.List);
      El := New_Expr_List;
      Ok := True;
      for I in 1..Length(E.List_Elements) loop
         Ith_Expr := Ith(E.List_Elements, I);
         Parse_Expr(Ith_Expr, Vars, Ex, Ok);
         if not Ok then
            Free_All(El);
            return;
         else
	    Append(El, Ex);
	    Possible := Possible_Colors(Ex, Get_Cls(N));
	    Ok := Card(Possible) >= 1;
	    if not Ok then
	       Add_Error(E, "Expression has undefined type");
	       Free_All(El);
	       return;
	    else
	       Filter_On_Type(Possible, (A_Num_Cls  => True,
					 A_Enum_Cls => True,
					 others     => False));
	       Ok := Card(Possible) >= 1;
	       if not Ok then
		  Add_Error(E, "Expression of discrete type expected");
		  Free_All(El);
		  return;
	       else
		  Color_Expr(Ith_Expr, Ex, Ith(Possible, 1), Ok);
	       end if;
	    end if;
         end if;
      end loop;
   end;

   procedure Parse_Basic_Expr_List
     (E     : in     Element;
      Vars  : in out Var_List_List;
      D     : in     Dom;
      Check : in     Boolean;
      El    :    out Expr_List;
      Ok    :    out Boolean;
      Uscore: in     Boolean := False) is
      Ith_Expr: Expr;
   begin
      Parse_Expr_List(E, Vars, D, Check, El, Ok, Uscore);
      if Ok then
         for I in 1..Length(El) loop
            Ith_Expr := Ith(El, I);
            if not Is_Basic(Ith_Expr) then
               Ok := False;
               Free(El);
               Add_Error
                 (Ith(E.List_Elements, I),
                  To_Ustring("Basic expression expected"));
               return;
            end if;
         end loop;
      end if;
   end;

end Helena_Parser.Exprs;
