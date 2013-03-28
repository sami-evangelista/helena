with
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Exprs.Containers,
  Pn.Nodes;

use
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Exprs.Containers,
  Pn.Nodes;

package body Pn.Vars.Iter is

   --==========================================================================
   --  Iteration variable domain
   --==========================================================================

   function New_Iter_Var_Place_Dom
     (P: in Place) return Iter_Var_Dom is
      Result: constant Iter_Var_Dom :=
        new Iter_Var_Dom_Record(A_Place_Iterator);
   begin
      Result.P := P;
      return Result;
   end;

   function New_Iter_Var_Discrete_Cls_Dom
     (R: in Range_Spec) return Iter_Var_Dom is
      Result: constant Iter_Var_Dom :=
        new Iter_Var_Dom_Record(A_Discrete_Cls_Iterator);
   begin
      Result.R := R;
      return Result;
   end;

   function New_Iter_Var_Container_Dom
     (Cont: in Expr) return Iter_Var_Dom is
      Result: constant Iter_Var_Dom :=
        new Iter_Var_Dom_Record(A_Container_Iterator);
   begin
      Result.Cont := Cont;
      return Result;
   end;

   function Copy
     (Dom: in Iter_Var_Dom) return Iter_Var_Dom is
      Result: Iter_Var_Dom;
   begin
      case Dom.K is
         when A_Place_Iterator =>
            Result := New_Iter_Var_Place_Dom(Dom.P);
         when A_Discrete_Cls_Iterator =>
            if Dom.R = No_Range then
               Result := New_Iter_Var_Discrete_Cls_Dom(No_Range);
            else
               Result := New_Iter_Var_Discrete_Cls_Dom(Copy(Dom.R));
            end if;
         when A_Container_Iterator =>
            Result := New_Iter_Var_Container_Dom(Copy(Dom.Cont));
      end case;
      return Result;
   end;

   procedure Free
     (Dom: in out Iter_Var_Dom) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Iter_Var_Dom_Record, Iter_Var_Dom);
   begin
      case Dom.K is
         when A_Place_Iterator =>
            null;
         when A_Discrete_Cls_Iterator =>
            if Dom.R /= No_Range then
               Free(Dom.R);
            end if;
         when A_Container_Iterator =>
            Free(Dom.Cont);
      end case;
      Deallocate(Dom);
      Dom := null;
   end;

   function Vars_In
     (Dom: in Iter_Var_Dom) return Var_List is
      Result: Var_List;
   begin
      case Dom.K is
         when A_Place_Iterator =>
            Result := New_Var_List;
         when A_Discrete_Cls_Iterator =>
            if Dom.R /= No_Range then
               Result := Vars_In(Dom.R);
            else
               Result := New_Var_List;
            end if;
         when A_Container_Iterator =>
            Result := Vars_In(Dom.Cont);
      end case;
      return Result;
   end;



   --==========================================================================
   --  Iteration variable
   --==========================================================================

   function New_Iter_Var
     (Name: in Ustring;
      C   : in Cls;
      Dom : in Iter_Var_Dom) return Var is
      Result: constant Iter_Var := new Iter_Var_Record;
   begin
      Vars.Initialize(Result, Name, C);
      Result.Dom := Dom;
      return Var(Result);
   end;

   procedure Free
     (V: in out Iter_Var_Record) is
   begin
      Free(V.Dom);
   end;

   function Copy
     (V: in Iter_Var_Record) return Var is
   begin
      return New_Iter_Var(V.Name, V.C, Copy(V.Dom));
   end;

   function Is_Static
     (V: in Iter_Var_Record) return Boolean is
   begin
      return False;
   end;

   function Is_Const
     (V: in Iter_Var_Record) return Boolean is
   begin
      return False;
   end;

   function Get_Init
     (V: in Iter_Var_Record) return Expr is
   begin
      pragma Assert(False);
      return null;
   end;

   function Get_Type
     (V: in Iter_Var_Record) return Var_Type is
      Result: Var_Type;
   begin
      case V.Dom.K is
         when A_Place_Iterator        => Result := A_Place_Iter_Var;
         when A_Discrete_Cls_Iterator => Result := A_Discrete_Cls_Iter_Var;
         when A_Container_Iterator    => Result := A_Container_Iter_Var;
      end case;
      return Result;
   end;

   procedure Replace_Var_In_Def
     (V: in out Iter_Var_Record;
      R: in     Var;
      E: in     Expr) is
   begin
      case V.Dom.K is
         when A_Place_Iterator =>
            null;
         when A_Discrete_Cls_Iterator =>
            if V.Dom.R /= No_Range then
               Replace_Var(V.Dom.R, R, E);
            end if;
         when A_Container_Iterator =>
            Replace_Var(V.Dom.Cont, R, E);
      end case;
   end;

   function To_Helena
     (V: in Iter_Var_Record) return Ustring is
      Result: Ustring;
   begin
      case V.Dom.K is
         when A_Container_Iterator =>
            Result := V.Name & " in " & To_Helena(V.Dom.Cont);
         when A_Discrete_Cls_Iterator =>
            Result := V.Name & " in " & Get_Name(V.C);
            if V.Dom.R /= No_Range then
               Result := Result & " range " & To_Helena(V.Dom.R);
            end if;
         when A_Place_Iterator =>
            if V.Name /= Null_String then
               Result := V.Name & " in " & Get_Name(V.Dom.P);
            else
               Result := Get_Name(V.Dom.P);
            end if;
      end case;
      return Result;
   end;

   procedure Compile_Definition
     (V   : in Iter_Var_Record;
      Tabs: in Natural;
      File: in File_Type) is
      N    : constant Ustring := Var_Name(V.Me);
      Cont : constant Ustring := N & "_cont";
      Index: constant Ustring := N & "_index";
      C    : constant Ustring := Cls_Name(Get_Cls(V.Me));
   begin
      Put_Line(File, Tabs*Tab & C & " " & N & ";");
      case V.Dom.K is
         when A_Container_Iterator =>
            declare
               Cont_Cls: constant Ustring := Cls_Name(Get_Cls(V.Dom.Cont));
            begin
               Put_Line(File, Tabs*Tab & Cont_Cls & " " & Cont  & ";");
               Put_Line(File, Tabs*Tab & "unsigned int "    & Index & ";");
            end;
         when A_Discrete_Cls_Iterator =>
            Put_Line(File, Tabs*Tab & C & " " & N & "_high;");
         when A_Place_Iterator =>
            null;
      end case;
   end;

   function Compile_Access
     (V: in Iter_Var_Record) return Ustring is
   begin
      return Var_Name(V.Me);
   end;

   function Static_Nb_Iterations
     (I: in Iter_Var) return Card_Type is
      Result: Card_Type;
      State : Count_State;
   begin
      case I.Dom.K is
         when A_Place_Iterator
           |  A_Container_Iterator =>
            pragma Assert(False);
            Result := 0;
         when A_Discrete_Cls_Iterator =>
            if I.Dom.R /= No_Range then
               Result := Static_Size(I.Dom.R);
            else
               Card(Get_Cls(I.Me), Result, State);
               pragma Assert(Is_Success(State));
            end if;
      end case;
      return Result;
   end;

   function Nb_Iterations
     (I: in Iter_Var;
      B: in Binding) return Card_Type is
      Result: Card_Type;
      State : Count_State;
   begin
      case I.Dom.K is
         when A_Place_Iterator =>
            pragma Assert(False);
            Result := 0;
         when A_Container_Iterator =>
            pragma Assert(False);
            Result := 0;
         when A_Discrete_Cls_Iterator =>
            if I.Dom.R /= No_Range then
               Result := Size(I.Dom.R, B);
            else
               Card(Get_Cls(I.Me), Result, State);
               pragma Assert(Is_Success(State));
            end if;
      end case;
      return Result;
   end;

   function Static_Enum_Values
     (I: in Iter_Var) return Expr_List is
      Result: Expr_List;
      C     : Card_Type;
      State : Count_State;
   begin
      case I.Dom.K is
         when A_Place_Iterator =>
            pragma Assert(False);
            Result := null;
         when A_Container_Iterator =>
            pragma Assert(Is_Static(I.Dom.Cont));
            Result := Copy(Get_Expr_List(Container(I.Dom.Cont)));
         when A_Discrete_Cls_Iterator =>
            Result := New_Expr_List;
            if I.Dom.R /= No_Range then
               pragma Assert(Is_Static(I.Dom.R));
               Result := Static_Enum_Values(I.Dom.R);
            else
               Card(I.C, C, State);
               pragma Assert(Is_Success(State));
               for J in 1..C loop
                  Append(Result, Ith_Value(I.C, J));
               end loop;
            end if;
      end case;
      return Result;
   end;

   procedure Enum_Values
     (I     : in     Iter_Var;
      B     : in     Binding;
      Result:    out Expr_List;
      State :    out Evaluation_State) is
      Low     : Expr;
      High    : Expr;
      Low_Val : Expr;
      High_Val: Expr;
      Cont    : Expr;
   begin
      case I.Dom.K is
         when A_Place_Iterator =>
            pragma Assert(False);
            State := Evaluation_Failure;
         when A_Container_Iterator =>
            Evaluate(I.Dom.Cont, B, True, Cont, State);
            Result := Copy(Get_Expr_List(Container(Cont)));
            Free(Cont);
         when A_Discrete_Cls_Iterator =>
            if I.Dom.R = No_Range then
               Result := Static_Enum_Values(I);
               State := Evaluation_Success;
            else
               Low := Get_Low(I.Dom.R);
               High := Get_High(I.Dom.R);
               Evaluate(Low, B, True, Low_Val, State);
               Free(Low);
               if not Is_Success(State) then
                  return;
               end if;
               Evaluate(High, B, True, High_Val, State);
               Free(High);
               if not Is_Success(State) then
                  Free(Low_Val);
                  return;
               end if;
               Result := New_Expr_List;
               for J in
                 Get_Value_Index(I.C, Low_Val) ..
                 Get_Value_Index(I.C, High_Val)
               loop
                  Append(Result, Ith_Value(I.C, J));
               end loop;
               Free(Low_Val);
               Free(High_Val);
            end if;
      end case;
   end;

   procedure Compile_Initialization
     (I   : in Iter_Var;
      Map : in Var_Mapping;
      Tabs: in Natural;
      Lib : in Library) is
      N    : constant Ustring := Var_Name(I.Me);
      Cont : constant Ustring := N & "_cont";
      Index: constant Ustring := N & "_index";
      Low  : Expr;
      High : Expr;
   begin
      case I.Dom.K is
         when A_Place_Iterator =>
            pragma Assert(False);
            null;
         when A_Discrete_Cls_Iterator =>
            if I.Dom.R /= No_Range then
               Low := Get_Low(I.Dom.R);
               High := Get_High(I.Dom.R);
            else
               Low := Low_Value(I.C);
               High := High_Value(I.C);
            end if;
            Plc(Lib, Tabs, N & "      = " &
                  Compile_Evaluation(Low, Map)  & ";");
            Plc(Lib, Tabs, N & "_high = " &
                  Compile_Evaluation(High, Map) & ";");
            Free(Low);
            Free(High);
         when A_Container_Iterator =>
            Plc(Lib, Tabs, Cont  & " = " &
                  Compile_Evaluation(I.Dom.Cont, Map) & ";");
            Plc(Lib, Tabs, Index & " = 0;");
            Plc(Lib, Tabs, N & " = " & Cont & ".items[0];");
      end case;
   end;

   procedure Compile_Initialization
     (I   : in Iter_Var;
      Tabs: in Natural;
      Lib : in Library) is
   begin
      Compile_Initialization(I, Empty_Var_Mapping, Tabs, Lib);
   end;

   procedure Compile_Iteration
     (I   : in Iter_Var;
      Tabs: in Natural;
      Lib : in Library) is
      N    : constant Ustring := Var_Name(I.Me);
      Cont : constant Ustring := N & "_cont";
      Index: constant Ustring := N & "_index";
   begin
      case I.Dom.K is
         when A_Place_Iterator =>
            pragma Assert(False);
            null;
         when A_Discrete_Cls_Iterator =>
            Plc(Lib, Tabs, N & " ++;");
         when A_Container_Iterator =>
            Plc(Lib, Tabs, Index & " ++;");
            Plc(Lib, Tabs, N & " = " & Cont & ".items[" & Index & "];");
      end case;
   end;

   function Compile_Start_Iteration_Check
     (I: in Iter_Var) return Ustring is
      N     : constant Ustring := Var_Name(I.Me);
      Cont  : constant Ustring := N & "_cont";
      Result: Ustring := Null_String;
   begin
      case I.Dom.K is
         when A_Place_Iterator =>
            pragma Assert(False);
            null;
         when A_Discrete_Cls_Iterator =>
            Result := N & " <= " & N & "_high";
         when A_Container_Iterator =>
            Result := Cont & ".length > 0";
      end case;
      return Result;
   end;

   function Compile_Is_Last_Check
     (I: in Iter_Var) return Ustring is
      N     : constant Ustring := Var_Name(I.Me);
      Cont  : constant Ustring := N & "_cont";
      Index : constant Ustring := N & "_index";
      Result: Ustring := Null_String;
   begin
      case I.Dom.K is
         when A_Place_Iterator =>
            pragma Assert(False);
            null;
         when A_Discrete_Cls_Iterator =>
            Result := N & " == " & N & "_high";
         when A_Container_Iterator =>
            Result := Index & " == (" & Cont & ".length - 1)";
      end case;
      return Result;
   end;

   function Get_Iter_Var_Dom
     (I: in Iter_Var) return Iter_Var_Dom is
   begin
      return I.Dom;
   end;

   function Get_Dom_Place
     (I: in Iter_Var) return Place is
   begin
      case I.Dom.K is
         when A_Place_Iterator        => return I.Dom.P;
         when A_Discrete_Cls_Iterator => return null;
         when A_Container_Iterator    => return null;
      end case;
   end;

   function Get_Dom_Range
     (I: in Iter_Var) return Range_Spec is
   begin
      case I.Dom.K is
         when A_Place_Iterator        => return null;
         when A_Discrete_Cls_Iterator => return I.Dom.R;
         when A_Container_Iterator    => return null;
      end case;
   end;



   --==========================================================================
   --  Iteration variable list
   --==========================================================================

   function Static_Nb_Iterations
     (S: in Iter_Scheme) return Card_Type is
      Result: Card_Type := 1;
   begin
      for I in 1..Length(S) loop
         Result := Result * Static_Nb_Iterations(Iter_Var(Ith(S, I)));
      end loop;
      return Result;
   end;

end Pn.Vars.Iter;
