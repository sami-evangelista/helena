--=============================================================================
--
--  Package: Pn.Compiler.Classes
--
--  This package provides a procedure that compile the color classes of a net
--  into C code.
--  Each color class CC is mapped to a C type called
--  <Pn.Compiler.Names.Cls_Name>(CC):
--  - Numerical and enumerate colors are mapped to a basic C type (char, short,
--    or int).
--  - Structured color classes are mapped to an identical struct type.
--  - Vector classes are mapped to a struct type which contains an array.
--    The name of the array component of this struct type is "vector".
--    The reason we do that is that, by this way, we can translate vectors in
--    expressions in a straightforward manner and easily do things such as
--    assignments from vector to vector (an array-to-array assignment is not
--    possible in C).
--  - List and set classes are mapped to a struct type which contains an array
--    "items" which contains the elements of the container and an integer
--    "length" which records the number of elements in the container, i.e.,
--    the number of elements in items which are used.
--
--=============================================================================


package Pn.Compiler.Classes is

   --==========================================================================
   --  Group: Main generation procedure
   --==========================================================================

   --=====
   --  Procedure: Gen
   --  Main generation procedure.
   --  Compile all the color classes of net N in a library.
   --  Path is the absolute path of the directory in which the library must be
   --  generated.
   --=====
   procedure Gen
     (N   : in Net;
      Path: in Ustring);

end Pn.Compiler.Classes;
