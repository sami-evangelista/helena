with
  Ada.Unchecked_Deallocation;

package body Generic_Bag is

   --==========================================================================
   --  Procedures to control the initialization, adjustment and finalization
   --==========================================================================

   procedure Deallocate is
      new Ada.Unchecked_Deallocation(Mult_Element_Array, Mult_Elements);

   procedure Initialize
     (B: in out Bag_Type) is
   begin
      B := Empty_Bag;
   end;

   procedure Adjust
     (B: in out Bag_Type) is
      X: constant Mult_Elements := B.Elements;
   begin
      if X /= null then
         B.Elements := new Mult_Element_Array(X'Range);
         B.Elements(B.Elements'Range) := X(B.Elements'Range);
      end if;
   end;

   procedure Finalize
     (B: in out Bag_Type) is
   begin
      if B.Elements /= null then
         Deallocate(B.Elements);
      end if;
   end;



   --==========================================================================
   --  Functions
   --==========================================================================

   function Card
     (B: in Bag_Type) return Card_Type is
      Result: Card_Type;
   begin
      if B.Last = No_Index then
         Result := 0;
      else
         Result := Index_Type'Pos(B.Last);
      end if;
      return Result;
   end;

   function First_Index
     (B: in Bag_Type) return Extended_Index_Type is
   begin
      return Index_Type'First;
   end;

   function Last_Index
     (B: in Bag_Type) return Extended_Index_Type is
   begin
      return B.Last;
   end;

   function Get_Mult
     (B: in Bag_Type;
      E: in Element_Type) return Mult_Type is
   begin
      if B.Elements /= null then
         for I in First_Index(B)..Last_Index(B) loop
            if B.Elements(I).E = E then
               return B.Elements(I).M;
            end if;
         end loop;
      end if;
      return 0;
   end;



   --==========================================================================
   --  Procedures
   --==========================================================================

   procedure Reallocate
     (B: in out Bag_Type) is
      Reallocate  : Boolean := False;
      New_Elements: Mult_Elements;
      New_Limit   : Extended_Index_Type;
   begin
      if B.Elements = null then
         New_Limit := No_Index;
      else
         New_Limit := B.Elements'Last;
      end if;
      while New_Limit = No_Index or New_Limit < B.Last loop
         Reallocate := True;
         if New_Limit = No_Index then
            New_Limit := Index_Type'First;
         else
            New_Limit := Index_Type'Val(Index_Type'Pos(New_Limit) * 2);
         end if;
      end loop;
      if Reallocate then
         New_Elements :=
           new Mult_Element_Array(Index_Type'First .. New_Limit);
         if B.Elements /= null then
            New_Elements(B.Elements'Range) := B.Elements(B.Elements'Range);
            Deallocate(B.Elements);
         end if;
         B.Elements := New_Elements;
      end if;
   end;

   procedure Element_At_Index
     (B: in     Bag_Type;
      I: in     Index_Type;
      E:    out Element_Type;
      M:    out Mult_Type) is
   begin
      pragma Assert(I in First_Index(B) .. Last_Index(B));
      E := B.Elements(I).E;
      M := B.Elements(I).M;
   end;

   procedure Insert
     (B: in out Bag_Type;
      E: in     Element_Type;
      M: in     Mult_Type;
      N:    out Boolean) is
   begin
      N := True;
      if B.Elements /= null then
         for I in First_Index(B)..Last_Index(B) loop
            if B.Elements(I).E = E then
               N := False;
               B.Elements(I).M := B.Elements(I).M + M;
               exit;
            end if;
         end loop;
      end if;
      if N then
         pragma Assert(B.Last /= Index_Type'Last);
         B.Last := Index_Type'Succ(B.Last);
         Reallocate(B);
         B.Elements(B.Last) := (E => E,
                                M => M);
      end if;
   end;

   procedure Union
     (B: in out Bag_Type;
      C: in     Bag_Type) is
      Is_New: Boolean;
   begin
      if C.Elements /= null then
         for I in First_Index(C)..Last_Index(C) loop
            Insert(B, C.Elements(I).E, C.Elements(I).M, Is_New);
         end loop;
      end if;
   end;



   --==========================================================================
   --  Generic operations
   --==========================================================================

   procedure Generic_Apply
     (B: in Bag_Type) is
   begin
      if B.Elements /= null then
         for I in First_Index(B)..Last_Index(B) loop
            Action(B.Elements(I).E);
         end loop;
      end if;
   end;

end Generic_Bag;
