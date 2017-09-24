with
  Pn.Classes,
  Pn.Classes.Containers,
  Pn.Classes.Discretes,
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Num_Consts,
  Pn.Vars;

use
  Pn.Classes,
  Pn.Classes.Containers,
  Pn.Classes.Discretes,
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Num_Consts,
  Pn.Vars;

package body Pn.Exprs.Bin_Ops is

   --==========================================================================
   --  binary operator
   --==========================================================================

   function To_Helena
     (Op: in Bin_Operator) return String is
   begin
      case Op is
         when Plus_Op   => return "+";
         when Minus_Op  => return "-";
         when Mult_Op   => return "*";
         when Div_Op    => return "/";
         when Mod_Op    => return "%";
         when And_Op    => return "and";
         when Or_Op     => return "or";
         when Sup_Op    => return ">";
         when Sup_Eq_Op => return ">=";
         when Inf_Op    => return "<";
         when Inf_Eq_Op => return "<=";
         when Eq_Op     => return "=";
         when Neq_Op    => return "!=";
         when In_Op     => return "in";
         when Concat_Op => return "&";
      end case;
   end;

   function Compile
     (Op: in Bin_Operator) return String is
   begin
      case Op is
         when Plus_Op   => return "+";
         when Minus_Op  => return "-";
         when Mult_Op   => return "*";
         when Div_Op    => return "/";
         when Mod_Op    => return "%";
         when And_Op    => return "&&";
         when Or_Op     => return "||";
         when Sup_Op    => return ">";
         when Sup_Eq_Op => return ">=";
         when Inf_Op    => return "<";
         when Inf_Eq_Op => return "<=";
         when Eq_Op     => return "==";
         when Neq_Op    => return "!=";
         when In_Op     => pragma Assert(False); return "";
         when Concat_Op => pragma Assert(False); return "";
      end case;
   end;



   --==========================================================================
   --  binary operation
   --==========================================================================

   function New_Bin_Op
     (Op   : in Bin_Operator;
      Left : in Expr;
      Right: in Expr;
      C    : in Cls) return Expr is
      Result: constant Bin_Op := new Bin_Op_Record;
   begin
      Initialize(Result, C);
      Result.Op   := Op;
      Result.Left := Left;
      Result.Right := Right;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Bin_Op_Record) is
   begin
      Free(E.Left);
      Free(E.Right);
   end;

   function Copy
     (E: in Bin_Op_Record) return Expr is
   begin
      return New_Bin_Op(E.Op,
                        Copy(E.Left),
                        Copy(E.Right),
                        E.C);
   end;

   function Get_Type
     (E: in Bin_Op_Record) return Expr_Type is
   begin
      return A_Bin_Op;
   end;

   procedure Color_Expr
     (E    : in     Bin_Op_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Left    : Cls_Set;
      Right   : Cls_Set;
      Possible: Cls_Set;
      C_Left  : Cls;
      C_Right: Cls;
      C_Root  : Cls;

      procedure Get_Container_Cls is
      begin
         Possible := Possible_Colors(E.Left, Cs);
         if Contains(Possible, C) then
            C_Left := C;
         else
            C_Left := Get_Elements_Cls(Container_Cls(C));
         end if;
         Free(Possible);
         Possible := Possible_Colors(E.Right, Cs);
         if Contains(Possible, C) then
            C_Right := C;
         else
            C_Right := Get_Elements_Cls(Container_Cls(C));
         end if;
         Free(Possible);
      end;

   begin
      case E.Op is

         --===
         --  and, or
         --===
         when Bool_Bin_Operator =>
            if C = Bool_Cls then
               C_Left := Bool_Cls;
               C_Right := Bool_Cls;
            else
               Get_Container_Cls;
            end if;

            --===
            --  +, *, /, mod
            --===
         when Plus_Op
           |  Mult_Op
           |  Mod_Op
           |  Div_Op =>
            C_Left := C;
            C_Right := C;

            --===
            --  -
            --===
         when Minus_Op =>
            C_Left := C;
            if Get_Type(C) /= A_Set_Cls then
               C_Right := C;
            else
               Right := Possible_Colors(E.Right, Cs);
               if Contains(Right, C) then
                  C_Right := C;
               else
                  C_Right := Get_Elements_Cls(Container_Cls(C));
               end if;
            end if;

            --===
            --  =, /=, >, >=, <=, <
            --===
         when Comparison_Bin_Operator =>
            Left    := Possible_Colors(E.Left, Cs);
            Right   := Possible_Colors(E.Right, Cs);
            Possible := Intersect(Left, Right);
            Free(Left);
            Free(Right);
            case Comparison_Bin_Operator(E.Op) is
               when Inf_Op
                 |  Inf_Eq_Op
                 |  Sup_Op
                 |  Sup_Eq_Op =>
                  Filter_On_Type(Possible, (A_Num_Cls  => True,
                                            A_Enum_Cls => True,
                                            A_Set_Cls  => True,
                                            others     => False));
               when Eq_Op
                 |  Neq_Op =>
                  null;
            end case;
            Choose(Possible, C_Left, State);
            Free(Possible);
            if not Is_Success(State) then
               return;
            end if;
            C_Right := C_Left;

            --===
            --  &
            --===
         when Concat_Op =>
            Get_Container_Cls;

            --===
            --  in
            --===
         when In_Op =>
            Left := Possible_Colors(E.Left, Cs);
            Right := Possible_Colors(E.Right, Cs);
            for I in 1..Card(Left) loop
               C_Left := Ith(Left, I);
               for J in 1..Card(Right) loop
                  C_Right := Ith(Right, J);
                  if Is_Container_Cls(C_Right) then
                     C_Root := Get_Root_Cls(Get_Elements_Cls
                                            (Container_Cls(C_Right)));
                     if C_Root = C_Left then
                        C_Left := Get_Elements_Cls(Container_Cls(C_Right));
                        exit;
                     end if;
                  end if;
               end loop;
            end loop;
            Free(Left);
            Free(Right);
      end case;
      Color_Expr(E.Left,  C_Left,  Cs, State);
      if not Is_Success(State) then return; end if;
      Color_Expr(E.Right, C_Right, Cs, State);
   end;

   function Possible_Colors
     (E: in Bin_Op_Record;
      Cs: in Cls_Set) return Cls_Set is
      Left_Possible: Cls_Set := Possible_Colors(E.Left,  Cs);
      Right_Possible: Cls_Set := Possible_Colors(E.Right, Cs);
      C_Left        : Cls;
      C_Right       : Cls;
      C_Root        : Cls;
      Result        : constant Cls_Set := New_Cls_Set;

      procedure Check_Container_Operation
        (C: in Cls_Type) is
         Tmp: Cls;
      begin
         if Get_Type(C_Right) = C then
            Tmp    := C_Left;
            C_Left := C_Right;
            C_Right := Tmp;
         end if;
         if Get_Type(C_Left) = C then
            if Get_Type(C_Right) = C then
               if C_Left = C_Right then
                  Insert(Result, C_Left);
               end if;
            else
               C_Root := Get_Root_Cls(Get_Elements_Cls
                                      (Container_Cls(C_Left)));
               if C_Root = C_Right then
                  Insert(Result, C_Left);
               end if;
            end if;
         end if;
      end;

   begin
      for I in 1..Card(Left_Possible) loop
         C_Left := Ith(Left_Possible, I);
         for J in 1..Card(Right_Possible) loop
            C_Right := Ith(Right_Possible, J);
            case E.Op is

               --===
               --  and, or
               --    - both operands must be booleans and so is the result
               --    - one of the operands must be a set which is also the type
               --      of the resulting expression
               --===
               when And_Op
                 |  Or_Op =>
                  if C_Left = Bool_Cls and C_Right = Bool_Cls then
                     Insert(Result, Bool_Cls);
                  else
                     Check_Container_Operation(A_Set_Cls);
                  end if;

                  --===
                  --  +, *, /, %
                  --     both operands must be numerical expressions and so is
                  --     the result
                  --===
               when Plus_Op
                 |  Mult_Op
                 |  Mod_Op
                 |  Div_Op =>
                  if
                    C_Left = C_Right              and
                    Get_Type(C_Left)  = A_Num_Cls and
                    Get_Type(C_Right) = A_Num_Cls
                  then
                     Insert(Result, C_Left);
                  end if;

                  --===
                  --  -
                  --     both operands must be numerical expressions and so is
                  --     the result
                  --  or
                  --     the left operand is a set and the right operand is an
                  --     expression of the element class of the set
                  --===
               when Minus_Op =>
                  if
                    C_Left = C_Right              and
                    Get_Type(C_Left)  = A_Num_Cls and
                    Get_Type(C_Right) = A_Num_Cls
                  then
                     Insert(Result, C_Left);
                  elsif Get_Type(C_Left) = A_Set_Cls then
                     C_Root :=
                       Get_Root_Cls(Get_Elements_Cls(Container_Cls(C_Left)));
                     if    C_Right = C_Left then
                        Insert(Result, C_Left);
                     elsif C_Right = C_Root then
                        Insert(Result, C_Left);
                     end if;
                  end if;

                  --===
                  --  >, >=, <, <=
                  --     both operands must be expressions of a discrete class
                  --     and so is the result
                  --===
               when Sup_Op
                 |  Sup_Eq_Op
                 |  Inf_Op
                 |  Inf_Eq_Op =>
                  if
                    C_Left = C_Right and
                    (Is_Discrete(C_Left) or else Get_Type(C_Left) = A_Set_Cls)
                  then
                     Insert(Result, Bool_Cls);
                  end if;

                  --===
                  --  =, !=
                  --     both operands must be have the same color and the
                  --     result is the boolean class
                  --===
               when Eq_Op
                 |  Neq_Op =>
                  if C_Left = C_Right then
                     Insert(Result, Bool_Cls);
                  end if;

                  --===
                  --  &
                  --     at least one of the operands must have a list class
                  --     which is the class of the expression
                  --===
               when Concat_Op =>
                  Check_Container_Operation(A_List_Cls);

                  --===
                  --  in
                  --     the right operand must be a container and the left
                  --     operand must have the class of the element class of
                  --     the container
                  --===
               when In_Op =>
                  if Is_Container_Cls(C_Right) then
                     C_Root := Get_Root_Cls(Get_Elements_Cls
                                            (Container_Cls(C_Right)));
                     if C_Root = C_Left then
                        Insert(Result, Bool_Cls);
                     end if;
                  end if;
            end case;
         end loop;
      end loop;
      Free(Left_Possible);
      Free(Right_Possible);
      return Result;
   end;

   function Is_Static
     (E: in Bin_Op_Record) return Boolean is
   begin
      return
        Is_Static(E.Left) and Is_Static(E.Right) and
        E.Op /= Concat_Op and E.Op /= In_Op;
   end;

   function Is_Basic
     (E: in Bin_Op_Record) return Boolean is
   begin
      return Is_Basic(E.Left) and Is_Basic(E.Right);
   end;

   function Get_True_Cls
     (E: in Bin_Op_Record) return Cls is
      Result: Cls;
   begin
      case E.Op is
         when Num_Bin_Operator        => Result := Get_Cls(E.Left);
         when Bool_Bin_Operator       => Result := Bool_Cls;
         when Comparison_Bin_Operator => Result := Bool_Cls;
         when In_Op                   => Result := Bool_Cls;
         when Concat_Op               => Result := Get_Cls(E.Left);
      end case;
      return Result;
   end;

   function Can_Overflow
     (E: in Bin_Op_Record) return Boolean is
   begin
      return
        E.Op in Num_Bin_Operator and then
        Is_Discrete(E.C)         and then
        not Is_Circular(Discrete_Cls(E.C));
   end;

   procedure Evaluate
     (E     : in     Bin_Op_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
      Left: Expr;
      Right: Expr;
      Bool: Boolean;
      Cmp  : Comparison_Result;
      Num  : Num_Type;

      procedure Evaluate_Right is
      begin
         Evaluate(E      => E.Right,
                  B      => B,
                  Check  => False,
                  Result => Right,
                  State  => State);
      end;

      procedure Free is
      begin
         if Left  /= null then Free(Left);  end if;
         if Right /= null then Free(Right); end if;
      end;

   begin
      --===
      --  in all cases we evaluate the left operand
      --===
      Evaluate(E      => E.Left,
               B      => B,
               Check  => False,
               Result => Left,
               State  => State);
      if not Is_Success(State) then
         Free;
         return;
      end if;

      case E.Op is

         --===
         --  +, -, *, /, mod
         --===
         when Num_Bin_Operator =>
            Evaluate_Right;
            if not Is_Success(State) then
               Free;
               return;
            end if;
            begin
               case Num_Bin_Operator(E.Op) is
                  when Plus_Op =>
                     Num :=
                       Get_Const(Num_Const(Left)) +
                       Get_Const(Num_Const(Right));
                  when Minus_Op =>
                     pragma Assert(Get_Type(Get_Cls(Left))  = A_Num_Cls and
                                   Get_Type(Get_Cls(Right)) = A_Num_Cls);
                     Num :=
                       Get_Const(Num_Const(Left)) -
                       Get_Const(Num_Const(Right));
                  when Mult_Op =>
                     Num :=
                       Get_Const(Num_Const(Left)) *
                       Get_Const(Num_Const(Right));
                  when Div_Op =>
                     if Get_Const(Num_Const(Right)) = 0 then
                        State := Evaluation_Div_By_Zero;
                        Free;
                        return;
                     end if;
                     Num :=
                       Get_Const(Num_Const(Left)) /
                       Get_Const(Num_Const(Right));
                  when Mod_Op =>
                     if Get_Const(Num_Const(Right)) = 0 then
                        State := Evaluation_Div_By_Zero;
                        Free;
                        return;
                     end if;
                     Num :=
                       Get_Const(Num_Const(Left)) mod
                       Get_Const(Num_Const(Right));
               end case;
            exception
               when Constraint_Error =>
                  State := Evaluation_Failure;
                  Free;
                  return;
            end;
            Result := New_Num_Const(Num, E.C);

            --===
            --  >, >=, <, <=, =, /=
            --===
         when Comparison_Bin_Operator =>
            Evaluate_Right;
            if not Is_Success(State) then
               Free;
               return;
            end if;
            Cmp := Compare(Left, Right);
            if Cmp = Cmp_Error then
               Free;
               State := Evaluation_Failure;
               return;
            end if;
            case Comparison_Bin_Operator(E.Op) is
               when Sup_Op    => Bool := Cmp  = Cmp_Sup;
               when Sup_Eq_Op => Bool := Cmp  = Cmp_Sup or Cmp = Cmp_Eq;
               when Inf_Op    => Bool := Cmp  = Cmp_Inf;
               when Inf_Eq_Op => Bool := Cmp  = Cmp_Inf or Cmp = Cmp_Eq;
               when Eq_Op     => Bool := Cmp  = Cmp_Eq;
               when Neq_Op    => Bool := Cmp /= Cmp_Eq;
            end case;
            if Bool then
               Result := New_Enum_Const(True_Const_Name,  Bool_Cls);
            else
               Result := New_Enum_Const(False_Const_Name, Bool_Cls);
            end if;
            Free;

            --===
            --  &
            --===
         when Concat_Op =>
            pragma Assert(False);
            null;

            --===
            --  in
            --===
         when In_Op =>
            pragma Assert(False);
            null;

            --===
            --  or, and
            --===
         when Bool_Bin_Operator =>
            if    E.Op = Or_Op  and then Is_True_Const (Enum_Const(Left)) then
               Bool := True;
            elsif E.Op = And_Op and then Is_False_Const(Enum_Const(Left)) then
               Bool := False;
            else
               Evaluate_Right;
               if not Is_Success(State) then
                  Free;
                  return;
               end if;
               case Bool_Bin_Operator(E.Op) is
                  when Or_Op =>
                     Bool :=
                       Is_True_Const(Enum_Const(Left)) or
                       Is_True_Const(Enum_Const(Right));
                  when And_Op =>
                     Bool :=
                       Is_True_Const(Enum_Const(Left)) and
                       Is_True_Const(Enum_Const(Right));
               end case;
            end if;
            if Bool then
               Result := New_Enum_Const(True_Const_Name,  Bool_Cls);
            else
               Result := New_Enum_Const(False_Const_Name, Bool_Cls);
            end if;
            Free;
      end case;
      State := Evaluation_Success;
   end;

   function Static_Equal
     (Left: in Bin_Op_Record;
      Right: in Bin_Op_Record) return Boolean is
   begin
      return
        Left.Op = Right.Op                  and then
        Static_Equal(Left.Left, Right.Left) and then
        Static_Equal(Left.Right, Right.Right);
   end;

   function Compare
     (Left: in Bin_Op_Record;
      Right: in Bin_Op_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in Bin_Op_Record) return Var_List is
      Result: constant Var_List := Vars_In(E.Left);
      Right: Var_List := Vars_In(E.Right);
   begin
      Union(Result, Right);
      Free(Right);
      return Result;
   end;

   procedure Get_Sub_Exprs
     (E: in Bin_Op_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.Left, R);
      Get_Sub_Exprs(E.Right, R);
   end;

   procedure Get_Observed_Places
     (E     : in     Bin_Op_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.Left, Places);
      Get_Observed_Places(E.Right, Places);
   end;

   function To_Helena
     (E: in Bin_Op_Record) return Ustring is
   begin
      return (To_Helena(E.Left) & " " &
              To_Helena(E.Op)   & " " &
              To_Helena(E.Right));
   end;

   function Compile_Evaluation
     (E: in Bin_Op_Record;
      M: in Var_Mapping) return Ustring is
   begin
      return
        Cls_Bin_Operator_Name(Get_Cls(E.Left), Get_Cls(E.Right), E.Op) &
        "(" &
        Compile_Evaluation(E.Left,  M, False) & ", " &
        Compile_Evaluation(E.Right, M, False) &
        ")";
   end;

   function Replace_Var
     (E: in Bin_Op_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: Expr;
   begin
      Result := New_Bin_Op(E.Op,
                           Replace_Var(E.Left, V, Ne),
                           Replace_Var(E.Right, V, Ne),
                           E.C);
      return Result;
   end;

end Pn.Exprs.Bin_Ops;
