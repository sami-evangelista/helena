with
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Classes.Structs;

use
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Classes.Structs;

package body Pn.Exprs.Structs is

   function New_Struct
     (E: in Expr_List;
      C: in Cls) return Expr is
      Result: constant Struct := new Struct_Record;
   begin
      Initialize(Result, C);
      Result.E := E;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Struct_Record) is
   begin
      Free_All(E.E);
   end;

   function Copy
     (E: in Struct_Record) return Expr is
      Result: constant Struct := new Struct_Record;
   begin
      Initialize(Result, E.C);
      Result.E := Copy(E.E);
      return Expr(Result);
   end;

   function Get_Type
     (E: in Struct_Record) return Expr_Type is
   begin
      return A_Struct;
   end;

   procedure Color_Expr
     (E    : in     Struct_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Sc: constant Struct_Cls := Struct_Cls(C);
   begin
      for I in 1..Length(E.E) loop
         Color_Expr(Ith(E.E, I), Get_Cls(Ith_Component(Sc, I)), Cs, State);
         if not Is_Success(State) then
            return;
         end if;
      end loop;
   end;

   function Possible_Colors
     (E : in Struct_Record;
      Cs: in Cls_Set) return Cls_Set is
      function Pred
        (C: in Cls) return Boolean is
         Ith_Possible: Cls_Set;
         Ith_Expr    : Expr;
         Struct_Color: constant Struct_Cls := Struct_Cls(C);
         Result      : Boolean;
      begin
         --===
         --  check that the structured expression has the same size as the
         --  structured color
         --===
         if Elements_Size(Cls(Struct_Color)) /= Length(E.E) then
            return False;
         end if;

         --===
         --  check that potential colors of the structure and the
         --  structured color match
         --===
         for I in 1..Length(E.E) loop
            Ith_Expr := Ith(E.E, I);
            Ith_Possible := Possible_Colors(Ith_Expr, Cs);
            Result :=
              Contains(Ith_Possible,
                       Get_Root_Cls(Get_Cls(Ith_Component(Struct_Color, I))));
            Free(Ith_Possible);
            if not Result then
               return False;
            end if;
         end loop;
         return True;
      end;
      function Filter is new Generic_Filter_On_Type(Pred);
   begin
      return Filter(Cs, (A_Struct_Cls => True,
                         others       => False));
   end;

   function Is_Static
     (E: in Struct_Record) return Boolean is
   begin
      return Is_Static(E.E);
   end;

   function Is_Basic
     (E: in Struct_Record) return Boolean is
   begin
      return Is_Basic(E.E);
   end;

   function Get_True_Cls
     (E: in Struct_Record) return Cls is
   begin
      return E.C;
   end;

   function Can_Overflow
     (E: in Struct_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Struct_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
      L: Expr_List := New_Expr_List;
      Ex: Expr;
   begin
      for I in 1..Length(E.E) loop
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
      end loop;
      Result := New_Struct(L, E.C);
      State := Evaluation_Success;
   end;

   function Static_Equal
     (Left: in Struct_Record;
      Right: in Struct_Record) return Boolean is
   begin
      return Static_Equal(Left.E, Right.E);
   end;

   function Compare
     (Left: in Struct_Record;
      Right: in Struct_Record) return Comparison_Result is
   begin
      return Compare(Left.E, Right.E);
   end;

   function Vars_In
     (E: in Struct_Record) return Var_List is
   begin
      return Vars_In(E.E);
   end;

   procedure Get_Sub_Exprs
     (E: in Struct_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.E, R);
   end;

   procedure Get_Observed_Places
     (E     : in     Struct_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.E, Places);
   end;

   function To_Helena
     (E: in Struct_Record) return Ustring is
   begin
      return "{" & To_Helena(E.E) & "}";
   end;

   function Compile_Evaluation
     (E: in Struct_Record;
      M: in Var_Mapping) return Ustring is
   begin
      return
        Cls_Constructor_Func(E.C) &
        "(" & Compile_Evaluation(E.E, M, True) & ")";
   end;

   function Replace_Var
     (E: in Struct_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: Expr;
   begin
      Result := New_Struct(Replace_Var(E.E, V, Ne), E.C);
      return Result;
   end;

   function Get_Components
     (S: in Struct) return Expr_List is
   begin
      return S.E;
   end;

   procedure Append
     (S: in Struct;
      E: in Expr) is
   begin
      Append(S.E, E);
   end;

   function Get_Component
     (S   : in Struct;
      Comp: in Ustring) return Expr is
      C: constant Struct_Cls := Struct_Cls(S.C);
      I: constant Index_Type := Get_Component_Index(C, Comp);
   begin
      return Ith(S.E, I);
   end;

   procedure Replace_Component
     (S   : in Struct;
      Comp: in Ustring;
      E   : in Expr) is
      C: constant Struct_Cls := Struct_Cls(S.C);
      I: constant Index_Type := Get_Component_Index(C, Comp);
   begin
      Replace(S.E, I, E, True);
   end;

end Pn.Exprs.Structs;
