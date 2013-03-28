with
  Pn.Classes,
  Pn.Classes.Containers.Lists,
  Pn.Compiler.Config,
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Containers,
  Pn.Exprs.List_Assigns,
  Pn.Vars;

use
  Pn.Classes,
  Pn.Classes.Containers.Lists,
  Pn.Compiler.Config,
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Containers,
  Pn.Exprs.List_Assigns,
  Pn.Vars;

package body Pn.Exprs.List_Accesses is

   function New_List_Access
     (L: in Expr;
      I: in Expr;
      C: in Cls) return Expr is
      Result: constant List_Access := new List_Access_Record;
   begin
      Initialize(Result, C);
      Result.L := L;
      Result.I := I;
      return Expr(Result);
   end;

   procedure Free
     (E: in out List_Access_Record) is
   begin
      Free(E.L);
      Free(E.I);
   end;

   function Copy
     (E: in List_Access_Record) return Expr is
      Result: Expr;
   begin
      Result := New_List_Access(Copy(E.L),
                                Copy(E.I),
                                E.C);
      return Result;
   end;

   function Get_Type
     (E: in List_Access_Record) return Expr_Type is
   begin
      return A_List_Access;
   end;

   procedure Color_Expr
     (E    : in     List_Access_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Possible: Cls_Set := Possible_Colors(E.L, Cs);
      Lc      : List_Cls;
   begin
      if Card(Possible) > 1 then
         State := Coloring_Ambiguous_Expression;
      elsif Card(Possible) = 0 then
         State := Coloring_Failure;
      else
         State := Coloring_Success;
      end if;
      if Is_Success(State) then
         Lc := List_Cls(Ith(Possible, 1));
         Color_Expr(E.L, Cls(Lc), Cs, State);
         if Is_Success(State) then
            Color_Expr(E.I, Get_Index_Cls(Lc), Cs, State);
         end if;
      end if;
      Free(Possible);
   end;

   function Possible_Colors
     (E: in List_Access_Record;
      Cs: in Cls_Set) return Cls_Set is
      Result        : constant Cls_Set := New_Cls_Set;
      Tmp           : Cls_Set := Possible_Colors(E.L, Cs);
      Possible_Index: Cls_Set := Possible_Colors(E.I, Cs);
      Possible_List: Cls_Set;
      Ith_Cls       : List_Cls;
      function Pred
        (C: in Cls) return Boolean is
      begin
         return Contains(Possible_Index,
                         Get_Root_Cls(Get_Index_Cls(List_Cls(C))));
      end;
      function Filter is new Generic_Filter(Pred);
   begin
      Filter_On_Type(Tmp, (A_List_Cls => True,
                           others     => False));
      Possible_List := Filter(Tmp);
      for I in 1..Card(Possible_List) loop
         Ith_Cls := List_Cls(Ith(Possible_List, I));
         Insert(Result, Get_Elements_Cls(Ith_Cls));
      end loop;
      Free(Tmp);
      Free(Possible_List);
      Free(Possible_Index);
      return Result;
   end;

   function Is_Assignable
     (E: in List_Access_Record) return Boolean is
   begin
      return Is_Assignable(E.L);
   end;

   function Is_Static
     (E: in List_Access_Record) return Boolean is
   begin
      return False;
   end;

   function Is_Basic
     (E: in List_Access_Record) return Boolean is
   begin
      return Is_Basic(E.L) and Is_Basic(E.I);
   end;

   function Get_True_Cls
     (E: in List_Access_Record) return Cls is
   begin
      return Get_Elements_Cls(List_Cls(Get_Cls(E.L)));
   end;

   function Can_Overflow
     (E: in List_Access_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate_List_And_Index
     (E    : in     List_Access_Record;
      B    : in     Binding;
      List:    out Expr;
      Index:    out Expr;
      State:    out Evaluation_State) is
   begin
      Evaluate(E      => E.L,
               B      => B,
               Check  => True,
               Result => List,
               State  => State);
      if Is_Success(State) then
         Evaluate(E      => E.I,
                  B      => B,
                  Check  => True,
                  Result => Index,
                  State  => State);
         if not Is_Success(State) then
            Free(List);
         end if;
      end if;
   end;

   procedure Evaluate
     (E     : in     List_Access_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
      L    : Expr;
      I    : Expr;
      El   : Expr_List;
      Index: Index_Type;
      C    : constant List_Cls := List_Cls(Get_Cls(E.L));
   begin
      Evaluate_List_And_Index(E, B, L, I, State);
      if Is_Success(State) then
         El   := Get_Expr_List(Container(L));
         Index := Index_Type(Get_Value_Index(Get_Index_Cls(C), I));
         if Index > Length(El) then
            State := Evaluation_List_Index_Check_Failed;
         else
            State := Evaluation_Success;
            Result := Copy(Ith(El, Index));
         end if;
         Free(L);
         Free(I);
      end if;
   end;

   function Static_Equal
     (Left: in List_Access_Record;
      Right: in List_Access_Record) return Boolean is
   begin
      return Static_Equal(Left.L, Right.L) and Static_Equal(Left.I, Right.I);
   end;

   function Compare
     (Left: in List_Access_Record;
      Right: in List_Access_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in List_Access_Record) return Var_List is
      Result  : constant Var_List := Vars_In(E.L);
      Elements: Var_List := Vars_In(E.I);
   begin
      Union(Result, Elements);
      Free(Elements);
      return Result;
   end;

   procedure Get_Sub_Exprs
     (E: in List_Access_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.L, R);
      Get_Sub_Exprs(E.I, R);
   end;

   procedure Get_Observed_Places
     (E     : in     List_Access_Record;
      Places: in out String_Set)is
   begin
      Get_Observed_Places(E.L, Places);
      Get_Observed_Places(E.I, Places);
   end;

   procedure Assign
     (E  : in List_Access_Record;
      B  : in Binding;
      Val: in Expr) is
      Index: Index_Type;
      L    : Expr;
      I    : Expr;
      State: Evaluation_State;
   begin
      Evaluate_List_And_Index(E, B, L, I, State);

      --===
      --  get the position of the index in the index class of the class of L
      --  and replace the element in the list at this position
      --===
      Index :=
        Index_Type(Get_Value_Index(Get_Index_Cls(List_Cls(Get_Cls(E.L))), I));
      if Index <= Length(Get_Expr_List(Container(L))) then
         Replace_Element(Container(L), Val, Index);
      end if;
   end;

   function Get_Assign_Expr
     (E  : in List_Access_Record;
      Val: in Expr) return Expr is
      Result: Expr;
      C      : constant List_Cls := List_Cls(Get_Cls(E.L));
      New_Val: Expr;
   begin
      New_Val := New_List_Assign(Copy(E.L), Copy(E.I), Val, Cls(C));
      Result := Get_Assign_Expr(E.L, New_Val);
      return Result;
   end;

   function To_Helena
     (E: in List_Access_Record) return Ustring is
   begin
      return To_Helena(E.L) & "[" & To_Helena(E.I) & "]";
   end;

   function Compile_Evaluation
     (E: in List_Access_Record;
      M: in Var_Mapping) return Ustring is
      Index_Cls: constant Cls    := Get_Index_Cls(List_Cls(Get_Cls(E.L)));
      Ex       : constant Ustring := Expr_Name(E.Me) & "_index";
      List     : constant Ustring := Compile_Evaluation(E.L, M);
      Shift    : constant Ustring := Cls_First_Const_Name(Index_Cls);
      Error    : constant String := "raise_error(""invalid list index"")";
      Result   : Ustring;
   begin
      if Get_Run_Time_Checks then

         --===
         --  we first compute the index that we put in a temporary variable.
         --  shift is the first value of the index class of the list
         --  if (index - shift) < list.length then
         --     the access is ok and we return list.items[index - shift]
         --  else
         --     we raise an error and we return list.items[0]
         --     (function raise_error always returns FALSE)
         --===
         Result :=
           List & ".items[((" &
           Compile_Evaluation(E.I, M) & " - " & Shift &
           ") < " & List & ".length || " & Error & ") ? " &
           Compile_Evaluation(E.I, M) & " - " & Shift & ": 0]";

      else
         Result :=
           List & ".items[" & Compile_Evaluation(E.I, M) & " - " & Shift & "]";
      end if;
      return Result;
   end;

   function Replace_Var
     (E: in List_Access_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: constant Expr := New_List_Access(Replace_Var(E.L, V, Ne),
                                                Replace_Var(E.I, V, Ne),
                                                E.C);
   begin
      return Result;
   end;

end Pn.Exprs.List_Accesses;
