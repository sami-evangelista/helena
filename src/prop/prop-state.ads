--=============================================================================
--
--  Package: Prop.State
--
--  This package implements state properties.  State properties are
--  properties that must be verified in each state, in constrast to,
--  for example, LTL properties which must hold on sequences.  State
--  properties that can be verified by Helena are: o deadlock freeness
--  o predicate on the contents of the places
--
--  A state property is composed of a reject part and a list (potentially
--  empty) of accept clause.
--  o The reject part specifies which property must not be verified by the
--    state.
--  o Accept clauses are used to limit the rejection of states.  If the reject
--    property is verified by a state but an accept clause is evaluated at true
--    for this state then the state is not rejected.
--
--  The reject part and the accept clauses are state property
--  components.  Each component is either the deadlock either a
--  predicate on the content of the places.
--
--=============================================================================


with
  Generic_Array;

package Prop.State is

   type State_Property_Record is new Property_Record with private;

   type State_Property is access all State_Property_Record'Class;

   type State_Property_Comp is private;

   type State_Property_Comp_List is private;


   --==========================================================================
   --  Group: State property
   --==========================================================================

   function New_State_Property
     (Name   : in Ustring;
      Reject : in State_Property_Comp;
      Accepts: in State_Property_Comp_List) return Property;



   --==========================================================================
   --  Group: Component of a state property
   --==========================================================================

   function New_Deadlock return State_Property_Comp;

   function New_Predicate
     (Prop: in Ustring) return State_Property_Comp;

   function Compile_Evaluation
     (C: in State_Property_Comp) return Ustring;



   --==========================================================================
   --  Group: Component list
   --==========================================================================

   function New_State_Property_Comp_List return State_Property_Comp_List;

   function Length
     (L: in State_Property_Comp_List) return Natural;

   function Ith
     (L: in State_Property_Comp_List;
      I: in Natural) return State_Property_Comp;

   procedure Append
     (L: in State_Property_Comp_List;
      C: in State_Property_Comp);


private


   --==========================================================================
   --  State property
   --==========================================================================

   type State_Property_Record is new Property_Record with
      record
         Reject : State_Property_Comp;
         Accepts: State_Property_Comp_List;
      end record;

   function Get_Type
     (P: in State_Property_Record) return Property_Type;

   procedure Compile_Definition
     (P  : in State_Property_Record;
      Lib: in Library;
      Dir: in String);

   function Get_Propositions
     (P: in State_Property_Record) return Ustring_List;



   --==========================================================================
   --  Component of a state property
   --==========================================================================

   type State_Property_Comp_Record is
      record
         Deadlock: Boolean;
	 Prop    : Ustring;
      end record;
   type State_Property_Comp is access all State_Property_Comp_Record;



   --==========================================================================
   --  Component list
   --==========================================================================

   package State_Property_Comp_Array_Pkg is
      new Generic_Array(State_Property_Comp, null, "=");

   type State_Property_Comp_List_Record is
      record
         Comps: State_Property_Comp_Array_Pkg.Array_Type;
      end record;
   type State_Property_Comp_List is
     access all State_Property_Comp_List_Record;

end Prop.State;
