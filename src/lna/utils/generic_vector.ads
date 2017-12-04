--=============================================================================
--
--  Description:
--
--  A generic vector package.
--
--=============================================================================


generic
   type Element is private;
package Generic_Vector is

   --  vector type
   type Vector is private;

   --  empty vector constant
   Empty_Vector: constant Vector;

   --  visible exceptions
   Element_Not_Found_Exception  : exception;
   Invalid_Index_Exception   : exception;
   Invalid_Vector_Size_Exception: exception;
   Empty_Vector_Exception       : exception;


   function Size
     (V: in Vector) return Natural;
   --  return the size of vector V

   procedure Add
     (V: in out Vector;
      E: in     Element);
   --  add element E at the end of the vector V

   procedure Add_Vector
     (V : in out Vector;
      V2: in     Vector);
   --  add vector V2 at the end of the vector V
   --  raise Invalid_Vector_Size_Exception if vectors do not have the same size

   procedure Add
     (V: in out Vector;
      E: in     Element;
      I: in     Natural);
   --  add element E at position I of vector E
   --  raise Invalid_Index_Exception if I is not in [1 .. Size(V)+1]

   procedure Remove
     (V: in out Vector);
   --  remove last element of vector V
   --  raise Empty_Vector_Exception if the vector is empty

   procedure Remove
     (V: in out Vector;
      I: in     Natural);
   --  remove element of vector V at position I
   --  raise Invalid_Index_Exception if I is not in [1 .. Size(V)]

   generic
      with procedure Free(E: in out Element);
   procedure Generic_Free
     (V: in out Vector);
   --  free vector V and all its elements

   generic
      with function Pred(E: in Element) return Boolean;
   function Satisfying_Element
     (V: in Vector) return Element;
   --  return first element of V which satifies predicate pred
   --  raise Element_Not_Found if no element satisfies the predicate

   procedure Free
     (V: in out Vector);
   --  free vector V

   function Get_Pos
     (V: in Vector;
      E: in Element) return Natural;
   --  return position of element E in vector V
   --  raise Element_Not_Found_Exception if E is not in V.

   function Ith
     (V: in Vector;
      I: in Natural) return Element;
   --  return Ith element of vector V
   --  raise Invalid_Index_Exception if I is not in [1..size(v)]

   function Is_In
     (V: in Vector;
      E: in Element) return Boolean;
   --  check if element E is in vector V

   procedure Set
     (V: in Vector;
      E: in Element;
      I: in Natural);
   --  Ith element of the vector V become E
   --  raise Invalid_Index_Exception if I is not in [1..size(v)]

   function Copy
     (V: in Vector) return Vector;
   --  return a copy of vector V

   generic
      with function Copy(E: in Element) return Element;
   function Generic_Map
     (V: in Vector) return Vector;
   --  return a copy of vector V. all elements of V are copied according to
   --  copy

   generic
      with procedure Addition(E1: in out Element;
                              E2: in     Element);
   procedure Addition
     (V1: in out Vector;
      V2: in     Vector);
   --  perform V(I) := V(I) + V2(I) for all elements of V. The addition is
   --  given by the generic parameter

   generic
      with function Pred(E: in Element) return Boolean;
   function Exists
     (V: in Vector) return Boolean;
   --  check that an element of the vector satisfies predicate Pred

   generic
      with function Pred(E: in Element) return Boolean;
   function For_All
     (V: in Vector) return Boolean;
   --  check that all elements of the vector satisfy predicate Pred

   generic
      with procedure Action(E: in out Element);
   procedure Apply
     (V: in out Vector);
   --  call procedure Action on all the elements of the vector V

   generic
      with function "="(E1: in Element;
                        E2: in Element) return Boolean;
   function Equal
     (V1: in Vector;
      V2: in Vector) return Boolean;
   --  check that two vectors are equal according to function "="

   generic
      with function To_Remove(E: in Element) return Boolean;
   procedure Remove_Sub_Set
     (V: in out Vector);
   --  remove from V all the elements which satisfy predicate To_Remove


private

   type Vector_Array is array(Positive range <>) of Element;
   type Vector is access all Vector_Array;

   Empty_Vector: constant Vector :=  null;

end Generic_Vector;
