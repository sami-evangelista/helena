--=============================================================================
--
--  Package: Utils.Strings
--
--  This package contains some useful functions to handle strings.
--
--=============================================================================


with
  Ada.Strings.Unbounded,
  Generic_Array,
  Utils.Generics;

use
  Ada.Strings.Unbounded,
  Utils.Generics;

package Utils.Strings is

   --=====
   --  Subtype: Unbounded_String
   --  A shortcut for Unbounded_String.
   --=====
   subtype Ustring is Ada.Strings.Unbounded.Unbounded_String;

   --=====
   --  Function: To_Ustring
   --  Renaming of To_Ustring.
   --=====
   function To_Ustring
     (Str: in String) return Ustring;

   --=====
   --  Constant: Null_String
   --  The empty Ustring.
   --=====
   Null_String: constant Ustring := To_Unbounded_String("");

   --=====
   --  Constant: Nl
   --  The line-feed character.
   --=====
   Nl: constant Character := Ascii.Lf;

   --=====
   --  Constant: Tab
   --  A tabulation.
   --=====
   Tab: constant Ustring := To_Unbounded_String("   ");

   --=====
   --  Constant: Space
   --  A single space.
   --=====
   Space: constant Ustring := To_Unbounded_String(" ");



   --==========================================================================
   --  Group: Some generic packages or sub-programs instantiations
   --==========================================================================

   --=====
   --  Package: Pn.Integer_String_Conversion
   --  This package is used to handle conversion from Integer values to
   --  Strings.
   --=====
   package Integer_String_Conversion is new Generic_String_Conversion(Integer);
   package ISC renames Integer_String_Conversion;
   function To_String
     (I: in Integer) return String renames ISC.To_String;
   function To_Ustring
     (I: in Integer) return Ustring renames ISC.To_Unbounded_String;
   function "&"
     (Left: in String;
      Right: in Integer) return Ustring renames ISC."&";
   function "&"
     (Left: in Integer;
      Right: in String) return Ustring renames ISC."&";
   function "&"
     (Left: in Ustring;
      Right: in Integer) return Ustring renames ISC."&";
   function "&"
     (Left: in Integer;
      Right: in Ustring) return Ustring renames ISC."&";

   --=====
   --  Package: Pn.Big_Int_String_Conversion
   --  This package is used to handle conversion from Big_Int values to
   --  Strings.
   --=====
   package Big_Int_String_Conversion is new Generic_String_Conversion(Big_Int);
   package BISC renames Big_Int_String_Conversion;
   function To_String
     (I: in Big_Int) return String renames BISC.To_String;
   function To_Ustring
     (I: in Big_Int) return Ustring renames BISC.To_Unbounded_String;
   function "&"
     (Left: in String;
      Right: in Big_Int) return Ustring renames BISC."&";
   function "&"
     (Left: in Big_Int;
      Right: in String)  return Ustring renames BISC."&";
   function "&"
     (Left: in Ustring;
      Right: in Big_Int) return Ustring renames BISC."&";
   function "&"
     (Left: in Big_Int;
      Right: in Ustring) return Ustring renames BISC."&";

   --=====
   --  Type: String_Mapping
   --  a string mapping associates a string to another one
   --=====
   type String_Mapping is private;

   --=====
   --  Type: String_Mapping_Set
   --  a set of String_Mapping
   --=====
   type String_Mapping_Set is array(Positive range <>) of String_Mapping;

   --=====
   --  Type: Unbounded_String_Array
   --  an array of unbounded strings
   --=====
   type Unbounded_String_Array is
     array (Positive range <>) of Unbounded_String;

   --=====
   --  Type: Char_Set
   --  an set of characters
   --=====
   type Char_Set is array(Character) of Boolean;

   Blanks: constant Char_Set := (' '      => True,
                                 Ascii.Ht => True,
                                 Ascii.Lf => True,
                                 others   => False);


   --=====
   --  Function: To_String_Mapping
   --  Return a string mapping which associates each occurence of string From
   --  to string To.
   --=====
   function To_String_Mapping
     (From: in String;
      To  : in String) return String_Mapping;

   --=====
   --  Function: Replace
   --  Return the image of Str by mapping Map.
   --=====
   function Replace
     (Str: in String;
      Map: in String_Mapping) return String;

   --=====
   --  Function: Replace
   --  Return the image of Str by mapping Map.
   --  Only the sub string of Str which ranges from First to Last is
   --  considered.
   --=====
   function Replace
     (Str  : in String;
      Map  : in String_Mapping;
      First: in Natural;
      Last : in Natural) return String;

   --=====
   --  Function: Replace
   --  Return the image of Str by the set of mappings Map_Set.
   --=====
   function Replace
     (Str    : in String;
      Map_Set: in String_Mapping_Set) return String;

   --=====
   --  Function: To_Upper
   --  Return Str in upper case.
   --=====
   function To_Upper
     (Str: in Unbounded_String) return Unbounded_String;

   --=====
   --  Function: To_Lower
   --  Return Str in lower case.
   --=====
   function To_Lower
     (Str: in Unbounded_String) return Unbounded_String;

   --=====
   --  Function: Trim
   --  Return S with no blanks at the beginning and at the end.
   --=====
   function Trim
     (S: in String) return String;

   --=====
   --  Function: Trim
   --  Return S with no blanks at the beginning and at the end.
   --=====
   function Trim
     (S: in Unbounded_String) return Unbounded_String;

   --=====
   --  Function: Split
   --  Split string S in several sub-strings and return an array containing
   --  these strings.
   --=====
   function Split
     (S  : in String;
      Sep: in Char_Set := Blanks) return Unbounded_String_Array;

   --=====
   --  Package: Utils.Generics.String_List_Pkg
   --  the list of strings package
   --=====
   package String_List_Pkg is
      new Generic_Array(Unbounded_String, Null_Unbounded_String, "=");
   subtype Ustring_List is String_List_Pkg.Array_Type;


private


   type String_Mapping is
      record
         From: Unbounded_String;
         To  : Unbounded_String;
      end record;

end Utils.Strings;
