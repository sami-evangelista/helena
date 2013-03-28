with
  Pn.Classes;

use
  Pn.Classes;

package body Pn.Nodes.Places is

   --==========================================================================
   --  Place
   --==========================================================================

   function New_Place
     (Name    : in Ustring;
      D       : in Dom;
      T       : in Place_Type;
      M0      : in Mapping;
      Capacity: in Mult_Type) return Place is
      Result: constant Place := new Place_Record;
   begin
      Initialize(Result, Name, D);
      Result.M0  := M0;
      Result.T   := T;
      Result.Cap := Capacity;
      return Result;
   end;

   procedure Free
     (P: in out Place) is
   begin
      Free(P.M0);
      Free(Node(P));
   end;

   function Get_Capacity
     (P: in Place) return Mult_Type is
   begin
      return P.Cap;
   end;

   procedure Set_Capacity
     (P       : in Place;
      Capacity: in Mult_Type) is
   begin
      P.Cap := Capacity;
   end;

   function Get_Type
     (P: in Place) return Place_Type is
   begin
      return P.T;
   end;

   procedure Set_Type
     (P: in Place;
      T: in Place_Type) is
   begin
      P.T := T;
   end;

   function Is_Marked
     (P: in Place) return Boolean is
   begin
      return not Is_Empty(P.M0);
   end;

   function Is_Safe
     (P: in Place) return Boolean is
   begin
      return Get_Capacity(P) = 1;
   end;

   function Get_M0
     (P: in Place) return Mapping is
   begin
      return P.M0;
   end;

   procedure Set_M0
     (P: in Place;
      M0: in Mapping) is
   begin
      P.M0 := M0;
   end;

   procedure Add_M0
     (P: in Place;
      T: in Tuple) is
   begin
      Add(P.M0, T);
   end;



   --===
   --
   --  a vector of places
   --
   --===

   package PAP renames Place_Array_Pkg;

   function New_Place_Vector return Place_Vector is
      Result: constant Place_Vector := new Place_Vector_Record;
   begin
      Result.Places := PAP.Empty_Array;
      return Result;
   end;

   function New_Place_Vector
     (P: in Place_Array) return Place_Vector is
      Result: constant Place_Vector := new Place_Vector_Record;
   begin
      Result.Places := PAP.New_Array(PAP.Element_Array(P));
      return Result;
   end;

   procedure Free
     (P: in out Place_Vector) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Place_Vector_Record, Place_Vector);
   begin
      Deallocate(P);
      P := null;
   end;

   procedure Free_All
     (P: in out Place_Vector) is
      procedure Free is new PAP.Generic_Apply(Free);
   begin
      Free(P.Places);
      Free(P);
   end;

   function Is_Empty
     (P: in Place_Vector) return Boolean is
   begin
      return PAP."="(P.Places, PAP.Empty_Array);
   end;

   function Size
     (P: in Place_Vector) return Count_Type is
   begin
      return PAP.Length(P.Places);
   end;

   function Get
     (P: in Place_Vector;
      Pl: in Ustring) return Place is
      function Is_Pl
        (P: in Place) return Boolean is
      begin
         return P.Name = Pl;
      end;
      function Get_Pl is
         new PAP.Generic_Get_First_Satisfying_Element(Is_Pl);
      Result: Place;
   begin
      Result := Get_Pl(P.Places);
      pragma Assert(Result /= Null_Place);
      return Result;
   end;

   function Get_Index
     (P: in Place_Vector;
      Pl: in Place) return Extended_Index_Type is
      I: constant PAP.Extended_Index_Type := PAP.Index(P.Places, Pl);
   begin
      return I;
   end;

   procedure Append
     (P : in Place_Vector;
      Pl: in Place) is
   begin
      PAP.Append(P.Places, Pl);
   end;

   procedure Delete
     (P : in Place_Vector;
      Pl: in Place) is
      Success: Boolean;
   begin
      PAP.Delete(P.Places, Pl, Success);
      pragma Assert(Success);
   end;

   function Ith
     (P: in Place_Vector;
      I: in Index_Type) return Place is
   begin
      return PAP.Ith(P.Places, I);
   end;

   function Contains
     (P: in Place_Vector;
      Pl: in Place) return Boolean is
   begin
      return PAP.Contains(P.Places, Pl);
   end;

   function Contains
     (P: in Place_Vector;
      Pl: in Ustring) return Boolean is
      function Is_Pl
        (P: in Place) return Boolean is
      begin
         return P.Name = Pl;
      end;
      function Contains_Pl is new PAP.Generic_Exists(Is_Pl);
   begin
      return Contains_Pl(P.Places);
   end;

   function Intersect
     (P1: in Place_Vector;
      P2: in Place_Vector) return Place_Vector is
      Result: constant Place_Vector := New_Place_Vector;
      Ith   : Place;
   begin
      for I in PAP.First_Index(P1.Places)..PAP.Last_Index(P1.Places) loop
         Ith := PAP.Ith(P1.Places, I);
         if PAP.Contains(P2.Places, Ith) then
            PAP.Append(Result.Places, Ith);
         end if;
      end loop;
      return Result;
   end;

   procedure Generic_Delete_Places
     (P: in Place_Vector) is
      procedure Delete is new PAP.Generic_Delete(Predicate);
   begin
      Delete(P.Places);
   end;

end Pn.Nodes.Places;
