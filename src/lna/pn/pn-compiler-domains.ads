--=============================================================================
--
--  Package: Pn.Compiler.Domains
--
--  This package provides procedures to compile the data types and
--  functions related to color domains.  Since a color domain is a
--  cartesian product, each color domain is mapped to an identical
--  struct type.  Many functions are compiled along with color
--  domains: comparison functions, encoding / decoding functions...
--
--=============================================================================


with
  Generic_Set,
  Pn.Classes;

use
  Pn.Classes;

package Pn.Compiler.Domains is

   --==========================================================================
   --  Group: Main generation procedure
   --==========================================================================

   procedure Gen
     (N   : in Net;
      Path: in Ustring);



   --==========================================================================
   --  Group: Elements generated for a color domain
   --==========================================================================

   function Dom_Type
     (D: in Dom) return Ustring;

   function Dom_Ith_Comp_Name
     (I: in Natural) return Ustring;

   function Dom_Eq_Func
     (D: in Dom) return Ustring;

   function Dom_Neq_Func
     (D: in Dom) return Ustring;

   function Dom_Cmp_Func
     (D: in Dom) return Ustring;

   function Dom_Hash_Func
     (D: in Dom) return Ustring;

   function Dom_Bit_Width_Func
     (D: in Dom) return Ustring;



   --==========================================================================
   --  Group: Elements generated for the color domain of a place
   --==========================================================================

   function Place_Dom_Type
     (P: in Place) return Ustring;

   function Place_Dom_Eq_Func
     (P: in Place) return Ustring;

   function Place_Dom_Neq_Func
     (P: in Place) return Ustring;

   function Place_Dom_Cmp_Func
     (P: in Place) return Ustring;

   function Place_Dom_Hash_Func
     (P: in Place) return Ustring;

   function Place_Dom_Bit_Width_Func
     (P: in Place) return Ustring;

   function Place_Dom_Encode_Func
     (P: in Place) return Ustring;

   function Place_Dom_Decode_Func
     (P: in Place) return Ustring;

   function Place_Dom_Print_Func
     (P: in Place) return Ustring;



   --==========================================================================
   --  Group: Elements generated for the color domain of a transition
   --==========================================================================

   function Trans_Dom_Type
     (T: in Trans) return Ustring;

   function Trans_Dom_Eq_Func
     (T: in Trans) return Ustring;

   function Trans_Dom_Neq_Func
     (T: in Trans) return Ustring;

   function Trans_Dom_Cmp_Func
     (T: in Trans) return Ustring;

   function Trans_Dom_Hash_Func
     (T: in Trans) return Ustring;

   function Trans_Dom_Encode_Func
     (T: in Trans) return Ustring;

   function Trans_Dom_Decode_Func
     (T: in Trans) return Ustring;

   function Trans_Dom_Print_Func
     (T: in Trans) return Ustring;



   --==========================================================================
   --  Group: Some useful functions and procedures
   --==========================================================================

   function Encoded_Size
     (D   : in Dom;
      Item: in Ustring) return Ustring;

   procedure Add_Dom
     (D: in Dom);


private

   --==========================================================================
   --  The set of color domains to compile
   --==========================================================================

   package Dom_Set_Pkg is new Generic_Set(Element_Type => Dom,
                                          Null_Element => null,
                                          "="          => Pn.Classes.Same);
   subtype Dom_Set is Dom_Set_Pkg.Set_Type;

   Doms: Dom_Set := Dom_Set_Pkg.Empty_Set;

end Pn.Compiler.Domains;
