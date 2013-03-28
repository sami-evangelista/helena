--=============================================================================
--
--  Package: Generic_Bag
--
--  A generic bag package.
--  A bag is a set in which a same item may appear several times.
--  We call the multiplicity of an item in a bag the number of times this item
--  appears in the bag.
--  The type of the elements in the bag is a generic parameter of the package.
--  Elements are accessed by the index type <Index_Type>.
--  The bag type <Bag_Type> is controlled so that the user does not need to
--  perform explicit deallocation.
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
   --  Function: "="
   --  function used to compare two elements
   --=====
   with function "="(E1: in Element_Type;
                     E2: in Element_Type) return Boolean;
package Generic_Bag is

   --==========================================================================
   --  Group: Types and constants
   --==========================================================================

   --=====
   --  Type: Bag_Type
   --  the bag type
   --=====
   type Bag_Type is private;

   --=====
   --  Subtype: Index_Type
   --  the index type used to index the elements of a bag
   --=====
   subtype Index_Type is Positive;

   --=====
   --  Subtype: Extended_Index_Type
   --  the index type + the <No_Index> constant
   --=====
   subtype Extended_Index_Type is Natural;

   --=====
   --  Subtype: Mult_Type
   --  the multiplicity type
   --=====
   subtype Mult_Type is Natural;

   --=====
   --  Subtype: Card_Type
   --  the cardinal type used to count the elements of a bag
   --=====
   subtype Card_Type is Natural;

   --=====
   --  Constant: No_Index
   --  the no index constant, returned, e.g., by some functions when an element
   --  is not found
   --=====
   No_Index: constant Extended_Index_Type := 0;

   --=====
   --  Constant: Empty_Bag
   --  the empty bag constant, i.e., with no element in it
   --=====
   Empty_Bag: constant Bag_Type;



   --==========================================================================
   --  Group: Functions
   --==========================================================================

   --=====
   --  Function: Card
   --  Get the cardinal of bag B, i.e., the number of distinct elements in it.
   --
   --  Return:
   --  the cardinal
   --=====
   function Card
     (B: in Bag_Type) return Card_Type;

   --=====
   --  Function: First_Index
   --  Get the index of the first item of bag B.
   --
   --  Return:
   --  the index or Index_Type'First if the set is empty (so that we always
   --  have First_Index(A) > Last_Index(A) if the set is empty)
   --=====
   function First_Index
     (B: in Bag_Type) return Extended_Index_Type;

   --=====
   --  Function: Last_Index
   --  Get the index of the last item of bag B.
   --
   --  Return:
   --  the index, or <No_Index> if the bag is empty
   --=====
   function Last_Index
     (B: in Bag_Type) return Extended_Index_Type;

   --=====
   --  Function: Get_Mult
   --  Get the multiplicity of element E in bag B.
   --
   --  Return:
   --  the multiplicity, 0 if E is not in the bag
   --=====
   function Get_Mult
     (B: in Bag_Type;
      E: in Element_Type) return Mult_Type;



   --==========================================================================
   --  Group: Procedures
   --==========================================================================

   --=====
   --  Procedure: Element_At_Index
   --  Get the element E at index I in bag B with its multiplicity M.
   --
   --  Pre-Conditions:
   --  o I is in range [First_Index(B)..Last_Index(B)]
   --=====
   procedure Element_At_Index
     (B: in     Bag_Type;
      I: in     Index_Type;
      E:    out Element_Type;
      M:    out Mult_Type);

   --=====
   --  Procedure: Insert
   --  Insert element E with multiplicity M in bag B.
   --  N = True if the element was not in the bag, False otherwise.
   --=====
   procedure Insert
     (B: in out Bag_Type;
      E: in     Element_Type;
      M: in     Mult_Type;
      N:    out Boolean);

   --=====
   --  Procedure: Union
   --  Perform the union operation B := B U C.
   --=====
   procedure Union
     (B: in out Bag_Type;
      C: in     Bag_Type);



   --==========================================================================
   --  Group: Generic operations
   --==========================================================================

   generic
      with procedure Action(E: in out Element_Type);
   --=====
   --  Procedure: Generic_Apply
   --  Apply procedure action on all the elements of bag B.
   --
   --  Generic parameters:
   --  > procedure Action(E: in out Element_Type);
   --  the procedure called on each element
   --=====
   procedure Generic_Apply
     (B: in Bag_Type);


private


   type Mult_Element is
      record
         E: Element_Type; --  the element
         M: Mult_Type;    --  its mulitplicity
      end record;

   type Mult_Element_Array is array(Index_Type range <>) of Mult_Element;
   type Mult_Elements is access all Mult_Element_Array;

   type Bag_Type is new Ada.Finalization.Controlled with
      record
         Elements: Mult_Elements;       --  the elements
         Last    : Extended_Index_Type; --  index of the last element in the
                                         --  array
      end record;

   procedure Initialize
     (B: in out Bag_Type);

   procedure Adjust
     (B: in out Bag_Type);

   procedure Finalize
     (B: in out Bag_Type);

   Empty_Bag: constant Bag_Type := (Controlled with
                                     Elements => null,
                                     Last     => 0);

end Generic_Bag;
