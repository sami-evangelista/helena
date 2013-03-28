with
  Pn.Classes,
  Pn.Compiler,
  Pn.Compiler.Domains,
  Pn.Classes.Products;

use
  Pn.Classes,
  Pn.Compiler,
  Pn.Compiler.Domains,
  Pn.Classes.Products;

package body Pn.Exprs.Tuple_Accesses is

   function New_Tuple_Access
     (T   : in Expr;
      Comp: in Natural;
      C   : in Cls) return Expr is
      Result: constant Tuple_Access := new Tuple_Access_Record;
   begin
      Initialize(Result, C);
      Result.T   := T;
      Result.Comp := Comp;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Tuple_Access_Record) is
   begin
      Free(E.T);
   end;

   function Copy
     (E: in Tuple_Access_Record) return Expr is
      Result: constant Tuple_Access := new Tuple_Access_Record;
   begin
      Initialize(Result, E.C);
      Result.T := E.T;
      Result.Comp := E.Comp;
      return Expr(Result);
   end;

   function Get_Type
     (E: in Tuple_Access_Record) return Expr_Type is
   begin
      return A_Tuple_Access;
   end;

   procedure Color_Expr
     (E    : in     Tuple_Access_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
   begin
      State := Coloring_Success;
   end;

   function Possible_Colors
     (E: in Tuple_Access_Record;
      Cs: in Cls_Set) return Cls_Set is
      Tc    : constant Product_Cls := Product_Cls(Get_Cls(E.T));
      Result: constant Cls_Set := New_Cls_Set;
   begin
      Insert(Result, Ith(Get_Dom(Tc), E.Comp));
      return Result;
   end;

   function Is_Static
     (E: in Tuple_Access_Record) return Boolean is
   begin
      return False;
   end;

   function Is_Basic
     (E: in Tuple_Access_Record) return Boolean is
   begin
      return True;
   end;

   function Get_True_Cls
     (E: in Tuple_Access_Record) return Cls is
   begin
      return Ith(Get_Dom(Product_Cls(Get_Cls(E.T))), E.Comp);
   end;

   function Can_Overflow
     (E: in Tuple_Access_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Tuple_Access_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
   begin
      pragma Assert(False);
      Result := null;
      State := Evaluation_Failure;
   end;

   function Static_Equal
     (Left: in Tuple_Access_Record;
      Right: in Tuple_Access_Record) return Boolean is
   begin
      return Left.T = Right.T and Left.Comp = Right.Comp;
   end;

   function Compare
     (Left: in Tuple_Access_Record;
      Right: in Tuple_Access_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function Vars_In
     (E: in Tuple_Access_Record) return Var_List is
   begin
      return Vars_In(E.T);
   end;

   procedure Get_Sub_Exprs
     (E: in Tuple_Access_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.T, R);
   end;

   procedure Get_Observed_Places
     (E     : in     Tuple_Access_Record;
      Places: in out String_Set) is
   begin
      null;
   end;

   function To_Helena
     (E: in Tuple_Access_Record) return Ustring is
      Result: constant Ustring := To_Helena(E.T) & "->" & E.Comp;
   begin
      return Result;
   end;

   function Compile_Evaluation
     (E: in Tuple_Access_Record;
      M: in Var_Mapping) return Ustring is
      Result: constant Ustring :=
        Compile_Evaluation(E.T.all, M) & "." & Dom_Ith_Comp_Name(E.Comp);
   begin
      return Result;
   end;

   function Replace_Var
     (E: in Tuple_Access_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: Expr;
   begin
      Result := New_Tuple_Access(Replace_Var(E.T, V, Ne), E.Comp, E.C);
      return Result;
   end;

end Pn.Exprs.Tuple_Accesses;
