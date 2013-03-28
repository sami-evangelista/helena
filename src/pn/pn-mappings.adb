with
  Pn.Classes,
  Pn.Exprs,
  Pn.Exprs.Var_Refs,
  Pn.Vars,
  Pn.Vars.Iter;

use
  Pn.Classes,
  Pn.Exprs,
  Pn.Exprs.Var_Refs,
  Pn.Vars,
  Pn.Vars.Iter;

package body Pn.Mappings is

   --==========================================================================
   --  Tuple
   --==========================================================================

   function New_Tuple
     (E     : in Expr_List;
      Vars  : in Var_List;
      Factor: in Mult_Type;
      G     : in Guard) return Tuple is
      Result: constant Tuple := new Tuple_Record;
   begin
      Result.Factor := Factor;
      Result.E     := E;
      Result.Vars  := Vars;
      Result.G     := G;
      return Result;
   end;

   procedure Free
     (T: in out Tuple) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Tuple_Record, Tuple);
   begin
      Free_All(T.E);
      Free(T.Vars);
      Free(T.G);
      Deallocate(T);
      T := null;
   end;

   function Copy
     (T: in Tuple) return Tuple is
      Result: constant Tuple := new Tuple_Record;
   begin
      Result.Factor := T.Factor;
      Result.E     := Copy(T.E);
      Result.Vars  := Copy(T.Vars);
      Result.G     := Copy(T.G);
      Map_Vars(Result.E, T.Vars, Result.Vars);
      Map_Vars(Result.G, T.Vars, Result.Vars);
      return Result;
   end;

   function Get_Factor
     (T: in Tuple) return Mult_Type is
   begin
      return T.Factor;
   end;

   procedure Set_Factor
     (T     : in Tuple;
      Factor: in Mult_Type) is
   begin
      T.Factor := Factor;
   end;

   function Get_Expr_List
     (T: in Tuple) return Expr_List is
   begin
      return T.E;
   end;

   procedure Set_Expr_List
     (T: in Tuple;
      E: in Expr_List) is
   begin
      T.E := E;
   end;

   function Get_Guard
     (T: in Tuple) return Guard is
   begin
      return T.G;
   end;

   procedure Set_Guard
     (T: in Tuple;
      G: in Guard) is
   begin
      T.G := G;
   end;

   function Get_Iter_Vars
     (T: in Tuple) return Var_List is
   begin
      return T.Vars;
   end;

   procedure Set_Iter_Vars
     (T   : in Tuple;
      Vars: in Var_List) is
   begin
      T.Vars := Vars;
   end;

   function Size
     (T: in Tuple) return Count_Type is
   begin
      return Length(T.E);
   end;

   function Ith
     (T: in Tuple;
      I: in Index_Type) return Expr is
   begin
      return Ith(T.E, I);
   end;

   procedure Append
     (T: in Tuple;
      E: in Expr) is
   begin
      Append(T.E, E);
   end;

   procedure Delete_Last
     (T: in Tuple;
      N: in Count_Type := 1) is
   begin
      for I in 1..N loop
         Delete_Last(T.E, True);
      end loop;
   end;

   procedure Delete
     (T: in Tuple;
      I: in Index_Type) is
   begin
      Delete(T.E, I, True);
   end;

   procedure Proj
     (T    : in out Tuple;
      First: in     Index_Type;
      Last: in     Index_Type) is
      Result: Tuple;
      After: Natural;
      Before: Natural;
   begin
      Before :=  First - 1;
      After := Size(T) - Last;
      Result := Copy(T);
      for I in 1..Before loop
         Delete(Result.E, 1, True);
      end loop;
      for I in 1..After loop
         Delete_Last(Result.E, True);
      end loop;
      Free(T);
      T := Result;
   end;

   function Vars_At_Top
     (T: in Tuple) return Var_List is
      Result: Var_List := New_Var_List;
      function Is_Tuple_Var
        (V: in Var) return Boolean is
      begin
         return Contains(T.Vars, V);
      end;
      procedure Remove_Tuple_Vars is new Generic_Delete_Vars(Is_Tuple_Var);
   begin
      Result := Vars_At_Top(T.E);

      --===
      --  remove the variables of the tuple
      --===
      Remove_Tuple_Vars(Result);
      return Result;
   end;

   function Vars_In
     (T: in Tuple) return Var_List is
      Result: constant Var_List := New_Var_List;
      Ex    : Expr;
      Vars  : Var_List;
      function Is_Tuple_Var
        (V: in Var) return Boolean is
      begin
         return Contains(T.Vars, V);
      end;
      procedure Remove_Tuple_Vars is new Generic_Delete_Vars(Is_Tuple_Var);
   begin
      --===
      --  add variables appearing in the expressions of the tuple
      --===
      for I in 1..Size(T) loop
         Ex := Ith(T, I);
         Vars := Vars_In(Ex);
         Union(Result, Vars);
         Free(Vars);
      end loop;

      --===
      --  add variables appearing in the guard
      --===
      Vars := Vars_In(T.G);
      Union(Result, Vars);
      Free(Vars);

      --===
      --  remove for-loop variables of the tuple
      --===
      Remove_Tuple_Vars(Result);
      return Result;
   end;

   function Needs_To_Unify
     (T: in Tuple) return Var_List is
      Result: Var_List;
      Temp  : Var_List;
   begin
      --===
      --  needed variables are the variables in T
      --===
      Result := Vars_In(T);

      --===
      --  add the variables which appear in the guard of T
      --===
      Temp := Vars_In(T.G);
      Difference(Temp, T.Vars);
      Union(Result, Temp);

      --===
      --  if the guard is true => remove the variable at top level
      --===
      if Get_Guard(T) = True_Guard then
         Temp := Vars_At_Top(T);
         Difference(Result, Temp);
         Free(Temp);
      end if;
      return Result;
   end;

   function Static_Equal
     (T1: in Tuple;
      T2: in Tuple) return Boolean is
   begin
      if T1.Factor /= T2.Factor then
         return False;
      end if;
      if T1.G /= True_Guard or T2.G /= True_Guard then
	 return False;
      end if;
      for I in 1..Size(T1) loop
	 if not Static_Equal(Ith(T1, I), Ith(T2, I)) then
	    return False;
	 end if;
      end loop;
      return True;
   end;

   function Unified_By
     (T: in Tuple) return Var_List is
      Result: Var_List;
   begin
      if Get_Guard(T) = True_Guard then
         Result := Vars_At_Top(T);
      else
         Result := New_Var_List;
      end if;
      return Result;
   end;

   function Is_Unifiable
     (T      : in Tuple;
      Unified: in Var_List) return Boolean is
      Result: Boolean;
      Needs: Var_List := Needs_To_Unify(T);
   begin
      --===
      --  variables needed by T must be already unified
      --===
      Result := Included(Needs, Unified);
      Free(Needs);
      return Result;
   end;

   procedure Replace_Var
     (T: in Tuple;
      V: in Var;
      E: in Expr) is
   begin
      Replace_Var(T.E, V, E);
      Replace_Var(T.G, V, E);
   end;

   procedure Map_Vars
     (T    : in Tuple;
      Vars: in Var_List;
      Nvars: in Var_List) is
   begin
      Map_Vars(T.E, Vars, Nvars);
      Map_Vars(T.G, Vars, Nvars);
   end;

   function Is_Unitary
     (T: in Tuple) return Boolean is
      Result: Boolean;
   begin
      Result := T.Factor <= 1;
      return Result;
   end;

   function Is_Projection
     (T: in Tuple) return Boolean is
      Ex   : Expr;
      Found: Var_List := New_Var_List;
      V    : Var;
   begin
      if T.Factor /= 1 or Get_Guard(T) /= True_Guard or Length(T.Vars) > 0 then
         return False;
      end if;
      for I in 1..Size(T) loop
         Ex := Ith(T, I);
         if Get_Type(Ex) /= Pn.A_Var then
            Free(Found);
            return False;
         end if;
         V := Get_Var(Var_Ref(Ex));
         if not Contains(Found, V) then
            Append(Found, V);
         else
            Free(Found);
            return False;
         end if;
      end loop;
      Free(Found);
      return True;
   end;

   function Is_Injective
     (T: in Tuple;
      V: in Var_List) return Boolean is
      Result: Boolean;
      Ex    : Expr;
      Found: Var_List := New_Var_List;
      Va    : Var;
   begin
      for I in 1..Size(T) loop
         Ex := Ith(T, I);
         if Get_Type(Ex) = Pn.A_Var then
            Va := Get_Var(Var_Ref(Ex));
            if not Contains(Found, Va) then
               Append(Found, Va);
            end if;
         end if;
      end loop;
      Result := Included(V, Found);
      Free(Found);
      return Result;
   end;

   function Is_Surjective
     (T: in Tuple) return Boolean is
      Found: Var_List := New_Var_List;
      Ex   : Expr;
      V    : Var;
   begin
      if Get_Guard(T) /= True_Guard then
         return False;
      end if;
      for I in 1..Size(T) loop
         Ex := Ith(T, I);
         if Get_Type(Ex) /= Pn.A_Var then
            Free(Found);
            return False;
         end if;
         V := Get_Var(Var_Ref(Ex));
         if not Contains(Found, V) then
            Append(Found, V);
         else
            Free(Found);
            return False;
         end if;
      end loop;
      Free(Found);
      return True;
   end;

   function Is_Token_Unitary
     (T: in Tuple) return Boolean is
      Result: Boolean;
   begin
      Result := Length(T.Vars) = 0;
      return Result;
   end;

   function Is_Total
     (T: in Tuple) return Boolean is
      Result: Boolean;
   begin
      Result := T.G = True_Guard and Length(T.Vars) = 0;
      return Result;
   end;

   function To_Helena
     (T: in Tuple) return Ustring is
      Result: Ustring := Null_String;
   begin
      if Length(T.Vars) > 0 then
         Result := "for (" & To_Helena(T.Vars) & ") ";
      end if;
      if T.G /= True_Guard then
         Result := Result & "if (" & To_Helena(T.G) & ") ";
      end if;
      if T.Factor > 1 then
         Result := Result & T.Factor & " * ";
      end if;
      if Size(T) > 0  then
         Result := Result & "<( ";
         for I in 1..Size(T) loop
            if I > 1 then
               Result := Result & ", ";
            end if;
            Result := Result & To_Helena(Ith(T, I));
         end loop;
         Result := Result & " )>";
      else
         Result := Result & "epsilon";
      end if;
      return Result;
   end;

   function To_Pnml
     (T: in Tuple) return Ustring_List is
      Result: Ustring_List;
      procedure Apply
        (T      : in Tuple;
         First  : in Card_Type;
         Last   : in Card_Type;
         Current: in Card_Type) is
	 G  : constant Guard := Get_Guard(T);
	 E  : constant Expr_List := Get_Expr_List(T);
	 F  : constant Mult_Type := Get_Factor(T);
	 Xml: Ustring := Null_String;
      begin
	 for I in 1..Length(E) loop
	    Xml := Xml & "<subterm>" & To_Pnml(Ith(E, I)) & "</subterm>";
	 end loop;
	 if Length(E) > 1 then
	    Xml := "<subterm><tuple>" & Xml & "</tuple></subterm>";
	 end if;
	 Xml :=
	   "<subterm><numberof><subterm>" &
	   "<numberconstant value=""" & F & """><positive/></numberconstant>" &
	   "</subterm>" & Xml & "</numberof></subterm>";
	 String_List_Pkg.Append(Result, Xml);
      end;
      procedure Tuple_Loop is new Generic_Unfold(Apply);
   begin
      Result := String_List_Pkg.Empty_Array;
      Tuple_Loop(T);
      return Result;
   end;

   procedure Generic_Unfold
     (T: in Tuple) is
      procedure Dummy_Expr
        (E  : in Expr;
         Pos: in Index_Type) is
      begin
         null;
      end;
      procedure Dummy_Guard
        (G: in Guard) is
      begin
         null;
      end;
      procedure Unfold is
         new Generic_Unfold_And_Handle(Apply           => Apply,
                                       On_Expr_Before  => Dummy_Expr,
                                       On_Expr_After   => Dummy_Expr,
                                       On_Guard_Before => Dummy_Guard,
                                       On_Guard_After  => Dummy_Guard);
   begin
      Unfold(T);
   end;

   procedure Generic_Unfold_And_Handle
     (T: in Tuple) is

      type Boolean_Array is array(1..Size(T)) of Boolean;

      Current: Card_Type := 1;
      First  : constant Card_Type := 1;
      Last   : constant Card_Type := Static_Nb_Iterations(T.Vars);

      procedure Rec_Unfold
        (Tup          : in Tuple;
         Pos          : in Index_Type;
         Exprs_Handled: in Boolean_Array;
         Guard_Handled: in Boolean) is
         G                  : constant Guard := Get_Guard(Tup);
         Val                : Expr := null;
         Nt                 : Tuple := null;
         Nel                : Expr_List;
         Ng                 : Guard;
         It_Var             : Iter_Var;
         Exprs_Handled_After: Boolean_Array;
         Guard_Handled_After: Boolean;
         Values             : Expr_List;

         function Is_Evaluable
           (Ex: in Expr) return Boolean is
            Result : Boolean;
            Ex_Vars: Var_List := Vars_In(Ex);
         begin
            Intersect(Ex_Vars, T.Vars);
            Result := Is_Empty(Ex_Vars);
            Free(Ex_Vars);
            return Result;
         end;

         function Is_Checkable
           (G: in Guard) return Boolean is
            Result: Boolean;
            G_Vars: Var_List := Vars_In(G);
         begin
            Intersect(G_Vars, T.Vars);
            Result := Is_Empty(G_Vars);
            Free(G_Vars);
            return Result;
         end;

      begin
         --===
         --  check all the evaluable expressions
         --===
         for I in Exprs_Handled_After'Range loop
            Exprs_Handled_After(I) := Is_Evaluable(Ith(Tup, I));
         end loop;

         --===
         --  check if the guard is evaluable
         --===
         Guard_Handled_After := Is_Checkable(G);

         --===
         --  apply the pre-procedure on the guard if this one is now evaluable
         --===
         if not Guard_Handled and Guard_Handled_After then
            On_Guard_Before(G);
         end if;

         --===
         --  apply the pre-procedure on all the newly evaluable expression
         --===
         for I in Exprs_Handled'Range loop
            if not Exprs_Handled(I) and Exprs_Handled_After(I) then
               On_Expr_Before(Ith(Tup, I), I);
            end if;
         end loop;

         if Pos > Length(T.Vars) then

            --===
            --  all the variables of the tuple have been unfolded we can apply
            --  the procedure on the tuple
            --===
            Apply(Tup, First, Last, Current);
            Current := Current + 1;

         else
            It_Var := Iter_Var(Ith(T.Vars, Pos));

            --  Low := Get_Low(It_Var);
            --  Evaluate_Static(E      => Low,
            --                  Check  => True,
            --                  Result => Low_Val,
            --                  State  => State);
            --  pragma Assert(Is_Success(State));
            --  Low_Pos := Get_Value_Index(C, Low_Val);
            --  Free(Low);
            --  Free(Low_Val);
            --  High := Get_High(It_Var);
            --  Evaluate_Static(E      => High,
            --                  Check  => True,
            --                  Result => High_Val,
            --                  State  => State);
            --  pragma Assert(Is_Success(State));
            --  High_Pos := Get_Value_Index(C, High_Val);
            --  Free(High);
            --  Free(High_Val);
            --===
            --  for each possible value of the iteration variable we
            --  recursively call on a new tuple in which the iteration
            --  variable has been replaced by its current value
            --===
            Values := Static_Enum_Values(It_Var);
            for I in 1..Length(Values) loop
               begin
                  Val := Ith(Values, I);
                  Nel := Copy(Tup.E);
                  Replace_Var(Nel, Var(It_Var), Val);
                  Ng := Copy(Tup.G);
                  Replace_Var(Ng, Var(It_Var), Val);
                  Nt := New_Tuple(E      => Nel,
                                  Vars   => New_Var_List,
                                  Factor => Tup.Factor,
                                  G      => Ng);
                  Rec_Unfold
                    (Nt, Pos + 1, Exprs_Handled_After, Guard_Handled_After);
                  Free(Nt);
               exception
                  when others =>
                     if Nt  /= null then Free(Nt);  end if;
                     if Val /= null then Free(Val); end if;
                     raise;
               end;
            end loop;
            Free_All(Values);
         end if;

         --===
         --  apply the post-procedure on all the newly evaluable expression
         --===
         for I in Exprs_Handled'Range loop
            if not Exprs_Handled(I) and Exprs_Handled_After(I) then
               On_Expr_After(Ith(Tup, I), I);
            end if;
         end loop;

         --===
         --  apply the post-procedure on the guard if this one is now evaluable
         --===
         if not Guard_Handled and Guard_Handled_After then
            On_Guard_After(G);
         end if;
      end;
   begin
      Rec_Unfold(T, 1, (others => False), False);
   end;



   --==========================================================================
   --  Tuple scheduling
   --==========================================================================

   package TAP renames Tuple_Array_Pkg;

   function New_Tuple_Scheduling return Tuple_Scheduling is
      Result: constant Tuple_Scheduling := new Tuple_Scheduling_Record;
   begin
      Result.Tuples := TAP.Empty_Array;
      return Result;
   end;

   function Ith
     (S: in Tuple_Scheduling;
      I: in Index_Type) return Tuple is
   begin
      return TAP.Ith(S.Tuples, I);
   end;

   function Length
     (S: in Tuple_Scheduling) return Count_Type is
   begin
      return TAP.Length(S.Tuples);
   end;

   function Copy
     (S: in Tuple_Scheduling) return Tuple_Scheduling is
      Result: constant Tuple_Scheduling := new Tuple_Scheduling_Record;
   begin
      Result.Tuples := S.Tuples;
      return Result;
   end;

   function Contains
     (S: in Tuple_Scheduling;
      T: in Tuple) return Boolean is
   begin
      return TAP.Contains(S.Tuples, T);
   end;

   procedure Free
     (S: in out Tuple_Scheduling) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Tuple_Scheduling_Record,
                                        Tuple_Scheduling);
   begin
      Deallocate(S);
   end;

   procedure Append
     (S: in Tuple_Scheduling;
      T: in Tuple) is
   begin
      TAP.Append(S.Tuples, T);
   end;

   procedure Delete_Last
     (S: in Tuple_Scheduling) is
   begin
      TAP.Delete_Last(S.Tuples);
   end;

   function Is_Valid
     (S      : in Tuple_Scheduling;
      Unified: in Var_List) return Boolean is
      Loc_Unified: Var_List := Copy(Unified);
      T          : Tuple;
      Temp       : Var_List;
   begin
      for I in 1..Length(S) loop
         T := Ith(S, I);
         if Is_Unifiable(T, Loc_Unified) then
            Temp := Unified_By(T);
            Union(Loc_Unified, Temp);
            Free(Temp);
         else
            Free(Loc_Unified);
            return False;
         end if;
      end loop;
      Free(Loc_Unified);
      return True;
   end;

   function Exist_Valid_Permutation
     (S: in Tuple_Scheduling) return Boolean is
      Result: Boolean;
      Temp  : Tuple_Scheduling := New_Tuple_Scheduling;
      function Is_Valid
        (I: in Index_Type) return Boolean is
         T     : Tuple;
         Vars  : Var_List;
         Result: Boolean;
      begin
         if I > Length(S) then
            Free(Vars);
            Result := True;
         else
            Vars := New_Var_List;
            Result := False;
            for J in 1..Length(S) loop
               T := Ith(S, J);
               if not Contains(Temp, T) then
                  Append(Temp, T);
                  if Is_Valid(Temp, Vars) and then Is_Valid(I + 1) then
                     Result := True;
                     exit;
                  end if;
                  Delete_Last(Temp);
               end if;
            end loop;
            Free(Vars);
         end if;
         return Result;
      end;
   begin
      Result := Is_Valid(1);
      Free(Temp);
      return Result;
   end;

   function To_String
     (S: in Tuple_Scheduling) return Ustring is
      Result: Ustring := Null_String;
   begin
      for I in 1..Length(S) loop
         if I > 1 then
            Result := Result & ", ";
         end if;
         Result := Result & To_Helena(Ith(S, I));
      end loop;
      return Result;
   end;



   --==========================================================================
   --  Color mapping
   --==========================================================================

   procedure Deallocate is
      new Ada.Unchecked_Deallocation(Mapping_Record, Mapping);

   function New_Mapping return Mapping is
      Result: constant Mapping := new Mapping_Record;
   begin
      Result.Tuples := TAP.Empty_Array;
      Result.Ref   := 1;
      return Result;
   end;

   function New_Mapping
     (T: in Tuple_Array) return Mapping is
      Result: constant Mapping := new Mapping_Record;
   begin
      Result.Tuples := TAP.New_Array(TAP.Element_Array(T));
      Result.Ref   := 1;
      return Result;
   end;

   function New_Mapping
     (T: in Tuple) return Mapping is
   begin
      return New_Mapping(Tuple_Array'(1 =>T));
   end;

   procedure Free
     (M: in out Mapping) is
      procedure Free is new TAP.Generic_Apply(Free);
   begin
      if M /= Null_Mapping then
         M.Ref := M.Ref - 1;
         if M.Ref = 0 then
            Free(M.Tuples);
            Deallocate(M);
            M := null;
         end if;
      end if;
   end;

   function Shared_Copy
     (M: in Mapping) return Mapping is
   begin
      if M = Null_Mapping then
         return Null_Mapping;
      else
         M.Ref := M.Ref + 1;
         return M;
      end if;
   end;

   function Copy
     (M: in Mapping) return Mapping is
      Result: Mapping;
      function Copy is new TAP.Generic_Map(Copy);
   begin
      if M = Null_Mapping then
         Result := null;
      else
         Result        := new Mapping_Record;
         Result.Ref    := 1;
         Result.Tuples := Copy(M.Tuples);
      end if;
      return Result;
   end;

   function Size
     (M: in Mapping) return Count_Type is
   begin
      if M = Null_Mapping then
         return 0;
      else
         return TAP.Length(M.Tuples);
      end if;
   end;

   function Ith
     (M: in Mapping;
      I: in Index_Type) return Tuple is
   begin
      return TAP.Ith(M.Tuples, I);
   end;

   procedure Add
     (M: in Mapping;
      T: in Tuple) is
   begin
      TAP.Append(M.Tuples, T);
   end;

   procedure Delete_Last_Expr
     (M: in Mapping) is
      T: Tuple;
   begin
      for I in 1..Size(M) loop
         T := Ith(M, I);
         Delete_Last(T);
      end loop;
   end;

   procedure Delete_Expr
     (M: in Mapping;
      I: in Index_Type) is
   begin
      for J in 1..Size(M) loop
         Delete(Ith(M, J), I);
      end loop;
   end;

   function Vars_At_Top
     (M: in Mapping) return Var_List is
      Result: constant Var_List := New_Var_List;
      T     : Tuple;
      Vars  : Var_List;
   begin
      for I in 1..Size(M) loop
         T := Ith(M, I);
         Vars := Vars_At_Top(T);
         Union(Result, Vars);
         Free(Vars);
      end loop;
      return Result;
   end;

   function Vars_In
     (M: in Mapping) return Var_List is
      Result: constant Var_List := New_Var_List;
      T     : Tuple;
      Vars  : Var_List;
   begin
      for I in 1..Size(M) loop
         T := Ith(M, I);
         Vars := Vars_In(T);
         Union(Result, Vars);
         Free(Vars);
      end loop;
      return Result;
   end;

   procedure Replace_Var
     (M: in Mapping;
      V: in Var;
      E: in Expr) is
   begin
      for I in 1..Size(M) loop
         Replace_Var(Ith(M, I), V, E);
      end loop;
   end;

   procedure Map_Vars
     (M    : in Mapping;
      Vars: in Var_List;
      Nvars: in Var_List) is
   begin
      for I in 1..Size(M) loop
         Map_Vars(Ith(M, I), Vars, Nvars);
      end loop;
   end;

   function Is_Empty
     (M: in Mapping) return Boolean is
   begin
      return M = Null_Mapping or else TAP."="(M.Tuples, TAP.Empty_Array);
   end;

   function Is_Unitary
     (M: in Mapping) return Boolean is
   begin
      return
        M = Null_Mapping or else
        Is_Empty(M) or else
        (Size(M) = 1 and then Is_Unitary(Ith(M, 1)));
   end;

   function Is_Projection
     (M: in Mapping) return Boolean is
   begin
      return
        M /= Null_Mapping and then
        Size(M) = 1 and then
        Is_Projection(Ith(M, 1));
   end;

   function Is_Injective
     (M: in Mapping;
      V: in Var_List) return Boolean is
   begin
      return
        M /= Null_Mapping and then
        Size(M) = 1 and then
        Is_Injective(Ith(M, 1), V);
   end;

   function Is_Surjective
     (M: in Mapping) return Boolean is
   begin
      for I in 1..Size(M) loop
         if Is_Surjective(Ith(M, I)) then
            return True;
         end if;
      end loop;
      return False;
   end;

   function Is_Token_Unitary
     (M: in Mapping) return Boolean is
   begin
      return
        M /= Null_Mapping and then
        Size(M) = 1 and then
        Is_Token_Unitary(Ith(M, 1));
   end;

   function Is_Total
     (M: in Mapping) return Boolean is
   begin
      for I in 1..Size(M) loop
         if Is_Total(Ith(M, I)) then
            return True;
         end if;
      end loop;
      return False;
   end;

   function Get_Max_Mult
     (M: in Mapping) return Mult_Type is
      Result: Mult_Type := 0;
   begin
      for I in 1..Size(M) loop
         Result := Result + Get_Factor(Ith(M, I));
      end loop;
      return Result;
   end;

   function Static_Equal
     (M1: in Mapping;
      M2: in Mapping) return Boolean is
      function Equal
        (M1: in Mapping;
         M2: in Mapping) return Boolean is
         T1: Tuple;
         T2: Tuple;
         Eq: Boolean;
      begin
         for I in 1..Size(M1) loop
            Eq := False;
            T1 := Ith(M1, I);
            for J in 1..Size(M2) loop
               T2 := Ith(M2, J);
               if Static_Equal(T1, T2) then
                  Eq := True;
                  exit;
               end if;
            end loop;
            if not Eq then
               return False;
            end if;
         end loop;
         return True;
      end;
   begin
      return
        (M1 = Null_Mapping   and then
         M2 = Null_Mapping)
        or else
        (M1 /= Null_Mapping  and then
         M2 /= Null_Mapping  and then
         Size(M1) = Size(M2) and then
         Equal(M1, M2)       and then
         Equal(M2, M1));
   end;

   function To_Helena
     (M: in Mapping) return Ustring is
      Result: Ustring := Null_String;
      T     : Tuple;
   begin
      for I in 1..Size(M) loop
         if I > 1 then
            Result := Result & " + ";
         end if;
         T := Ith(M, I);
         Result := Result & To_Helena(T);
      end loop;
      return Result;
   end;

   function To_Pnml
     (M: in Mapping) return Ustring is
      Result: Ustring := Null_String;
      L     : Ustring_List;
   begin
      for I in 1..Size(M) loop
	 String_List_Pkg.Append(L, To_Pnml(Ith(M, I)));
      end loop;
      for I in 1..String_List_Pkg.Length(L) loop
	 Result := Result & String_List_Pkg.Ith(L, I);
      end loop;
      Result := "<add>" & Result & "</add>";
      return Result;
   end;

end Pn.Mappings;
