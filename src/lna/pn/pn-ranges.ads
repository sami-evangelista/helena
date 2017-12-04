--=============================================================================
--
--  Package: Pn.Ranges
--
--  This package implements ranges which are used by iteration variables, e.g.,
--  for(i in int range 1..10)
--
--  The possibilities for a range are:
--    - a low-high range, i.e., low..high
--
--=============================================================================


package Pn.Ranges is

   --  a range
   type Range_Spec_Record is abstract tagged private;
   type Range_Spec is access all Range_Spec_Record'Class;

   --  a range in the form low..high
   type Low_High_Range_Record is new Range_Spec_Record with private;
   type Low_High_Range is access all Low_High_Range_Record;


   --==========================================================================
   --  a range
   --==========================================================================

   --===
   --  Procedure: Free
   --===
   procedure Free
     (R: in out Range_Spec);
   procedure Free
     (R: in out Range_Spec_Record) is abstract;

   --===
   --  Function: Copy
   --===
   function Copy
     (R: access Range_Spec_Record'Class) return Range_Spec;
   function Copy
     (R: in Range_Spec_Record) return Range_Spec is abstract;

   --===
   --  Function: Get_Low
   --===
   function Get_Low
     (R: access Range_Spec_Record'Class) return Expr;
   function Get_Low
     (R: in Range_Spec_Record) return Expr is abstract;

   --===
   --  Function: Get_High
   --===
   function Get_High
     (R: access Range_Spec_Record'Class) return Expr;
   function Get_High
     (R: in Range_Spec_Record) return Expr is abstract;

   --===
   --  Function: Get_Low_Value_Index
   --===
   function Get_Low_Value_Index
     (R: access Range_Spec_Record'Class) return Num_Type;

   --===
   --  Function: Get_High_Value_Index
   --===
   function Get_High_Value_Index
     (R: access Range_Spec_Record'Class) return Num_Type;

   --===
   --  Function: Is_Static
   --===
   function Is_Static
     (R: access Range_Spec_Record'Class) return Boolean;
   function Is_Static
     (R: in Range_Spec_Record) return Boolean is abstract;

   --===
   --  Function: Is_Positive
   --===
   function Is_Positive
     (R: access Range_Spec_Record'Class) return Boolean;

   --===
   --  Function: Static_Size
   --===
   function Static_Size
     (R: access Range_Spec_Record'Class) return Card_Type;

   --===
   --  Function: Size
   --===
   function Size
     (R: access Range_Spec_Record'Class;
      B: in     Binding) return Card_Type;

   --===
   --  Function: Static_Enum_Values
   --===
   function Static_Enum_Values
     (R: access Range_Spec_Record'Class) return Expr_List;

   --===
   --  Function: Vars_In
   --  Return the list of variables appearing in the range.
   --===
   function Vars_In
     (R: access Range_Spec_Record'Class) return Var_List;
   function Vars_In
     (R: in Range_Spec_Record) return Var_List is abstract;

   --===
   --  Function: Replace_Var
   --  Replace in range R all the occurrences of variable V by expression E.
   --===
   procedure Replace_Var
     (R: access Range_Spec_Record'Class;
      V: in     Var;
      E: in     Expr);
   procedure Replace_Var
     (R: in out Range_Spec_Record;
      V: in     Var;
      E: in     Expr) is abstract;

   --===
   --  Function: To_Helena
   --  Return the string corresponding to the range in helena format.
   --===
   function To_Helena
     (R: access Range_Spec_Record'Class) return Ustring;
   function To_Helena
     (R: in Range_Spec_Record) return Ustring is abstract;



   --==========================================================================
   --  a range in the form low..high
   --==========================================================================

   --===
   --  Function: New_Low_High_Range
   --===
   function New_Low_High_Range
     (Low : in Expr;
      High: in Expr) return Range_Spec;


private


   --==========================================================================
   --  a range
   --==========================================================================

   type Range_Spec_Record is abstract tagged
      record
         null;
      end record;



   --==========================================================================
   --  a range in the form low..high
   --==========================================================================

   type Low_High_Range_Record is new Range_Spec_Record with
      record
         Low : Expr;  --  lower bound of the range
         High: Expr;  --  upper bound of the range
      end record;

   procedure Free
     (R: in out Low_High_Range_Record);

   function Copy
     (R: in Low_High_Range_Record) return Range_Spec;

   function Get_Low
     (R: in Low_High_Range_Record) return Expr;

   function Get_High
     (R: in Low_High_Range_Record) return Expr;

   function Is_Static
     (R: in Low_High_Range_Record) return Boolean;

   function Vars_In
     (R: in Low_High_Range_Record) return Var_List;

   procedure Replace_Var
     (R: in out Low_High_Range_Record;
      V: in     Var;
      E: in     Expr);

   function To_Helena
     (R: in Low_High_Range_Record) return Ustring;

end Pn.Ranges;
