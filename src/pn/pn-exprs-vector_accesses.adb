with
  Pn.Classes,
  Pn.Classes.Vectors,
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Vector_Assigns,
  Pn.Exprs.Vectors,
  Pn.Vars;

use
  Pn.Classes,
  Pn.Classes.Vectors,
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Vector_Assigns,
  Pn.Exprs.Vectors,
  Pn.Vars;

package body Pn.Exprs.Vector_Accesses is

   function New_Vector_Access
     (V: in Expr;
      I: in Expr_List;
      C: in Cls) return Expr is
      Result: constant Vector_Access := new Vector_Access_Record;
   begin
      Initialize(Result, C);
      Result.V := V;
      Result.I := I;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Vector_Access_Record) is
   begin
      Free(E.V);
      Free_All(E.I);
   end;

   function Copy
     (E: in Vector_Access_Record) return Expr is
      Result: constant Vector_Access := new Vector_Access_Record;
   begin
      Initialize(Result, E.C);
      Result.V := Copy(E.V);
      Result.I := Copy(E.I);
      return Expr(Result);
   end;

   function Get_Type
     (E: in Vector_Access_Record) return Expr_Type is
   begin
      return A_Vector_Access;
   end;

   procedure Color_Expr
     (E    : in     Vector_Access_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Possible: Cls_Set := Possible_Colors(E.V, Cs);
      Vc      : Vector_Cls;
   begin
      if Card(Possible) > 1 then
         State := Coloring_Ambiguous_Expression;
      elsif Card(Possible) = 0 then
         State := Coloring_Failure;
      else
         State := Coloring_Success;
         Vc   := Vector_Cls(Ith(Possible, 1));
         Color_Expr(E.V, Cls(Vc), Cs, State);
         if Is_Success(State) then
            Color_Expr_List(E.I, Get_Index_Dom(Vc), Cs, State);
         end if;
      end if;
      Free(Possible);
   end;

   function Possible_Colors
     (E: in Vector_Access_Record;
      Cs: in Cls_Set) return Cls_Set is
      Result         : constant Cls_Set := New_Cls_Set;
      Possible_Vector: Cls_Set;
      Tmp            : Cls_Set := Possible_Colors(E.V, Cs);
      Ith_Cls        : Vector_Cls;
      function Pred
        (C: in Cls) return Boolean is
         Vector      : constant Vector_Cls := Vector_Cls(C);
         Index       : constant Dom := Get_Index_Dom(Vector);
         Ith_Possible: Cls_Set;
         Ith_Expr    : Expr;
         Result      : Boolean;
      begin
         --===
         --  check that the indexes list has the same size than the indexes dom
         --  of the vector color
         --===
         if Size(Index) /= Length(E.I) then
            return False;
         end if;

         --===
         --  check that potential colors of the vector and the
         --  vector color match
         --===
         for I in 1..Length(E.I) loop
            Ith_Expr := Ith(E.I, I);
            Ith_Possible := Possible_Colors(Ith_Expr, Cs);
            Result := Contains(Ith_Possible, Get_Root_Cls(Ith(Index, I)));
            Free(Ith_Possible);
            if not Result then
               return False;
            end if;
         end loop;
         return True;
      end;
      function Filter is new Generic_Filter_On_Type(Pred);
   begin

      --===
      --  get the potential colors of the vector and filter it according the
      --  supplied indexes
      --===
      Possible_Vector := Filter(Tmp, (A_Vector_Cls => True,
                                      others       => False));
      for I in 1..Card(Possible_Vector) loop
         Ith_Cls := Vector_Cls(Ith(Possible_Vector, I));
         Insert(Result, Get_Elements_Cls(Ith_Cls));
      end loop;
      Free(Tmp);
      Free(Possible_Vector);
      return Result;
   end;

   function Is_Assignable
     (E: in Vector_Access_Record) return Boolean is
   begin
      return Is_Assignable(E.V);
   end;

   function Is_Static
     (E: in Vector_Access_Record) return Boolean is
   begin
      return False;
   end;

   function Is_Basic
     (E: in Vector_Access_Record) return Boolean is
   begin
      return Is_Basic(E.V) and Is_Basic(E.I);
   end;

   function Get_True_Cls
     (E: in Vector_Access_Record) return Cls is
   begin
      return Get_Elements_Cls(Vector_Cls(Get_Cls(E.V)));
   end;

   function Can_Overflow
     (E: in Vector_Access_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate_Vector_And_Index
     (E     : in     Vector_Access_Record;
      B     : in     Binding;
      Vector:    out Expr;
      Index:    out Expr_List;
      State:    out Evaluation_State) is
   begin
      Evaluate(E      => E.V,
               B      => B,
               Check  => True,
               Result => Vector,
               State  => State);
      if Is_Success(State) then
         Evaluate(E      => E.I,
                  B      => B,
                  Check  => True,
                  Result => Index,
                  State  => State);
         if not Is_Success(State) then
            Free(Vector);
         end if;
      end if;
   end;

   procedure Evaluate
     (E     : in     Vector_Access_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
      V     : Expr;
      Index: Expr_List;
      Pos   : Card_Type;
   begin
      Evaluate_Vector_And_Index(E, B, V, Index, State);
      if Is_Success(State) then
         Pos   := Get_Index_Position(Vector_Cls(Get_Cls(E.V)), Index);
         Result := Copy(Get_Element(Vector(V), Natural(Pos)));
         Free(V);
         Free_All(Index);
      end if;
   end;

   function Static_Equal
     (Left: in Vector_Access_Record;
      Right: in Vector_Access_Record) return Boolean is
   begin
      return
        Static_Equal(Left.V, Right.V) and then
        Static_Equal(Left.I, Right.I);
   end;

   function Compare
     (Left: in Vector_Access_Record;
      Right: in Vector_Access_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in Vector_Access_Record) return Var_List is
      Result  : constant Var_List := Vars_In(E.V);
      Elements: Var_List := Vars_In(E.I);
   begin
      Union(Result, Elements);
      Free(Elements);
      return Result;
   end;

   procedure Get_Sub_Exprs
     (E: in Vector_Access_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.V, R);
      Get_Sub_Exprs(E.I, R);
   end;

   procedure Get_Observed_Places
     (E     : in     Vector_Access_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.V, Places);
      Get_Observed_Places(E.I, Places);
   end;

   procedure Assign
     (E  : in Vector_Access_Record;
      B  : in Binding;
      Val: in Expr) is
      Index: Expr_List;
      V    : Expr;
      Pos  : Card_Type;
      State: Evaluation_State;
   begin
      Evaluate_Vector_And_Index(E, B, V, Index, State);
      if Is_Success(State) then
         Pos := Get_Index_Position(Vector_Cls(E.V.C), Index);
         Free_All(Index);
         Replace_Element(Vector(V), Val, Natural(Pos));
         Assign(E.V, B, V);
      end if;
   end;

   function Get_Assign_Expr
     (E  : in Vector_Access_Record;
      Val: in Expr) return Expr is
      Result: Expr;
      C      : constant Vector_Cls := Vector_Cls(E.V.C);
      New_Val: Expr;
   begin
      New_Val := New_Vector_Assign(Copy(E.V), Copy(E.I), Val, Cls(C));
      Result := Get_Assign_Expr(E.V, New_Val);
      return Result;
   end;

   function To_Helena
     (E: in Vector_Access_Record) return Ustring is
   begin
      return To_Helena(E.V) & "[" & To_Helena(E.I) & "]";
   end;

   function Compile_Evaluation
     (E: in Vector_Access_Record;
      M: in Var_Mapping) return Ustring is
      Result: Ustring;
      C     : Cls;
   begin
      Result := Compile_Evaluation(E.V, M, False) & ".vector";
      for I in 1..Length(E.I) loop
         C     := Get_Cls(Ith(E.I, I));
         Result := Result &
           "[" &
           Compile_Evaluation(Ith(E.I, I), M, True) & " - " &
           Cls_First_Const_Name(C) &
           "]";
      end loop;
      return Result;
   end;

   function Replace_Var
     (E: in Vector_Access_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: constant Expr := New_Vector_Access(Replace_Var(E.V, V, Ne),
                                                  Replace_Var(E.I, V, Ne),
                                                  E.C);
   begin
      return Result;
   end;

end Pn.Exprs.Vector_Accesses;
