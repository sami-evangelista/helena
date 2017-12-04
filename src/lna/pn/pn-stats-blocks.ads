--=============================================================================
--
--  Package: Pn.Stats.Blocks
--
--  This package implements blocks.  A block is a sequence of statements
--  possibly preceded by a list of variables or constants declaration.
--
--=============================================================================


package Pn.Stats.Blocks is

   type Block_Stat_Record is new Stat_Record with private;

   type Block_Stat is access all Block_Stat_Record;


   function New_Block_Stat
     (Vars: in Var_List;
      Seq : in Stat_List) return Stat;


private


   type Block_Stat_Record is new Stat_Record with
      record
         Vars: Var_List;  --  variables declared in the block
         Seq : Stat_List; --  sequence of statements in the block
      end record;

   procedure Free
     (S: in out Block_Stat_Record);

   function Copy
     (S: in Block_Stat_Record) return Stat;

   procedure Compile
     (S   : in Block_Stat_Record;
      Tabs: in Natural;
      Lib : in Library);

end Pn.Stats.Blocks;
