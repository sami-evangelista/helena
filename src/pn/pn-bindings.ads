--=============================================================================
--
--  Package: Pn.Bindings
--
--  This library defines the transition binding type and the
--  transition binding sequence type.  In colored Petri nets,
--  transitions can be fired in multiple ways, i.e., instantiated
--  according to the variables of the transition.
--
--  o A variable binding (type <Pn.Var_Binding>) is a couple
--    (variable, value of the variable).
--  o A binding (type <Pn.Binding>) is a set of variable bindings.
--
--  Because of some visibility constraints type types <Var_Binding> and
--  <Binding> are defined in package <Pn>.  This should be changed with Ada 05.
--
--=============================================================================


with
  Generic_Array,
  Pn.Exprs,
  Pn.Nodes.Transitions;

use
  Pn.Exprs,
  Pn.Nodes.Transitions;

package Pn.Bindings is

   --==========================================================================
   --  Group: Variable binding
   --==========================================================================

   function New_Var_Binding
     (V: in Var;
      E: in Expr) return Var_Binding;

   function New_Var_Binding
     (V: in Ustring;
      E: in Expr) return Var_Binding;

   procedure Free
     (V: in out Var_Binding);

   function Get_Expr
     (V: in Var_Binding) return Expr;

   function Get_Var
     (V: in Var_Binding) return Var;

   function To_String
     (V: in Var_Binding) return Ustring;



   --==========================================================================
   --  Group: Binding
   --==========================================================================

   function New_Binding return Binding;

   procedure Free
     (B: in out Binding);

   function Copy
     (B: in Binding) return Binding;

   function Is_Empty
     (B: in Binding) return Boolean;

   function Is_Bound
     (B: in Binding;
      V: in Var) return Boolean;

   function Is_Bound
     (B: in Binding;
      V: in Ustring) return Boolean;

   procedure Bind_Var
     (B: in Binding;
      V: in Var;
      E: in Expr);

   procedure Bind_Var
     (B: in Binding;
      V: in Ustring;
      E: in Expr);

   procedure Unbind_Var
     (B: in Binding;
      V: in Var);

   function Get_Var_Binding
     (B: in Binding;
      V: in Var) return Expr;

   function Get_Var_Binding
     (B: in Binding;
      V: in Ustring) return Expr;

   function To_String
     (B: in Binding) return Ustring;

end Pn.Bindings;
