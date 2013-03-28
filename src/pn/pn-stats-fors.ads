--=============================================================================
--
--  Package: Pn.Stats.Fors
--
--  This package implements for-loop statements.
--
--=============================================================================


with
  Pn.Vars.Iter;

use
  Pn.Vars.Iter;

package Pn.Stats.Fors is

   type For_Stat_Record is new Stat_Record with private;

   type For_Stat is access all For_Stat_Record;


   function New_For_Stat
     (I: in Iter_Scheme;
      S: in Stat) return Stat;


private


   type For_Stat_Record is new Stat_Record with
      record
         I: Iter_Scheme;  --  iteration scheme
         S: Stat;         --  statement enclosed in the for
      end record;

   procedure Free
     (S: in out For_Stat_Record);

   function Copy
     (S: in For_Stat_Record) return Stat;

   procedure Compile
     (S   : in For_Stat_Record;
      Tabs: in Natural;
      Lib : in Library);

end Pn.Stats.Fors;
