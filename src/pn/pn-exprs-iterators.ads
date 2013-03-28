--=============================================================================
--
--  Package: Pn.Exprs.Iterators
--
--  This package implements iteration expressions.  There are different kinds
--  of iterators:
--  o *forall*: checks that a condition is fulfilled for all the iterations
--  o *exists*: checks that a condition is fulfulled for at least one
--                iteration
--  o *card*   : counts the number of iterations that fulfill a condition
--  o *mult*   : counts the cumulated multiplicities of all the tokens in a
--                place which fulfill a given condition
--  o *sum*    : compute a sum
--  o *product*: compute a product
--  o *max*    : compute a maximal value
--  o *min*    : compute a minimal value
--
--  Some examples:
--  >  forall(p in my_place | p->2 = 0: p->1 > 2)
--  check that all the tokens in my_place which are such that their first
--  component is 0 have their first component greater than 2
--  >  max(p in my_place: p->1)
--  on all the tokens p in my_place get the highest value of the first
--  component
--  >  sum(p in my_place | exists(q in my_other_place | p = q): p->1)
--  calculates the sum of the first components of all the tokens p in
--  my_place such that p is also present in my_other_place
--
--=============================================================================


package Pn.Exprs.Iterators is

   --=====
   --  Type: Iterator_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Iterator_Record is new Expr_Record with private;

   --=====
   --  Type: Iterator
   --=====
   type Iterator is access all Iterator_Record;


   --=====
   --  Type: Iterator_Type
   --  type of an iterator
   --=====
   type Iterator_Type is
     (A_Forall,
      A_Exists,
      A_Card,
      A_Mult,
      A_Sum,
      A_Product,
      A_Max,
      A_Min);


   --=====
   --  Function: New_Iterator
   --  Iterator constructor.
   --
   --  Parameters:
   --  V    - iteration variable list of the iterator
   --  Iv   - iteration variable list inherited from iterators enclosing this
   --         one
   --  T    - type of the iterator
   --  Cond - condition that must fulfill the iteration variables for the
   --         expression to be evaluated
   --  E    - expression computed
   --  C    - color class of the expression constructed
   --=====
   function New_Iterator
     (V   : in Var_List;
      Iv  : in Var_List;
      T   : in Iterator_Type;
      Cond: in Expr;
      E   : in Expr;
      C   : in Cls) return Expr;


private


   type Iterator_Record is new Expr_Record with
      record
         V   : Var_List;       --  iteration variables of the iterator
         Iv  : Var_List;       --  iteration variables inherited from other
			       --  iterators that enclose this one
         T   : Iterator_Type;  --  type of the iterator
         Cond: Expr;           --  condition of the iterator
         E   : Expr;           --  expression of the iterator
      end record;

   procedure Free
     (E: in out Iterator_Record);

   function Copy
     (E: in Iterator_Record) return Expr;

   function Get_Type
     (E: in Iterator_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Iterator_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E : in Iterator_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Iterator_Record) return Boolean;

   function Is_Basic
     (E: in Iterator_Record) return Boolean;

   function Get_True_Cls
     (E: in Iterator_Record) return Cls;

   function Can_Overflow
     (E: in Iterator_Record) return Boolean;

   procedure Evaluate
     (E     : in     Iterator_Record;
      B     : in     Binding;
      Result:    out Expr;
      State :    out Evaluation_State);

   function Static_Equal
     (Left : in Iterator_Record;
      Right: in Iterator_Record) return Boolean;

   function Compare
     (Left : in Iterator_Record;
      Right: in Iterator_Record) return Comparison_Result;

   function Vars_In
     (E: in Iterator_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Iterator_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Iterator_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Iterator_Record) return Ustring;

   function Compile_Evaluation
     (E: in Iterator_Record;
      M: in Var_Mapping) return Ustring;

   procedure Compile_Definition
     (E  : in Iterator_Record;
      R  : in Var_Mapping;
      Lib: in Library);

   function Replace_Var
     (E : in Iterator_Record;
      V : in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Iterators;
