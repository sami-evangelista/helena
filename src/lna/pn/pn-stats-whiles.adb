with
  Pn.Exprs.Enum_Consts;

use
  Pn.Exprs.Enum_Consts;

package body Pn.Stats.Whiles is

   function New_While_Stat
     (Cond_Expr: in Expr;
      True_Stat: in Stat) return Stat is
      Result: constant While_Stat := new While_Stat_Record;
   begin
      Initialize(Result);
      Result.Cond_Expr := Cond_Expr;
      Result.True_Stat := True_Stat;
      return Stat(Result);
   end;

   procedure Free
     (S: in out While_Stat_Record) is
   begin
      Free(S.Cond_Expr);
      Free(S.True_Stat);
   end;

   function Copy
     (S: in While_Stat_Record) return Stat is
      Result: constant While_Stat := new While_Stat_Record;
   begin
      Result.Cond_Expr := Copy(S.Cond_Expr);
      Result.True_Stat := Copy(S.True_Stat);
      return Stat(Result);
   end;

   procedure Compile
     (S   : in While_Stat_Record;
      Tabs: in Natural;
      Lib: in Library) is
   begin
      Plc(Lib, Tabs, "while (" & Compile_Evaluation(S.Cond_Expr) & ")");
      Compile(S.True_Stat, Tabs+1, Lib);
   end;

end Pn.Stats.Whiles;
