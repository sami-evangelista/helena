--=============================================================================
--
--  Package: Pn.Stats.Whiles
--
--  This package implements while-loops statements.
--
--=============================================================================


package Pn.Stats.Whiles is

   type While_Stat_Record is new Stat_Record with private;

   type While_Stat is access all While_Stat_Record;


   function New_While_Stat
     (Cond_Expr: in Expr;
      True_Stat: in Stat) return Stat;


private


   type While_Stat_Record is new Stat_Record with
      record
         Cond_Expr: Expr; --  expression of the while
         True_Stat: Stat; --  statement enclosed in the while
      end record;

   procedure Free
     (S: in out While_Stat_Record);

   function Copy
     (S: in While_Stat_Record) return Stat;

   procedure Compile
     (S   : in While_Stat_Record;
      Tabs: in Natural;
      Lib : in Library);

end Pn.Stats.Whiles;
