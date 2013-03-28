with
  Pn.Exprs.Enum_Consts;

use
  Pn.Exprs.Enum_Consts;

package body Pn.Stats.Ifs is

   function New_If_Stat
     (Cond_Expr: in Expr;
      True_Stat: in Stat;
      False_Stat: in Stat) return Stat is
      Result: constant If_Stat := new If_Stat_Record;
   begin
      Initialize(Result);
      Result.Cond_Expr := Cond_Expr;
      Result.True_Stat := True_Stat;
      Result.False_Stat := False_Stat;
      return Stat(Result);
   end;

   function New_If_Stat
     (Cond_Expr: in Expr;
      True_Stat: in Stat) return Stat is
      Result: constant If_Stat := new If_Stat_Record;
   begin
      Initialize(Result);
      Result.Cond_Expr := Cond_Expr;
      Result.True_Stat := True_Stat;
      Result.False_Stat := null;
      return Stat(Result);
   end;

   procedure Free
     (S: in out If_Stat_Record) is
   begin
      Free(S.Cond_Expr);
      Free(S.True_Stat);
      if S.False_Stat /= null then
         Free(S.False_Stat);
      end if;
   end;

   function Copy
     (S: in If_Stat_Record) return Stat is
      Result: constant If_Stat := new If_Stat_Record;
   begin
      Result.Cond_Expr := Copy(S.Cond_Expr);
      Result.True_Stat := Copy(S.True_Stat);
      if S.False_Stat /= null then
         Result.False_Stat := Copy(S.False_Stat);
      else
         Result.False_Stat := null;
      end if;
      return Stat(Result);
   end;

   procedure Compile
     (S   : in If_Stat_Record;
      Tabs: in Natural;
      Lib : in Library) is
   begin
      Plc(Lib, Tabs, "if(" & Compile_Evaluation(S.Cond_Expr) & ")");
      Compile(S.True_Stat, Tabs+1, Lib);
      if S.False_Stat /= null then
         Plc(Lib, Tabs, "else");
         Compile(S.False_Stat, Tabs+1, Lib);
      end if;
   end;

end Pn.Stats.Ifs;
