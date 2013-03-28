with
  Pn.Bindings,
  Pn.Classes,
  Pn.Exprs,
  Pn.Exprs.Var_Refs,
  Pn.Vars;

use
  Pn.Bindings,
  Pn.Classes,
  Pn.Exprs,
  Pn.Exprs.Var_Refs,
  Pn.Vars;

package body Pn.Nodes.Transitions is

   --==========================================================================
   --  Transition
   --==========================================================================

   function New_Trans
     (Name    : in Ustring;
      Vars    : in Var_List;
      Ivars   : in Var_List;
      Lvars   : in Var_List;
      G       : in Guard;
      P       : in Priority;
      Visible : in Fuzzy_Boolean;
      Safe    : in Fuzzy_Boolean;
      Desc    : in Trans_Desc) return Trans is
      Result: constant Trans := new Trans_Record;
      D     : constant Dom  := New_Dom;
   begin
      for I in 1..Length(Vars) loop
         Append(D, Get_Cls(Ith(Vars, I)));
      end loop;
      Initialize(Result, Name, D);
      Result.Vars := Vars;
      Result.Ivars := Ivars;
      Result.Lvars := Lvars;
      Result.G := G;
      Result.P := P;
      Result.Visible := Visible;
      Result.Safe := Safe;
      Result.Safe_Set := 0;
      Result.Desc := Desc;
      return Result;
   end;

   procedure Free
     (T: in out Trans) is
   begin
      Free_All(T.Vars);
      Free_All(T.Ivars);
      if T.Desc.Has_Desc then
	 Free_All(T.Desc.Desc_Exprs);
      end if;
      Free(Node(T));
   end;

   function Get_Vars
     (T: in Trans) return Var_List is
   begin
      return T.Vars;
   end;

   function Get_Ivars
     (T: in Trans) return Var_List is
   begin
      return T.Ivars;
   end;

   function Get_Lvars
     (T: in Trans) return Var_List is
   begin
      return T.Lvars;
   end;

   procedure Set_Vars
     (T   : in Trans;
      Vars: in Var_List) is
   begin
      T.Vars := Vars;
      Free(T.D);
      T.D := New_Dom;
      for I in 1..Length(Vars) loop
         Append(T.D, Get_Cls(Ith(Vars, I)));
      end loop;
   end;

   procedure Add_Var
     (T: in Trans;
      V: in Var) is
   begin
      Append(T.Vars, V);
      Append(T.D, Get_Cls(V));
   end;

   procedure Delete_Var
     (T: in Trans;
      V: in Var) is
   begin
      Delete(T.D, Get_Index(T.Vars, V));
      Delete(T.Vars, V);
   end;

   procedure Replace_Var
     (T  : in Trans;
      V  : in Var;
      E  : in Expr;
      Del: in Boolean) is
      procedure Handle_Guard
        (G: in out Guard) is
      begin
         Replace_Var(G, V, E);
         if Is_Static(G) and then Is_Tautology(G) then
            Free(G);
            G := True_Guard;
         end if;
      end;
      Tv: Var;
   begin
      Handle_Guard(T.G);
      if Del then
         Delete_Var(T, V);
      end if;
      for I in 1..Length(T.Vars) loop
         Tv := Ith(T.Vars, I);
         Replace_Var_In_Def(Tv, V, E);
      end loop;
   end;

   procedure Map_Vars
     (T    : in Trans;
      V_Old: in Var_List;
      V_New: in Var_List) is
      V : Var;
      Vn: Var;
      Ex: Expr;
   begin
      pragma Assert(Length(V_New) = Length(V_Old));
      for I in 1..Length(V_Old) loop
         V  := Ith(V_Old, I);
         Vn := Ith(V_New, I);
         Ex := New_Var_Ref(Vn);
         Replace_Var(T, V, Ex, False);
         Free(Ex);
      end loop;
   end;

   function Get_Var_Index
     (T: in Trans;
      V: in Var) return Index_Type is
   begin
      return Get_Index(T.Vars, V);
   end;

   function Get_Var_Index
     (T: in Trans;
      V: in Ustring) return Index_Type is
   begin
      return Get_Index(T.Vars, V);
   end;

   function Is_Var
     (T: in Trans;
      V: in Var) return Boolean is
   begin
      return Contains(T.Vars, V);
   end;

   function Is_Var
     (T: in Trans;
      V: in Ustring) return Boolean is
   begin
      return Contains(T.Vars, V);
   end;

   function Get_Var
     (T: in Trans;
      V: in Ustring) return Var is
   begin
      return Get(T.Vars, V);
   end;

   function Get_Guard
     (T: in Trans) return Guard is
   begin
      return T.G;
   end;

   procedure Set_Guard
     (T: in Trans;
      G: in Guard) is
   begin
      T.G := G;
   end;

   function Is_Safe
     (T: in Trans) return Boolean is
   begin
      return T.Safe = FTrue;
   end;

   function Get_Safe
     (T: in Trans) return Fuzzy_Boolean is
   begin
      return T.Safe;
   end;

   procedure Set_Safe
     (T   : in Trans;
      Safe: in Fuzzy_Boolean) is
   begin
      T.Safe := Safe;
   end;

   function Is_Visible
     (T: in Trans) return Boolean is
   begin
      return T.Visible = FTrue;
   end;

   function Get_Visible
     (T: in Trans) return Fuzzy_Boolean is
   begin
      return T.Visible;
   end;

   procedure Set_Visible
     (T      : in Trans;
      Visible: in Fuzzy_Boolean) is
   begin
      T.Visible := Visible;
   end;

   function Get_Priority
     (T: in Trans) return Priority is
   begin
      return T.P;
   end;

   procedure Set_Priority
     (T: in Trans;
      P: in Priority) is
   begin
      T.P := P;
   end;

   function Get_Safe_Set
     (T: in Trans) return Natural is
   begin
      return T.Safe_Set;
   end;

   procedure Set_Safe_Set
     (T  : in Trans;
      Set: in Natural) is
   begin
      T.Safe_Set := Set;
   end;

   function Ith_Binding
     (T: in Trans;
      I: in Card_Type) return Binding is
      Result: constant Binding := New_Binding;
      E     : Expr_List;
   begin
      E := Ith_Value(T.D, I);
      for I in 1..Size(T.D) loop
         Bind_Var(Result, Ith(T.Vars, I), Ith(E, I));
      end loop;
      Free(E);
      return Result;
   end;

   function Has_Desc
     (T : in Trans) return Boolean is
   begin
      return T.Desc.Has_Desc;
   end;

   function Get_Desc
     (T : in Trans) return Ustring is
   begin
      pragma Assert(T.Desc.Has_Desc);
      return T.Desc.Desc;
   end;

   function Get_Desc_Exprs
     (T : in Trans) return Expr_List is
   begin
      pragma Assert(T.Desc.Has_Desc);
      return T.Desc.Desc_Exprs;
   end;



   --==========================================================================
   --  Transition descriptor
   --==========================================================================

   function New_Trans_Desc
     (Desc      : in Ustring;
      Desc_Exprs: in Expr_List) return Trans_Desc is
   begin
      return (Has_Desc   => True,
	      Desc       => Desc,
	      Desc_Exprs => Desc_Exprs);
   end;

   function New_Empty_Trans_Desc return Trans_Desc is
      Result: Trans_Desc;
   begin
      Result.Has_Desc := False;
      return Result;
   end;



   --==========================================================================
   --  Transition vector
   --==========================================================================

   package TAP renames Trans_Array_Pkg;

   function New_Trans_Vector return Trans_Vector is
      Result: constant Trans_Vector := new Trans_Vector_Record;
   begin
      Result.Trans := TAP.Empty_Array;
      return Result;
   end;

   function New_Trans_Vector
     (T: in Trans_Array) return Trans_Vector is
      Result: constant Trans_Vector := new Trans_Vector_Record;
   begin
      Result.Trans := TAP.New_Array(TAP.Element_Array(T));
      return Result;
   end;

   procedure Free
     (T: in out Trans_Vector) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Trans_Vector_Record, Trans_Vector);
   begin
      Deallocate(T);
      T := null;
   end;

   procedure Free_All
     (T: in out Trans_Vector) is
      procedure Free is new TAP.Generic_Apply(Free);
   begin
      Free(T.Trans);
      Free(T);
   end;

   function Size
     (T: in Trans_Vector) return Count_Type is
   begin
      return TAP.Length(T.Trans);
   end;

   function Is_Empty
     (T: in Trans_Vector) return Boolean is
   begin
      return TAP."="(T.Trans, TAP.Empty_Array);
   end;

   function Get
     (T: in Trans_Vector;
      Tr: in Ustring) return Trans is
      function Is_Tr
        (T: in Trans) return Boolean is
      begin
         return T.Name = Tr;
      end;
      function Get_Tr is new TAP.Generic_Get_First_Satisfying_Element(Is_Tr);
      Result: Trans;
   begin
      Result := Get_Tr(T.Trans);
      pragma Assert(Result /= Null_Trans);
      return Result;
   end;

   function Get_Index
     (T: in Trans_Vector;
      Tr: in Trans) return Index_Type is
   begin
      return TAP.Index(T.Trans, Tr);
   end;

   procedure Append
     (T : in Trans_Vector;
      Tr: in Trans) is
   begin
      TAP.Append(T.Trans, Tr);
   end;

   procedure Delete
     (T: in Trans_Vector;
      Tr: in Trans) is
      Success: Boolean;
   begin
      TAP.Delete(T.Trans, Tr, Success);
      pragma Assert(Success);
   end;

   function Ith
     (T: in Trans_Vector;
      I: in Index_Type) return Trans is
   begin
      return TAP.Ith(T.Trans, I);
   end;

   function Contains
     (T: in Trans_Vector;
      Tr: in Trans) return Boolean is
   begin
      return TAP.Contains(T.Trans, Tr);
   end;

   function Contains
     (T: in Trans_Vector;
      Tr: in Ustring) return Boolean is
   begin
      for I in 1..Size(T) loop
         if Get_Name(Ith(T, I)) = Tr then
            return True;
         end if;
      end loop;
      return False;
   end;

   function Intersect
     (T1: in Trans_Vector;
      T2: in Trans_Vector) return Trans_Vector is
      Result: constant Trans_Vector := New_Trans_Vector;
      T     : Trans;
   begin
      for I in 1..Size(T1) loop
         T := Ith(T1, I);
         if Contains(T2, T) then
            Append(Result, T);
         end if;
      end loop;
      return Result;
   end;

   procedure Difference
     (T1: in Trans_Vector;
      T2: in Trans_Vector) is
      T: Trans;
   begin
      for I in 1..Size(T2) loop
         T := Ith(T2, I);
         if Contains(T1, T) then
            Delete(T1, T);
         end if;
      end loop;
   end;

end Pn.Nodes.Transitions;
