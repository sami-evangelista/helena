--=============================================================================
--
--  Package: Pn.Nodes.Transitions
--
--  This library implements all the transition features.  Transitions can have
--  the following attributes:
--  o *a guard* is a boolean expression which indicates under which condition
--    the transition firable. If the guard does not hold the transition cannot
--    be fired
--  o *safe* attribute. If a transition is safe, then once it is enabled it can
--    not be disabled by the firing of another transition.  This information is
--    used by partial order reduction.
--  o *visible* attribute.  A visible transition is a transition which can
--    change the validity of the property verified.
--  o *priority* attribute.  It is an expression evaluable on the current
--    marking that gives the priority of a firable transition.
--
--=============================================================================


with
  Generic_Array,
  Pn.Guards,
  Pn.Nodes.Places;

use
  Pn.Guards,
  Pn.Nodes.Places;

package Pn.Nodes.Transitions is

   type Trans_Record is new Node_Record with private;

   type Trans is access all Trans_Record;

   type Trans_Array is array(Positive range <>) of Trans;

   type Trans_Vector is private;

   type Trans_Desc is private;

   Null_Trans: constant Trans := null;

   subtype Priority is Expr;



   --==========================================================================
   --  Group: Transition
   --==========================================================================

   function New_Trans
     (Name      : in Ustring;
      Vars      : in Var_List;
      Ivars     : in Var_List;
      Lvars     : in Var_List;
      G         : in Guard;
      P         : in Priority;
      Visible   : in Fuzzy_Boolean;
      Safe      : in Fuzzy_Boolean;
      Desc      : in Trans_Desc) return Trans;

   procedure Free
     (T: in out Trans);

   function Get_Vars
     (T: in Trans) return Var_List;

   function Get_Ivars
     (T: in Trans) return Var_List;

   function Get_Lvars
     (T: in Trans) return Var_List;

   procedure Set_Vars
     (T   : in Trans;
      Vars: in Var_List);

   procedure Add_Var
     (T: in Trans;
      V: in Var);

   procedure Delete_Var
     (T: in Trans;
      V: in Var);

   procedure Replace_Var
     (T  : in Trans;
      V  : in Var;
      E  : in Expr;
      Del: in Boolean);

   procedure Map_Vars
     (T    : in Trans;
      V_Old: in Var_List;
      V_New: in Var_List);

   function Get_Var_Index
     (T: in Trans;
      V: in Var) return Index_Type;

   function Get_Var_Index
     (T: in Trans;
      V: in Ustring) return Index_Type;

   function Is_Var
     (T: in Trans;
      V: in Var) return Boolean;

   function Is_Var
     (T: in Trans;
      V: in Ustring) return Boolean;

   function Get_Var
     (T: in Trans;
      V: in Ustring) return Var;

   function Get_Guard
     (T: in Trans) return Guard;

   procedure Set_Guard
     (T: in Trans;
      G: in Guard);

   function Is_Safe
     (T: in Trans) return Boolean;

   function Get_Safe
     (T: in Trans) return Fuzzy_Boolean;

   procedure Set_Safe
     (T   : in Trans;
      Safe: in Fuzzy_Boolean);

   function Is_Visible
     (T: in Trans) return Boolean;

   function Get_Visible
     (T: in Trans) return Fuzzy_Boolean;

   procedure Set_Visible
     (T      : in Trans;
      Visible: in Fuzzy_Boolean);

   function Get_Priority
     (T: in Trans) return Priority;

   procedure Set_Priority
     (T: in Trans;
      P: in Priority);

   function Get_Safe_Set
     (T: in Trans) return Natural;

   procedure Set_Safe_Set
     (T  : in Trans;
      Set: in Natural);

   function Ith_Binding
     (T: in Trans;
      I: in Card_Type) return Binding;

   function Has_Desc
     (T : in Trans) return Boolean;

   function Get_Desc
     (T : in Trans) return Ustring;

   function Get_Desc_Exprs
     (T : in Trans) return Expr_List;



   --==========================================================================
   --  Group: Transition descriptor
   --==========================================================================

   function New_Trans_Desc
     (Desc      : in Ustring;
      Desc_Exprs: in Expr_List) return Trans_Desc;

   function New_Empty_Trans_Desc return Trans_Desc;



   --==========================================================================
   --  Group: Transition vector
   --==========================================================================

   function New_Trans_Vector return Trans_Vector;

   function New_Trans_Vector
     (T: in Trans_Array) return Trans_Vector;

   procedure Free
     (T: in out Trans_Vector);

   procedure Free_All
     (T: in out Trans_Vector);

   function Size
     (T: in Trans_Vector) return Count_Type;

   function Is_Empty
     (T: in Trans_Vector) return Boolean;

   function Get
     (T: in Trans_Vector;
      Tr: in Ustring) return Trans;

   function Get_Index
     (T: in Trans_Vector;
      Tr: in Trans) return Index_Type;

   procedure Append
     (T: in Trans_Vector;
      Tr: in Trans);

   procedure Delete
     (T: in Trans_Vector;
      Tr: in Trans);

   function Ith
     (T: in Trans_Vector;
      I: in Index_Type) return Trans;

   function Contains
     (T: in Trans_Vector;
      Tr: in Trans) return Boolean;

   function Contains
     (T: in Trans_Vector;
      Tr: in Ustring) return Boolean;

   function Intersect
     (T1: in Trans_Vector;
      T2: in Trans_Vector) return Trans_Vector;

   procedure Difference
     (T1: in Trans_Vector;
      T2: in Trans_Vector);

   No_Priority: constant Priority;


private


   --==========================================================================
   --  Transition
   --==========================================================================

   type Trans_Record is new Node_Record with
      record
         Vars      : Var_List;       --  its variables
         Ivars     : Var_List;       --  its inhibitor variables
	 Lvars     : Var_List;       --  its let variables
         G         : Guard;          --  its guard
	 P         : Priority;       --  priority of the transition
         Safe      : Fuzzy_Boolean;  --  statically safe
         Visible   : Fuzzy_Boolean;  --  visibility of the transition
	 Safe_Set  : Natural;
	 Desc      : Trans_Desc;
      end record;

   No_Priority: constant Priority := null;



   --==========================================================================
   --  Transition description
   --==========================================================================

   type Trans_Desc is
      record
         Has_Desc  : Boolean;
	 Desc      : Ustring;
	 Desc_Exprs: Expr_List;
      end record;



   --==========================================================================
   --  Transition vector
   --==========================================================================

   package Trans_Array_Pkg is
      new Generic_Array(Trans, Null_Trans, "=");

   type Trans_Vector_Record is
      record
         Trans: Trans_Array_Pkg.Array_Type;  --  the transitions
      end record;
   type Trans_Vector is access all Trans_Vector_Record;


end Pn.Nodes.Transitions;
