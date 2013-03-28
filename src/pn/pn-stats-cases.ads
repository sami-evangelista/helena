--=============================================================================
--
--  Package: Pn.Stats.Cases
--
--  This package implements case statements.
--
--=============================================================================


with
  Generic_Array;

package Pn.Stats.Cases is

   type Case_Stat_Alternative is private;

   type Case_Stat_Alternative_Array is
     array(Positive range <>) of Case_Stat_Alternative;

   type Case_Stat_Alternative_List is private;

   type Case_Stat_Record is new Stat_Record with private;

   type Case_Stat is access all Case_Stat_Record;


   --==========================================================================
   --  Group: Case alternative
   --==========================================================================

   function New_Case_Stat_Alternative
     (E: in Expr;
      S: in Stat) return Case_Stat_Alternative;

   procedure Free
     (C: in out Case_Stat_Alternative);

   function Get_Expr
     (C: in Case_Stat_Alternative) return Expr;



   --==========================================================================
   --  Group: Case alternative list
   --==========================================================================

   function New_Case_Stat_Alternative_List return Case_Stat_Alternative_List;

   function New_Case_Stat_Alternative_List
     (C: in Case_Stat_Alternative_Array) return Case_Stat_Alternative_List;

   procedure Free
     (C: in out Case_Stat_Alternative_List);

   procedure Append
     (C : in Case_Stat_Alternative_List;
      Ca: in Case_Stat_Alternative);

   function Contains
     (C  : in Case_Stat_Alternative_List;
      Alt: in Expr) return Boolean;



   --==========================================================================
   --  Group: Case statement
   --==========================================================================

   function New_Case_Stat
     (E      : in Expr;
      Alt    : in Case_Stat_Alternative_List;
      Default: in Stat) return Stat;

   function New_Case_Stat
     (E  : in Expr;
      Alt: in Case_Stat_Alternative_List) return Stat;


private


   type Case_Stat_Alternative is
      record
         E: Expr;  --  constant expression for the alternative
         S: Stat;  --  statement executed if the evaluated expression match E
      end record;

   package Case_Stat_Alternative_Array_Pkg is
      new Generic_Array(Case_Stat_Alternative, (null, null), "=");

   type Case_Stat_Alternative_List_Record is
      record
         Alts: Case_Stat_Alternative_Array_Pkg.Array_Type; --  alternatives
      end record;
   type Case_Stat_Alternative_List is
     access all Case_Stat_Alternative_List_Record;

   type Case_Stat_Record is new Stat_Record with
      record
         E      : Expr;                       --  evaluated expression
         Alt    : Case_Stat_Alternative_List; --  alternatives
         Default: Stat;                       --  default alternative
      end record;

   procedure Free
     (S: in out Case_Stat_Record);

   function Copy
     (S: in Case_Stat_Record) return Stat;

   procedure Compile
     (S   : in Case_Stat_Record;
      Tabs: in Natural;
      Lib : in Library);

end Pn.Stats.Cases;
