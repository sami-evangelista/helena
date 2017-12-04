with
  Pn.Classes,
  Pn.Classes.Containers.Lists,
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Containers,
  Pn.Vars;

use
  Pn.Classes,
  Pn.Classes.Containers.Lists,
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Containers,
  Pn.Vars;

package body Pn.Exprs.List_Slices is

   function New_List_Slice
     (L    : in Expr;
      First: in Expr;
      Last: in Expr;
      C    : in Cls) return Expr is
      Result: constant List_Slice := new List_Slice_Record;
   begin
      Initialize(L, C);
      Result.L    := L;
      Result.First := First;
      Result.Last := Last;
      return Expr(Result);
   end;

   procedure Free
     (E: in out List_Slice_Record) is
   begin
      Free(E.L);
      Free(E.First);
      Free(E.Last);
   end;

   function Copy
     (E: in List_Slice_Record) return Expr is
   begin
      return New_List_Slice(Copy(E.L),
                            Copy(E.First),
                            Copy(E.Last),
                            E.C);
   end;

   function Get_Type
     (E: in List_Slice_Record) return Expr_Type is
   begin
      return A_List_Slice;
   end;

   procedure Color_Expr
     (E    : in     List_Slice_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Index_Cls: constant Cls := Get_Index_Cls(List_Cls(C));
   begin
      Color_Expr(E.L, C, Cs, State);
      if Is_Success(State) then
         Color_Expr(E.First, Index_Cls, Cs, State);
         if Is_Success(State) then
            Color_Expr(E.Last,  Index_Cls, Cs, State);
         end if;
      end if;
   end;

   function Possible_Colors
     (E: in List_Slice_Record;
      Cs: in Cls_Set) return Cls_Set is
      Result: constant Cls_Set := Possible_Colors(E.L, Cs);
   begin
      Filter_On_Type(Result, (A_List_Cls => True,
                              others     => False));
      return Result;
   end;

   function Is_Static
     (E: in List_Slice_Record) return Boolean is
   begin
      return False;
   end;

   function Is_Basic
     (E: in List_Slice_Record) return Boolean is
   begin
      return Is_Basic(E.L) and Is_Basic(E.First) and Is_Basic(E.Last);
   end;

   function Get_True_Cls
     (E: in List_Slice_Record) return Cls is
   begin
      return Get_True_Cls(E.L);
   end;

   function Can_Overflow
     (E: in List_Slice_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     List_Slice_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
   begin
      pragma Assert(False);
      Result := null;
      State := Evaluation_Failure;
   end;

   function Static_Equal
     (Left: in List_Slice_Record;
      Right: in List_Slice_Record) return Boolean is
   begin
      return
        Static_Equal(Left.L,     Right.L)     and then
        Static_Equal(Left.First, Right.First) and then
        Static_Equal(Left.Last,  Right.Last);
   end;

   function Compare
     (Left: in List_Slice_Record;
      Right: in List_Slice_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in List_Slice_Record) return Var_List is
      Result: constant Var_List := Vars_In(E.L);
      First: Var_List := Vars_In(E.First);
      Last  : Var_List := Vars_In(E.Last);
   begin
      Union(Result, First);
      Union(Result, Last);
      Free(First);
      Free(Last);
      return Result;
   end;

   procedure Get_Sub_Exprs
     (E: in List_Slice_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.L,     R);
      Get_Sub_Exprs(E.First, R);
      Get_Sub_Exprs(E.Last,  R);
   end;

   procedure Get_Observed_Places
     (E     : in     List_Slice_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.L,     Places);
      Get_Observed_Places(E.First, Places);
      Get_Observed_Places(E.Last,  Places);
   end;

   function To_Helena
     (E: in List_Slice_Record) return Ustring is
   begin
      return
        To_Helena(E.L) &
        "[" & To_Helena(E.First) & " .. " & To_Helena(E.Last) &  "]";
   end;

   function Compile_Evaluation
     (E: in List_Slice_Record;
      M: in Var_Mapping) return Ustring is
   begin
      return
        Cls_Slice_Func(Get_Cls(E.L)) &
        "(" & Compile_Evaluation(E.L,     M) & "," &
        " " & Compile_Evaluation(E.First, M) & "," &
        " " & Compile_Evaluation(E.Last,  M) & ")";
   end;

   function Replace_Var
     (E: in List_Slice_Record;
      V: in Var;
      Ne: in Expr) return Expr is
   begin
      return New_List_Slice(Replace_Var(E.L,     V, Ne),
                            Replace_Var(E.First, V, Ne),
                            Replace_Var(E.Last,  V, Ne), E.C);
   end;

end Pn.Exprs.List_Slices;
