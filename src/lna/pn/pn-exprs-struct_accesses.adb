with
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Classes,
  Pn.Exprs.Structs,
  Pn.Exprs.Struct_Assigns,
  Pn.Classes.Structs;

use
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Classes,
  Pn.Exprs.Structs,
  Pn.Exprs.Struct_Assigns,
  Pn.Classes.Structs;

package body Pn.Exprs.Struct_Accesses is

   function New_Struct_Access
     (Struct: in Expr;
      Comp  : in Ustring;
      C     : in Cls) return Expr is
      Result: constant Struct_Access := new Struct_Access_Record;
   begin
      Initialize(Result, C);
      Result.Struct := Struct;
      Result.Comp := Comp;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Struct_Access_Record) is
   begin
      Free(E.Struct);
   end;

   function Copy
     (E: in Struct_Access_Record) return Expr is
      Result: constant Struct_Access := new Struct_Access_Record;
   begin
      Initialize(Result, E.C);
      Result.Struct := Copy(E.Struct);
      Result.Comp := E.Comp;
      return Expr(Result);
   end;

   function Get_Type
     (E: in Struct_Access_Record) return Expr_Type is
   begin
      return A_Struct_Access;
   end;

   procedure Color_Expr
     (E    : in     Struct_Access_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Possible_Struct: Cls_Set := Possible_Colors(E.Struct, Cs);
   begin
      if not Is_Empty(Possible_Struct) then
         if Card(Possible_Struct) = 1 then
            Color_Expr(E.Struct, Ith(Possible_Struct, 1), Cs, State);
            Free(Possible_Struct);
         else
            Free(Possible_Struct);
            State := Coloring_Ambiguous_Expression;
         end if;
      else
         Free(Possible_Struct);
         State := Coloring_Failure;
      end if;
   end;

   function Possible_Colors
     (E: in Struct_Access_Record;
      Cs: in Cls_Set) return Cls_Set is
      Possible_Struct: Cls_Set := Possible_Colors(E.Struct, Cs);
      Struct         : Struct_Cls;
      Result         : constant Cls_Set := New_Cls_Set;
   begin
      Filter_On_Type(Possible_Struct, (A_Struct_Cls => True,
                                       others       => False));
      for I in 1..Card(Possible_Struct) loop
         Struct := Struct_Cls(Ith(Possible_Struct, I));
         if Contains_Component(Struct, E.Comp) then
            Insert(Result, Get_Cls(Get_Component(Struct, E.Comp)));
         end if;
      end loop;
      Free(Possible_Struct);
      return Result;
   end;

   function Is_Assignable
     (E: in Struct_Access_Record) return Boolean is
   begin
      return Is_Assignable(E.Struct);
   end;

   function Is_Static
     (E: in Struct_Access_Record) return Boolean is
   begin
      return Is_Static(E.Struct);
   end;

   function Is_Basic
     (E: in Struct_Access_Record) return Boolean is
   begin
      return Is_Basic(E.Struct);
   end;

   function Get_True_Cls
     (E: in Struct_Access_Record) return Cls is
      C: constant Struct_Cls := Struct_Cls(Get_Cls(E.Struct));
   begin
      return Get_Root_Cls(Get_Cls(Get_Component(C, E.Comp)));
   end;

   function Can_Overflow
     (E: in Struct_Access_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Struct_Access_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
      Struct_Expr: Expr;
   begin
      Evaluate(E      => E.Struct,
               B      => B,
               Check  => False,
               Result => Struct_Expr,
               State  => State);
      if Is_Success(State) then
         Result := Copy(Get_Component(Struct(Struct_Expr), E.Comp));
         Free(Struct_Expr);
      end if;
   end;

   function Static_Equal
     (Left: in Struct_Access_Record;
      Right: in Struct_Access_Record) return Boolean is
   begin
      return
        Left.Comp = Right.Comp and then
        Static_Equal(Left.Struct, Right.Struct);
   end;

   function Compare
     (Left: in Struct_Access_Record;
      Right: in Struct_Access_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in Struct_Access_Record) return Var_List is
   begin
      return Vars_In(E.Struct);
   end;

   procedure Get_Sub_Exprs
     (E: in Struct_Access_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.Struct, R);
   end;

   procedure Get_Observed_Places
     (E     : in     Struct_Access_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.Struct, Places);
   end;

   procedure Assign
     (E  : in Struct_Access_Record;
      B  : in Binding;
      Val: in Expr) is
      Struct_Expr: Expr;
      State      : Evaluation_State;
   begin
      Evaluate(E      => E.Struct,
               B      => B,
               Check  => False,
               Result => Struct_Expr,
               State  => State);
      Replace_Component(Struct(Struct_Expr), E.Comp, Val);
      Assign(E.Struct, B, Struct_Expr);
   end;

   function Get_Assign_Expr
     (E  : in Struct_Access_Record;
      Val: in Expr) return Expr is
      C        : constant Struct_Cls := Struct_Cls(E.Struct.C);
      Component: constant Struct_Comp := Get_Component(C, E.Comp);
      New_Val  : Expr;
      Result   : Expr;
   begin
      New_Val := New_Struct_Assign(Copy(E.Struct), E.Comp, Val, Cls(C));
      Result := Get_Assign_Expr(E.Struct, New_Val);
      return Result;
   end;

   function To_Helena
     (E: in Struct_Access_Record) return Ustring is
   begin
      return To_Helena(E.Struct) & "." & E.Comp;
   end;

   function Compile_Evaluation
     (E: in Struct_Access_Record;
      M: in Var_Mapping) return Ustring is
   begin
      return
        Compile_Evaluation(E.Struct, M, False) & "." &
        Cls_Struct_Comp_Name(E.Comp);
   end;

   function Replace_Var
     (E: in Struct_Access_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: Expr;
   begin
      Result := New_Struct_Access(Replace_Var(E.Struct, V, Ne), E.Comp, E.C);
      return Result;
   end;

   function Get_Accessed_Component_Name
     (S: in Struct_Access) return Ustring is
   begin
      return S.Comp;
   end;

end Pn.Exprs.Struct_Accesses;
