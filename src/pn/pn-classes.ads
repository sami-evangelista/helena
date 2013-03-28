--=============================================================================
--
--  Package: Pn.Classes
--
--  This package implement color classes.  A color class is a type in the
--  colored Petri nets terminology.  There are different kinds of color
--  classes.
--  o enumeration classes.  See <Pn.Classes.Discretes.Enums>
--  o numerical classes.  See <Pn.Classes.Discretes.Nums>
--  o vector classes.  See <Pn.Classes.Vectors>
--  o structured classes.  See <Pn.Classes.Structs>
--  o list classes.  See <Pn.Classes.Containers.Lists>
--  o set classes.  See <Pn.Classes.Containers.Sets>
--  o product classes.  See <Pn.Classes.Products>
--
--=============================================================================


package Pn.Classes is

   --==========================================================================
   --  Group: Color class
   --==========================================================================

   procedure Initialize
     (C   : access Cls_Record'Class;
      Name: in     Ustring);

   function Get_Name
     (C: access Cls_Record'Class) return Ustring;

   procedure Set_Name
     (C   : access Cls_Record'Class;
      Name: in     Ustring);

   procedure Free
     (C: in out Cls);

   function Get_Type
     (C: access Cls_Record'Class) return Cls_Type;

   procedure Card
     (C     : access Cls_Record'Class;
      Result:    out Card_Type;
      State:    out Count_State);

   function Low_Value
     (C: access Cls_Record'Class) return Expr;

   function High_Value
     (C: access Cls_Record'Class) return Expr;

   function Ith_Value
     (C: access Cls_Record'Class;
      I: in     Card_Type) return Expr;

   function Get_Value_Index
     (C: access Cls_Record'Class;
      E: access Expr_Record'Class) return Card_Type;

   function Elements_Size
     (C: access Cls_Record'Class) return Natural;

   function Basic_Elements_Size
     (C: access Cls_Record'Class) return Natural;

   function Is_Const_Of_Cls
     (C: access Cls_Record'Class;
      E: access Expr_Record'Class) return Boolean;

   function Is_Discrete
     (C: access Cls_Record'Class) return Boolean;

   function Colors_Used
     (C: access Cls_Record'Class) return Cls_Set;

   function Has_Constant_Bit_Width
     (C: access Cls_Record'Class) return Boolean;

   function Bit_Width
     (C: access Cls_Record'Class) return Natural;

   function Get_Root_Cls
     (C: access Cls_Record'Class) return Cls;

   function Is_Castable
     (C: access Cls_Record'Class;
      To: access Cls_Record'Class) return Boolean;

   function Is_Sub_Cls
     (C: access Cls_Record'Class) return Boolean;

   function Is_Sub_Cls
     (C     : access Cls_Record'Class;
      Parent: access Cls_Record'Class) return Boolean;

   function Is_Container_Cls
     (C: access Cls_Record'Class) return Boolean;

   function To_Pnml
     (C: access Cls_Record'Class) return Ustring;

   procedure Compile
     (C  : access Cls_Record'Class;
      Lib: in     Library);

   generic
      with procedure Action(C: in Cls);
   procedure Generic_Apply_In_Right_Order
     (Set             : in Cls_Set;
      Apply_Predefined: in Boolean);



   --==========================================================================
   --  Group: Color domain
   --==========================================================================

   function New_Dom return Dom;

   function New_Dom
     (C: in Cls) return Dom;

   function New_Dom
     (D: in Cls_Array) return Dom;

   procedure Free
     (D: in out Dom);

   function Copy
     (D: in Dom) return Dom;

   function Size
     (D: in Dom) return Count_Type;

   procedure Card
     (D     : in     Dom;
      Result:    out Card_Type;
      State :    out Count_State);

   function Ith_Value
     (D: in Dom;
      I: in Card_Type) return Expr_List;

   function Get_Index
     (D: in Dom;
      T: in Expr_List) return Card_Type;

   function Ith
     (D: in Dom;
      I: in Index_Type) return Cls;

   procedure Insert
     (D: in Dom;
      C: in Cls;
      I: in Index_Type);

   procedure Append
     (D: in Dom;
      C: in Cls);

   procedure Append
     (D: in Dom;
      E: in Dom);

   procedure Delete
     (D: in Dom;
      I: in Index_Type);

   procedure Delete_Last
     (D: in Dom);

   function Same
     (D1: in Dom;
      D2: in Dom) return Boolean;

   function Has_Constant_Bit_Width
     (D: in Dom) return Boolean;

   function Bit_Width
     (D: in Dom) return Natural;

   function Slot_Width
     (D: in Dom) return Natural;

   function To_Helena
     (D: in Dom) return Ustring;

   Null_Dom: constant Dom;



   --==========================================================================
   --  Group: Color class set
   --==========================================================================

   function New_Cls_Set return Cls_Set;

   function New_Cls_Set
     (Set: in Cls_Array) return Cls_Set;

   procedure Free
     (Set: in out Cls_Set);

   procedure Free_All
     (Set: in out Cls_Set);

   function Copy
     (Set: in Cls_Set) return Cls_Set;

   procedure Insert
     (Set: in Cls_Set;
      C  : in Cls);

   function Ith
     (Set: in Cls_Set;
      I  : in Index_Type) return Cls;

   function Card
     (Set: in Cls_Set) return Count_Type;

   function Is_Empty
     (Set: in Cls_Set) return Boolean;

   function Contains
     (Set: in Cls_Set;
      C  : in Cls) return Boolean;

   function Contains
     (Set: in Cls_Set;
      C  : in Ustring) return Boolean;

   function Get
     (Set: in Cls_Set;
      C  : in Ustring) return Cls;

   function Subset
     (Sub: in Cls_Set;
      Set: in Cls_Set) return Boolean;

   function Equal
     (Set1: in Cls_Set;
      Set2: in Cls_Set) return Boolean;

   function Intersect
     (Set1: in Cls_Set;
      Set2: in Cls_Set) return Cls_Set;

   procedure Filter_On_Type
     (Set  : in Cls_Set;
      Types: in Cls_Type_Set);

   function Filter_On_Type
     (Set  : in Cls_Set;
      Types: in Cls_Type_Set) return Cls_Set;

   generic
      with function Predicate(C: in Cls) return Boolean;
   function Generic_Filter_On_Type
     (Set  : in Cls_Set;
      Types: in Cls_Type_Set) return Cls_Set;

   generic
      with function Predicate(C: in Cls) return Boolean;
   function Generic_Filter
     (Set: in Cls_Set) return Cls_Set;

   function Get_Types
     (Set: in Cls_Set) return Cls_Type_Set;

   procedure Choose
     (Set  : in     Cls_Set;
      C    :    out Cls;
      State:    out Coloring_State);

   function Get_Root_Cls
     (Set: in Cls_Set) return Cls_Set;

   function To_String
     (Set: in Cls_Set) return Ustring;

   procedure Compile
     (Set: in Cls_Set;
      Lib: in Library);

   procedure Compile_Type_Definitions
     (Set: in Cls_Set;
      Lib: in Library);



   --==========================================================================
   --  Group: Predefined color classes
   --==========================================================================

   function Get_Predefined_Cls return Cls_Array;

   function Is_Predefined_Cls
     (C: in Ustring) return Boolean;

   function Get_Predefined_Cls
     (C: in Ustring) return Cls;

   function Bool_Cls return Cls;

   function Int_Cls return Cls;

   function Nat_Cls return Cls;

   function Short_Cls return Cls;

   function Unsigned_Short_Cls return Cls;

   Bool_Cls_Name: constant Ustring;

   Int_Cls_Name: constant Ustring;

   Nat_Cls_Name: constant Ustring;

   Short_Cls_Name: constant Ustring;

   Unsigned_Short_Cls_Name: constant Ustring;

   False_Const_Name: constant Ustring;

   True_Const_Name: constant Ustring;


private


   Null_Dom               : constant Dom := null;
   Bool_Cls_Name          : constant Ustring := To_Ustring("bool");
   Int_Cls_Name           : constant Ustring := To_Ustring("int");
   Nat_Cls_Name           : constant Ustring := To_Ustring("nat");
   Short_Cls_Name         : constant Ustring := To_Ustring("short");
   Unsigned_Short_Cls_Name: constant Ustring := To_Ustring("ushort");
   False_Const_Name       : constant Ustring := To_Ustring("false");
   True_Const_Name        : constant Ustring := To_Ustring("true");

   procedure Add_Predefined_Cls
     (C: in Cls);

end Pn.Classes;
