--=============================================================================
--
--  Package: Pn.Stats.Ifs
--
--  This package implements if-then-else statements.
--
--=============================================================================


package Pn.Stats.Ifs is

   type If_Stat_Record is new Stat_Record with private;

   type If_Stat is access all If_Stat_Record;


   function New_If_Stat
     (Cond_Expr : in Expr;
      True_Stat : in Stat;
      False_Stat: in Stat) return Stat;

   function New_If_Stat
     (Cond_Expr: in Expr;
      True_Stat: in Stat) return Stat;


private


   type If_Stat_Record is new Stat_Record with
      record
         Cond_Expr : Expr;  --  expression of the if statement
         True_Stat : Stat;  --  statement executed if the condition is
			    --  evaluated to true
         False_Stat: Stat;  --  statement executed if the condition is
			    --  evaluated to false (can be null if the if
			    --  statement does not have an else part)
      end record;

   procedure Free
     (S: in out If_Stat_Record);

   function Copy
     (S: in If_Stat_Record) return Stat;

   procedure Compile
     (S   : in If_Stat_Record;
      Tabs: in Natural;
      Lib : in Library);

end Pn.Stats.Ifs;
