with
  Pn.Compiler.Bit_Stream,
  Pn.Classes,
  Pn.Compiler,
  Pn.Exprs,
  Pn.Exprs.Enum_Consts;

use
  Pn.Compiler.Bit_Stream,
  Pn.Classes,
  Pn.Compiler,
  Pn.Exprs,
  Pn.Exprs.Enum_Consts;

package body Pn.Classes is

   --==========================================================================
   --  Color class
   --==========================================================================

   procedure Deallocate is
      new Ada.Unchecked_Deallocation(Cls_Record'Class, Cls);

   procedure Initialize
     (C   : access Cls_Record'Class;
      Name: in     Ustring) is
   begin
      C.Name := Name;
      C.Me := Cls(C);
   end;

   procedure Free
     (C: in out Cls) is
   begin
      Free(C.all);
      Deallocate(C);
      C := null;
   end;

   function Get_Name
     (C: access Cls_Record'Class) return Ustring is
   begin
      return C.Name;
   end;

   procedure Set_Name
     (C   : access Cls_Record'Class;
      Name: in     Ustring) is
   begin
      C.Name := Name;
   end;

   function Get_Type
     (C: access Cls_Record'Class) return Cls_Type is
   begin
      return Get_Type(C.all);
   end;

   procedure Card
     (C     : access Cls_Record'Class;
      Result:    out Card_Type;
      State:    out Count_State) is
   begin
      Card(C.all, Result, State);
   end;

   function Low_Value
     (C: access Cls_Record'Class) return Expr is
      Result: Expr;
   begin
      Result := Low_Value(C.all);
      if Result.C = null then
         Set_Cls(Result, Cls(C));
      end if;
      return Result;
   end;

   function High_Value
     (C: access Cls_Record'Class) return Expr is
      Result: Expr;
   begin
      Result := High_Value(C.all);
      if Result.C = null then
         Set_Cls(Result, Cls(C));
      end if;
      return Result;
   end;

   function Ith_Value
     (C: access Cls_Record'Class;
      I: in     Card_Type) return Expr is
      Result: Expr;
   begin
      Result := Ith_Value(C.all, I);
      Set_Cls(Result, Cls(C));
      return Result;
   end;

   function Get_Value_Index
     (C: access Cls_Record'Class;
      E: access Expr_Record'Class) return Card_Type is
   begin
      return Get_Value_Index(C.all, E);
   end;

   function Elements_Size
     (C: access Cls_Record'Class) return Natural is
   begin
      return Elements_Size(C.all);
   end;

   function Basic_Elements_Size
     (C: access Cls_Record'Class) return Natural is
   begin
      return Basic_Elements_Size(C.all);
   end;

   function Is_Const_Of_Cls
     (C: access Cls_Record'Class;
      E: access Expr_Record'Class) return Boolean is
   begin
      pragma Assert(Is_Static(E));
      return Is_Const_Of_Cls(C.all, E);
   end;

   function Is_Discrete
     (C: access Cls_Record'Class) return Boolean is
   begin
      return Get_Type(C) in Discrete_Cls_Type;
   end;

   function Is_Container_Cls
     (C: access Cls_Record'Class) return Boolean is
   begin
      return Get_Type(C) in Container_Cls_Type;
   end;

   function Colors_Used
     (C: access Cls_Record'Class) return Cls_Set is
   begin
      return Colors_Used(C.all);
   end;

   function Has_Constant_Bit_Width
     (C: access Cls_Record'Class) return Boolean is
   begin
      return Has_Constant_Bit_Width(C.all);
   end;

   function Bit_Width
     (C: access Cls_Record'Class) return Natural is
   begin
      return Bit_Width(C.all);
   end;

   function Get_Root_Cls
     (C: access Cls_Record'Class) return Cls is
   begin
      return Get_Root_Cls(C.all);
   end;

   function Is_Castable
     (C: access Cls_Record'Class;
      To: access Cls_Record'Class) return Boolean is
   begin
      --===
      --  both class must be of the same type
      --===
      if Get_Type(C) /= Get_Type(To) then
         return False;
      end if;

      --===
      --  if they both have the same root class then the cast is possible
      --===
      if Get_Root_Cls(C) = Get_Root_Cls(To) then
         return True;
      end if;

      --===
      --  else the cast is only possible if C and To are numerical classes
      --===
      return Get_Type(C) = A_Num_Cls;
   end;

   function Is_Sub_Cls
     (C: access Cls_Record'Class) return Boolean is
   begin
      return C /= Get_Root_Cls(C);
   end;

   function Is_Sub_Cls
     (C     : access Cls_Record'Class;
      Parent: access Cls_Record'Class) return Boolean is
   begin
      return Is_Sub_Cls(C.all, Parent);
   end;

   procedure Compile
     (C  : access Cls_Record'Class;
      Lib: in     Library) is
   begin
      Section_Start_Comment(Lib, "color " & C.Name);
      Compile_Constants(C.all, Lib);
      Compile_Operators(C.all, Lib);
      Compile_Encoding_Functions(C.all, Lib);
      Compile_Io_Functions(C.all, Lib);
      Compile_Hash_Function(C.all, Lib);
      Compile_Others(C.all, Lib);
      Section_End_Comment(Lib);
   end;



   --==========================================================================
   --  Color domain
   --==========================================================================

   package CAP renames Cls_Array_Pkg;

   function New_Dom return Dom is
      Result: constant Dom := new Dom_Record;
   begin
      Result.Cls := CAP.Empty_Array;
      return Result;
   end;

   function New_Dom
     (C: in Cls) return Dom is
      Result: constant Dom := New_Dom((1 => C));
   begin
      return Result;
   end;

   function New_Dom
     (D: in Cls_Array) return Dom is
      Result: constant Dom := new Dom_Record;
   begin
      Result.Cls := CAP.New_Array(CAP.Element_Array(D));
      return Result;
   end;

   procedure Free
     (D: in out Dom) is
      procedure Deallocate is new Ada.Unchecked_Deallocation(Dom_Record, Dom);
   begin
      Deallocate(D);
   end;

   function Copy
     (D: in Dom) return Dom is
      Result: constant Dom := new Dom_Record;
   begin
      Result.Cls := D.Cls;
      return Result;
   end;

   function Size
     (D: in Dom) return Count_Type is
   begin
      return CAP.Length(D.Cls);
   end;

   --  compute the cardinal of the color domain which consists in D(I..D'last)
   procedure Sub_Card
     (D     : in     Dom;
      I     : in     Natural;
      Result:    out Card_Type;
      State:    out Count_State) is
      C: Card_Type;
   begin
      Result := 1;
      State := Count_Success;
      for J in I..Size(D) loop
         Card(Ith(D, J), C, State);
         if Is_Success(State) then
            Result := Result * C;
            if Result = 0 then
               raise Constraint_Error;
            end if;
         else
            return;
         end if;
      end loop;
   exception
      when Constraint_Error =>
         State := Count_Too_Large;
   end;

   procedure Card
     (D     : in     Dom;
      Result:    out Card_Type;
      State:    out Count_State) is
   begin
      Sub_Card(D, 1, Result, State);
   end;

   function Ith_Value
     (D: in Dom;
      I: in Card_Type) return Expr_List is
      Result: constant Expr_List := New_Expr_List;
      Still : Card_Type := I;
      Pos   : Card_Type;
      Sub   : Card_Type;
      C     : Cls;
      E     : Expr;
      State : Count_State;
      function Round_Up
        (Num: in Card_Type;
         Div: in Card_Type) return Card_Type is
         Result: Card_Type := Num / Div;
      begin
         if (Num mod Div) /= 0 then
            Result := Result + 1;
         end if;
         return Result;
      end;
   begin
      for I in 1..Size(D) loop
         C := Ith(D, I);
         Sub_Card(D, I + 1, Sub, State);
         pragma Assert(Is_Success(State));
         Pos := Round_Up(Still, Sub);
         Still := Still - ((Pos - 1) * Sub);
         E := Ith_Value(C, Pos);
         Append(Result, E);
      end loop;
      return Result;
   end;

   function Get_Index
     (D: in Dom;
      T: in Expr_List) return Card_Type is
      Result: Card_Type := 1;
      C     : Cls;
      E     : Expr;
      E_Pos : Card_Type;
      Cc    : Card_Type;
      State : Count_State;
   begin
      for I in 1..Size(D) loop
         C    := Ith(D, I);
         E    := Ith(T, I);
         E_Pos := Get_Value_Index(C, E);
         Sub_Card(D, I + 1, Cc, State);
         pragma Assert(Is_Success(State));
         Result := Result + (E_Pos - 1) * Cc;
      end loop;
      return Result;
   end;

   function Ith
     (D: in Dom;
      I: in Index_Type) return Cls is
   begin
      return CAP.Ith(D.Cls, I);
   end;

   procedure Insert
     (D: in Dom;
      C: in Cls;
      I: in Index_Type) is
   begin
      CAP.Insert(D.Cls, C, I);
   end;

   procedure Append
     (D: in Dom;
      C: in Cls) is
   begin
      CAP.Append(D.Cls, C);
   end;

   procedure Append
     (D: in Dom;
      E: in Dom) is
   begin
      CAP.Append(D.Cls, E.Cls);
   end;

   procedure Delete
     (D: in Dom;
      I: in Index_Type) is
   begin
      CAP.Delete(D.Cls, I);
   end;

   procedure Delete_Last
     (D: in Dom) is
   begin
      CAP.Delete_Last(D.Cls);
   end;

   function Same
     (D1: in Dom;
      D2: in Dom) return Boolean is
      function Equal
        (C1: in Cls;
         C2: in Cls) return Boolean is
      begin
         return Get_Name(C1) = Get_Name(C2);
      end;
      function Equal is new CAP.Generic_Equal(Equal);
   begin
      return Equal(D1.Cls, D2.Cls);
   end;

   function Has_Constant_Bit_Width
     (D: in Dom) return Boolean is
      function Pred
        (C: in Cls) return Boolean is
      begin
         return Has_Constant_Bit_Width(C);
      end;
      function Has_Constant_Bit_Width is new CAP.Generic_Forall(Pred);
   begin
      return Has_Constant_Bit_Width(D.Cls);
   end;

   function Bit_Width
     (D: in Dom) return Natural is
      Result: Natural := 0;
   begin
      for I in 1..Size(D) loop
         Result := Result + Bit_Width(Ith(D, I));
      end loop;
      return Result;
   end;

   function Slot_Width
     (D: in Dom) return Natural is
      Bits  : constant Natural := Bit_Width(D);
      Result: Natural;
   begin
      if Bits mod Bits_Per_Slot /= 0 then
         Result := 1 + Bits / Bits_Per_Slot;
      else
         Result := Bits / Bits_Per_Slot;
      end if;
      return Result;
   end;

   function To_Helena
     (D: in Dom) return Ustring is
      Result: Ustring := Null_String;
   begin
      if Size(D) = 0 then
	 Result := Result & "epsilon";
      else
	 for I in 1..Size(D) loop
	    if I > 1 then
	       Result := Result & " * ";
	    end if;
	    Result := Result & Get_Name(Ith(D, I));
	 end loop;
      end if;
      return Result;
   end;



   --==========================================================================
   --  Color class set
   --==========================================================================

   package CSP renames Cls_Set_Pkg;

   function New_Cls_Set return Cls_Set is
      Result: constant Cls_Set := new Cls_Set_Record;
   begin
      Result.Cls := CSP.Empty_Set;
      return Result;
   end;

   function New_Cls_Set
     (Set: in Cls_Array) return Cls_Set is
      Result: constant Cls_Set := new Cls_Set_Record;
   begin
      Result.Cls := CSP.New_Set(CSP.Element_Array(Set));
      return Result;
   end;

   procedure Free
     (Set: in out Cls_Set) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Cls_Set_Record, Cls_Set);
   begin
      Deallocate(Set);
      Set := null;
   end;

   procedure Free_All
     (Set: in out Cls_Set) is
      procedure Free is new CSP.Generic_Apply(Free);
   begin
      Free(Set.Cls);
      Free(Set);
   end;

   function Copy
     (Set: in Cls_Set) return Cls_Set is
      Result: constant Cls_Set := new Cls_Set_Record;
   begin
      Result.Cls := Set.Cls;
      return Result;
   end;

   function Ith
     (Set: in Cls_Set;
      I  : in Index_Type) return Cls is
   begin
      return CSP.Ith(Set.Cls, I);
   end;

   function Card
     (Set: in Cls_Set) return Natural is
   begin
      return CSP.Card(Set.Cls);
   end;

   function Is_Empty
     (Set: in Cls_Set) return Boolean is
   begin
      return CSP.Is_Empty(Set.Cls);
   end;

   function Contains
     (Set: in Cls_Set;
      C  : in Cls) return Boolean is
   begin
      return CSP.Contains(Set.Cls, C);
   end;

   function Contains
     (Set: in Cls_Set;
      C  : in Ustring) return Boolean is
      function Is_C
        (C: in Cls) return Boolean is
      begin
         return Get_Name(C) = Contains.C;
      end;
      function Contains is new CSP.Generic_Exists(Is_C);
   begin
      return Contains(Set.Cls);
   end;

   function Get
     (Set: in Cls_Set;
      C  : in Ustring) return Cls is
      function Is_C
        (C: in Cls) return Boolean is
      begin
         return Get_Name(C) = Get.C;
      end;
      function Get is new CSP.Generic_Get_Satisfying_Element(Is_C);
   begin
      return Get(Set.Cls);
   end;

   procedure Insert
     (Set: in Cls_Set;
      C  : in Cls) is
   begin
      CSP.Insert(Set.Cls, C);
   end;

   function Subset
     (Sub: in Cls_Set;
      Set: in Cls_Set) return Boolean is
   begin
      return CSP.Subset(Sub.Cls, Set.Cls);
   end;

   function Equal
     (Set1: in Cls_Set;
      Set2: in Cls_Set) return Boolean is
   begin
      return CSP.Equal(Set1.Cls, Set2.Cls);
   end;

   function Intersect
     (Set1: in Cls_Set;
      Set2: in Cls_Set) return Cls_Set is
      Result: constant Cls_Set := new Cls_Set_Record;
   begin
      Result.Cls := CSP."and"(Set1.Cls, Set2.Cls);
      return Result;
   end;

   procedure Filter_On_Type
     (Set  : in Cls_Set;
      Types: in Cls_Type_Set) is
      function Predicate
        (C: in Cls) return Boolean is
      begin
         return not Types(Get_Type(C));
      end;
      procedure Filter is new CSP.Generic_Delete(Predicate);
   begin
      Filter(Set.Cls);
   end;

   function Filter_On_Type
     (Set  : in Cls_Set;
      Types: in Cls_Type_Set) return Cls_Set is
      function Predicate
        (C: in Cls) return Boolean is
      begin
         return Types(Get_Type(C));
      end;
      function Filter is new CSP.Generic_Subset(Predicate);
      Result: constant Cls_Set := new Cls_Set_Record;
   begin
      Result.Cls := Filter(Set.Cls);
      return Result;
   end;

   function Generic_Filter_On_Type
     (Set  : in Cls_Set;
      Types: in Cls_Type_Set) return Cls_Set is
      function Types_Ok
        (C: in Cls) return Boolean is
      begin
         return Types(Get_Type(C)) and then Predicate(C);
      end;
      function Filter is new CSP.Generic_Subset(Types_Ok);
      Result: constant Cls_Set := new Cls_Set_Record;
   begin
      Result.Cls := Filter(Set.Cls);
      return Result;
   end;

   function Generic_Filter
     (Set: in Cls_Set) return Cls_Set is
      function Filter is new Generic_Filter_On_Type(Predicate);
   begin
      return Filter(Set, (others => True));
   end;

   function Get_Types
     (Set: in Cls_Set) return Cls_Type_Set is
      Result: Cls_Type_Set := (others => False);
      C     : Cls;
   begin
      for I in 1..Card(Set) loop
         C := Ith(Set, I);
         Result(Get_Type(C)) := True;
      end loop;
      return Result;
   end;

   procedure Choose
     (Set  : in     Cls_Set;
      C    :    out Cls;
      State:    out Coloring_State) is
      Roots: Cls_Set := Get_Root_Cls(Set);
      Types: Cls_Type_Set;
   begin
      if Card(Roots) = 1 then
         C := Ith(Roots, 1);
         State := Coloring_Success;
      else
         Types := Get_Types(Roots);
         if Card(Types) > 1 or else not Types(A_Num_Cls) then
            State := Coloring_Ambiguous_Expression;
         else
            C := Int_Cls;
            State := Coloring_Success;
         end if;
      end if;
      Free(Roots);
   end;

   function Get_Root_Cls
     (Set: in Cls_Set) return Cls_Set is
      Result: constant Cls_Set := New_Cls_Set;
      C     : Cls;
   begin
      for I in 1..Card(Set) loop
         C := Get_Root_Cls(Ith(Set, I));
         if not Contains(Result, C) then
            Insert(Result, C);
         end if;
      end loop;
      return Result;
   end;

   function To_String
     (Set: in Cls_Set) return Ustring is
      function To_String
        (C: in Cls) return String is
      begin
         return To_String(Get_Name(C));
      end;
      function To_String is new CSP.Generic_To_String(", ", "", To_String);
   begin
      return To_Ustring("{" & To_String(Set.Cls) & "}");
   end;

   procedure Generic_Apply_In_Right_Order
     (Set             : in Cls_Set;
      Apply_Predefined: in Boolean) is
      Already: Cls_Set := New_Cls_Set;
      C      : Cls;
      Used   : Cls_Set;
   begin
      while not Equal(Set, Already) loop
         for I in 1..Card(Set) loop
            C := Ith(Set, I);
            if Apply_Predefined or else not Is_Predefined_Cls(C.Name) then
               if not Contains(Already, C) then
                  Used := Colors_Used(C);
                  if Subset(Used, Already) then
                     Action(C);
                     Insert(Already, C);
                  end if;
                  Free(Used);
               end if;
            else
               Insert(Already, C);
            end if;
         end loop;
      end loop;
      Free(Already);
   end;

   procedure Compile
     (Set: in Cls_Set;
      Lib: in Library) is
      procedure Action
        (C: in Cls) is
      begin
         Compile(C, Lib);
      end;
      procedure Apply is new Generic_Apply_In_Right_Order(Action);
   begin
      Apply(Set, True);
   end;

   procedure Compile_Type_Definitions
     (Set: in Cls_Set;
      Lib: in Library) is
      procedure Action
        (C: in Cls) is
      begin
         Plh(Lib, "/***");
         Plh(Lib, " *  type " & C.Name);
         Plh(Lib, " ***/");
         Compile_Type_Definition(C.all, Lib);
         Nlh(Lib);
      end;
      procedure Apply is new Generic_Apply_In_Right_Order(Action);
   begin
      Apply(Set, True);
   end;



   --==========================================================================
   --  Predefined color classes
   --==========================================================================

   Predefined_Cls: Cls_Set;

   function Get_Predefined_Cls return Cls_Array is
      Result: Cls_Array(1 .. Card(Predefined_Cls));
   begin
      for I in Result'Range loop
         Result(I) := Ith(Predefined_Cls, I);
      end loop;
      return Result;
   end;

   function Is_Predefined_Cls
     (C: in Ustring) return Boolean is
   begin
      return Contains(Predefined_Cls, C);
   end;

   function Get_Predefined_Cls
     (C: in Ustring) return Cls is
   begin
      pragma Assert(Is_Predefined_Cls(C));
      return Get(Predefined_Cls, C);
   end;

   function Bool_Cls return Cls is
   begin
      return Get_Predefined_Cls(Bool_Cls_Name);
   end;

   function Int_Cls return Cls is
   begin
      return Get_Predefined_Cls(Int_Cls_Name);
   end;

   function Nat_Cls return Cls is
   begin
      return Get_Predefined_Cls(Nat_Cls_Name);
   end;

   function Short_Cls return Cls is
   begin
      return Get_Predefined_Cls(Short_Cls_Name);
   end;

   function Unsigned_Short_Cls return Cls is
   begin
      return Get_Predefined_Cls(Unsigned_Short_Cls_Name);
   end;

   procedure Add_Predefined_Cls
     (C: in Cls) is
   begin
      Insert(Predefined_Cls, C);
   end;


begin

   Predefined_Cls := New_Cls_Set;

end Pn.Classes;
