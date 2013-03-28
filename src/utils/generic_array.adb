with
  Ada.Unchecked_Deallocation;

package body Generic_Array is

   --==========================================================================
   --  Procedures to control the initialization, adjustment and finalization
   --==========================================================================

   procedure Deallocate is
      new Ada.Unchecked_Deallocation(Element_Array, Element_Array_Access);

   procedure Initialize
     (A: in out Array_Type) is
   begin
      A := Empty_Array;
   end;

   procedure Adjust
     (A: in out Array_Type) is
      X: constant Element_Array_Access := A.Elements;
   begin
      if X /= null then
         A.Elements := new Element_Array(X'Range);
         A.Elements(A.Elements'Range) := X(A.Elements'Range);
      end if;
   end;

   procedure Finalize
     (A: in out Array_Type) is
   begin
      if A.Elements /= null then
         Deallocate(A.Elements);
      end if;
   end;



   --==========================================================================
   --  Functions
   --==========================================================================

   function New_Array
     (E: in Element_Type) return Array_Type is
      Result: Array_Type := Empty_Array;
   begin
      Append(Result, E);
      return Result;
   end;

   function New_Array
     (E: in Element_Array) return Array_Type is
      Result: Array_Type := Empty_Array;
   begin
      for I in E'Range loop
         Append(Result, E(I));
      end loop;
      return Result;
   end;

   function Length
     (A: in Array_Type) return Count_Type is
      Result: Count_Type;
   begin
      if A.Last = No_Index then
         Result := 0;
      else
         Result := Index_Type'Pos(A.Last);
      end if;
      return Result;
   end;

   function Is_Empty
     (A: in Array_Type) return Boolean is
   begin
      return A.Last = No_Index;
   end;

   function Ith
     (A: in Array_Type;
      I: in Index_Type) return Element_Type is
   begin
      pragma Assert(Valid_Index(A, I));
      return A.Elements(I);
   end;

   function Index
     (A: in Array_Type;
      E: in Element_Type) return Extended_Index_Type is
   begin
      for I in First_Index(A)..Last_Index(A) loop
         if A.Elements(I) = E then
            return I;
         end if;
      end loop;
      return No_Index;
   end;

   function First
     (A: in Array_Type) return Element_Type is
   begin
      pragma Assert(not Is_Empty(A));
      return A.Elements(Index_Type'First);
   end;

   function Last
     (A: in Array_Type) return Element_Type is
   begin
      pragma Assert(not Is_Empty(A));
      return A.Elements(A.Last);
   end;

   function First_Index
     (A: in Array_Type) return Extended_Index_Type is
   begin
      return Index_Type'First;
   end;

   function Last_Index
     (A: in Array_Type) return Extended_Index_Type is
   begin
      return A.Last;
   end;

   function Valid_Index
     (A: in Array_Type;
      I: in Extended_Index_Type) return Boolean is
      Result: Boolean;
   begin
      if I = No_Index then
         Result := False;
      else
         Result :=
           A.Elements /= null and then I in First_Index(A)..Last_Index(A);
      end if;
      return Result;
   end;

   function Contains
     (A: in Array_Type;
      E: in Element_Type) return Boolean is
   begin
      return Index(A, E) /= No_Index;
   end;

   function Equal
     (A: in Array_Type;
      B: in Array_Type) return Boolean is
      Result: Boolean;
   begin
      if Length(A) /= Length(B) then
         Result := False;
      else
         Result := True;
         for I in First_Index(A)..Last_Index(A) loop
            if not Generic_Array."="(A.Elements(I), B.Elements(I)) then
               Result := False;
               exit;
            end if;
         end loop;
      end if;
      return Result;
   end;



   --==========================================================================
   --  Procedures
   --==========================================================================

   procedure Reallocate
     (A: in out Array_Type) is
      Reallocate  : Boolean := False;
      New_Elements: Element_Array_Access;
      New_Limit   : Extended_Index_Type;
   begin
      if A.Elements = null then
         New_Limit := No_Index;
      else
         New_Limit := A.Elements'Last;
      end if;
      while New_Limit = No_Index or New_Limit < A.Last loop
         Reallocate := True;
         if New_Limit = No_Index then
            New_Limit := Index_Type'First;
         else
            New_Limit := Index_Type'Val(Index_Type'Pos(New_Limit) * 2);
         end if;
      end loop;
      if Reallocate then
         New_Elements := new Element_Array(Index_Type'First .. New_Limit);
         if A.Elements /= null then
            New_Elements(A.Elements'Range) := A.Elements(A.Elements'Range);
            Deallocate(A.Elements);
         end if;
         A.Elements := New_Elements;
      end if;
   end;

   procedure Append
     (A: in out Array_Type;
      E: in     Element_Type) is
   begin
      pragma Assert(A.Last /= Index_Type'Last);
      A.Last := Index_Type'Succ(A.Last);
      Reallocate(A);
      A.Elements(A.Last) := E;
   end;

   procedure Append
     (A: in out Array_Type;
      B: in     Array_Type) is
   begin
      for I in First_Index(B)..Last_Index(B) loop
         Append(A, B.Elements(I));
      end loop;
   end;

   procedure Prepend
     (A: in out Array_Type;
      E: in     Element_Type) is
      Previous_Last: constant Extended_Index_Type := A.Last;
   begin
      pragma Assert(A.Last /= Index_Type'Last);
      A.Last := Index_Type'Succ(A.Last);
      Reallocate(A);
      if Previous_Last /= No_Index then
         A.Elements(Index_Type'Succ(Index_Type'First)..A.Last) :=
           A.Elements(Index_Type'First..Previous_Last);
      end if;
      A.Elements(Index_Type'First) := E;
   end;

   procedure Prepend
     (A: in out Array_Type;
      B: in     Array_Type) is
   begin
      for I in reverse First_Index(B)..Last_Index(B) loop
         Prepend(A, B.Elements(I));
      end loop;
   end;

   procedure Replace
     (A: in out Array_Type;
      E: in     Element_Type;
      I: in     Index_Type) is
   begin
      pragma Assert(Valid_Index(A, I));
      A.Elements(I) := E;
   end;

   procedure Insert
     (A: in out Array_Type;
      E: in     Element_Type;
      I: in     Index_Type) is
      Previous_Last: constant Extended_Index_Type := A.Last;
   begin
      pragma Assert(((A.Last = No_Index and then I = Index_Type'First) or else
                     (I in Index_Type'First..A.Last + 1)) and then
                    A.Last /= Index_Type'Last);
      A.Last := Index_Type'Succ(A.Last);
      Reallocate(A);
      if Previous_Last /= No_Index then
         A.Elements(Index_Type'Succ(I)..A.Last) :=
           A.Elements(I..Previous_Last);
      end if;
      A.Elements(I) := E;
   end;

   procedure Delete
     (A: in out Array_Type;
      E: in     Element_Type) is
      Success: Boolean;
   begin
      Delete(A, E, Success);
      Success := not Success;
   end;

   procedure Delete
     (A: in out Array_Type;
      E: in     Element_Type;
      R:    out Boolean) is
      Tmp: Array_Type := Empty_Array;
   begin
      R := False;
      for I in First_Index(A)..Last_Index(A) loop
         if A.Elements(I) /= E then
            Append(Tmp, A.Elements(I));
         else
            R := True;
         end if;
      end loop;
      A := Tmp;
   end;

   procedure Delete
     (A: in out Array_Type;
      I: in     Index_Type) is
      Previous_Last: constant Extended_Index_Type := A.Last;
   begin
      pragma Assert(Valid_Index(A, I));
      if A.Last = Index_Type'First then
         A.Last := No_Index;
         Deallocate(A.Elements);
         A.Elements := null;
      else
         A.Last := Index_Type'Pred(A.Last);
         A.Elements(I..A.Last) :=
           A.Elements(Index_Type'Succ(I)..Previous_Last);
      end if;
   end;

   procedure Delete_First
     (A: in out Array_Type) is
   begin
      pragma Assert(A.Last /= No_Index);
      if A.Last = Index_Type'First then
         A.Last := No_Index;
      else
         A.Elements(Index_Type'First .. A.Last - 1) :=
           A.Elements(Index_Type'First + 1 .. A.Last);
         A.Last := A.Last - 1;
      end if;
   end;

   procedure Delete_Last
     (A: in out Array_Type) is
   begin
      pragma Assert(A.Last /= No_Index);
      A.Elements(A.Last) := Null_Element;
      if A.Last = Index_Type'First then
         A.Last := No_Index;
      else
         A.Last := A.Last - 1;
      end if;
   end;



   --==========================================================================
   --  Generic operations
   --==========================================================================

   procedure Generic_Delete
     (A: in out Array_Type) is
      Tmp: Array_Type := Empty_Array;
   begin
      for I in First_Index(A)..Last_Index(A) loop
         if not Predicate(A.Elements(I)) then
            Append(Tmp, A.Elements(I));
         end if;
      end loop;
      A := Tmp;
   end;

   procedure Generic_Apply
     (A: in Array_Type) is
   begin
      for I in First_Index(A)..Last_Index(A) loop
         Action(A.Elements(I));
      end loop;
   end;

   procedure Generic_Apply_Subset
     (A: in out Array_Type) is
   begin
      for I in First_Index(A)..Last_Index(A) loop
         if Predicate(A.Elements(I)) then
            Action(A.Elements(I));
         end if;
      end loop;
   end;

   procedure Generic_Apply_Subset_And_Delete
     (A: in out Array_Type) is
      Tmp: Array_Type := Empty_Array;
   begin
      for I in First_Index(A)..Last_Index(A) loop
         if not Predicate(A.Elements(I)) then
            Append(Tmp, A.Elements(I));
         else
            Action(A.Elements(I));
         end if;
      end loop;
      A := Tmp;
   end;

   function Generic_Map
     (A: in Array_Type) return Array_Type is
      Result: Array_Type;
   begin
      if A.Elements = null then
         Result.Elements := null;
      else
         Result.Elements := new Element_Array(A.Elements'Range);
         for I in First_Index(A)..Last_Index(A) loop
            Result.Elements(I) := Map(A.Elements(I));
         end loop;
      end if;
      Result.Last := A.Last;
      return Result;
   end;

   function Generic_Get_First_Satisfying_Element
     (A: in Array_Type) return Element_Type is
   begin
      for I in First_Index(A)..Last_Index(A) loop
         if Predicate(A.Elements(I)) then
            return A.Elements(I);
         end if;
      end loop;
      return Null_Element;
   end;

   function Generic_Get_First_Satisfying_Element_Index
     (A: in Array_Type) return Extended_Index_Type is
   begin
      for I in First_Index(A)..Last_Index(A) loop
         if Predicate(A.Elements(I)) then
            return I;
         end if;
      end loop;
      return No_Index;
   end;

   function Generic_Forall
     (A: in Array_Type) return Boolean is
   begin
      for I in First_Index(A)..Last_Index(A) loop
         if not Predicate(A.Elements(I)) then
            return False;
         end if;
      end loop;
      return True;
   end;

   function Generic_Exists
     (A: in Array_Type) return Boolean is
   begin
      for I in First_Index(A)..Last_Index(A) loop
         if Predicate(A.Elements(I)) then
            return True;
         end if;
      end loop;
      return False;
   end;

   procedure Generic_Compute
     (A: in     Array_Type;
      D: in out Data_Type) is
   begin
      for I in First_Index(A)..Last_Index(A) loop
         Compute(A.Elements(I), D);
      end loop;
   end;

   function Generic_Equal
     (A: in Array_Type;
      B: in Array_Type) return Boolean is
   begin
      if A.Last /= B.Last then
         return False;
      else
         for I in First_Index(A)..Last_Index(A) loop
            if not Generic_Equal."="(A.Elements(I), B.Elements(I)) then
               return False;
            end if;
         end loop;
         return True;
      end if;
   end;

   function Generic_To_String
     (A: in Array_Type) return String is
      function Rec_To_String
        (I: in Index_Type) return String is
      begin
         if I > Last_Index(A) then
            return "";
         else
            declare
               After: constant String := Rec_To_String(I + 1);
               Ith  : constant String := To_String(A.Elements(I));
            begin
               if After /= "" then
                  return Ith & Separator & After;
               else
                  return Ith;
               end if;
            end;
         end if;
      end;
   begin
      if Length(A) = 0 then
         return Empty;
      else
         return Rec_To_String(Index_Type'First);
      end if;
   end;

   function Generic_Count
     (A: in Array_Type) return Count_Type is
      Result: Count_Type := 0;
   begin
      for I in First_Index(A)..Last_Index(A) loop
         if Predicate(A.Elements(I)) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end;

end Generic_Array;
