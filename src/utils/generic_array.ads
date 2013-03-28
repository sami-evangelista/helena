--=============================================================================
--
--  Package: Generic_Array
--
--  A generic array package.
--  The type of the elements in the array is a generic parameter of the
--  package.
--  Elements are accessed by the index type <Index_Type>.
--  The array type <Array_Type> is controlled so that the user does not need to
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
   --  the type of the elements stored in the array
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
package Generic_Array is

   --==========================================================================
   --  Group: Types, subtypes and constants
   --==========================================================================

   --=====
   --  Type: Array_Type
   --  the array type
   --=====
   type Array_Type is private;

   --=====
   --  Subtype: Index_Type
   --  the index type used to index the elements of an array
   --=====
   subtype Index_Type is Positive;

   --=====
   --  Subtype: Extended_Index_Type
   --  the index type + the <No_Index> constant
   --=====
   subtype Extended_Index_Type is Natural;

   --=====
   --  Subtype: Count_Type
   --  the count type used to count the elements of an array
   --=====
   subtype Count_Type is Natural;

   --=====
   --  Type: Element_Array
   --  an array of elements
   --=====
   type Element_Array is array(Index_Type range <>) of Element_Type;

   --=====
   --  Constant: Empty_Array
   --  the empty array constant, i.e., with no element in it
   --=====
   Empty_Array: constant Array_Type;

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
   --  Function: New_Array
   --  Array constructor. The array is intialized to the only element E.
   --
   --  Return:
   --  a new array
   --=====
   function New_Array
     (E: in Element_Type) return Array_Type;

   --=====
   --  Function: New_Array
   --  Array constructor. The array is intialized to the elements of E.
   --
   --  Return:
   --  a new array
   --=====
   function New_Array
     (E: in Element_Array) return Array_Type;

   --=====
   --  Function: Length
   --  Get the length of array A.
   --
   --  Return:
   --  the length
   --=====
   function Length
     (A: in Array_Type) return Count_Type;

   --=====
   --  Function: Is_Empty
   --  Check if array A is empty.
   --
   --  Return:
   --  True if A is empty, False otherwise
   --=====
   function Is_Empty
     (A: in Array_Type) return Boolean;

   --=====
   --  Function: Ith
   --  Get the element at index I in array A.
   --
   --  Return:
   --  the element
   --
   --  Pre-Conditions:
   --  o I is a valid index of array A
   --=====
   function Ith
     (A: in Array_Type;
      I: in Index_Type) return Element_Type;

   --=====
   --  Function: Index
   --  Get the index of the first occurence of element E in A.
   --
   --  Return:
   --  the index or <No_Index> if there is no occurence of E in A
   --=====
   function Index
     (A: in Array_Type;
      E: in Element_Type) return Extended_Index_Type;

   --=====
   --  Function: First
   --  Get the first element of array A.
   --
   --  Return:
   --  the element
   --
   --  Pre-Conditions:
   --  o A is not empty
   --=====
   function First
     (A: in Array_Type) return Element_Type;

   --=====
   --  Function: Last
   --  Get the last element of array A.
   --
   --  Return:
   --  the element
   --
   --  Pre-Conditions:
   --  o A is not empty
   --=====
   function Last
     (A: in Array_Type) return Element_Type;

   --=====
   --  Function: First_Index
   --  Get the index of the first element of the array.
   --
   --  Return:
   --  the index or Index_Type'First if the array is empty (so that we always
   --  have First_Index(A) > Last_Index(A) if the set is empty)
   --=====
   function First_Index
     (A: in Array_Type) return Extended_Index_Type;

   --=====
   --  Function: Last_Index
   --  Get the index of the last element of the array.
   --
   --  Return:
   --  the index or <No_Index> if the array is empty
   --=====
   function Last_Index
     (A: in Array_Type) return Extended_Index_Type;

   --=====
   --  Function: Valid_Index
   --  Check if I is a valid index for array A, i.e., it is in range
   --  [First_Index(A)..Last_Index(A)].
   --
   --  Return:
   --  True if I is a valid index, False otherwise
   --=====
   function Valid_Index
     (A: in Array_Type;
      I: in Extended_Index_Type) return Boolean;

   --=====
   --  Function: Contains
   --  Check if Element E is in array A.
   --
   --  Return:
   --  True is E is in A, False otherwise
   --=====
   function Contains
     (A: in Array_Type;
      E: in Element_Type) return Boolean;

   --=====
   --  Function: Equal
   --  Compares the content of two arrays.
   --  To be equal, both arrays must have the same length and the same
   --  elements at the same indexes.
   --
   --  Return:
   --  True if the arrays are equal, False otherwise
   --=====
   function Equal
     (A: in Array_Type;
      B: in Array_Type) return Boolean;



   --==========================================================================
   --  Group: Procedures
   --==========================================================================

   --=====
   --  Procedure: Append
   --  Add element E at the end of array A.
   --=====
   procedure Append
     (A: in out Array_Type;
      E: in     Element_Type);

   --=====
   --  Procedure: Append
   --  Add all the elements of array B at the end of array A.
   --=====
   procedure Append
     (A: in out Array_Type;
      B: in     Array_Type);

   --=====
   --  Procedure: Prepend
   --  Add element E at the beginning of array A.
   --=====
   procedure Prepend
     (A: in out Array_Type;
      E: in     Element_Type);

   --=====
   --  Procedure: Prepend
   --  Add all the elements of array B at the beginning of array A.
   --=====
   procedure Prepend
     (A: in out Array_Type;
      B: in     Array_Type);

   --=====
   --  Procedure: Replace
   --  Replace element of array A at index I by element E.
   --
   --  Pre-Conditions:
   --  o I is a valid index of array A.
   --=====
   procedure Replace
     (A: in out Array_Type;
      E: in     Element_Type;
      I: in     Index_Type);

   --=====
   --  Procedure: Insert
   --  Insert element E at index I in array A.
   --
   --  Pre-Conditions:
   --  o I is in the range [1..Last_Index(A)+1]
   --=====
   procedure Insert
     (A: in out Array_Type;
      E: in     Element_Type;
      I: in     Index_Type);

   --=====
   --  Procedure: Delete
   --  Delete all the occurences of element E from array A.
   --=====
   procedure Delete
     (A: in out Array_Type;
      E: in     Element_Type);

   --=====
   --  Procedure: Delete
   --  Delete all the occurences of element E from array A. R states if some
   --  element have been deleted.
   --=====
   procedure Delete
     (A: in out Array_Type;
      E: in     Element_Type;
      R:    out Boolean);

   --=====
   --  Procedure: Delete
   --  Delete from array A the element at index I.
   --
   --  Pre-Conditions:
   --  o I is a valid index of array A.
   --=====
   procedure Delete
     (A: in out Array_Type;
      I: in     Index_Type);

   --=====
   --  Procedure: Delete_First
   --  Delete the first element of array A.
   --
   --  Pre-Conditions:
   --  o A is not empty
   --=====
   procedure Delete_First
     (A: in out Array_Type);

   --=====
   --  Procedure: Delete_Last
   --  Delete the last element of array A.
   --
   --  Pre-Conditions:
   --  o A is not empty
   --=====
   procedure Delete_Last
     (A: in out Array_Type);



   --==========================================================================
   --  Group: Generic operations
   --==========================================================================

   generic
      with function Predicate(E: in Element_Type) return Boolean;
   --=====
   --  Generic procedure: Generic_Delete
   --  Delete from A all the elements which satisfy Predicate.
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --=====
   procedure Generic_Delete
     (A: in out Array_Type);

   generic
      with procedure Action(E: in out Element_Type);
   --=====
   --  Generic procedure: Generic_Apply
   --  Call procedure Action on all the elements of A.
   --
   --  Generic parameters:
   --  > procedure Action(E: in out Element_Type);
   --  the procedure called on the elements
   --=====
   procedure Generic_Apply
     (A: in Array_Type);

   generic
      with function Predicate(E: in Element_Type) return Boolean;
      with procedure Action(E: in out Element_Type);
   --=====
   --  Generic procedure: Generic_Apply_Subset
   --  Call procedure Action on all the elements of A which satisfy Predicate.
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --  > procedure Action(E: in out Element_Type);
   --  the procedure called on the element
   --=====
   procedure Generic_Apply_Subset
     (A: in out Array_Type);

   generic
      with function Predicate(E: in Element_Type) return Boolean;
      with procedure Action(E: in out Element_Type);
   --=====
   --  Generic procedure: Generic_Apply_Subset_And_Delete
   --  Call procedure Action on all the elements of A which satisfy Predicate
   --  and then delete them.
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --  > procedure Action(E: in out Element_Type);
   --  the procedure called on the element
   --=====
   procedure Generic_Apply_Subset_And_Delete
     (A: in out Array_Type);

   generic
      with function Map(E: in Element_Type) return Element_Type;
   --=====
   --  Generic function: Generic_Map
   --  Map array A to another array.
   --  The returned array has the same length as A and its elements are the
   --  images of the elements of A by mapping Map.
   --
   --  Return:
   --  the image of A
   --
   --  Generic parameters:
   --  > function Map(E: in Element_Type) return Element_Type;
   --  the function used to map elements
   --=====
   function Generic_Map
     (A: in Array_Type) return Array_Type;

   generic
      with function Predicate(E: in Element_Type) return Boolean;
   --=====
   --  Generic function: Generic_Get_First_Satisfying_Element
   --  Get the first element in array A which satisfies Predicate.
   --
   --  Return:
   --  the element, <Null_Element> if no element of A satisfies Predicate
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --=====
   function Generic_Get_First_Satisfying_Element
     (A: in Array_Type) return Element_Type;

   generic
      with function Predicate(E: in Element_Type) return Boolean;
   --=====
   --  Generic function: Generic_Get_First_Satisfying_Element_Index
   --  Get the index of the first element in array A which satisfies Predicate.
   --
   --  Return:
   --  the index, <No_Index> if no element of A satisfies Predicate
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --=====
   function Generic_Get_First_Satisfying_Element_Index
     (A: in Array_Type) return Extended_Index_Type;

   generic
      with function Predicate(E: in Element_Type) return Boolean;
   --=====
   --  Generic function: Generic_Forall
   --  Check if all the elements in array A satisfy Predicate.
   --
   --  Return:
   --  True if all the elements satisfy Predicate, False othwerise
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --=====
   function Generic_Forall
     (A: in Array_Type) return Boolean;

   generic
      with function Predicate(E: in Element_Type) return Boolean;
   --=====
   --  Generic function: Generic_Exists
   --  Check if there is in array A an element which satisfies Predicate.
   --
   --  Return:
   --  True if an element satisfies Predicate, False othwerise
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --=====
   function Generic_Exists
     (A: in Array_Type) return Boolean;

   generic
      type Data_Type is private;
      with procedure Compute(E: in     Element_Type;
                             D: in out Data_Type);
   --=====
   --  Generic function: Generic_Compute
   --  Iterate on all the elements of the array and compute a data.
   --  The data is computed by calling a procedure on each of these elements.
   --
   --  Generic parameters:
   --  > type Data_Type is private;
   --  the type of the data computed
   --  > procedure Compute(E: in     Element_Type;
   --  >                   D: in out Data_Type);
   --  the procedure called on all the elements of the array
   --
   --  Remarks:
   --  o the initialisation of the data is left to the caller
   --=====
   procedure Generic_Compute
     (A: in     Array_Type;
      D: in out Data_Type);

   generic
      with function "="(E1, E2: in Element_Type) return Boolean;
   --=====
   --  Generic function: Generic_Equal
   --  Check if arrays A and B are equal, i.e., same length and same elements
   --  at the same indexes.
   --
   --  Return:
   --  True if the arrays are equal, False otherwise
   --
   --  Generic parameters:
   --  > function "="(E1, E2: in Element_Type) return Boolean;
   --  function used to compare two elements
   --=====
   function Generic_Equal
     (A: in Array_Type;
      B: in Array_Type) return Boolean;

   generic
      Separator: String;
      Empty    : String;
      with function To_String(E: in Element_Type) return String;
   --=====
   --  Generic function: Generic_To_String
   --  Convert array A to a String.
   --
   --  Return:
   --  the string
   --
   --  Generic parameters:
   --  > Separator: String;
   --  the string placed between each element
   --  > Empty: String
   --  the string returned if the array is empty
   --  > function To_String(E: in Element_Type) return String;
   --  the function used to convert an element of the array to a string
   --=====
   function Generic_To_String
     (A: in Array_Type) return String;

   generic
      with function Predicate(E: in Element_Type) return Boolean;
   --=====
   --  Generic function: Generic_Count
   --  Count the number of elements of array A which satisfy Predicate.
   --
   --  Return:
   --  the number of elements
   --
   --  Generic parameters:
   --  > function Predicate(E: in Element_Type) return Boolean;
   --  the predicate
   --=====
   function Generic_Count
     (A: in Array_Type) return Count_Type;


private


   type Element_Array_Access is access all Element_Array;

   type Array_Type is new Ada.Finalization.Controlled with
      record
         Elements: Element_Array_Access; --  the elements
         Last    : Extended_Index_Type;  --  index of the last element of the
                                          --  array
      end record;

   procedure Initialize
     (A: in out Array_Type);

   procedure Adjust
     (A: in out Array_Type);

   procedure Finalize
     (A: in out Array_Type);

   Empty_Array: constant Array_Type := (Controlled with
                                         Elements => null,
                                         Last     => No_Index);

end Generic_Array;
