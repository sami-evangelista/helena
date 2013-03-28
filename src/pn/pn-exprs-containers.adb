with
  Pn.Compiler.Names,
  Pn.Classes,
  Pn.Classes.Containers;

use
  Pn.Compiler.Names,
  Pn.Classes,
  Pn.Classes.Containers;

package body Pn.Exprs.Containers is

   function New_Container
     (E: in Expr_List;
      C: in Cls) return Expr is
      Result: constant Container := new Container_Record;
   begin
      Initialize(Result, C);
      Result.E := E;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Container_Record) is
   begin
      Free(E.E);
   end;

   function Copy
     (E: in Container_Record) return Expr is
   begin
      return New_Container(Copy(E.E), E.C);
   end;

   function Get_Type
     (E: in Container_Record) return Expr_Type is
   begin
      return A_Container;
   end;

   procedure Color_Expr
     (E    : in     Container_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Cc    : constant Container_Cls := Container_Cls(C);
      El_Cls: constant Cls          := Get_Elements_Cls(Cc);
   begin
      for I in 1..Length(E.E) loop
         Color_Expr(Ith(E.E, I), El_Cls, Cs, State);
         if not Is_Success(State) then
            return;
         end if;
      end loop;
   end;

   function Possible_Colors
     (E: in Container_Record;
      Cs: in Cls_Set) return Cls_Set is
      function Pred
        (C: in Cls) return Boolean is
         Cc      : constant Container_Cls := Container_Cls(C);
         El_Cls  : constant Cls          := Get_Elements_Cls(Cc);
         Possible: Cls_Set;
         Ex      : Expr;
         Result  : Boolean;
      begin
         --===
         --  for each element E of the list we check that the element class of
         --  the list color C is included the possible colors of E
         --===
         for I in 1..Length(E.E) loop
            Ex      := Ith(E.E, I);
            Possible := Possible_Colors(Ex, Cs);
            Result  := Contains(Possible, Get_Root_Cls(El_Cls));
            Free(Possible);
            if not Result then
               return False;
            end if;
         end loop;
         return True;
      end;
      function Filter is new Generic_Filter_On_Type(Pred);
   begin
      return Filter(Cs, (A_List_Cls => True,
                         A_Set_Cls  => True,
                         others     => False));
   end;

   function Is_Static
     (E: in Container_Record) return Boolean is
   begin
      return Is_Static(E.E);
   end;

   function Is_Basic
     (E: in Container_Record) return Boolean is
   begin
      return Is_Basic(E.E);
   end;

   function Get_True_Cls
     (E: in Container_Record) return Cls is
   begin
      return E.C;
   end;

   function Can_Overflow
     (E: in Container_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Container_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
      Cap: constant Num_Type := Get_Capacity_Value(Container_Cls(E.C));
      L  : Expr_List;
   begin
      Evaluate(E      => E.E,
               B      => B,
               Check  => True,
               Result => L,
               State  => State);
      if Is_Success(State) then
         if Length(L) > Natural(Cap) then
            State := Evaluation_List_Overflow;
         else
            Result := New_Container(L, E.C);
         end if;
      end if;
   end;

   function Static_Equal
     (Left: in Container_Record;
      Right: in Container_Record) return Boolean is
   begin
      return Static_Equal(Left.E, Right.E);
   end;

   function Compare
     (Left: in Container_Record;
      Right: in Container_Record) return Comparison_Result is
   begin
      return Compare(Left.E, Right.E);
   end;

   function Vars_In
     (E: in Container_Record) return Var_List is
   begin
      return Vars_In(E.E);
   end;

   procedure Get_Sub_Exprs
     (E: in Container_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.E, R);
   end;

   procedure Get_Observed_Places
     (E     : in     Container_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.E, Places);
   end;

   function To_Helena
     (E: in Container_Record) return Ustring is
   begin
      if Length(E.E) > 0 then
         return "|" & To_Helena(E.E) & "|";
      else
         return To_Ustring("empty");
      end if;
   end;

   function Compile_Evaluation
     (E: in Container_Record;
      M: in Var_Mapping) return Ustring is
      Result: Ustring;
   begin
      Result := Cls_Constructor_Func(E.C) & "(" & Length(E.E);
      if Length(E.E) > 0 then
         Result := Result & ", ";
      end if;
      Result := Result & Compile_Evaluation(E.E, M, True);
      Result := Result & ")";
      return Result;
   end;

   function Replace_Var
     (E: in Container_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: constant Expr := New_Container(Replace_Var(E.E, V, Ne), E.C);
   begin
      return Result;
   end;

   function Get_Expr_List
     (C: in Container) return Expr_List is
   begin
      return C.E;
   end;

   procedure Replace_Element
     (C: in Container;
      E: in Expr;
      I: in Index_Type) is
   begin
      Replace(C.E, I, E, True);
   end;

end Pn.Exprs.Containers;
