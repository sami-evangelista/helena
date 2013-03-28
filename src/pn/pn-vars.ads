--=============================================================================
--
--  Package: Pn.Vars
--
--  This package implement variables.  There are different kind of variables:
--  o transition variables.  See <Pn.Vars.Trans_Vars>.
--  o net constants.  See <Pn.Vars.Net_Consts>.
--  o iteration variables.  See <Pn.Vars.Iter>.
--  o function parameters.  See <Pn.Vars.Func_Params>.
--  o function variables.  See <Pn.Vars.Func_Vars>.
--
--=============================================================================


package Pn.Vars is

   --==========================================================================
   --  Group: Variable
   --==========================================================================

   procedure Initialize
     (V   : access Var_Record'Class;
      Name: in     Ustring;
      C   : in     Cls);

   procedure Free
     (V: in out Var);

   function Copy
     (V: access Var_Record'Class) return Var;

   function Get_Name
     (V: access Var_Record'Class) return Ustring;

   procedure Set_Name
     (V: access Var_Record'Class;
      N: in     Ustring);

   function Get_Cls
     (V: access Var_Record'Class) return Cls;

   procedure Set_Cls
     (V: access Var_Record'Class;
      C: in     Cls);

   function Is_Const
     (V: access Var_Record'Class) return Boolean;

   function Is_Static
     (V: access Var_Record'Class) return Boolean;

   function Get_Init
     (V: access Var_Record'Class) return Expr;

   procedure Set_Init
     (V: access Var_Record'Class;
      E: in     Expr);

   function Get_Type
     (V: access Var_Record'Class) return Var_Type;

   procedure Replace_Var_In_Def
     (V: access Var_Record'Class;
      R: in     Var;
      E: in     Expr);

   function To_Helena
     (V: access Var_Record'Class) return Ustring;

   procedure Compile_Definition
     (V   : access Var_Record'Class;
      Tabs: in     Natural;
      File: in     File_Type);

   function Compile_Access
     (V: access Var_Record'Class;
      M: in     Var_Mapping) return Ustring;



   --==========================================================================
   --  Group: Variable list
   --==========================================================================

   function New_Var_List return Var_List;

   function New_Var_List
     (V: in Var_Array) return Var_List;

   procedure Free_All
     (V: in out Var_List);

   procedure Free
     (V: in out Var_List);

   function Length
     (V: in Var_List) return Count_Type;

   function Is_Empty
     (V: in Var_List) return Boolean;

   function Copy
     (V: in Var_List) return Var_List;

   function Copy_All
     (V: in Var_List) return Var_List;

   function Ith
     (V: in Var_List;
      I: in Index_Type) return Var;

   procedure Append
     (V : in Var_List;
      Va: in Var);

   procedure Delete
     (V : in Var_List;
      Va: in Var);

   procedure Union
     (V1: in Var_List;
      V2: in Var_List);

   procedure Intersect
     (V1: in Var_List;
      V2: in Var_List);

   procedure Difference
     (V1: in Var_List;
      V2: in Var_List);

   function Included
     (V1: in Var_List;
      V2: in Var_List) return Boolean;

   function Get_Index
     (V: in Var_List;
      N: in Ustring) return Index_Type;

   function Get_Index
     (V: in     Var_List;
      Va: access Var_Record'Class) return Index_Type;

   function Get
     (V: in Var_List;
      N: in Ustring) return Var;

   function Contains
     (V : in Var_List;
      Va: in Ustring) return Boolean;

   function Contains
     (V : in Var_List;
      Va: in Var) return Boolean;

   function Equal
     (V1: in Var_List;
      V2: in Var_List) return Boolean;

   function Check_Type
     (V: in Var_List;
      T: in Var_Type_Set) return Boolean;

   generic
      with function Predicate(V: in Var) return Boolean;
   procedure Generic_Delete_Vars
     (V: in Var_List);

   function To_String
     (V: in Var_List) return Ustring;

   function To_Helena
     (V: in Var_List) return Ustring;

   procedure Compile_Definition
     (V   : in Var_List;
      Tabs: in Natural;
      File: in File_Type);

end Pn.Vars;
