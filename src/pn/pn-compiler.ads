--=============================================================================
--
--  Package: Pn.Compiler
--
--  This is the basic package for the compilation of a high level net
--  into a set of C source files.  Sub-packages are used to generate
--  libraries.  All the source files are generated in a single
--  directory that we will call the net directory.
--
--=============================================================================


with
  Pn.Exprs,
  Pn.Funcs,
  Pn.Nodes.Places,
  Pn.Nets,
  Pn.Nodes.Transitions;

use
  Pn.Exprs,
  Pn.Funcs,
  Pn.Nodes.Places,
  Pn.Nets,
  Pn.Nodes.Transitions;

package Pn.Compiler is

   --==========================================================================
   --  Group: Generation procedures
   --==========================================================================

   procedure Gen
     (N          : in Net;
      Net_Path   : in Ustring;
      Helena_File: in Ustring);

   procedure Gen_Interfaces
     (N        : in Net;
      File_Path: in Ustring);



   --==========================================================================
   --  Group: Useful functions
   --==========================================================================

   function Get_Printable_String
     (Str: in Ustring) return Ustring;

   function Const_Name
     (Const: in String) return Ustring;

   function Lib_Init_Func
     (Lib_Name: in Ustring) return Ustring;

   function Lib_Free_Func
     (Lib_Name: in Ustring) return Ustring;

   procedure Init_Library
     (Name   : in     Ustring;
      Comment: in     Ustring;
      Path   : in     Ustring;
      Lib    :    out Library);

   procedure Init_Library
     (Name    : in     Ustring;
      Comment : in     Ustring;
      Path    : in     Ustring;
      Included: in     Libraries.String_Array;
      Lib     :    out Library);

   function Get_Net_Path return Ustring;



   --==========================================================================
   --  Group: Types and subtypes
   --==========================================================================

   type Firing_Mode is
     (Firing,
      Unfiring);

   type Lib is
      record
         Lib_Name: Ustring; --  name of the library
         Lib_Desc: Ustring; --  description of the library
         Lib_Path: Ustring; --  path of the library
      end record;


private


   --==========================================================================
   --  Private constants
   --==========================================================================

   type String_Array is array(Positive range <>) of Ustring;

   No_File          : constant Ustring := Null_String;
   Library_Prefix   : constant Ustring := To_Ustring("lib_");
   Construct_Prefix : constant Ustring := To_Ustring("construct_");
   Const_Prefix     : constant Ustring := To_Ustring("const_");
   Marking_Type_Size: constant Natural := 1;



   --==========================================================================
   --  Private constants corresponding to static libraries
   --==========================================================================

   Util_Lib            : constant Ustring := To_Ustring("model_util");
   Colors_Lib          : constant Ustring := To_Ustring("colors");
   Constants_Lib       : constant Ustring := To_Ustring("constants");
   Domains_Lib         : constant Ustring := To_Ustring("domains");
   Funcs_Lib           : constant Ustring := To_Ustring("funcs");
   State_Lib           : constant Ustring := To_Ustring("mstate");
   Mappings_Lib        : constant Ustring := To_Ustring("mappings");
   Event_Lib           : constant Ustring := To_Ustring("mevent");
   Event_Set_Lib       : constant Ustring := To_Ustring("mevent_set");
   Enabling_Test_Lib   : constant Ustring := To_Ustring("enabling_test");
   Por_Lib             : constant Ustring := To_Ustring("por");
   Model_Lib           : constant Ustring := To_Ustring("model");
   Interfaces_File     : constant Ustring := To_Ustring("interfaces");
   Graph_Lib           : constant Ustring := To_Ustring("model_graph");



   --==========================================================================
   --  Group: Global variables
   --==========================================================================

   Helena_File: Ustring;
   Net_Path   : Ustring;

end Pn.Compiler;
