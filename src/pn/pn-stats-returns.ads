--=============================================================================
--
--  Package: Pn.Stats.Returns
--
--  This package implements return statements that appear in functions.
--
--=============================================================================


package Pn.Stats.Returns is

   type Return_Stat_Record is new Stat_Record with private;

   type Return_Stat is access all Return_Stat_Record;


   function New_Return_Stat
     (Ret_Expr: in Expr) return Stat;


private


   type Return_Stat_Record is new Stat_Record with
      record
         Ret_Expr: Expr; --  the expression returned
      end record;

   procedure Free
     (S: in out Return_Stat_Record);

   function Copy
     (S: in Return_Stat_Record) return Stat;

   procedure Compile
     (S   : in Return_Stat_Record;
      Tabs: in Natural;
      Lib : in Library);

end Pn.Stats.Returns;
