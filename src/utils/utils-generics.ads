--=============================================================================
--
--  Package: Utils.Generics
--
--  An utility package.  Contains some instantiations of generic packages or
--  sub-programs.
--
--=============================================================================


with
  Ada.Strings.Unbounded;

use
  Ada.Strings.Unbounded;

package Utils.Generics is

   generic
      type Element is private;
      with function ">"(E1: in Element; E2: in Element) return Boolean;
   --=====
   --  Function: Generic_Max
   --  A generic max function.
   --
   --  Return:
   --  the max between E1 and E2 according to ">"
   --
   --  Generic parameters:
   --  > type Element is private;
   --  the type of element compared
   --  > function ">"(E1: in Element; E2: in Element) return Boolean;
   --  the function used to compare elements
   --=====
   function Generic_Max
     (E1: in Element;
      E2: in Element) return Element;

   generic
      type Element is private;
      with function "<"(E1: in Element; E2: in Element) return Boolean;
   --=====
   --  Function: Generic_Min
   --  A generic min function.
   --
   --  Return:
   --  the min between E1 and E2 according to "<"
   --
   --  Generic parameters:
   --  > type Element is private;
   --  the type of element compared
   --  > function "<"(E1: in Element; E2: in Element) return Boolean;
   --  the function used to compare elements
   --=====
   function Generic_Min
     (E1: in Element;
      E2: in Element) return Element;

   generic
      type Element is private;
   --=====
   --  Function: Generic_Ite
   --  A generic if-then-else function.
   --
   --  Return:
   --  Etrue if B = true, Efalse otherwise
   --
   --  Generic parameters:
   --  > type Element is private;
   --  the type of the element returned
   --=====
   function Generic_Ite
     (B     : in Boolean;
      Etrue : in Element;
      Efalse: in Element) return Element;

   --=====
   --  Package: Generic_String_Conversion
   --  A generic package to convert items of discrete types to strings.
   --=====
   generic

      --=======================================================================
      --  Group: Generic parameters of the package
      --=======================================================================

      --=====
      --  Type: T
      --  the discrete type of the elements converted
      --=====
      type T is (<>);
   package Generic_String_Conversion is

      --=======================================================================
      --  Group: Conversion functions
      --=======================================================================

      --=====
      --  Function: To_Unbounded_String
      --=====
      function To_Unbounded_String
        (E: in T) return Unbounded_String;

      --=====
      --  Function: To_String
      --=====
      function To_String
        (E: in T) return String;

      --=======================================================================
      --  Group: Concatenation operators
      --=======================================================================

      --=====
      --  Function: "&"
      --=====
      function "&"
        (E: in T;
         S: in String) return Unbounded_String;

      --=====
      --  Function: "&"
      --=====
      function "&"
        (S: in String;
         E: in T) return Unbounded_String;

      --=====
      --  Function: "&"
      --=====
      function "&"
        (E: in T;
         S: in Unbounded_String) return Unbounded_String;

      --=====
      --  Function: "&"
      --=====
      function "&"
        (S: in Unbounded_String;
         E: in T) return Unbounded_String;

   end Generic_String_Conversion;

end Utils.Generics;

