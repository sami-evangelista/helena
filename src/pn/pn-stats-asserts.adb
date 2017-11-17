with
  Pn.Compiler,
  Pn.Compiler.Util;

use
  Pn.Compiler,
  Pn.Compiler.Util;

package body Pn.Stats.Asserts is

   function New_Assert_Stat
     (A: in Assert;
      F: in Func) return Stat is
      Result: constant Assert_Stat := new Assert_Stat_Record;
   begin
      Result.A := A;
      Result.F := F;
      return Stat(Result);
   end;

   procedure Free
     (S: in out Assert_Stat_Record) is
   begin
      Free(S.A);
   end;

   function Copy
     (S: in Assert_Stat_Record) return Stat is
   begin
      return New_Assert_Stat(Copy(S.A), S.F);
   end;

   procedure Compile
     (S   : in Assert_Stat_Record;
      Tabs: in Natural;
      Lib: in Library) is
   begin
      Plc(Lib, Tabs, "if(!(" & Compile_Evaluation(S.A) & "))");
      Plc(Lib, Tabs+1, "context_error(""assertion failed in function " &
          Get_Name(S.F) & """);");
   end;

end Pn.Stats.Asserts;
