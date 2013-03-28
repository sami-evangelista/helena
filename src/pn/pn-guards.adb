with
  Pn.Exprs,
  Pn.Exprs.Enum_Consts,
  Pn.Classes,
  Pn.Vars;

use
  Pn.Exprs,
  Pn.Exprs.Enum_Consts,
  Pn.Classes,
  Pn.Vars;

package body Pn.Guards is

   function New_Guard
     (Pred: in Expr) return Guard is
      Result: constant Guard := Guard(Pred);
   begin
      return Result;
   end;

   procedure Free
     (G: in out Guard) is
   begin
      if G /= null then
         Free(Expr(G));
      end if;
   end;

   function Copy
     (G: in Guard) return Guard is
   begin
      if G /= null then
         return Guard(Copy(Expr(G)));
      else
         return null;
      end if;
   end;

   function Get_Expr
     (G: in Guard) return Expr is
   begin
      return Expr(G);
   end;

   function Vars_In
     (G: in Guard) return Var_List is
   begin
      if G /= null then
         return Vars_In(Expr(G));
      else
         return New_Var_List;
      end if;
   end;

   function To_Helena
     (G: in Guard) return Ustring is
   begin
      if G /= null then
         return To_Helena(Expr(G));
      else
         return True_Const_Name;
      end if;
   end;

   function To_Pnml
     (G: in Guard) return Ustring is
   begin
      if G /= null then
         return To_Pnml(Expr(G));
      else
         return Null_String;
      end if;
   end;

   function Compile_Evaluation
     (G: in Guard) return Ustring is
   begin
      return Guards.Compile_Evaluation(G, Empty_Var_Mapping);
   end;

   function Compile_Evaluation
     (G: in Guard;
      M: in Var_Mapping) return Ustring is
   begin
      if G /= null then
         return Compile_Evaluation(Expr(G), M);
      else
         return To_Ustring("TRUE");
      end if;
   end;

   function Is_Checkable
     (G   : in Guard;
      Vars: in Var_List) return Boolean is
      Result: Boolean;
      G_Vars: Var_List;
   begin
      G_Vars := Guards.Vars_In(G);
      Result := Included(G_Vars, Vars);
      Free(G_Vars);
      return Result;
   end;

   procedure Replace_Var
     (G: in out Guard;
      V: in     Var;
      Ne: in     Expr) is
   begin
      if G /= null then
         Replace_Var(Expr(G), V, Ne);
      end if;
   end;

   procedure Map_Vars
     (G    : in out Guard;
      Vars: in     Var_List;
      Nvars: in     Var_List) is
   begin
      if G /= null then
         Map_Vars(Expr(G), Vars, Nvars);
      end if;
   end;

   procedure Evaluate
     (G     : in     Guard;
      B     : in     Binding;
      Result:    out Boolean;
      State:    out Evaluation_State) is
      V: Expr;
   begin
      if G = null then
         Result := True;
         State := Evaluation_Success;
      else
         Evaluate(E      => Expr(G),
                  B      => B,
                  Check  => False,
                  Result => V,
                  State  => State);
         if Is_Success(State) then
            pragma Assert(Get_Type(V) = A_Enum_Const);
            Result := Is_True_Const(Enum_Const(V));
            Free(V);
         end if;
      end if;
   end;

   function Is_Static
     (G: in Guard) return Boolean is
   begin
      if G = null then
         return True;
      else
         return Is_Static(Expr(G));
      end if;
   end;

   function Is_Tautology
     (G: in Guard) return Boolean  is
      Result: Boolean;
      V     : Expr;
      State: Evaluation_State;
   begin
      if G = null then
         Result := True;
      elsif Is_Static(Expr(G)) then
         Evaluate_Static(E      => Expr(G),
                         Check  => False,
                         Result => V,
                         State  => State);
         if not Is_Success(State) then
            Result := False;
         else
            pragma Assert(Get_Type(V) = A_Enum_Const);
            Result := Is_True_Const(Enum_Const(V));
            Free(V);
         end if;
      else
         Result := False;
      end if;
      return Result;
   end;

   function Is_Contradiction
     (G: in Guard) return Boolean is
      Result: Boolean;
      V     : Expr;
      State: Evaluation_State;
   begin
      if G = null then
         Result := False;
      elsif Is_Static(Expr(G)) then
         Evaluate_Static(E      => Expr(G),
                         Check  => False,
                         Result => V,
                         State  => State);
         if not Is_Success(State) then
            Result := False;
         else
            pragma Assert(Get_Type(V) = A_Enum_Const);
            Result := Is_False_Const(Enum_Const(V));
            Free(V);
         end if;
      else
         Result := False;
      end if;
      return Result;
   end;

end Pn.Guards;
