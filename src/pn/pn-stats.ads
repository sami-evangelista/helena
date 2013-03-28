--=============================================================================
--
--  Package: Pn.Stats
--
--  This package implement statements that may appear in functions.  There are
--  different kinds of statements:
--  o *assert* statements (package <Pn.Stats.Asserts>)
--  o *assignment* statements (package <Pn.Stats.Assigns>)
--  o *blocks* (package <Pn.Stats.Blocks>)
--  o *case* statements (package <Pn.Stats.Cases>)
--  o *for* statements (package <Pn.Stats.Fors>)
--  o *if-then-else* statements (package <Pn.Stats.Ifs>)
--  o *return* statements (package <Pn.Stats.Returns>)
--  o *while* statements (package <Pn.Stats.Whiles>)
--
--=============================================================================


with
  Generic_Array,
  Pn.Exprs;

use
  Pn.Exprs;

package Pn.Stats is

   type Stat_Record is abstract tagged private;

   type Stat is access all Stat_Record'Class;

   type Stat_List is private;

   type Stat_Array is array(Positive range <>) of Stat;



   --==========================================================================
   --  Group: Statement
   --==========================================================================

   procedure Initialize
     (S: access Stat_Record'Class);

   procedure Free
     (S: in out Stat);

   function Copy
     (S: access Stat_Record'Class) return Stat;

   procedure Compile
     (S   : access Stat_Record'Class;
      Tabs: in     Natural;
      Lib : in     Library);

   Null_Stat: constant Stat;



   --==========================================================================
   --  Group: Primitive operations of type Stat_Record
   --==========================================================================

   procedure Free
     (S: in out Stat_Record) is abstract;

   function Copy
     (S: in Stat_Record) return Stat is abstract;

   procedure Compile
     (S   : in Stat_Record;
      Tabs: in Natural;
      Lib : in Library) is abstract;



   --==========================================================================
   --  Group: Statement list
   --==========================================================================

   function New_Stat_List return Stat_List;

   function New_Stat_List
     (S: in Stat_Array) return Stat_List;

   procedure Free
     (S: in out Stat_List);

   function Copy
     (S: in Stat_List) return Stat_List;

   procedure Append
     (S : in Stat_List;
      St: in Stat);

   procedure Compile
     (S   : in Stat_List;
      Tabs: in Natural;
      Lib : in Library);


private


   type Stat_Record is abstract tagged
      record
         null;
      end record;
   Null_Stat: constant Stat := null;

   package Stat_Array_Pkg is new Generic_Array(Stat, null, "=");

   type Stat_List_Record is
      record
         Stats: Stat_Array_Pkg.Array_Type;  --  the sequence
      end record;
   type Stat_List is access all Stat_List_Record;

end Pn.Stats;
