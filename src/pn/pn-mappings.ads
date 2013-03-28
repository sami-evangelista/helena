--=============================================================================
--
--  Package: Pn.Mappings
--
--  This library contains the color mappings definition for the class
--  of high level supported by Helena.  A color mapping is an
--  expression that labels the arcs of the net and which specifies for
--  a given instantiation of the variables of the corresponding
--  transition which tokens are removed or added to a place.  In
--  Helena, color mappings are linear combinations of simpler ones
--  called tuples.  Tuples are list of expressions possibly preceded
--  by a guard.  If this guard holds for the instantiation of the
--  variables, the tokens are normally produced, else the tuple does
--  not produce any token.  Tuples can also be preceded by iteration
--  variables.
--
--  Examples:
--
--  > 2 * <(v, 4)>
--  is a tuple. Its list of expression is (v, 4)
--
--  > if(x > 2) 3 * <(true, x)>
--  is a tuple which produces three tokens <(true, x)> at the condition that
--  x > 2.  If this condition does not hold the tuple does not produce any
--  token.  (x > 2) is the guard of the tuple.
--
--  > for(b in bool, c in bool) if(b != c) <(b, c)> is equivalent to
--  <(false, true)> + <(true, false)>.  Iteration variables of the
--  tuple are b and c.
--
--  > 2*<(v, 4)> + if(x > 2) 3*<(true, x)>
--  is an example of color mapping.
--
--  Properties of color mappings:
--  Some reduction techniques rely on a static analysis of the model.  To this
--  end we use some properties of color mappings.  Common properties are listed
--  below.
--  o a color mapping is *unitary* if it cannot produce several occurences of
--    the same token.
--  o a color mapping is *token-unitary* if it cannot produce several distinct
--    tokens
--  o a color mapping is *total* if it cannot produce an empty bag
--  o a color mapping is *surjective* if it can produce all the possible tokens
--    of its co-domain
--  o a color mapping is *injective* if the same token cannot be produced by
--    two different instantiations
--
--=============================================================================


with
  Generic_Array,
  Pn.Guards,
  Pn.Ranges;

use
  Pn.Guards,
  Pn.Ranges;

package Pn.Mappings is

   type Tuple is private;

   type Mapping is private;

   type Tuple_Array is array(Positive range <>) of Tuple;

   type Tuple_Scheduling is private;


   --==========================================================================
   --  Group: Tuple
   --==========================================================================

   function New_Tuple
     (E     : in Expr_List;
      Vars  : in Var_List;
      Factor: in Mult_Type;
      G     : in Guard) return Tuple;

   procedure Free
     (T: in out Tuple);

   function Copy
     (T: in Tuple) return Tuple;

   function Size
     (T: in Tuple) return Count_Type;

   function Ith
     (T: in Tuple;
      I: in Index_Type) return Expr;

   function Get_Factor
     (T: in Tuple) return Mult_Type;

   procedure Set_Factor
     (T     : in Tuple;
      Factor: in Mult_Type);

   function Get_Expr_List
     (T: in Tuple) return Expr_List;

   procedure Set_Expr_List
     (T: in Tuple;
      E: in Expr_List);

   function Get_Guard
     (T: in Tuple) return Guard;

   procedure Set_Guard
     (T: in Tuple;
      G: in Guard);

   function Get_Iter_Vars
     (T: in Tuple) return Var_List;

   procedure Set_Iter_Vars
     (T   : in Tuple;
      Vars: in Var_List);

   procedure Append
     (T: in Tuple;
      E: in Expr);

   procedure Delete_Last
     (T: in Tuple;
      N: in Count_Type := 1);

   procedure Delete
     (T: in Tuple;
      I: in Index_Type);

   procedure Proj
     (T    : in out Tuple;
      First: in     Index_Type;
      Last: in     Index_Type);

   function Vars_At_Top
     (T: in Tuple) return Var_List;

   function Vars_In
     (T: in Tuple) return Var_List;

   function Needs_To_Unify
     (T: in Tuple) return Var_List;

   function Unified_By
     (T: in Tuple) return Var_List;

   function Is_Unifiable
     (T      : in Tuple;
      Unified: in Var_List) return Boolean;

   procedure Replace_Var
     (T: in Tuple;
      V: in Var;
      E: in Expr);

   procedure Map_Vars
     (T    : in Tuple;
      Vars: in Var_List;
      Nvars: in Var_List);

   function Is_Unitary
     (T: in Tuple) return Boolean;

   function Is_Projection
     (T: in Tuple) return Boolean;

   function Is_Injective
     (T: in Tuple;
      V: in Var_List) return Boolean;

   function Is_Surjective
     (T: in Tuple) return Boolean;

   function Is_Token_Unitary
     (T: in Tuple) return Boolean;

   function Is_Total
     (T: in Tuple) return Boolean;

   function Static_Equal
     (T1: in Tuple;
      T2: in Tuple) return Boolean;

   generic
      with procedure Apply
        (T      : in Tuple;
         First  : in Card_Type;
         Last   : in Card_Type;
         Current: in Card_Type);
   --=====
   --  Generic procedure: Generic_Unfold
   --  Unfold the iteration variables of tuple T and apply procedure Apply on
   --  each tuple which results from this unfolding.
   --
   --  Generic parameters:
   --  > procedure Apply
   --  >   (T      : in Tuple;
   --  >    First  : in Card_Type;
   --  >    Last   : in Card_Type;
   --  >    Current: in Card_Type);
   --  the procedure called on each unfolded tuple.  First, Last, and Current
   --  are the numbers of the first unfolded tuple, last unfolded tuple and the
   --  number of the current tuple.
   --
   --  Example:
   --  If the tuple is
   --  > for(b in bool, i in int range 1..3) <(b, i)>
   --  it will call procedure Apply with the following parameters:
   --  > <(false, 1)>, 1, 6, 1
   --  > <(false, 2)>, 1, 6, 2
   --  > <(false, 3)>, 1, 6, 3
   --  > <(true,  1)>, 1, 6, 4
   --  > <(true,  2)>, 1, 6, 5
   --  > <(true,  3)>, 1, 6, 6
   --=====
   procedure Generic_Unfold
     (T: in Tuple);

   generic
      with procedure Apply
        (T      : in Tuple;
         First  : in Card_Type;
         Last   : in Card_Type;
         Current: in Card_Type);
      with procedure On_Expr_Before
        (Ex: in Expr;
         Pos: in Index_Type);
      with procedure On_Expr_After
        (Ex: in Expr;
         Pos: in Index_Type);
      with procedure On_Guard_Before
        (G: in Guard);
      with procedure On_Guard_After
        (G: in Guard);
   --=====
   --  Generic procedure: Generic_Unfold_And_Handle
   --  Same as the previous one but also call procedures On_Expr_Before each
   --  time an expression in the tuple becomes evaluable and On_Expr_After
   --  each time an expression is no more evaluable.  Similar procedures are
   --  provided for the guard of the tuple.  An expression becomes evaluable if
   --  all the variables which appear in it are iteration variables of the
   --  tuple and these have been unfolded.
   --
   --  Generic parameters:
   --  > procedure Apply
   --  >   (T      : in Tuple;
   --  >    First  : in Card_Type;
   --  >    Last   : in Card_Type;
   --  >    Current: in Card_Type);
   --  the procedure called on each unfolded tuple
   --
   --  > procedure On_Expr_Before
   --  >   (Ex: in Expr;
   --  >    Pos: in Index_Type);
   --  the procedure called each time expression Ex becomes evaluable
   --
   --  > procedure On_Expr_After
   --  >   (Ex: in Expr;
   --  >    Pos: in Index_Type);
   --  the procedure called each time expression Ex is no more evaluable
   --
   --  > procedure On_Guard_Before
   --  >   (G: in Guard);
   --  the procedure called each time guard G becomes evaluable
   --
   --  > procedure On_Guard_After
   --  >   (G: in Guard);
   --  the procedure called each time guard G is no more evaluable
   --=====
   procedure Generic_Unfold_And_Handle
     (T: in Tuple);

   function To_Helena
     (T: in Tuple) return Ustring;



   --==========================================================================
   --  Group: Tuple scheduling
   --==========================================================================

   function New_Tuple_Scheduling return Tuple_Scheduling;

   function Ith
     (S: in Tuple_Scheduling;
      I: in Index_Type) return Tuple;

   function Length
     (S: in Tuple_Scheduling) return Count_Type;

   function Copy
     (S: in Tuple_Scheduling) return Tuple_Scheduling;

   procedure Free
     (S: in out Tuple_Scheduling);

   function Contains
     (S: in Tuple_Scheduling;
      T: in Tuple) return Boolean;

   procedure Append
     (S: in Tuple_Scheduling;
      T: in Tuple);

   procedure Delete_Last
     (S: in Tuple_Scheduling);

   function Is_Valid
     (S      : in Tuple_Scheduling;
      Unified: in Var_List) return Boolean;

   function Exist_Valid_Permutation
     (S: in Tuple_Scheduling) return Boolean;

   function To_String
     (S: in Tuple_Scheduling) return Ustring;



   --==========================================================================
   --  Group: Color mapping
   --==========================================================================

   function New_Mapping return Mapping;

   function New_Mapping
     (T: in Tuple_Array) return Mapping;

   function New_Mapping
     (T: in Tuple) return Mapping;

   procedure Free
     (M: in out Mapping);

   function Copy
     (M: in Mapping) return Mapping;

   function Shared_Copy
     (M: in Mapping) return Mapping;

   function Size
     (M: in Mapping) return Count_Type;

   function Ith
     (M: in Mapping;
      I: in Index_Type) return Tuple;

   procedure Add
     (M: in Mapping;
      T: in Tuple);

   procedure Delete_Last_Expr
     (M: in Mapping);

   procedure Delete_Expr
     (M: in Mapping;
      I: in Index_Type);

   function Vars_At_Top
     (M: in Mapping) return Var_List;

   function Vars_In
     (M: in Mapping) return Var_List;

   procedure Replace_Var
     (M: in Mapping;
      V: in Var;
      E: in Expr);

   procedure Map_Vars
     (M    : in Mapping;
      Vars : in Var_List;
      Nvars: in Var_List);

   function Is_Empty
     (M: in Mapping) return Boolean;

   function Is_Unitary
     (M: in Mapping) return Boolean;

   function Is_Projection
     (M: in Mapping) return Boolean;

   function Is_Injective
     (M: in Mapping;
      V: in Var_List) return Boolean;

   function Is_Surjective
     (M: in Mapping) return Boolean;

   function Is_Token_Unitary
     (M: in Mapping) return Boolean;

   function Is_Total
     (M: in Mapping) return Boolean;

   function Get_Max_Mult
     (M: in Mapping) return Mult_Type;

   function Static_Equal
     (M1: in Mapping;
      M2: in Mapping) return Boolean;

   function To_Helena
     (M: in Mapping) return Ustring;

   function To_Pnml
     (M: in Mapping) return Ustring;

   Null_Mapping: constant Mapping;


private


   --==========================================================================
   --  Tuple
   --==========================================================================

   type Tuple_Record is
      record
         E     : Expr_List;  --  expression list of the tuple
         Vars  : Var_List;   --  variables of the iteration
         Factor: Mult_Type;  --  factor of the tuple
         G     : Guard;      --  guard of the tuple
      end record;
   type Tuple is access all Tuple_Record;



   --==========================================================================
   --  Tuple scheduling
   --==========================================================================

   package Tuple_Array_Pkg is new Generic_Array(Tuple, null, "=");

   type Tuple_Scheduling_Record is
      record
         Tuples: Tuple_Array_Pkg.Array_Type;  --  the tuples
      end record;
   type Tuple_Scheduling is access all Tuple_Scheduling_Record;



   --==========================================================================
   --  Color mapping
   --==========================================================================

   type Mapping_Record is
      record
         Tuples: Tuple_Array_Pkg.Array_Type;  --  the tuples
         Ref   : Natural;                     --  reference counter
      end record;
   type Mapping is access all Mapping_Record;

   Null_Mapping: constant Mapping := null;

end Pn.Mappings;
