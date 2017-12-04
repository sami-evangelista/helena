package body Pn.Stats.Returns is

   function New_Return_Stat
     (Ret_Expr: in Expr) return Stat is
      Result: constant Return_Stat := new Return_Stat_Record;
   begin
      Initialize(Result);
      Result.Ret_Expr := Ret_Expr;
      return Stat(Result);
   end;

   procedure Free
     (S: in out Return_Stat_Record) is
   begin
      Free(S.Ret_Expr);
   end;

   function Copy
     (S: in Return_Stat_Record) return Stat is
      Result: constant Return_Stat := new Return_Stat_Record;
   begin
      Result.Ret_Expr := Copy(S.Ret_Expr);
      return Stat(Result);
   end;

   procedure Compile
     (S   : in Return_Stat_Record;
      Tabs: in Natural;
      Lib : in Library) is
   begin
      Plc(Lib, Tabs, "{");
      Plc(Lib, Tabs + 1, "result = " & Compile_Evaluation(S.Ret_Expr) & ";");
      Plc(Lib, Tabs + 1, "goto function_end;");
      Plc(Lib, Tabs, "}");
   end;

end Pn.Stats.Returns;
