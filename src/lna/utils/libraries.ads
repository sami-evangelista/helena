--=============================================================================
--
--  Package: Libraries
--
--  This package contains some basic procedures to handle C libraries in which
--  Helena compiles colored Petri nets.
--
--=============================================================================


with
  Ada.Strings.Unbounded,
  Ada.Text_Io;

use
  Ada.Strings.Unbounded,
  Ada.Text_Io;

package Libraries is

   --=====
   --  Type: Library
   --  a C library
   --=====
   type Library is private;

   --=====
   --  Type: String_Array
   --  an array of strings
   --=====
   type String_Array is array(Positive range <>) of Unbounded_String;
   Empty_String_Array: constant String_Array :=
     (1..0 => Null_Unbounded_String);


   --=====
   --  Procedure: Init_Library
   --  Initialize in a new library.
   --
   --  Parameters:
   --  Name    - name of the library.  the code and header file will be called
   --            Name.c and Name.h
   --  Comment - a comment to put in the header of the code and header file
   --  Path    - absolute path of the directory in which the library must be
   --            created
   --  Lib     - the library created
   --  Include - a list of header files that must be included in the header
   --            file of the generated library
   --=====
   procedure Init_Library
     (Name    : in     String;
      Comment : in     String;
      Path    : in     String;
      Lib     :    out Library;
      Included: in     String_Array := Empty_String_Array);

   --=====
   --  Procedure: End_Library
   --  End the library.
   --=====
   procedure End_Library
     (L: in out Library);

   --=====
   --  Procedure: Nlh
   --  New line in the header file.
   --=====
   procedure Nlh
     (L: in Library;
      N: in Natural := 1);

   --=====
   --  Procedure: Ph
   --  Put string S in the header file of the library and place T
   --  tabulations before S.
   --=====
   procedure Ph
     (L: in Library;
      S: in String;
      T: in Natural := 0);

   --=====
   --  Procedure: Ph
   --  Put string S in the header file of the library and place T
   --  tabulations before S.
   --=====
   procedure Ph
     (L: in Library;
      S: in Unbounded_String;
      T: in Natural := 0);

   --=====
   --  Procedure: Ph
   --  Put string S in the header file of the library and place T
   --  tabulations before S.
   --=====
   procedure Ph
     (L: in Library;
      T: in Natural;
      S: in String);

   --=====
   --  Procedure: Ph
   --  Put string S in the header file of the library and place T
   --  tabulations before S.
   --=====
   procedure Ph
     (L: in Library;
      T: in Natural;
      S: in Unbounded_String);

   --=====
   --  Procedure: Plh
   --  Put-line string S in the header file of the library and place T
   --  tabulations before S.
   --=====
   procedure Plh
     (L: in Library;
      S: in String;
      T: in Natural := 0);

   --=====
   --  Procedure: Plh
   --  Put-line string S in the header file of the library and place T
   --  tabulations before S.
   --=====
   procedure Plh
     (L: in Library;
      S: in Unbounded_String;
      T: in Natural := 0);

   --=====
   --  Procedure: Plh
   --  Put-line string S in the header file of the library and place T
   --  tabulations before S.
   --=====
   procedure Plh
     (L: in Library;
      T: in Natural;
      S: in String);

   --=====
   --  Procedure: Plh
   --  Put-line string S in the header file of the library and place T
   --  tabulations before S.
   --=====
   procedure Plh
     (L: in Library;
      T: in Natural;
      S: in Unbounded_String);

   --=====
   --  Procedure: Nlc
   --  New line in the code file.
   --=====
   procedure Nlc
     (L: in Library;
      N: in Natural := 1);

   --=====
   --  Procedure: Pc
   --  Put string S in the code file of the library and place T
   --  tabulations before S.
   --=====
   procedure Pc
     (L: in Library;
      S: in String;
      T: in Natural := 0);

   --=====
   --  Procedure: Pc
   --  Put string S in the code file of the library and place T
   --  tabulations before S.
   --=====
   procedure Pc
     (L: in Library;
      S: in Unbounded_String;
      T: in Natural := 0);

   --=====
   --  Procedure: Pc
   --  Put string S in the code file of the library and place T
   --  tabulations before S.
   --=====
   procedure Pc
     (L: in Library;
      T: in Natural;
      S: in String);

   --=====
   --  Procedure: Pc
   --  Put string S in the code file of the library and place T
   --  tabulations before S.
   --=====
   procedure Pc
     (L: in Library;
      T: in Natural;
      S: in Unbounded_String);

   --=====
   --  Procedure: Plc
   --  Put-line string S in the code file of the library L and place T
   --  tabulations before S.
   --=====
   procedure Plc
     (L: in Library;
      S: in String;
      T: in Natural := 0);

   --=====
   --  Procedure: Plc
   --  Put-line string S in the code file of the library L and place T
   --  tabulations before S.
   --=====
   procedure Plc
     (L: in Library;
      S: in Unbounded_String;
      T: in Natural := 0);

   --=====
   --  Procedure: Plc
   --  Put-line string S in the code file of the library L and place T
   --  tabulations before S.
   --=====
   procedure Plc
     (L: in Library;
      T: in Natural;
      S: in String);

   --=====
   --  Procedure: Plc
   --  Put-line string S in the code file of the library L and place T
   --  tabulations before S.
   --=====
   procedure Plc
     (L: in Library;
      T: in Natural;
      S: in Unbounded_String);

   --=====
   --  Procedure: Section_Start_Comment
   --  Comment the begining of a section.
   --=====
   procedure Section_Start_Comment
     (L      : in Library;
      Comment: in Unbounded_String);

   --=====
   --  Procedure: Section_Start_Comment
   --  Comment the begining of a section.
   --=====
   procedure Section_Start_Comment
     (L      : in Library;
      Comment: in String);

   --=====
   --  Procedure: Section_End_Comment
   --  Comment the end of a section.
   --=====
   procedure Section_End_Comment
     (L: in Library);

   --=====
   --  Procedure: Function_Header
   --  Comment the header of a function.
   --=====
   procedure Function_Header
     (L      : in Library;
      Comment: in Unbounded_String);

   --=====
   --  Function: Get_Header_File
   --  Return an access to the header file of libary L.
   --=====
   function Get_Header_File
     (L: in Library) return access File_Type;

   --=====
   --  Function: Get_Code_File
   --  Return an access to the code file of libary L.
   --=====
   function Get_Code_File
     (L: in Library) return access File_Type;

   --=====
   --  Constant: Header_Extension
   --  extension of header files
   --=====
   Header_Extension: constant Unbounded_String;

   --=====
   --  Constant: Code_Extension
   --  extension of code files
   --=====
   Code_Extension  : constant Unbounded_String;

   --=====
   --  Constant: Object_Extension
   --  extension of object files
   --=====
   Object_Extension: constant Unbounded_String;

   --=====
   --  Constant: Null_Library
   --=====
   Null_Library: constant Library;


private


   type Library_Record is
      record
         N: Unbounded_String;   --  name of the library
         S: Unbounded_String;   --  current section
         H: aliased File_Type;  --  header file of the library
         C: aliased File_Type;  --  code file of the library
      end record;
   type Library is access all Library_Record;


   Header_Extension: constant Unbounded_String := To_Unbounded_String("h");
   Code_Extension  : constant Unbounded_String := To_Unbounded_String("c");
   Object_Extension: constant Unbounded_String := To_Unbounded_String("o");
   Tab             : constant String := "   ";
   Null_Library    : constant Library := null;

end Libraries;
