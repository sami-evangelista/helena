--=============================================================================
--
--  Package: Pn.Classes.Structs
--
--  This package implements structured color classes.  A structured color class
--  is exactly has a C struct type or an Ada record type: it contains
--  components which have name and color classes.  For example:
--  > type my_struct_type: struct {
--  >    int  i;
--  >    bool b;
--  > };
--
--=============================================================================


with
  Generic_Array;

package Pn.Classes.Structs is

   --=====
   --  Type: Struct_Comp
   --  a component of a structured class
   --=====
   type Struct_Comp is private;

   --=====
   --  Type: Struct_Comp_Array
   --  an array of components
   --=====
   type Struct_Comp_Array is array(Positive range <>) of Struct_Comp;

   --=====
   --  Type: Struct_Comp_List
   --  a list of components of a structured class
   --=====
   type Struct_Comp_List is private;

   --=====
   --  Type: Struct_Cls_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Struct_Cls_Record is new Cls_Record with private;

   --=====
   --  Type: Struct_Cls
   --=====
   type Struct_Cls is access all Struct_Cls_Record'Class;


   --==========================================================================
   --  Group: Component of a structured class
   --==========================================================================

   --=====
   --  Function: New_Struct_Comp
   --  Constructor.
   --
   --  Parameters:
   --     Name - name of the component
   --     C    - color class of the component
   --=====
   function New_Struct_Comp
     (Name: in Ustring;
      C   : in Cls) return Struct_Comp;

   --=====
   --  Function: Get_Name
   --  Get the name of component C.
   --=====
   function Get_Name
     (C: in Struct_Comp) return Ustring;

   --=====
   --  Procedure: Set_Name
   --  Set the name of component C to Name.
   --=====
   procedure Set_Name
     (C   : in out Struct_Comp;
      Name: in     Ustring);

   --=====
   --  Function: Get_Cls
   --  Get the color class of component C.
   --=====
   function Get_Cls
     (C: in Struct_Comp) return Cls;

   --=====
   --  Procedure: Set_Cls
   --  Set the color class of component C to Cl.
   --=====
   procedure Set_Cls
     (C: in out Struct_Comp;
      Cl: in     Cls);



   --==========================================================================
   --  Group: Component list of a structured class
   --==========================================================================

   --=====
   --  Function: New_Struct_Comp_List
   --  Constructor.  Returns an empty component list.
   --=====
   function New_Struct_Comp_List return Struct_Comp_List;

   --=====
   --  Function: New_Struct_Comp_List
   --  Constructor.  Return a component list which consists of all the
   --  components in array C.
   --=====
   function New_Struct_Comp_List
     (C: in Struct_Comp_Array) return Struct_Comp_List;

   --=====
   --  Procedure: Free
   --  Deallocator.
   --=====
   procedure Free
     (C: in out Struct_Comp_List);

   --=====
   --  Function: Length
   --  Return the length of list C.
   --=====
   function Length
     (C: in Struct_Comp_List) return Count_Type;

   --=====
   --  Function: Ith
   --  Return the Ith component of list C.
   --
   --  Pre-Conditions:
   --  o I is in [1..Length(C )]
   --=====
   function Ith
     (C: in Struct_Comp_List;
      I: in Index_Type) return Struct_Comp;

   --=====
   --  Function: Get_Index
   --  Return the index in C of the component called Name.
   --
   --  Pre-Conditions:
   --  o C has a component called Name.
   --=====
   function Get_Index
     (C   : in Struct_Comp_List;
      Name: in Ustring) return Index_Type;

   --=====
   --  Function: Get_Component
   --  Return the component of C called Name.
   --
   --  Pre-Conditions:
   --  o C has a component called Name.
   --=====
   function Get_Component
     (C   : in Struct_Comp_List;
      Name: in Ustring) return Struct_Comp;

   --=====
   --  Function: Contains
   --  Check if there is in list C a component called Name.
   --=====
   function Contains
     (C   : in Struct_Comp_List;
      Name: in Ustring) return Boolean;

   --=====
   --  Procedure: Append
   --  Add component Comp at the end of list C.
   --
   --  Pre-Conditions:
   --  o C has no component with the same name as Comp.
   --=====
   procedure Append
     (C   : in Struct_Comp_List;
      Comp: in Struct_Comp);



   --==========================================================================
   --  Group: Structured class
   --==========================================================================

   --=====
   --  Function: New_Struct_Cls
   --  Constructor.
   --
   --  Parameters:
   --  Name       - name of the color class
   --  Components - components of the class
   --=====
   function New_Struct_Cls
     (Name      : in Ustring;
      Components: in Struct_Comp_List) return Cls;

   --=====
   --  Function: Get_Components
   --  Return the component list of S.
   --=====
   function Get_Components
     (S: in Struct_Cls) return Struct_Comp_List;

   --=====
   --  Function: Contains_Component
   --  Check if S has a component called C.
   --=====
   function Contains_Component
     (S: in Struct_Cls;
      C: in Ustring) return Boolean;

   --=====
   --  Function: Get_Component
   --  Get the component of S called C.
   --
   --  Pre-Conditions:
   --  o S has a component called C
   --=====
   function Get_Component
     (S: in Struct_Cls;
      C: in Ustring) return Struct_Comp;

   --=====
   --  Function: Get_Component_Index
   --  Get the index of the component called C in the component list of S.
   --
   --  Pre-Conditions:
   --  o S has a component called C
   --=====
   function Get_Component_Index
     (S: in Struct_Cls;
      C: in Ustring) return Index_Type;

   --=====
   --  Function: Ith_Component
   --  Get the Ith component of the structured class S.
   --
   --  Pre-Conditions:
   --  o I is in [1..Length(Get_Components(S))]
   --=====
   function Ith_Component
     (S: in Struct_Cls;
      I: in Index_Type) return Struct_Comp;


private


   --==========================================================================
   --  Component of a structured class
   --==========================================================================

   type Struct_Comp is
      record
         Name: Ustring;  --  name of the component
         C   : Cls;      --  color of the component
      end record;

   Null_Component: constant Struct_Comp := (Null_String, null);



   --==========================================================================
   --  Component list of a structured class
   --==========================================================================

   package Struct_Comp_Array_Pkg is
      new Generic_Array(Struct_Comp, Null_Component, "=");

   type Struct_Comp_List_Record is
      record
         Components: Struct_Comp_Array_Pkg.Array_Type;  --  the components
      end record;
   type Struct_Comp_List is access all Struct_Comp_List_Record;

   procedure Compile
     (C  : in Struct_Comp_List;
      Lib: in Library);



   --==========================================================================
   --  Structured class
   --==========================================================================

   type Struct_Cls_Record is new Cls_Record with
      record
         Components: Struct_Comp_List;  --  components of the structured class
      end record;

   procedure Free
     (C: in out Struct_Cls_Record);

   function Get_Type
     (C: in Struct_Cls_Record) return Cls_Type;

   procedure Card
     (C     : in     Struct_Cls_Record;
      Result:    out Card_Type;
      State:    out Count_State);

   function Low_Value
     (C: in Struct_Cls_Record) return Expr;

   function High_Value
     (C: in Struct_Cls_Record) return Expr;

   function Ith_Value
     (C: in Struct_Cls_Record;
      I: in Card_Type) return Expr;

   function Get_Value_Index
     (C: in     Struct_Cls_Record;
      E: access Expr_Record'Class) return Card_Type;

   function Elements_Size
     (C: in Struct_Cls_Record) return Natural;

   function Basic_Elements_Size
     (C: in Struct_Cls_Record) return Natural;

   function Is_Const_Of_Cls
     (C: in     Struct_Cls_Record;
      E: access Expr_Record'Class) return Boolean;

   function Colors_Used
     (C: in Struct_Cls_Record) return Cls_Set;

   function Has_Constant_Bit_Width
     (C: in Struct_Cls_Record) return Boolean;

   function Bit_Width
     (C: in Struct_Cls_Record) return Natural;

   procedure Compile_Type_Definition
     (C  : in Struct_Cls_Record;
      Lib: in Library);

   procedure Compile_Constants
     (C  : in Struct_Cls_Record;
      Lib: in Library);

   procedure Compile_Operators
     (C  : in Struct_Cls_Record;
      Lib: in Library);

   procedure Compile_Encoding_Functions
     (C  : in Struct_Cls_Record;
      Lib: in Library);

   procedure Compile_Io_Functions
     (C  : in Struct_Cls_Record;
      Lib: in Library);

   procedure Compile_Hash_Function
     (C  : in Struct_Cls_Record;
      Lib: in Library);

   procedure Compile_Others
     (C  : in Struct_Cls_Record;
      Lib: in Library);

end Pn.Classes.Structs;
