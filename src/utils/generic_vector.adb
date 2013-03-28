with
  Ada.Unchecked_Deallocation;

package body Generic_Vector is

   procedure Deallocate is
      new Ada.Unchecked_Deallocation(Vector_Array, Vector);

   function Size
     (V: in Vector) return Natural is
      Result: Natural;
   begin
      if V = null then
         Result := 0;
      else
         Result := V'Last - V'First + 1;
      end if;
      return Result;
   end;

   procedure Add
     (V: in out Vector;
      E: in     Element) is
      Result: constant Vector := new Vector_Array(1..Size(V)+1);
   begin
      for I in 1..Size(V) loop
         Result(I) := V(I);
      end loop;
      Result(Size(V) + 1) := E;
      if V /= null then
         Deallocate(V);
      end if;
      V := Result;
   end;

   procedure Add_Vector
     (V : in out Vector;
      V2: in     Vector) is
      Result: Vector;
   begin
      if V = Empty_Vector and V2 = Empty_Vector then
         V := Empty_Vector;
      else
         Result := new Vector_Array(1..Size(V)+Size(V2));
         for I in 1..Size(V) loop
            Result(I) := V(I);
         end loop;
         for I in 1..Size(V2) loop
            Result(I+Size(V)) := V2(I);
         end loop;
         if V /= null then
            Deallocate(V);
         end if;
         V := Result;
      end if;
   end;

   procedure Add
     (V: in out Vector;
      E: in     Element;
      I: in     Natural) is
      Result: Vector;
   begin
      if not (I in 1..Size(V)+1) then
         raise Invalid_Index_Exception;
      else
         Result := new Vector_Array(1..Size(V) + 1);
         for J in 1..I-1 loop
            Result(J) := V(J);
         end loop;
         Result(I) := E;
         for J in I+1..Size(V) + 1 loop
            Result(J) := V(J - 1);
         end loop;
         if V /= null then
            Deallocate(V);
         end if;
         V := Result;
      end if;
   end;

   procedure Remove
     (V: in out Vector) is
      Result: Vector;
   begin
      if V = Empty_Vector then
         raise Empty_Vector_Exception;
      end if;
      if Size(V) = 1 then
         Deallocate(V);
         Result := Empty_Vector;
      else
         Result := new Vector_Array(1..Size(V) - 1);
         for I in 1..Size(Result) loop
            Result(I) := V(I);
         end loop;
         if V /= null then
            Deallocate(V);
         end if;
      end if;
      V := Result;
   end;

   procedure Remove
     (V: in out Vector;
      I: in     Natural) is
      Result: Vector;
   begin
      if not (I in 1..Size(V)) then
         raise Invalid_Index_Exception;
      end if;
      if Size(V) = 1 then
         Deallocate(V);
         Result := Empty_Vector;
      else
         Result := new Vector_Array(1..Size(V) - 1);
         for J in 1..I-1 loop
            Result(J) := V(J);
         end loop;
         for J in I..Size(Result) loop
            Result(J) := V(J + 1);
         end loop;
         if V /= null then
            Deallocate(V);
         end if;
      end if;
      V := Result;
   end;

   procedure Generic_Free
     (V: in out Vector) is
   begin
      for I in 1..Size(V) loop
         Free(V(I));
      end loop;
      if V /= null then
         Deallocate(V);
      end if;
      V := null;
   end;

   function Satisfying_Element
     (V: in Vector) return Element is
   begin
      for I in 1..Size(V) loop
         if Pred(V(I)) then
            return V(I);
         end if;
      end loop;
      raise Element_Not_Found_Exception;
   end;

   procedure Free
     (V: in out Vector) is
   begin
      if V /= null then
         Deallocate(V);
      end if;
      V := null;
   end;

   function Get_Pos
     (V: in Vector;
      E: in Element) return Natural is
   begin
      for I in 1..Size(V) loop
         if E = V(I) then
            return I;
         end if;
      end loop;
      raise Element_Not_Found_Exception;
   end;

   function Ith
     (V: in Vector;
      I: in Natural) return Element is
   begin
      if not (I in 1..Size(V)) then
         raise Invalid_Index_Exception;
      else
         return V(I);
      end if;
   end;

   function Is_In
     (V: in Vector;
      E: in Element) return Boolean is
   begin
      for I in 1..Size(V) loop
         if V(I) = E then
            return True;
         end if;
      end loop;
      return False;
   end;

   procedure Set
     (V: in Vector;
      E: in Element;
      I: in Natural) is
   begin
      if not (I in 1..Size(V)) then
         raise Invalid_Index_Exception;
      else
         V(I) := E;
      end if;
   end;

   function Copy
     (V: in Vector) return Vector is
      Result: Vector;
   begin
      if V = Empty_Vector then
         Result := Empty_Vector;
      else
         Result := new Vector_Array(1..Size(V));
         for I in 1..Size(V) loop
            Result(I) := V(I);
         end loop;
      end if;
      return Result;
   end;

   function Generic_Map
     (V: in Vector) return Vector is
      Result: Vector;
   begin
      if V = Empty_Vector then
         Result := Empty_Vector;
      else
         Result := new Vector_Array(1..Size(V));
         for I in 1..Size(V) loop
            Result(I) := Copy(V(I));
         end loop;
      end if;
      return Result;
   end;

   procedure Addition
     (V1: in out Vector;
      V2: in     Vector) is
   begin
      if Size(V1) /= Size(V2) then
         raise Invalid_Vector_Size_Exception;
      end if;
      for I in 1..Size(V1) loop
         Addition(V1(I), V2(I));
      end loop;
   end;

   function Exists
     (V: in Vector) return Boolean is
   begin
      for I in 1..Size(V) loop
         if Pred(V(I)) then
            return True;
         end if;
      end loop;
      return False;
   end;

   function For_All
     (V: in Vector) return Boolean is
   begin
      for I in 1..Size(V) loop
         if not Pred(V(I)) then
            return False;
         end if;
      end loop;
      return True;
   end;

   procedure Apply
     (V: in out Vector) is
   begin
      for I in 1..Size(V) loop
         Action(V(I));
      end loop;
   end;

   function Equal
     (V1: in Vector;
      V2: in Vector) return Boolean is
   begin
      if Size(V1) /= Size(V2) then
         return False;
      end if;
      for I in 1..Size(V1) loop
         if not (V1(I) = V2(I)) then
            return False;
         end if;
      end loop;
      return True;
   end;

   procedure Remove_Sub_Set
     (V: in out Vector) is
      I: Natural := 1;
   begin
      while I <= Size(V) loop
         if To_Remove(V(I)) then
            Remove(V, I);
         else
            I := I + 1;
         end if;
      end loop;
   end;

end Generic_Vector;
