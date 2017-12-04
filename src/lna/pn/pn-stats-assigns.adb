package body Pn.Stats.Assigns is

   function New_Assign_Stat
     (Var: in Expr;
      Val: in Expr) return Stat is
      Result: constant Assign_Stat := new Assign_Stat_Record;
   begin
      Initialize(Result);
      Result.Var := Var;
      Result.Val := Val;
      return Stat(Result);
   end;

   procedure Free
     (S: in out Assign_Stat_Record) is
   begin
      Free(S.Val);
      Free(S.Var);
   end;

   function Copy
     (S: in Assign_Stat_Record) return Stat is
      Result: constant Assign_Stat := new Assign_Stat_Record;
   begin
      Result.Var := Copy(S.Var);
      Result.Val := Copy(S.Val);
      return Stat(Result);
   end;

   procedure Compile
     (S   : in Assign_Stat_Record;
      Tabs: in Natural;
      Lib : in Library) is
   begin
      Plc(Lib, Tabs,
          Compile_Evaluation(S.Var) & " = " & Compile_Evaluation(S.Val) & ";");
   end;

end Pn.Stats.Assigns;
