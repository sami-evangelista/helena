with
  Pn.Compiler;

use
  Pn.Compiler;

package body Pn.Vars is

   --==========================================================================
   --  Variable
   --==========================================================================

   procedure Deallocate is
      new Ada.Unchecked_Deallocation(Var_Record'Class, Var);

   procedure Initialize
     (V   : access Var_Record'Class;
      Name: in     Ustring;
      C   : in     Cls) is
   begin
      V.Name := Name;
      V.C   := C;
      V.Me  := Var(V);
   end;

   procedure Free
     (V: in out Var) is
   begin
      Free(V.all);
      Deallocate(V);
      V := null;
   end;

   function Copy
     (V: access Var_Record'Class) return Var is
   begin
      return Copy(V.all);
   end;

   function Get_Name
     (V: access Var_Record'Class) return Ustring is
   begin
      return V.Name;
   end;

   procedure Set_Name
     (V: access Var_Record'Class;
      N: in     Ustring) is
   begin
      V.Name := N;
   end;

   function Get_Cls
     (V: access Var_Record'Class) return Cls is
   begin
      return V.C;
   end;

   procedure Set_Cls
     (V: access Var_Record'Class;
      C: in     Cls) is
   begin
      V.C := C;
   end;

   function Is_Const
     (V: access Var_Record'Class) return Boolean is
   begin
      return Is_Const(V.all);
   end;

   function Is_Static
     (V: access Var_Record'Class) return Boolean is
   begin
      return Is_Static(V.all);
   end;

   function Get_Init
     (V: access Var_Record'Class) return Expr is
   begin
      return Get_Init(V.all);
   end;

   procedure Set_Init
     (V: access Var_Record'Class;
      E: in     Expr) is
   begin
      Set_Init(V.all, E);
   end;

   function Get_Type
     (V: access Var_Record'Class) return Var_Type is
   begin
      return Get_Type(V.all);
   end;

   procedure Replace_Var_In_Def
     (V: access Var_Record'Class;
      R: in     Var;
      E: in     Expr) is
   begin
      Replace_Var_In_Def(V.all, R, E);
   end;

   function To_Helena
     (V: access Var_Record'Class) return Ustring is
   begin
      return To_Helena(V.all);
   end;

   procedure Compile_Definition
     (V   : access Var_Record'Class;
      Tabs: in     Natural;
      File: in     File_Type) is
   begin
      Compile_Definition(V.all, Tabs, File);
   end;

   function Compile_Access
     (V: access Var_Record'Class;
      M: in     Var_Mapping) return Ustring is
   begin
      for I in M'Range loop
         if M(I).V = V then
            return M(I).Expr;
         end if;
      end loop;
      return Compile_Access(V.all);
   end;



   --==========================================================================
   --  Variable list
   --==========================================================================

   package VAP renames Var_Array_Pkg;

   function New_Var_List return Var_List is
      Result: constant Var_List := new Var_List_Record;
   begin
      Result.Vars := VAP.Empty_Array;
      return Result;
   end;

   function New_Var_List
     (V: in Var_Array) return Var_List is
      Result: constant Var_List := new Var_List_Record;
   begin
      Result.Vars := VAP.New_Array(VAP.Element_Array(V));
      return Result;
   end;

   procedure Free_All
     (V: in out Var_List) is
      procedure Free is new VAP.Generic_Apply(Free);
   begin
      Free(V.Vars);
      Free(V);
   end;

   procedure Free
     (V: in out Var_List) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Var_List_Record, Var_List);
   begin
      Deallocate(V);
      V := null;
   end;

   function Length
     (V: in Var_List) return Count_Type is
   begin
      return VAP.Length(V.Vars);
   end;

   function Is_Empty
     (V: in Var_List) return Boolean is
   begin
      return VAP.Length(V.Vars) = 0;
   end;

   function Copy
     (V: in Var_List) return Var_List is
      Result: constant Var_List := new Var_List_Record;
   begin
      Result.Vars := V.Vars;
      return Result;
   end;

   function Copy_All
     (V: in Var_List) return Var_List is
      Result: constant Var_List := new Var_List_Record;
      function Copy
        (V: in Var) return Var is
      begin
         return Pn.Vars.Copy(V);
      end;
      function Copy is new VAP.Generic_Map(Copy);
   begin
      Result.Vars := Copy(V.Vars);
      return Result;
   end;

   function Ith
     (V: in Var_List;
      I: in Index_Type) return Var is
   begin
      return VAP.Ith(V.Vars, I);
   end;

   procedure Append
     (V: in Var_List;
      Va: in Var) is
   begin
      VAP.Append(V.Vars, Va);
   end;

   procedure Delete
     (V: in Var_List;
      Va: in Var) is
   begin
      VAP.Delete(V.Vars, Va);
   end;

   procedure Union
     (V1: in Var_List;
      V2: in Var_List) is
      V: Var;
   begin
      for I in 1..Length(V2) loop
         V := Ith(V2, I);
         if not Contains(V1, V) then
            Append(V1, V);
         end if;
      end loop;
   end;

   procedure Intersect
     (V1: in Var_List;
      V2: in Var_List) is
      V   : Var;
      Vars: VAP.Array_Type := VAP.Empty_Array;
   begin
      for I in 1..Length(V1) loop
         V := Ith(V1, I);
         if Contains(V2, V) then
            VAP.Append(Vars, V);
         end if;
      end loop;
      V1.Vars := Vars;
   end;

   procedure Difference
     (V1: in Var_List;
      V2: in Var_List) is
      V: Var;
   begin
      for I in 1..Length(V2) loop
         V := Ith(V2, I);
         if Contains(V1, V) then
            VAP.Delete(V1.Vars, V);
         end if;
      end loop;
   end;

   function Included
     (V1: in Var_List;
      V2: in Var_List) return Boolean is
   begin
      for I in 1..Length(V1) loop
         if not Contains(V2, Ith(V1, I)) then
            return False;
         end if;
      end loop;
      return True;
   end;

   function Get_Index
     (V: in Var_List;
      N: in Ustring) return Index_Type is
      function Is_N
        (V: in Var) return Boolean is
      begin
         return V.Name = N;
      end;
      function Get_N is
         new VAP.Generic_Get_First_Satisfying_Element_Index(Is_N);
      Result: constant VAP.Extended_Index_Type := Get_N(V.Vars);
   begin
      pragma Assert(Result /= VAP.No_Index);
      return Index_Type(Result);
   end;

   function Get_Index
     (V: in     Var_List;
      Va: access Var_Record'Class) return Index_Type is
   begin
      return VAP.Index(V.Vars, Var(Va));
   end;

   function Get
     (V: in Var_List;
      N: in Ustring) return Var is
      function Is_N
        (V: in Var) return Boolean is
      begin
         return V.Name = N;
      end;
      function Get_N is new VAP.Generic_Get_First_Satisfying_Element(Is_N);
      Result: constant Var := Get_N(V.Vars);
   begin
      pragma Assert(Result /= Null_Var);
      return Result;
   end;

   function Contains
     (V : in Var_List;
      Va: in Ustring) return Boolean is
      function Is_Va
        (V: in Var) return Boolean is
      begin
         return V.Name = Va;
      end;
      function Contains is new VAP.Generic_Exists(Is_Va);
   begin
      return Contains(V.Vars);
   end;

   function Contains
     (V: in Var_List;
      Va: in Var) return Boolean is
   begin
      return VAP.Contains(V.Vars, Va);
   end;

   function Equal
     (V1: in Var_List;
      V2: in Var_List) return Boolean is
      function "="
        (V1: in Var;
         V2: in Var) return Boolean is
      begin
         return V1.Name = V2.Name and V1.C = V2.C;
      end;
      function Equal is new VAP.Generic_Equal("=");
   begin
      return Equal(V1.Vars, V2.Vars);
   end;

   function Check_Type
     (V: in Var_List;
      T: in Var_Type_Set) return Boolean is
   begin
      for I in 1..Length(V) loop
         if not T(Get_Type(Ith(V, I))) then
            return False;
         end if;
      end loop;
      return True;
   end;

   procedure Generic_Delete_Vars
     (V: in Var_List) is
      procedure Delete is new VAP.Generic_Delete(Predicate);
   begin
      Delete(V.Vars);
   end;

   function To_String
     (V: in Var_List) return Ustring is
      Result: Ustring := Null_String;
   begin
      Result := Result & "{";
      for I in 1..Length(V) loop
         if I > 1 then
            Result := Result & ", ";
         end if;
         Result := Result & Get_Name(Ith(V, I));
      end loop;
      Result := Result & "}";
      return Result;
   end;

   function To_Helena
     (V: in Var_List) return Ustring is
      Result: Ustring := Null_Unbounded_String;
   begin
      for I in 1..Length(V) loop
         if I > 1 then
            Result := Result & ", ";
         end if;
         Result := Result & To_Helena(Ith(V, I));
      end loop;
      return Result;
   end;

   procedure Compile_Definition
     (V   : in Var_List;
      Tabs: in Natural;
      File: in File_Type) is
   begin
      for I in 1..Length(V) loop
         Compile_Definition(Ith(V, I), Tabs, File);
      end loop;
   end;

end Pn.Vars;
