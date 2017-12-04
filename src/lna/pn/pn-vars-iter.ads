--=============================================================================
--
--  Package: Pn.Vars.Iter
--
--  This library implements iteration variables. Iteration variables
--  are those placed in a for statement, e.g., for(i in integer range
--  1..10), in an iterator expression, e.g., forall(token in
--  my_place), or before a tuple, e.g., for(b in boolean) <(b)>.
--
--  There are different kind of iteration variables:
--  o *place* iteration variables.  Those iterate on all the tokens present in
--    a place.
--  o *container* iteration variables.  Those iterate on all the items
--    of a container.
--  o *discrete* iteration variables.  Those iterate on all the values of a
--    discrete class.  A range may be specified to limit the iteration to some
--    values of the class.
--
--=============================================================================


with
  Generic_Array,
  Pn.Exprs,
  Pn.Nodes.Places,
  Pn.Ranges;

use
  Pn.Exprs,
  Pn.Nodes.Places,
  Pn.Ranges;

package Pn.Vars.Iter is

   type Iter_Var_Record is new Var_Record with private;

   type Iter_Var is access all Iter_Var_Record'Class;

   type Iter_Var_Dom is private;

   subtype Iter_Scheme is Var_List;


   --==========================================================================
   --  Group: Iteration variable domain
   --==========================================================================

   function New_Iter_Var_Place_Dom
     (P: in Place) return Iter_Var_Dom;

   function New_Iter_Var_Discrete_Cls_Dom
     (R: in Range_Spec) return Iter_Var_Dom;

   function New_Iter_Var_Container_Dom
     (Cont: in Expr) return Iter_Var_Dom;

   function Vars_In
     (Dom: in Iter_Var_Dom) return Var_List;



   --==========================================================================
   --  Group: Iteration variable
   --==========================================================================

   function New_Iter_Var
     (Name: in Ustring;
      C   : in Cls;
      Dom : in Iter_Var_Dom) return Var;

   function Static_Enum_Values
     (I: in Iter_Var) return Expr_List;

   procedure Enum_Values
     (I     : in     Iter_Var;
      B     : in     Binding;
      Result:    out Expr_List;
      State :    out Evaluation_State);

   function Static_Nb_Iterations
     (I: in Iter_Var) return Card_Type;

   function Nb_Iterations
     (I: in Iter_Var;
      B: in Binding) return Card_Type;

   procedure Compile_Initialization
     (I   : in Iter_Var;
      Tabs: in Natural;
      Lib : in Library);

   procedure Compile_Initialization
     (I   : in Iter_Var;
      Map : in Var_Mapping;
      Tabs: in Natural;
      Lib : in Library);

   procedure Compile_Iteration
     (I   : in Iter_Var;
      Tabs: in Natural;
      Lib : in Library);

   function Compile_Start_Iteration_Check
     (I: in Iter_Var) return Ustring;

   function Compile_Is_Last_Check
     (I: in Iter_Var) return Ustring;

   function Get_Iter_Var_Dom
     (I: in Iter_Var) return Iter_Var_Dom;

   function Get_Dom_Place
     (I: in Iter_Var) return Place;

   function Get_Dom_Range
     (I: in Iter_Var) return Range_Spec;



   --==========================================================================
   --  Group: Iteration variable list
   --==========================================================================

   function Static_Nb_Iterations
     (S: in Iter_Scheme) return Card_Type;



private


   --==========================================================================
   --  Domain of an iteration variable
   --==========================================================================

   No_Range: constant Range_Spec := null;

   type Iter_Var_Dom_Kind is
     (A_Place_Iterator,
      A_Container_Iterator,
      A_Discrete_Cls_Iterator);

   type Iter_Var_Dom_Record(K: Iter_Var_Dom_Kind) is
      record
         case K is
            when A_Place_Iterator        => P   : Place;
            when A_Container_Iterator    => Cont: Expr;
            when A_Discrete_Cls_Iterator => R   : Range_Spec;
         end case;
      end record;

   type Iter_Var_Dom is access all Iter_Var_Dom_Record;


   --==========================================================================
   --  Iteration variable
   --==========================================================================

   type Iter_Var_Record is new Var_Record with
      record
         Dom: Iter_Var_Dom;
      end record;

   procedure Free
     (V: in out Iter_Var_Record);

   function Copy
     (V: in Iter_Var_Record) return Var;

   function Is_Static
     (V: in Iter_Var_Record) return Boolean;

   function Is_Const
     (V: in Iter_Var_Record) return Boolean;

   function Get_Init
     (V: in Iter_Var_Record) return Expr;

   function Get_Type
     (V: in Iter_Var_Record) return Var_Type;

   procedure Replace_Var_In_Def
     (V: in out Iter_Var_Record;
      R: in     Var;
      E: in     Expr);

   function To_Helena
     (V: in Iter_Var_Record) return Ustring;

   procedure Compile_Definition
     (V   : in Iter_Var_Record;
      Tabs: in Natural;
      File: in File_Type);

   function Compile_Access
     (V: in Iter_Var_Record) return Ustring;

end Pn.Vars.Iter;
