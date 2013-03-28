with
  Pn.Bindings,
  Pn.Classes,
  Pn.Vars;

use
  Pn.Bindings,
  Pn.Classes,
  Pn.Vars;

package body Pn.Stats.Blocks is

   function New_Block_Stat
     (Vars: in Var_List;
      Seq: in Stat_List) return Stat is
      Result: constant Block_Stat := new Block_Stat_Record;
   begin
      Initialize(Result);
      Result.Vars := Vars;
      Result.Seq := Seq;
      return Stat(Result);
   end;

   procedure Free
     (S: in out Block_Stat_Record) is
   begin
      Free(S.Seq);
   end;

   function Copy
     (S: in Block_Stat_Record) return Stat is
      Result: constant Block_Stat := new Block_Stat_Record;
   begin
      Result.Seq := Copy(S.Seq);
      return Stat(Result);
   end;

   procedure Compile
     (S   : in Block_Stat_Record;
      Tabs: in Natural;
      Lib : in Library) is
   begin
      Plc(Lib, Tabs - 1, "{");
      Compile_Definition(S.Vars, Tabs, Get_Code_File(Lib).all);
      Compile(S.Seq, Tabs, Lib);
      Plc(Lib, Tabs - 1, "}");
   end;

end Pn.Stats.Blocks;
