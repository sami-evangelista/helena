with
  Pn.Compiler.Names,
  Pn.Classes.Containers,
  Pn.Classes.Containers.Lists,
  Pn.Vars;

use
  Pn.Compiler.Names,
  Pn.Classes.Containers,
  Pn.Classes.Containers.Lists,
  Pn.Vars;

package body Pn.Exprs.List_Assigns is

   function New_List_Assign
     (L: in Expr;
      I: in Expr;
      E: in Expr;
      C: in Cls) return Expr is
      Result: constant List_Assign := new List_Assign_Record;
   begin
      Initialize(Result, C);
      Result.L := L;
      Result.I := I;
      Result.E := E;
      return Expr(Result);
   end;

   procedure Free
     (E: in out List_Assign_Record) is
   begin
      Free(E.L);
      Free(E.I);
      Free(E.E);
   end;

   function Copy
     (E: in List_Assign_Record) return Expr is
   begin
      return New_List_Assign(Copy(E.L), Copy(E.I), Copy(E.E), E.C);
   end;

   function Get_Type
     (E: in List_Assign_Record) return Expr_Type is
   begin
      return A_List_Assign;
   end;

   procedure Color_Expr
     (E    : in     List_Assign_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Index_Cls   : constant Cls := Get_Index_Cls(List_Cls(C));
      Elements_Cls: constant Cls := Get_Elements_Cls(Container_Cls(C));
   begin
      Color_Expr(E.L, C, Cs, State);
      if Is_Success(State) then
         Color_Expr(E.I, Index_Cls, Cs, State);
         if Is_Success(State) then
            Color_Expr(E.E, Elements_Cls, Cs, State);
         end if;
      end if;
   end;

   function Possible_Colors
     (E: in List_Assign_Record;
      Cs: in Cls_Set) return Cls_Set is
   begin
      return Possible_Colors(E.L, Cs);
   end;

   function Is_Static
     (E: in List_Assign_Record) return Boolean is
   begin
      return False;
   end;

   function Is_Basic
     (E: in List_Assign_Record) return Boolean is
   begin
      return Is_Basic(E.L) and Is_Basic(E.I) and Is_Basic(E.E);
   end;

   function Get_True_Cls
     (E: in List_Assign_Record) return Cls is
   begin
      return Get_True_Cls(E.L);
   end;

   function Can_Overflow
     (E: in List_Assign_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     List_Assign_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
   begin
      pragma Assert(False);
      Result := null;
      State := Evaluation_Failure;
   end;

   function Static_Equal
     (Left: in List_Assign_Record;
      Right: in List_Assign_Record) return Boolean is
   begin
      return
        Static_Equal(Left.L, Right.L) and
        Static_Equal(Left.I, Right.I) and
        Static_Equal(Left.E, Right.E);
   end;

   function Compare
     (Left: in List_Assign_Record;
      Right: in List_Assign_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in List_Assign_Record) return Var_List is
      Result  : constant Var_List := Vars_In(E.L);
      In_Index: Var_List := Vars_In(E.I);
      In_Value: Var_List := Vars_In(E.E);
   begin
      Union(Result, In_Index);
      Union(Result, In_Value);
      Free(In_Index);
      Free(In_Value);
      return Result;
   end;

   procedure Get_Sub_Exprs
     (E: in List_Assign_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.L, R);
      Get_Sub_Exprs(E.I, R);
      Get_Sub_Exprs(E.E, R);
   end;

   procedure Get_Observed_Places
     (E     : in     List_Assign_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.L, Places);
      Get_Observed_Places(E.I, Places);
      Get_Observed_Places(E.E, Places);
   end;

   function To_Helena
     (E: in List_Assign_Record) return Ustring is
   begin
      return
        To_Helena(E.L) & " list ([" &
        To_Helena(E.I) & "] word " &
        To_Helena(E.E) & ")";
   end;

   function Compile_Evaluation
     (E: in List_Assign_Record;
      M: in Var_Mapping) return Ustring is
   begin
      return
        Cls_Assign_Func(E.C) &
        "(" &
        Compile_Evaluation(E.L, M, False) & ", " &
        Compile_Evaluation(E.E, M, True) & ", " &
        Compile_Evaluation(E.I, M, True) &
        ")";
   end;

   function Replace_Var
     (E: in List_Assign_Record;
      V: in Var;
      Ne: in Expr) return Expr is
   begin
      return New_List_Assign(Replace_Var(E.L, V, Ne),
                             Replace_Var(E.I, V, Ne),
                             Replace_Var(E.E, V, Ne),
                             E.C);
   end;

end Pn.Exprs.List_Assigns;
