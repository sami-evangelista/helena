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

   type Library is private;

   type String_Array is array(Positive range <>) of Unbounded_String;
   Empty_String_Array: constant String_Array :=
     (1..0 => Null_Unbounded_String);

   procedure Init_Library
     (Name    : in     String;
      Comment : in     String;
      Path    : in     String;
      Lib     :    out Library;
      Included: in     String_Array := Empty_String_Array);

   procedure End_Library
     (L: in out Library);

   procedure Nlh
     (L: in Library;
      N: in Natural := 1);

   procedure Ph
     (L: in Library;
      S: in String;
      T: in Natural := 0);

   procedure Ph
     (L: in Library;
      S: in Unbounded_String;
      T: in Natural := 0);

   procedure Ph
     (L: in Library;
      T: in Natural;
      S: in String);

   procedure Ph
     (L: in Library;
      T: in Natural;
      S: in Unbounded_String);

   procedure Plh
     (L: in Library;
      S: in String;
      T: in Natural := 0);

   procedure Plh
     (L: in Library;
      S: in Unbounded_String;
      T: in Natural := 0);

   procedure Plh
     (L: in Library;
      T: in Natural;
      S: in String);

   procedure Plh
     (L: in Library;
      T: in Natural;
      S: in Unbounded_String);

   procedure Nlc
     (L: in Library;
      N: in Natural := 1);

   procedure Pc
     (L: in Library;
      S: in String;
      T: in Natural := 0);

   procedure Pc
     (L: in Library;
      S: in Unbounded_String;
      T: in Natural := 0);

   procedure Pc
     (L: in Library;
      T: in Natural;
      S: in String);
   
   procedure Pc
     (L: in Library;
      T: in Natural;
      S: in Unbounded_String);
   
   procedure Plc
     (L: in Library;
      S: in String;
      T: in Natural := 0);
   
   procedure Plc
     (L: in Library;
      S: in Unbounded_String;
      T: in Natural := 0);
   
   procedure Plc
     (L: in Library;
      T: in Natural;
      S: in String);
   
   procedure Plc
     (L: in Library;
      T: in Natural;
      S: in Unbounded_String);
   
   procedure Section_Start_Comment
     (L      : in Library;
      Comment: in Unbounded_String);
   
   procedure Section_Start_Comment
     (L      : in Library;
      Comment: in String);

   procedure Section_End_Comment
     (L: in Library);

   function Get_Header_File
     (L: in Library) return access File_Type;

   function Get_Code_File
     (L: in Library) return access File_Type;

   Header_Extension: constant Unbounded_String;

   Code_Extension  : constant Unbounded_String;

   Object_Extension: constant Unbounded_String;

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
