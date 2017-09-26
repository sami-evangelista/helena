with
  Pn.Classes,
  Pn.Nodes.Transitions;

use
  Pn.Classes,
  Pn.Nodes.Transitions;

package body Pn.Nodes is

   --==========================================================================
   --  Arc
   --==========================================================================

   function New_Arc
     (Target: access Node_Record'Class;
      T     : in     Arc_Type;
      Label : in     Mapping) return Arc is
      Result: constant Arc := new Arc_Record;
   begin
      Result.Target := Target;
      Result.T     := T;
      Result.Label := Label;
      return Result;
   end;

   procedure Free
     (A: in out Arc) is
      procedure Deallocate is new Ada.Unchecked_Deallocation(Arc_Record, Arc);
   begin
      Free(A.Label);
      Deallocate(A);
      A := null;
   end;



   --==========================================================================
   --  Arc list
   --==========================================================================

   package AAP renames Arc_Array_Pkg;

   function New_Arc_List return Arc_List is
      Result: constant Arc_List := new Arc_List_Record;
   begin
      Result.Arcs := AAP.Empty_Array;
      return Result;
   end;

   procedure Free
     (A: in out Arc_List) is
      procedure Free is new AAP.Generic_Apply(Free);
      procedure Deallocate is new Ada.Unchecked_Deallocation(Arc_List_Record,
                                                             Arc_List);
   begin
      Free(A.Arcs);
      Deallocate(A);
      A := null;
   end;

   function Length
     (L: in Arc_List) return Count_Type is
   begin
      return AAP.Length(L.Arcs);
   end;

   function Ith
     (L: in Arc_List;
      I: in Index_Type) return Arc is
   begin
      return AAP.Ith(L.Arcs, I);
   end;

   procedure Insert
     (L: in Arc_List;
      A: in Arc) is
   begin
      AAP.Append(L.Arcs, A);
   end;

   procedure Delete
     (L: in Arc_List;
      A: in Arc) is
   begin
      AAP.Delete(L.Arcs, A);
   end;



   --==========================================================================
   --  Node
   --==========================================================================

   procedure Initialize
     (N   : access Node_Record'Class;
      Name: in     Ustring;
      D   : in     Dom) is
   begin
      N.Name := Name;
      N.D   := D;
      N.Arcs := New_Arc_List;
   end;

   procedure Free
     (N: in out Node) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Node_Record'Class, Node);
   begin
      Free(N.Arcs);
      Deallocate(N);
      N := null;
   end;

   function Get_Name
     (N: access Node_Record'Class) return Ustring is
   begin
      return N.Name;
   end;

   procedure Set_Name
     (N   : access Node_Record'Class;
      Name: in     Ustring) is
   begin
      N.Name := Name;
   end;

   function Get_Dom
     (N: access Node_Record'Class) return Dom is
   begin
      return N.D;
   end;

   procedure Set_Dom
     (N: access Node_Record'Class;
      D: in     Dom) is
   begin
      N.D := D;
   end;

   function Dom_Size
     (N: access Node_Record'Class) return Count_Type is
   begin
      return Size(N.D);
   end;

   function Ith_Dom
     (N: access Node_Record'Class;
      I: in     Index_Type) return Cls is
   begin
      return Ith(N.D, I);
   end;

   procedure Add_Dom
     (N: access Node_Record'Class;
      C: in     Cls) is
   begin
      Append(N.D, C);
   end;

   procedure Add_Dom
     (N: access Node_Record'Class;
      C: in     Cls;
      I: in     Index_Type) is
   begin
      Insert(N.D, C, I);
   end;

   procedure Remove_Dom
     (N: access Node_Record'Class) is
   begin
      Delete_Last(N.D);
   end;

   procedure Remove_Dom
     (N: access Node_Record'Class;
      I: in     Index_Type) is
   begin
      Delete(N.D, I);
   end;

   procedure Add_Arc
     (N: access Node_Record'Class;
      A: in     Arc) is
   begin
      Insert(N.Arcs, A);
   end;

   procedure Delete_Arc
     (N     : access Node_Record'Class;
      Target: access Node_Record'Class;
      T     : in     Arc_Type) is

      procedure Do_Delete
        (Src: access Node_Record'Class;
         Dest: access Node_Record'Class) is
         A: Arc;
      begin
         for I in 1..Length(Src.Arcs) loop
            A := Ith(Src.Arcs, I);
            if A.Target = Dest and A.T = T then
               Delete(Src.Arcs, A);
               Free(A);
               return;
            end if;
         end loop;
      end;

   begin
      Do_Delete(N, Target);
      Do_Delete(Target, N);
   end;

   procedure Delete_Arcs
     (N: access Node_Record'Class) is
      A: Arc;
   begin
      while Length(N.Arcs) > 0 loop
         A := Ith(N.Arcs, 1);
         Delete_Arc(N, A.Target, A.T);
      end loop;
   end;

   function Get_Arc_Label
     (N     : access Node_Record'Class;
      Target: access Node_Record'Class;
      T     : in     Arc_Type) return Mapping is
      Result: Mapping := Null_Mapping;
      A     : Arc;
   begin
      for I in 1..Length(N.Arcs) loop
         A := Ith(N.Arcs, I);
         if A.Target = Target and A.T = T then
            Result := A.Label;
            exit;
         end if;
      end loop;
      return Result;
   end;

   procedure Set_Arc_Label
     (N     : access Node_Record'Class;
      Target: access Node_Record'Class;
      T     : in     Arc_Type;
      M     : in     Mapping) is
   begin
      Delete_Arc(N, Target, T);
      if M /= Null_Mapping then
         Add_Arc(N,      New_Arc(Target, T, M));
         Add_Arc(Target, New_Arc(N,      T, Shared_Copy(M)));
      end if;
   end;

   procedure Add_To_Arc_Label
     (N     : access Node_Record'Class;
      Target: access Node_Record'Class;
      T     : in     Arc_Type;
      M     : in     Mapping) is
   begin
      for I in 1..Size(M) loop
         Add_To_Arc_Label(N, Target, T, Ith(M, I));
      end loop;
   end;

   procedure Add_To_Arc_Label
     (N     : access Node_Record'Class;
      Target: access Node_Record'Class;
      T     : in     Arc_Type;
      Tup   : in     Tuple) is
      M    : Mapping;
      A    : Arc;
      Added: Boolean := False;
   begin
      for I in 1..Length(N.Arcs) loop
         A := Ith(N.Arcs, I);
         if A.Target = Target and A.T = T then
            Add(A.Label, Tup);
            Added := True;
            exit;
         end if;
      end loop;
      if not Added then
         M := New_Mapping(Tup);
         Add_Arc(N,      New_Arc(Target, T, M));
         Add_Arc(Target, New_Arc(N,      T, Shared_Copy(M)));
      end if;
   end;

   procedure Generic_Apply_Arcs_Labels
     (N: access Node_Record'Class) is
      A: Arc;
   begin
      for I in 1..Length(N.Arcs) loop
         A := Ith(N.Arcs, I);
         Action(A.Label);
      end loop;
   end;

end Pn.Nodes;
