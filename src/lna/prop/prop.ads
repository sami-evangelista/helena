--=============================================================================
--
--  Package: Prop
--
--  This is the base package for properties that can be verified by
--  Helena.
--
--=============================================================================


with
  Ada.Strings.Unbounded,
  Ada.Unchecked_Deallocation,
  Generic_Array,
  Libraries,
  Utils,
  Utils.Generics,
  Utils.Strings;

use
  Ada.Strings.Unbounded,
  Libraries,
  Utils,
  Utils.Generics,
  Utils.Strings;

package Prop is

   type Property_Record is abstract tagged private;

   type Property is access all Property_Record'Class;

   type Property_Array is array(Positive range <>) of Property;

   type Property_List is private;


   --==========================================================================
   --  Group: Type of a property
   --==========================================================================

   type Property_Type is
     (A_Ltl_Property,
      A_State_Property,
      A_Deadlock_Property);



   --==========================================================================
   --  Group: Property
   --==========================================================================

   procedure Initialize
     (P   : access Property_Record'Class;
      Name: in     Ustring);

   function Get_Type
     (P: in Property) return Property_Type;

   function Get_Name
     (P: in Property) return Ustring;

   procedure Set_Name
     (P   : in Property;
      Name: in Ustring);

   procedure Compile_Definition
     (P  : in Property;
      Lib: in Library;
      Dir: in String);

   function Get_Propositions
     (P: in Property) return Ustring_List;



   --==========================================================================
   --  Group: Primitive operations of type Property_Record
   --==========================================================================

   function Get_Type
     (P: in Property_Record) return Property_Type is abstract;

   procedure Compile_Definition
     (P  : in Property_Record;
      Lib: in Library;
      Dir: in String) is abstract;

   function Get_Propositions
     (P: in Property_Record) return Ustring_List is abstract;



   --==========================================================================
   --  Group: Property list
   --==========================================================================

   function New_Property_List return Property_List;

   function New_Property_List
     (P: in Property_Array) return Property_List;

   function Length
     (P: in Property_List) return Natural;

   function Ith
     (P: in Property_List;
      I: in Natural) return Property;

   procedure Append
     (P: in Property_List;
      Q: in Property);

   function Contains
     (P   : in Property_List;
      Name: in Ustring) return Boolean;

   function Get
     (P   : in Property_List;
      Name: in Ustring) return Property;



   Compilation_Exception: exception;


private


   --==========================================================================
   --  Property
   --==========================================================================

   type Property_Record is abstract tagged
      record
         Name: Ustring;
      end record;

   True_Property: constant Property := null;



   --==========================================================================
   --  Property list
   --==========================================================================

   package Property_Array_Pkg is new Generic_Array(Property, null, "=");

   type Property_List_Record is
      record
         Properties: Property_Array_Pkg.Array_Type;
      end record;
   type Property_List is access all Property_List_Record;

end Prop;
