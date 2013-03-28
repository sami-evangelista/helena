with
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Classes.Vectors;

use
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Classes.Vectors;

package body Pn.Exprs.Vectors is

   function New_Vector
     (E: in Expr_List;
      C: in Cls) return Expr is
      Result: constant Vector := new Vector_Record;
   begin
      Initialize(Result, C);
      Result.E := E;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Vector_Record) is
   begin
      Free_All(E.E);
   end;

   function Copy
     (E: in Vector_Record) return Expr is
      Result: constant Vector := new Vector_Record;
   begin
      Initialize(Result, E.C);
      Result.E := Copy(E.E);
      return Expr(Result);
   end;

   function Get_Type
     (E: in Vector_Record) return Expr_Type is
   begin
      return A_Vector;
   end;

   procedure Color_Expr
     (E    : in    Vector_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Vc: constant Pn.Classes.Vectors.Vector_Cls :=
        Pn.Classes.Vectors.Vector_Cls(C);
   begin
      for I in 1..Length(E.E) loop
         Color_Expr(Ith(E.E, I), Get_Elements_Cls(Vc), Cs, State);
         if not Is_Success(State) then
            return;
         end if;
      end loop;
   end;

   function Possible_Colors
     (E: in Vector_Record;
      Cs: in Cls_Set) return Cls_Set is
      function Pred
        (C: in Cls) return Boolean is
         Ith_Possible: Cls_Set;
         Ith_Expr    : Expr;
         Vector_Color: constant Vector_Cls := Vector_Cls(C);
         Result      : Boolean;
      begin
         --===
         --  check that the vector expression has no more expressions than
         --  the vector color
         --===
         if Elements_Size(Cls(Vector_Color)) < Length(E.E) then
            return False;
         end if;

         --===
         -- check that possible colors of the vector and the vector color match
         --===
         for I in 1..Length(E.E) loop
            Ith_Expr := Ith(E.E, I);
            Ith_Possible := Possible_Colors(Ith_Expr, Cs);
            Result := Contains(Ith_Possible,
                               Get_Root_Cls(Get_Elements_Cls(Vector_Color)));
            Free(Ith_Possible);
            if not Result then
               return False;
            end if;
         end loop;
         return True;
      end;
      function Filter is new Generic_Filter_On_Type(Pred);
   begin
      return Filter(Cs, (A_Vector_Cls => True,
                         others       => False));
   end;

   function Is_Static
     (E: in Vector_Record) return Boolean is
   begin
      return Is_Static(E.E);
   end;

   function Is_Basic
     (E: in Vector_Record) return Boolean is
   begin
      return Is_Basic(E.E);
   end;

   function Get_True_Cls
     (E: in Vector_Record) return Cls is
   begin
      return E.C;
   end;

   function Can_Overflow
     (E: in Vector_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Vector_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
      Vector_Color: constant Vector_Cls := Vector_Cls(E.C);
      Len         : constant Count_Type := Length(E.E);
      L           : Expr_List := New_Expr_List;
      Ex          : Expr;
   begin
      for I in 1..Elements_Size(Cls(Vector_Color)) loop
         if I > Len then
            Append(L, Copy(Ex));
         else
            Evaluate(E      => Ith(E.E, I),
                     B      => B,
                     Check  => True,
                     Result => Ex,
                     State  => State);
            if Is_Success(State) then
               Append(L, Ex);
            else
               Free_All(L);
               return;
            end if;
         end if;
      end loop;
      Result := New_Vector(L, E.C);
   end;

   function Static_Equal
     (Left: in Vector_Record;
      Right: in Vector_Record) return Boolean is
   begin
      return Static_Equal(Left.E, Right.E);
   end;

   function Compare
     (Left: in Vector_Record;
      Right: in Vector_Record) return Comparison_Result is
      procedure Complete
        (L1: in Expr_List;
         L2: in Expr_List) is
         Last: constant Expr := Ith(L1, Length(L1));
      begin
         while Length(L1) < Length(L2) loop
            Append(L1, Copy(Last));
         end loop;
      end;
      Result: Comparison_Result;
      L     : Expr_List;
      R     : Expr_List;
   begin
      L := Copy(Left.E);
      R := Copy(Right.E);
      if    Length(L) > Length(R) then
         Complete(R, L);
      elsif Length(L) < Length(R) then
         Complete(L, R);
      end if;
      Result := Compare(L, R);
      Free_All(L);
      Free_All(R);
      return Result;
   end;

   function Vars_In
     (E: in Vector_Record) return Var_List is
   begin
      return Vars_In(E.E);
   end;

   procedure Get_Sub_Exprs
     (E: in Vector_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.E, R);
   end;

   procedure Get_Observed_Places
     (E     : in     Vector_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.E, Places);
   end;

   function To_Helena
     (E: in Vector_Record) return Ustring is
   begin
      return "[" & To_Helena(E.E) & "]";
   end;

   function Compile_Evaluation
     (E: in Vector_Record;
      M: in Var_Mapping) return Ustring is
      Result: Ustring;
   begin
      Result := Cls_Constructor_Func(E.C) & "(" & Length(E.E);
      if Length(E.E) > 0 then
         Result := Result & ", ";
      end if;
      Result := Result & Compile_Evaluation(E.E, M, True);
      Result := Result & ")";
      return Result;
   end;

   function Replace_Var
     (E: in Vector_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: Expr;
   begin
      Result := New_Vector(Replace_Var(E.E, V, Ne), E.C);
      return Result;
   end;

   function Get_Element
     (V: in Vector;
      I: in Index_Type) return Expr is
      Result: Expr;
   begin
      if I > Length(V.E) then
         Result := Ith(V.E, Length(V.E));
      else
         Result := Ith(V.E, I);
      end if;
      return Result;
   end;

   function Get_Elements
     (V: in Vector) return Expr_List is
   begin
      return V.E;
   end;

   procedure Replace_Element
     (V: in Vector;
      E: in Expr;
      I: in Index_Type) is
      Last: Expr;
   begin
      --===
      --  the size of the vector is less than I =>
      --  we complete the vector by adding the last expression of the vector
      --  at the end of this one until the size = I
      --===
      Last := Ith(V.E, Length(V.E));
      while Length(V.E) < I loop
         Append(V.E, Copy(Last));
      end loop;
      Replace(V.E, I, E, True);
   end;

   procedure Append
     (V: in Vector;
      E: in Expr) is
   begin
      Append(V.E, E);
   end;

end Pn.Exprs.Vectors;
