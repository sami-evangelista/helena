--=============================================================================
--
--  Package: Pn.Stats.Asserts
--
--  This package implements assertion statements:
--  assert: X > 0;
--
--=============================================================================


with
  Pn.Funcs,
  Pn.Guards;

use
  Pn.Funcs,
  Pn.Guards;

package Pn.Stats.Asserts is

   type Assert_Stat_Record is new Stat_Record with private;

   type Assert_Stat is access all Assert_Stat_Record;


   function New_Assert_Stat
     (A: in Assert;
      F: in Func) return Stat;


private


   type Assert_Stat_Record is new Stat_Record with
      record
         A: Assert; --  the assertion
         F: Func;   --  the function in which the assertion appears
      end record;

   procedure Free
     (S: in out Assert_Stat_Record);

   function Copy
     (S: in Assert_Stat_Record) return Stat;

   procedure Compile
     (S   : in Assert_Stat_Record;
      Tabs: in Natural;
      Lib : in Library);

end Pn.Stats.Asserts;
