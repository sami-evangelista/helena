--=============================================================================
--
--  Package: Generic_Set
--
--  A generic set package.
--  The type of the elements in the set is a generic parameter of the package.
--  Elements are accessed by the index type <Index_Type>.
--  The set type <Set_Type> is controlled so that the user does not need to
--  perform explicit deallocation.
--  Many generic operations are provided.
--
--=============================================================================


with
  Ada.Finalization;

use
  Ada.Finalization;

generic

   --==========================================================================
   --  Group: Generic parameters of the package
   --==========================================================================

   --=====
   --  Type: Element_Type
   --  the type of the elements stored in the set
   --=====
   type Element_Type is private;

   --=====
   --  Constant: Null_Element
   --  the null element that will be returned, e.g., when an element is not
   --  found
   --=====
   Null_Element: Element_Type;

   --=====
   --  Function: "="
   --  function used to compare two elements
   --=====
   with function "="(E1: in Element_Type;
                     E2: in Element_Type) return Boolean;
package Generic_Set is

   --==========================================================================
   --  Group: Types, subtypes and constants
   --==========================================================================

   --=====
   --  Type: Set_Type
   --  the set type
   --=====
   type Set_Type is private;

   --=====
   --  Subtype: Card_Type
   --  the cardinal type used to count the elements of a set
   --=====
   subtype Card_Type is Natural;

   --=====
   --  Subtype: Index_Type
   --  the index type used to index the elements of a set
   --=====
   subtype Index_Type is Positive;

   --=====
   --  Subtype: Extended_Index_Type
   --  the index type + the <No_Index> constant
   --=====
   subtype Extended_Index_Type is Natural;

   --=====
   --  Type: Element_Array
   --  an array of elements
   --=====
   type Element_Array is array(Index_Type range <>) of Element_Type;

   --=====
   --  Constant: Empty_Set
   --  the empty set constant, i.e., with no element in it
   --=====
   Empty_Set: constant Set_Type;

   --=====
   --  Constant: No_Index
   --  the no index constant, returned, e.g., by some functions when an element
   --  is not found
   --=====
   No_Index: constant Extended_Index_Type := 0;



   --==========================================================================
   --  Group: Functions
   --==========================================================================

   --=====
   --  Function: New_Set
   --  Set constructor.
   --
   --  Return:
   --  a new set composed of the only element E
   --=====
   function New_Set
     (E: in Element_Type) return Set_Type;

   --=====
   --  Function: New_Set
   --  Set constructor.
   --
   --  Return:
   --  a new set composed of the elements of E
   --=====
   function New_Set
     (E: in Element_Array) return Set_Type;

   --=====
   --  Function: Card
   --  Get the cardinal of set S.
   --
   --  Return:
   --  the cardinal
   --=====
   function Card
     (S: in Set_Type) return Card_Type;

   --=====
   --  Function: Is_Empty
   --  Check if the set S is empty.
   --
   --  Return:
   --  True if the set is empty, False otherwise
   --=====
   function Is_Empty
     (S: in Set_Type) return Boolean;

   --=====
   --  Function: Ith
   --  Get the element at index I in set S
   --
   --  Return:
   --  the element
   --
   --  Pre-Conditions:
   --  o I is in the range of set S
   --=====
   function Ith
     (S: in Set_Type;
      I: in Index_Type) return Element_Type;

   --=====
   --  Function: Index
   --  Get the index of element E in set S
   --
   --  Return:
   --  the index, or <No_Index> if E is not in set S
   --=====
   function Index
     (S: in Set_Type;
      E: in Element_Type) return Extended_Index_Type;

   --=====
   --  Function: First_Index
   --  Get the index of the first element of the set.
   --
   --  Return:
   --  the index or Index_Type'First if the set is empty (so that we always
   --  have First_Index(A) > Last_Index(A) if the set is empty)
   --=====
   function First_Index
     (S: in Set_Type) return Extended_Index_Type;

   --=====
   --  Function: Last_Index
   --  Get the index of the last element of the set.
   --
   --  Return:
   --  the index or <No_Index> if the set is empty
   --=====
   function Last_Index
     (S: in Set_Type) return Extended_Index_Type;

   --=====
   --  Function: Valid_Index
   --  Check if I is a valid index for set S, i.e., it is in range
   --  [First_Index(S)..Last_Index(S)].
   --
   --  Return:
   --  True if it is valid, False otherwise
   --=====
   function Valid_Index
     (S: in Set_Type;
      I: in Extended_Index_Type) return Boolean;

   --=====
   --  Function: Contains
   --  Check if set S contains element E.
   --
   --  Return:
   --  True if E is in S, False otherwise
   --=====
   function Contains
     (S: in Set_Type;
      E: in Element_Type) return Boolean;

   --=====
   --  Function: Equal
   --  Compare the contents of the two sets S and T.
   --
   --  Return:
   --  True if both sets are equal, False otherwise
   --=====
   function Equal
     (S: in Set_Type;
      T: in Set_Type) return Boolean;

   --=====
   --  Function: Subset
   --  Check if T is a subset of set S.
   --
   --  Return:
   --  True if T is a subset, False otherwise
   --=====
   function Subset
     (S: in Set_Type;
      T: in Set_Type) return Boolean;



   --==========================================================================
   --  Group: Operators
   --==========================================================================

   --=====
   --  Function: "or"
   --  Union operator.
   --
   --  Return:
   --  the union of S and T
   --=====
   function "or"
     (S: in Set_Type;
      T: in Set_Type) return Set_Type;

   --=====
   --  Function: "or"
   --  Union operator.
   --
   --  Return:
   --  the union of {E} and S
   --=====
   function "or"
     (E: in Element_Type;
      S: in Set_Type) return Set_Type;

   --=====
   --  Function: "or"
   --  Union operator.
   --
   --  Return:
   --  the union of S and {E}
   --=====
   function "or"
     (S: in Set_Type;
      E: in Element_Type) return Set_Type;

   --=====
   --  Function: "and"
   --  Intersection operator.
   --
   --  Return:
   --  the intersection of S and T
   --=====
   function "and"
     (S: in Set_Type;
      T: in Set_Type) return Set_Type;

   --=====
   --  Function: "and"
   --  Intersection operator.
   --
   --  Return:
   --  the intersection of {E} and S
   --=====
   function "and"
     (E: in Element_Type;
      S: in Set_Type) return Set_Type;

   --=====
   --  Function: "and"
   --  Intersection operator.
   --
   --  Return:
   --  the intersection of S and {E}
   --=====
   function "and"
     (S: in Set_Type;
      E: in Element_Type) return Set_Type;

   --=====
   --  Function: "-"
   --  Difference operator.
   --
   --  Return:
   --  the difference of S and T
   --=====
   function "-"
     (S: in Set_Type;
      T: in Set_Type) return Set_Type;

   --=====
   --  Function: "-"
   --  Difference operator.
   --
   --  Return:
   --  the difference of S and {E}
   --=====
   function "-"
     (S: in Set_Type;
      E: in Element_Type) return Set_Type;



   --==========================================================================
   --  Group: Procedures
   --==========================================================================

   --=====
   --  Procedure: Insert
   --  Insert element E in set S.
   --  No effect if E is already in S.
   --=====
   procedure Insert
     (S: in out Set_Type;
      E: in     Element_Type);

   --=====
   --  Procedure: Insert
   --  Insert element E in set S.
   --  R = True if E has been inserted, False otherwise.
   --=====
   procedure Insert
     (S: in out Set_Type;
      E: in     Element_Type;
      R:    out Boolean);

   --=====
   --  Procedure: Delete
   --  Delete element E from set S.
   --  No effect if E is not in S.
   --=====
   procedure Delete
     (S: in out Set_Type;
      E: in     Element_Type);

   --=====
   --  Procedure: Delete
   --  Delete element E from set S.
   --  R = True if E has been deleted, False otherwise.
   --=====
   procedure Delete
     (S: in out Set_Type;
      E: in     Element_Type;
      R:    out Boolean);



   --==========================================================================
   --  Group: Generic operations
   --==========================================================================

   generic
      with function Predicate(E: in Element_Type) return Boolean;
   --=====
   --  Generic procedure: Generic_Delete
   --  Delete from set S all the elements which satisfy Predicate.
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --=====
   procedure Generic_Delete
     (S: in out Set_Type);

   generic
      with procedure Action(E: in out Element_Type);
   --=====
   --  Generic procedure: Generic_Apply
   --  Call procedure Action on all the elements of set S.
   --
   --  Generic parameters:
   --  > procedure Action(E: in out Element_Type);
   --  the procedure called on the elements
   --=====
   procedure Generic_Apply
     (S: in Set_Type);

   generic
      with function Map(E: in Element_Type) return Element_Type;
   --=====
   --  Generic function: Generic_Map
   --  Map set S to another set.
   --  Each element of S is mapped in the set returned to its image by function
   --  Map.
   --
   --  Return:
   --  the image of S
   --
   --  Generic parameters:
   --  > function Map(E: in Element_Type) return Element_Type;
   --  the function used to map the elements of the set
   --=====
   function Generic_Map
     (S: in Set_Type) return Set_Type;

   generic
      with function Predicate(E: in Element_Type) return Boolean;
   --=====
   --  Generic function: Generic_Get_Satisfying_Element
   --  Get an arbitrary element of S which satisfy Predicate.
   --
   --  Return:
   --  an element or <Null_Element> if no element of S satisfy Predicate
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --=====
   function Generic_Get_Satisfying_Element
     (S: in Set_Type) return Element_Type;

   generic
      with function Predicate(E: in Element_Type) return Boolean;
   --=====
   --  Generic function: Generic_Forall
   --  Check if all the elements of S satisfy Predicate.
   --
   --  Return:
   --  True if all the elements satisfy Predicate, False otherwise
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --=====
   function Generic_Forall
     (S: in Set_Type) return Boolean;

   generic
      with function Predicate(E: in Element_Type) return Boolean;
   --=====
   --  Generic function: Generic_Exists
   --  Check if at least one element of S satisfy Predicate.
   --
   --  Return:
   --  True if an element satisfy Predicate, False otherwise
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --=====
   function Generic_Exists
     (S: in Set_Type) return Boolean;

   generic
      with function "="(E1, E2: in Element_Type) return Boolean;
   --=====
   --  Generic function: Generic_Equal
   --  Check if sets S and T are equal with respect to the comparison function
   --  "=".
   --
   --  Return:
   --  True if the set are equal, False otherwise
   --
   --  Generic parameters:
   --  > function "="(E1, E2: in Element_Type) return Boolean;
   --  the function used to compare elements
   --=====
   function Generic_Equal
     (S: in Set_Type;
      T: in Set_Type) return Boolean;

   generic
      Separator: String;
      Empty    : String;
      with function To_String(E: in Element_Type) return String;
   --=====
   --  Generic function: Generic_To_String
   --  Convert set S to a String.
   --
   --  Return:
   --  the string
   --
   --  Generic parameters:
   --  > Separator: String;
   --  the string placed between each element
   --  > Empty: String;
   --  the string returned if the set is empty
   --  > function To_String(E: in Element_Type) return String;
   --  the function used to convert an element of the set to a string
   --=====
   function Generic_To_String
     (S: in Set_Type) return String;

   generic
      with function Predicate(E: in Element_Type) return Boolean;
   --=====
   --  Generic function: Generic_Count
   --  Count the elements of S which satisfy Predicate.
   --
   --  Return:
   --  the number of elements
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --=====
   function Generic_Count
     (S: in Set_Type) return Natural;

   generic
      with function Predicate(E: in Element_Type) return Boolean;
   --=====
   --  Generic function: Generic_Subset
   --  Get the subset of all the elements of S which satisfy Predicate.
   --
   --  Return:
   --  the subset
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --=====
   function Generic_Subset
     (S: in Set_Type) return Set_Type;


private


   type Element_Array_Access is access all Element_Array;

   type Set_Type is new Ada.Finalization.Controlled with
      record
         Elements: Element_Array_Access; --  the elements
         Last    : Extended_Index_Type;  --  index of the last element of the
                                          --  array
      end record;

   procedure Initialize
     (S: in out Set_Type);

   procedure Adjust
     (S: in out Set_Type);

   procedure Finalize
     (S: in out Set_Type);

   procedure Insert_No_Check
     (S: in out Set_Type;
      E: in     Element_Type);

   Empty_Set: constant Set_Type := (Controlled with
                                     Elements => null,
                                     Last     => No_Index);

end Generic_Set;
