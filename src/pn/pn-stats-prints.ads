--=============================================================================
--
--  Package: Pn.Stats.Prints
--
--  This package implements print statements:
--  print "%d = %d\n", x, y;
--  print my_list, my_struct;
--
--=============================================================================


with
  Pn.Funcs,
  Pn.Guards;

use
  Pn.Funcs,
  Pn.Guards;

package Pn.Stats.Prints is

   type Print_Stat_Record is new Stat_Record with private;

   type Print_Stat is access all Print_Stat_Record;


   function New_Print_Stat
     (With_Str: in Boolean;
      Str     : in String;
      E       : in Expr_List) return Stat;


private


   type Print_Stat_Record is new Stat_Record with
      record
	 With_Str: Boolean;
	 Str     : Ustring;
	 E       : Expr_List;
      end record;

   procedure Free
     (S: in out Print_Stat_Record);

   function Copy
     (S: in Print_Stat_Record) return Stat;

   procedure Compile
     (S   : in Print_Stat_Record;
      Tabs: in Natural;
      Lib : in Library);

end Pn.Stats.Prints;
