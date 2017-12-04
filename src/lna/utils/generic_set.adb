with
  Ada.Unchecked_Deallocation;

package body Generic_Set is

   --==========================================================================
   --  Procedures to control the initialization, adjustment and finalization
   --==========================================================================

   procedure Deallocate is
      new Ada.Unchecked_Deallocation(Element_Array, Element_Array_Access);

   procedure Initialize
     (S: in out Set_Type) is
   begin
      S := Empty_Set;
   end;

   procedure Adjust
     (S: in out Set_Type) is
      X: constant Element_Array_Access := S.Elements;
   begin
      if X /= null then
         S.Elements := new Element_Array(X'Range);
         S.Elements(S.Elements'Range) := X(S.Elements'Range);
      end if;
   end;

   procedure Finalize
     (S: in out Set_Type) is
   begin
      if S.Elements /= null then
         Deallocate(S.Elements);
      end if;
   end;



   --==========================================================================
   --  Functions
   --==========================================================================

   function New_Set
     (E: in Element_Type) return Set_Type is
      Result: Set_Type := Empty_Set;
   begin
      Insert(Result, E);
      return Result;
   end;

   function New_Set
     (E: in Element_Array) return Set_Type is
      Result: Set_Type := Empty_Set;
   begin
      for I in E'Range loop
         Insert(Result, E(I));
      end loop;
      return Result;
   end;

   function Card
     (S: in Set_Type) return Card_Type is
      Result: Card_Type;
   begin
      if S.Last = No_Index then
         Result := 0;
      else
         Result := Index_Type'Pos(S.Last);
      end if;
      return Result;
   end;

   function Is_Empty
     (S: in Set_Type) return Boolean is
   begin
      return S.Last = No_Index;
   end;

   function Ith
     (S: in Set_Type;
      I: in Index_Type) return Element_Type is
   begin
      pragma Assert(Valid_Index(S, I));
      return S.Elements(I);
   end;

   function Index
     (S: in Set_Type;
      E: in Element_Type) return Extended_Index_Type is
   begin
      for I in First_Index(S)..Last_Index(S) loop
         if S.Elements(I) = E then
            return I;
         end if;
      end loop;
      return No_Index;
   end;

   function First_Index
     (S: in Set_Type) return Extended_Index_Type is
   begin
      return Index_Type'First;
   end;

   function Last_Index
     (S: in Set_Type) return Extended_Index_Type is
   begin
      return S.Last;
   end;

   function Valid_Index
     (S: in Set_Type;
      I: in Extended_Index_Type) return Boolean is
      Result: Boolean;
   begin
      if I = No_Index then
         Result := False;
      else
         Result :=
           S.Elements /= null and then I in First_Index(S)..Last_Index(S);
      end if;
      return Result;
   end;

   function Contains
     (S: in Set_Type;
      E: in Element_Type) return Boolean is
   begin
      return Index(S, E) /= No_Index;
   end;

   function Equal
     (S: in Set_Type;
      T: in Set_Type) return Boolean is
   begin
      return Card(S) = Card(T) and then Subset(S, T) and then Subset(T, S);
   end;

   function Subset
     (S: in Set_Type;
      T: in Set_Type) return Boolean is
   begin
      for I in First_Index(S)..Last_Index(S) loop
         if not Contains(T, S.Elements(I)) then
            return False;
         end if;
      end loop;
      return True;
   end;



   --==========================================================================
   --  Operators
   --==========================================================================

   function "or"
     (S: in Set_Type;
      T: in Set_Type) return Set_Type is
      Result: Set_Type := S;
   begin
      for I in First_Index(T)..Last_Index(T) loop
         Insert(Result, T.Elements(I));
      end loop;
      return Result;
   end;

   function "or"
     (E: in Element_Type;
      S: in Set_Type) return Set_Type is
      Result: Set_Type := S;
   begin
      Insert(Result, E);
      return Result;
   end;

   function "or"
     (S: in Set_Type;
      E: in Element_Type) return Set_Type is
   begin
      return E or S;
   end;

   function "and"
     (S: in Set_Type;
      T: in Set_Type) return Set_Type is
      Result: Set_Type := Empty_Set;
   begin
      for I in First_Index(S)..Last_Index(S) loop
         if Contains(T, S.Elements(I)) then
            Insert_No_Check(Result, S.Elements(I));
         end if;
      end loop;
      return Result;
   end;

   function "and"
     (E: in Element_Type;
      S: in Set_Type) return Set_Type is
   begin
      if Contains(S, E) then
         return New_Set(E);
      else
         return Empty_Set;
      end if;
   end;

   function "and"
     (S: in Set_Type;
      E: in Element_Type) return Set_Type is
   begin
      return E and S;
   end;

   function "-"
     (S: in Set_Type;
      T: in Set_Type) return Set_Type is
      Result: Set_Type := S;
   begin
      for I in First_Index(T)..Last_Index(T) loop
         Delete(Result, T.Elements(I));
      end loop;
      return Result;
   end;

   function "-"
     (S: in Set_Type;
      E: in Element_Type) return Set_Type is
      Result: Set_Type := S;
   begin
      Delete(Result, E);
      return Result;
   end;



   --==========================================================================
   --  Procedures
   --==========================================================================

   procedure Reallocate
     (S: in out Set_Type) is
      Reallocate  : Boolean := False;
      New_Elements: Element_Array_Access;
      New_Limit   : Extended_Index_Type;
   begin
      if S.Elements = null then
         New_Limit := No_Index;
      else
         New_Limit := S.Elements'Last;
      end if;
      while New_Limit = No_Index or New_Limit < S.Last loop
         Reallocate := True;
         if New_Limit = No_Index then
            New_Limit := Index_Type'First;
         else
            New_Limit := Index_Type'Val(Index_Type'Pos(New_Limit) * 2);
         end if;
      end loop;
      if Reallocate then
         New_Elements := new Element_Array(Index_Type'First .. New_Limit);
         if S.Elements /= null then
            New_Elements(S.Elements'Range) := S.Elements(S.Elements'Range);
            Deallocate(S.Elements);
         end if;
         S.Elements := New_Elements;
      end if;
   end;

   procedure Insert_No_Check
     (S: in out Set_Type;
      E: in     Element_Type) is
   begin
      S.Last := Index_Type'Succ(S.Last);
      Reallocate(S);
      S.Elements(S.Last) := E;
   end;

   procedure Insert
     (S: in out Set_Type;
      E: in     Element_Type) is
      Success: Boolean;
   begin
      Insert (S, E, Success);
      if not Success then --  just to avoid a warning
	 return;
      end if;
   end;

   procedure Insert
     (S: in out Set_Type;
      E: in     Element_Type;
      R:    out Boolean) is
      Previous_Last: constant Extended_Index_Type := S.Last;
   begin
      R := False;
      if Contains(S, E) then
         return;
      end if;
      R := True;
      S.Last := Index_Type'Succ(S.Last);
      Reallocate(S);
      S.Elements(S.Last) := E;
   end;

   procedure Delete
     (S: in out Set_Type;
      E: in     Element_Type) is
      Success: Boolean;
   begin
      Delete(S, E, Success);
      if not Success then --  just to avoid a warning
	 return;
      end if;
   end;

   procedure Delete
     (S: in out Set_Type;
      E: in     Element_Type;
      R:    out Boolean) is
      Tmp: Set_Type := Empty_Set;
   begin
      R := False;
      for I in First_Index(S)..Last_Index(S) loop
         if not Generic_Set."="(S.Elements(I), E) then
            Insert_No_Check(Tmp, S.Elements(I));
         else
            R := True;
         end if;
      end loop;
      S := Tmp;
   end;



   --==========================================================================
   --  Generic operations
   --==========================================================================

   procedure Generic_Delete
     (S: in out Set_Type) is
      Tmp: Set_Type := Empty_Set;
   begin
      for I in First_Index(S)..Last_Index(S) loop
         if not Predicate(S.Elements(I)) then
            Insert_No_Check(Tmp, S.Elements(I));
         end if;
      end loop;
      S := Tmp;
   end;

   procedure Generic_Apply
     (S: in Set_Type) is
   begin
      for I in First_Index(S)..Last_Index(S) loop
         Action(S.Elements(I));
      end loop;
   end;

   function Generic_Map
     (S: in Set_Type) return Set_Type is
      Result: Set_Type;
   begin
      if S.Elements = null then
         Result.Elements := null;
      else
         Result.Elements := new Element_Array(S.Elements'Range);
         for I in First_Index(S)..Last_Index(S) loop
            Result.Elements(I) := Map(S.Elements(I));
         end loop;
      end if;
      Result.Last := S.Last;
      return Result;
   end;

   function Generic_Get_Satisfying_Element
     (S: in Set_Type) return Element_Type is
   begin
      for I in First_Index(S)..Last_Index(S) loop
         if Predicate(S.Elements(I)) then
            return S.Elements(I);
         end if;
      end loop;
      return Null_Element;
   end;

   function Generic_Forall
     (S: in Set_Type) return Boolean is
   begin
      for I in First_Index(S)..Last_Index(S) loop
         if not Predicate(S.Elements(I)) then
            return False;
         end if;
      end loop;
      return True;
   end;

   function Generic_Exists
     (S: in Set_Type) return Boolean is
   begin
      for I in First_Index(S)..Last_Index(S) loop
         if Predicate(S.Elements(I)) then
            return True;
         end if;
      end loop;
      return False;
   end;

   function Generic_Equal
     (S: in Set_Type;
      T: in Set_Type) return Boolean is
   begin
      if S.Last /= T.Last then
         return False;
      else
         for I in First_Index(S)..Last_Index(S) loop
            if not Generic_Equal."="(S.Elements(I), T.Elements(I)) then
               return False;
            end if;
         end loop;
         return True;
      end if;
   end;

   function Generic_To_String
     (S: in Set_Type) return String is
      function Rec_To_String
        (I: in Index_Type) return String is
      begin
         if I > Last_Index(S) then
            return "";
         else
            declare
               After: constant String := Rec_To_String(I + 1);
               Ith  : constant String := To_String(S.Elements(I));
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
      if Card(S) = 0 then
         return Empty;
      else
         return Rec_To_String(Index_Type'First);
      end if;
   end;

   function Generic_Count
     (S: in Set_Type) return Natural is
      Result: Natural := 0;
   begin
      for I in First_Index(S)..Last_Index(S) loop
         if Predicate(S.Elements(I)) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end;

   function Generic_Subset
     (S: in Set_Type) return Set_Type is
      Result: Set_Type := Empty_Set;
   begin
      for I in First_Index(S)..Last_Index(S) loop
         if Predicate(S.Elements(I)) then
            Insert_No_Check(Result, S.Elements(I));
         end if;
      end loop;
      return Result;
   end;

end Generic_Set;
