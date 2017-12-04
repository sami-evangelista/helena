--=============================================================================
--
--  Packag: Pn.Guards
--
--  This package implements guards.  A guard is a boolean condition
--  which can be associated to a transition (resp. a tuple) and which
--  states under which conditions the transition is firable (resp. the
--  tuple produces tokens).  Assertions are special guards which cause
--  the interruption of the search whenever they do not hold.
--
--=============================================================================


package Pn.Guards is

   type Guard is private;

   subtype Assert is Guard;


   function New_Guard
     (Pred: in Expr) return Guard;

   procedure Free
     (G: in out Guard);

   function Copy
     (G: in Guard) return Guard;

   function Get_Expr
     (G: in Guard) return Expr;

   function Vars_In
     (G: in Guard) return Var_List;

   function To_Helena
     (G: in Guard) return Ustring;

   function Compile_Evaluation
     (G: in Guard) return Ustring;

   function Compile_Evaluation
     (G: in Guard;
      M: in Var_Mapping) return Ustring;

   function Is_Checkable
     (G   : in Guard;
      Vars: in Var_List) return Boolean;

   procedure Replace_Var
     (G : in out Guard;
      V : in     Var;
      Ne: in     Expr);

   procedure Map_Vars
     (G    : in out Guard;
      Vars : in     Var_List;
      Nvars: in     Var_List);

   procedure Evaluate
     (G     : in     Guard;
      B     : in     Binding;
      Result:    out Boolean;
      State :    out Evaluation_State);

   function Is_Static
     (G: in Guard) return Boolean;

   function Is_Tautology
     (G: in Guard) return Boolean;

   function Is_Contradiction
     (G: in Guard) return Boolean;

   True_Guard: constant Guard;


private


   type Guard is new Pn.Expr;

   True_Guard: constant Guard := null;

end Pn.Guards;
