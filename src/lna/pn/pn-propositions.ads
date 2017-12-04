--=============================================================================
--
--  Package: Pn.Propositions
--
--  This is the base package for properties that can be verified by Helena.
--
--=============================================================================


with
  Generic_Array,
  Pn.Exprs,
  Pn.Nodes.Transitions;

use
  Pn.Exprs,
  Pn.Nodes.Transitions;

package Pn.Propositions is

   type State_Proposition_Record is private;

   type State_Proposition is access all State_Proposition_Record;

   type State_Proposition_List is private;


   --==========================================================================
   --  Group: State proposition
   --==========================================================================

   function New_State_Proposition
     (Name: in Ustring;
      Prop: in Expr) return State_Proposition;

   procedure Free
     (P: in out State_Proposition);

   function Get_Name
     (P: in State_Proposition) return Ustring;

   procedure Set_Name
     (P   : in State_Proposition;
      Name: in Ustring);

   function Is_Observed
     (P: in State_Proposition) return Boolean;

   procedure Set_Observed
     (P       : in State_Proposition;
      Observed: in Boolean);

   function Get_Places_In
     (P: in State_Proposition) return String_Set;

   procedure Compile
     (P  : in State_Proposition;
      Lib: in Library);



   --==========================================================================
   --  Group: State proposition list
   --==========================================================================

   function New_State_Proposition_List return State_Proposition_List;

   procedure Free
     (P: in out State_Proposition_List);

   procedure Free_All
     (P: in out State_Proposition_List);

   function Length
     (P: in State_Proposition_List) return Natural;

   function Ith
     (P: in State_Proposition_List;
      I: in Index_Type) return State_Proposition;

   procedure Append
     (P: in State_Proposition_List;
      Q: in State_Proposition);

   function Contains
     (P   : in State_Proposition_List;
      Name: in Ustring) return Boolean;

   function Get
     (P   : in State_Proposition_List;
      Name: in Ustring) return State_Proposition;

   procedure Compile
     (P  : in State_Proposition_List;
      Lib: in Library);


private


   type State_Proposition_Record is
      record
         Name    : Ustring;
	 Prop    : Expr;
	 Observed: Boolean;
      end record;

   package State_Proposition_Array_Pkg is
      new Generic_Array(State_Proposition, null, "=");

   type State_Proposition_List_Record is
      record
         Propositions: State_Proposition_Array_Pkg.Array_Type;
      end record;
   type State_Proposition_List is access all State_Proposition_List_Record;

end Pn.Propositions;
