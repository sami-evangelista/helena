--=============================================================================
--
--  Package: Pn.Nodes.Places
--
--  This library implements all the features related to places.
--  A place of our colored nets is described by the following elements:
--
--  o a *name*.
--
--  o a *capacity* of type <Pn.Mult_Type>.
--  The capacity of a place is the maximum number of times an item can appear
--  in the place.
--  For instance, a capacity of 1 indicates that the place is safe: it cannot
--  contain several instances of the same item.
--
--  o a *color domain* of type <Pn.Dom>.
--
--  o an *initial marking* of type <Pn.Mappings.Mapping>.
--
--  o a *type* of type <Place_Type>.
--  The type of a place indicates which kind of informations the place models.
--  It is used in several reduction algorithms of Helena, e.g., partial order
--  reductions.
--
--  Typing places:
--  The possible types (type <Place_Type>) that can be given to a
--  type are the following:
--  o *process* place: a place that models the control of a process
--  o *local* place: a place that models a ressource which can only be
--    accessed by a single process, e.g., a local variable
--  o *shared* place: a place that models a ressource which can be accessed
--    concurrently by several process, e.g., a lock
--  o *buffer* place: a buffer place is a shared place which models a
--    communication buffer between process. consequently only one process can
--    remove tokens from this place
--  o *ack* place: an ack place is a buffer place which models an
--    acknowledgment
--  o *protected* place: a protected place is a shared place which modification
--    can only be in mutual exclusion, e.g. variables of a protected object
--  o undefined place
--
--=============================================================================


with
  Generic_Array;

package Pn.Nodes.Places is

   type Place_Record is new Node_Record with private;

   type Place is access all Place_Record'Class;

   type Place_Vector is private;

   type Place_Array is array (Positive range <>) of Place;

   type Place_Type is
     (Process_Place,
      Shared_Place,
      Local_Place,
      Buffer_Place,
      Ack_Place,
      Protected_Place,
      Undefined_Place);

   Null_Place: constant Place;



   --==========================================================================
   --  Group: Place
   --==========================================================================

   function New_Place
     (Name    : in Ustring;
      D       : in Dom;
      T       : in Place_Type;
      M0      : in Mapping;
      Capacity: in Mult_Type) return Place;

   procedure Free
     (P: in out Place);

   function Get_Capacity
     (P: in Place) return Mult_Type;

   procedure Set_Capacity
     (P       : in Place;
      Capacity: in Mult_Type);

   function Get_Type
     (P: in Place) return Place_Type;

   procedure Set_Type
     (P: in Place;
      T: in Place_Type);

   function Is_Marked
     (P: in Place) return Boolean;

   function Is_Safe
     (P: in Place) return Boolean;

   function Get_M0
     (P: in Place) return Mapping;

   procedure Set_M0
     (P : in Place;
      M0: in Mapping);

   procedure Add_M0
     (P: in Place;
      T: in Tuple);



   --==========================================================================
   --  Group: Place vector
   --==========================================================================

   function New_Place_Vector return Place_Vector;

   function New_Place_Vector
     (P: in Place_Array) return Place_Vector;

   procedure Free
     (P: in out Place_Vector);

   procedure Free_All
     (P: in out Place_Vector);

   function Is_Empty
     (P: in Place_Vector) return Boolean;

   function Size
     (P: in Place_Vector) return Count_Type;

   function Get
     (P : in Place_Vector;
      Pl: in Ustring) return Place;

   function Get_Index
     (P : in Place_Vector;
      Pl: in Place) return Extended_Index_Type;

   procedure Append
     (P : in Place_Vector;
      Pl: in Place);

   procedure Delete
     (P : in Place_Vector;
      Pl: in Place);

   function Ith
     (P: in Place_Vector;
      I: in Index_Type) return Place;

   function Contains
     (P : in Place_Vector;
      Pl: in Place) return Boolean;

   function Contains
     (P : in Place_Vector;
      Pl: in Ustring) return Boolean;

   function Intersect
     (P1: in Place_Vector;
      P2: in Place_Vector) return Place_Vector;

   generic
      with function Predicate(P: in Place) return Boolean;
   procedure Generic_Delete_Places
     (P: in Place_Vector);


private


   type Place_Record is new Node_Record with
      record
         T  : Place_Type;
         M0 : Pn.Mappings.Mapping;
         Cap: Mult_Type;
      end record;

   Null_Place: constant Place := null;

   package Place_Array_Pkg is new Generic_Array(Place, Null_Place, "=");

   type Place_Vector_Record is
      record
         Places: Place_Array_Pkg.Array_Type;
      end record;
   type Place_Vector is access all Place_Vector_Record;

end Pn.Nodes.Places;
