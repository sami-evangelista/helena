with
  Pn.Bindings,
  Pn.Classes,
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Vars;

use
  Pn.Bindings,
  Pn.Classes,
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Vars;

package body Pn.Stats.Fors is

   function New_For_Stat
     (I: in Iter_Scheme;
      S: in Stat) return Stat is
      Result: constant For_Stat := new For_Stat_Record;
   begin
      Initialize(Result);
      Result.I := I;
      Result.S := S;
      return Stat(Result);
   end;

   procedure Free
     (S: in out For_Stat_Record) is
   begin
      Free(S.I);
      Free(S.S);
   end;

   function Copy
     (S: in For_Stat_Record) return Stat is
      Result: constant For_Stat := new For_Stat_Record;
   begin
      Result.I := Copy(S.I);
      Result.S := Copy(S.S);
      return Stat(Result);
   end;

   procedure Compile
     (S   : in For_Stat_Record;
      Tabs: in Natural;
      Lib : in Library) is
      procedure Rec_Compile
        (I   : in Natural;
         Tabs: in Natural) is
         V: Iter_Var;
      begin
         if I > Length(S.I) then
            Compile(S.S, Tabs, Lib);
         else
            V := Iter_Var(Ith(S.I, I));
            Plc(Lib, Tabs, "{");
            Compile_Definition(Var(V), Tabs + 1, Get_Code_File(Lib).all);
            Compile_Initialization(V, Tabs + 1, Lib);
            Plc(Lib, Tabs + 1, "if(" & Compile_Start_Iteration_Check(V) & ")");
            Plc(Lib, Tabs + 2, "while(TRUE) {");
            Rec_Compile(I + 1, Tabs + 3);
            Plc(Lib, Tabs + 3, "if(" & Compile_Is_Last_Check(V) & ") break;");
            Compile_Iteration(V, Tabs + 3, Lib);
            Plc(Lib, Tabs + 2, "}");
            Plc(Lib, Tabs, "}");
         end if;
      end;
   begin
      Rec_Compile(1, Tabs);
   end;

end Pn.Stats.Fors;
