--=============================================================================
--
--  Package: Pn.Stats.Assigns
--
--  This package implements assignment statements.
--
--=============================================================================


package Pn.Stats.Assigns is

   type Assign_Stat_Record is new Stat_Record with private;

   type Assign_Stat is access all Assign_Stat_Record;


   function New_Assign_Stat
     (Var: in Expr;
      Val: in Expr) return Stat;


private


   type Assign_Stat_Record is new Stat_Record with
      record
         Var: Expr; --  variable which is assigned a value
         Val: Expr; --  expression assigned
      end record;

   procedure Free
     (S: in out Assign_Stat_Record);

   function Copy
     (S: in Assign_Stat_Record) return Stat;

   procedure Compile
     (S   : in Assign_Stat_Record;
      Tabs: in Natural;
      Lib : in Library);

end Pn.Stats.Assigns;
