with
  Pn.Classes,
  Pn.Classes.Discretes,
  Pn.Exprs,
  Pn.Exprs.Num_Consts,
  Pn.Vars;

use
  Pn.Classes,
  Pn.Classes.Discretes,
  Pn.Exprs,
  Pn.Exprs.Num_Consts,
  Pn.Vars;

package body Pn.Ranges is

   --==========================================================================
   --  a range
   --==========================================================================

   procedure Free
     (R: in out Range_Spec) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Range_Spec_Record'Class, Range_Spec);
   begin
      Free(R.all);
      Deallocate(R);
      R := null;
   end;

   function Copy
     (R: access Range_Spec_Record'Class) return Range_Spec is
   begin
      return Copy(R.all);
   end;

   function Get_Low
     (R: access Range_Spec_Record'Class) return Expr is
   begin
      return Get_Low(R.all);
   end;

   function Convert_To_Num_Type
     (E: in Expr) return Num_Type is
      Result: Num_Type;
   begin
      case Get_Type(E) is
         when A_Num_Const =>
            Result := Get_Const(Num_Const(E));
         when A_Enum_Const =>
            Result := Num_Type(Get_Value_Index(Get_Root_Cls(Get_Cls(E)), E));
         when others =>
            pragma Assert(False);
            null;
      end case;
      return Result;
   end;

   function Get_Low_Value_Index
     (R: access Range_Spec_Record'Class) return Num_Type is
      E     : Expr := Get_Low(R);
      State : Evaluation_State;
      Tmp   : Expr;
      Result: Num_Type;
   begin
      Evaluate_Static(E      => E,
                      Check  => False,
                      Result => Tmp,
                      State  => State);
      pragma Assert(Is_Success(State));
      Result := Convert_To_Num_Type(Tmp);
      Free(E);
      Free(Tmp);
      return Result;
   end;

   function Get_High
     (R: access Range_Spec_Record'Class) return Expr is
   begin
      return Get_High(R.all);
   end;

   function Get_High_Value_Index
     (R: access Range_Spec_Record'Class) return Num_Type is
      E     : Expr := Get_High(R);
      State : Evaluation_State;
      Tmp   : Expr;
      Result: Num_Type;
   begin
      Evaluate_Static(E      => E,
                      Check  => False,
                      Result => Tmp,
                      State  => State);
      pragma Assert(Is_Success(State));
      Result := Convert_To_Num_Type(Tmp);
      Free(E);
      Free(Tmp);
      return Result;
   end;

   function Is_Static
     (R: access Range_Spec_Record'Class) return Boolean is
   begin
      return Is_Static(R.all);
   end;

   function Is_Positive
     (R: access Range_Spec_Record'Class) return Boolean is
   begin
      return Get_High_Value_Index(R) >= Get_Low_Value_Index(R);
   end;

   function Static_Size
     (R: access Range_Spec_Record'Class) return Card_Type is
      Result: Card_Type;
      Low   : constant Card_Type := Card_Type(Get_Low_Value_Index(R));
      High  : constant Card_Type := Card_Type(Get_High_Value_Index(R));
   begin
      if Low > High then
         Result := 0;
      else
         Result := 1 + High - Low;
      end if;
      return Result;
   end;

   function Size
     (R: access Range_Spec_Record'Class;
      B: in     Binding) return Card_Type is
      Low     : Expr := Get_Low(R);
      High    : Expr := Get_High(R);
      Low_Val : Expr;
      High_Val: Expr;
      Result  : Num_Type;
      L       : Num_Type;
      H       : Num_Type;
      State   : Evaluation_State;
   begin
      Evaluate(E      => Low,
               B      => B,
               Check  => False,
               Result => Low_Val,
               State  => State);
      pragma Assert(Is_Success(State));
      Evaluate(E      => High,
               B      => B,
               Check  => False,
               Result => High_Val,
               State  => State);
      pragma Assert(Is_Success(State));
      L := Convert_To_Num_Type(Low);
      H := Convert_To_Num_Type(High);
      Result := H - L + 1;
      if L > H then
         Result := 0;
      else
         Result := H - L + 1;
      end if;
      Free(Low);
      Free(Low_Val);
      Free(High);
      Free(High_Val);
      return Card_Type(Result);
   end;

   function Static_Enum_Values
     (R: access Range_Spec_Record'Class) return Expr_List is
      Ex    : Expr := Get_Low(R);
      C     : constant Cls := Get_Cls(Ex);
      Low   : constant Num_Type := Get_Low_Value_Index(R);
      High  : constant Num_Type := Get_High_Value_Index(R);
      Result: constant Expr_List := New_Expr_List;
   begin
      Free(Ex);
      for I in Low..High loop
         Append(Result, From_Num_Value(Discrete_Cls(C), I));
      end loop;
      return Result;
   end;

   function Vars_In
     (R: access Range_Spec_Record'Class) return Var_List is
   begin
      return Ranges.Vars_In(R.all);
   end;

   procedure Replace_Var
     (R: access Range_Spec_Record'Class;
      V: in     Var;
      E: in     Expr) is
   begin
      Replace_Var(R.all, V, E);
   end;

   function To_Helena
     (R: access Range_Spec_Record'Class) return Ustring is
   begin
      return To_Helena(R.all);
   end;



   --==========================================================================
   --  a range in the form low..high
   --==========================================================================

   function New_Low_High_Range
     (Low : in Expr;
      High: in Expr) return Range_Spec is
      Result: constant Low_High_Range := new Low_High_Range_Record;
   begin
      Result.Low := Low;
      Result.High := High;
      return Range_Spec(Result);
   end;

   procedure Free
     (R: in out Low_High_Range_Record) is
   begin
      Free(R.Low);
      Free(R.High);
   end;

   function Copy
     (R: in Low_High_Range_Record) return Range_Spec is
      Result: constant Low_High_Range := new Low_High_Range_Record;
   begin
      Result.Low := Copy(R.Low);
      Result.High := Copy(R.High);
      return Range_Spec(Result);
   end;

   function Get_Low
     (R: in Low_High_Range_Record) return Expr is
   begin
      return Copy(R.Low);
   end;

   function Get_High
     (R: in Low_High_Range_Record) return Expr is
   begin
      return Copy(R.High);
   end;

   function Is_Static
     (R: in Low_High_Range_Record) return Boolean is
   begin
      return Is_Static(R.Low) and Is_Static(R.High);
   end;

   function Vars_In
     (R: in Low_High_Range_Record) return Var_List is
      Result: constant Var_List := Vars_In(R.Low);
      Tmp   : Var_List := Vars_In(R.High);
   begin
      Union(Result, Tmp);
      Free(Tmp);
      return Result;
   end;

   procedure Replace_Var
     (R: in out Low_High_Range_Record;
      V: in     Var;
      E: in     Expr) is
   begin
      Replace_Var(R.Low, V, E);
      Replace_Var(R.High, V, E);
   end;

   function To_Helena
     (R: in Low_High_Range_Record) return Ustring is
   begin
      return To_Helena(R.Low) & " .. " & To_Helena(R.High);
   end;

end Pn.Ranges;
