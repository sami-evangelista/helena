with
  Pn.Compiler.Names,
  Pn.Classes,
  Pn.Classes.Discretes,
  Pn.Classes.Discretes.Nums,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Num_Consts;

use
  Pn.Compiler.Names,
  Pn.Classes,
  Pn.Classes.Discretes,
  Pn.Classes.Discretes.Nums,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Num_Consts;

package body Pn.Exprs.Un_Ops is

   --==========================================================================
   --  unary operator
   --==========================================================================

   function To_Helena
     (Op: in Un_Operator) return String is
   begin
      case Op is
         when Pred_Op   => return "pred";
         when Succ_Op   => return "succ";
         when Plus_Uop  => return "+";
         when Minus_Uop => return "-";
         when Not_Op    => return "not";
      end case;
   end;

   function Compile
     (Op: in Un_Operator) return String is
   begin
      case Op is
         when Pred_Op   => pragma Assert(False); return "";
         when Succ_Op   => pragma Assert(False); return "";
         when Plus_Uop  => return "+";
         when Minus_Uop => return "-";
         when Not_Op    => return "!";
      end case;
   end;



   --==========================================================================
   --  unary operation
   --==========================================================================

   function New_Un_Op
     (Op   : in Un_Operator;
      Right: in Expr;
      C    : in Cls) return Expr is
      Result: constant Un_Op := new Un_Op_Record;
   begin
      Initialize(Result, C);
      Result.Op := Op;
      Result.Right := Right;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Un_Op_Record) is
   begin
      Free(E.Right);
   end;

   function Copy
     (E: in Un_Op_Record) return Expr is
      Result: constant Un_Op := new Un_Op_Record;
   begin
      Initialize(Result, E.C);
      Result.Op   := E.Op;
      Result.Right := Copy(E.Right);
      return Expr(Result);
   end;

   function Get_Type
     (E: in Un_Op_Record) return Expr_Type is
   begin
      return A_Un_Op;
   end;

   procedure Color_Expr
     (E    : in     Un_Op_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
   begin
      Color_Expr(E.Right, C, Cs, State);
   end;

   function Possible_Colors
     (E: in Un_Op_Record;
      Cs: in Cls_Set) return Cls_Set is

      --===
      --  get the potential colors of the operand
      --===
      Operand: Cls_Set := Possible_Colors(E.Right, Cs);
      Result: Cls_Set;
   begin
      --===
      --  depending on the operator we filter the colors
      --===
      case E.Op is

            --===
            --  pred, succ
            --     accept only discrete colors
            --===
         when Pred_Op
           |  Succ_Op =>

            Filter_On_Type(Operand, (A_Num_Cls  => True,
                                     A_Enum_Cls => True,
                                     others     => False));

            --===
            --  +, -
            --     accept only numerical colors
            --===
         when Plus_Uop
           |  Minus_Uop =>
            Filter_On_Type(Operand, (A_Num_Cls => True,
                                     others    => False));

            --===
            --  not
            --     accept only the boolean color
            --===
         when Not_Op =>
            if Contains(Operand, Bool_Cls) then
               Free(Operand);
               Operand := New_Cls_Set((1 => Bool_Cls));
            else
               Free(Operand);
               Operand := New_Cls_Set;
            end if;

      end case;
      if not Is_Empty(Operand) then
         Result := Operand;
      else
         Result := New_Cls_Set;
      end if;
      return Result;
   end;

   function Is_Static
     (E: in Un_Op_Record) return Boolean is
   begin
      return Is_Static(E.Right);
   end;

   function Is_Basic
     (E: in Un_Op_Record) return Boolean is
   begin
      return Is_Basic(E.Right);
   end;

   function Get_True_Cls
     (E: in Un_Op_Record) return Cls is
   begin
      return Get_True_Cls(E.Right);
   end;

   function Can_Overflow
     (E: in Un_Op_Record) return Boolean is
   begin
      return
        (Get_Type(E.C) = A_Num_Cls and then
         not Is_Circular(Discrete_Cls(E.C)));
   end;

   procedure Evaluate
     (E     : in     Un_Op_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
      Right: Expr;
      Cs   : Count_State;
      C    : Card_Type;
      I    : Card_Type;
      Num  : Num_Type;
   begin
      Evaluate(E      => E.Right,
               B      => B,
               Check  => False,
               Result => Right,
               State  => State);
      if not Is_Success(State) then
         return;
      end if;
      begin
         case E.Op is
            when Pred_Op
              |  Succ_Op =>
               I := Get_Value_Index(E.C, Right);
               Card(E.C, C, Cs);
               pragma Assert(Is_Success(Cs));
               if E.Op = Pred_Op then
                  if I = 1 and then Is_Circular(Discrete_Cls(E.C)) then
                     I := C;
                  else
                     I := I - 1;
                  end if;
               else
                  if I = C and then Is_Circular(Discrete_Cls(E.C)) then
                     I := 1;
                  else
                     I := I + 1;
                  end if;
               end if;
               Result := Ith_Value(E.C, I);
               Free(Right);
            when Plus_Uop =>
               Result := Right;
            when Minus_Uop =>
               Num   := - Get_Const(Num_Const(Right));
               Num   := Normalize_Value(Num_Cls(E.C), Num);
               Result := New_Num_Const(Num, E.C);
               Free(Right);
            when Not_Op =>
               if Is_True_Const(Enum_Const(Right)) then
                  Result := New_Enum_Const(False_Const_Name, Bool_Cls);
               else
                  Result := New_Enum_Const(True_Const_Name,  Bool_Cls);
               end if;
               Free(Right);
         end case;
      exception
         when Constraint_Error =>
            Free(Right);
            State := Evaluation_Range_Check_Failed;
            return;
      end;
      State := Evaluation_Success;
   end;

   function Static_Equal
     (Left: in Un_Op_Record;
      Right: in Un_Op_Record) return Boolean is
   begin
      return Left.Op = Right.Op and Static_Equal(Left.Right, Right.Right);
   end;

   function Compare
     (Left: in Un_Op_Record;
      Right: in Un_Op_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in Un_Op_Record) return Var_List is
   begin
      return Vars_In(E.Right);
   end;

   procedure Get_Sub_Exprs
     (E: in Un_Op_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.Right, R);
   end;

   procedure Get_Observed_Places
     (E     : in     Un_Op_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.Right, Places);
   end;

   function To_Helena
     (E: in Un_Op_Record) return Ustring is
   begin
      return To_Helena(E.Op) & " " & To_Helena(E.Right);
   end;

   function To_Pnml
     (E: in Un_Op_Record) return Ustring is
      Result : Ustring := "<subterm>" & To_Pnml(E.Right) & "</subterm>";
   begin
      case E.Op is
         when Pred_Op => Result := "<predecessor>" & Result & "</predecessor>";
	 when Succ_Op => Result := "<successor>" & Result & "</successor>";
         when Not_Op  => Result := "<not>" & Result & "</not>";
         when others  => raise Export_Exception;
      end case;
      return Result;
   end;

   function Compile_Evaluation
     (E: in Un_Op_Record;
      M: in Var_Mapping) return Ustring is
   begin
      return
        "(" & Cls_Un_Operator_Name(Get_Cls(E.Right), E.Op) &
        "(" & Compile_Evaluation(E.Right, M, False) & "))";
   end;

   function Replace_Var
     (E: in Un_Op_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: Expr;
   begin
      Result := New_Un_Op(E.Op, Replace_Var(E.Right, V, Ne), E.C);
      Set_Cls(Result, E.C);
      return Result;
   end;

end Pn.Exprs.Un_Ops;
