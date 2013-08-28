with
  Pn.Compiler,
  Pn.Compiler.Names;

use
  Pn.Compiler,
  Pn.Compiler.Names;

package body Pn.Stats.Prints is

   function New_Print_Stat
     (With_Str: in Boolean;
      Str     : in String;
      E       : in Expr_List) return Stat is
      Result: constant Print_Stat := new Print_Stat_Record;
   begin
      Result.With_Str := With_Str;
      Result.Str := To_Ustring(Str);
      Result.E := E;
      return Stat(Result);
   end;

   procedure Free
     (S: in out Print_Stat_Record) is
   begin
      Free(S.E);
   end;

   function Copy
     (S: in Print_Stat_Record) return Stat is
   begin
      return New_Print_Stat(S.With_Str, To_String(S.Str), Copy(S.E));
   end;

   procedure Compile
     (S   : in Print_Stat_Record;
      Tabs: in Natural;
      Lib : in Library) is
      E: Expr;
      C: Cls;
   begin
      Plc(Lib, "#ifdef ACTION_SIMULATE");
      if S.With_Str then
	 Pc(Lib, 2, "printf(""" & S.Str & """");
	 for I in 1..Length(S.E) loop
	    E := Ith(S.E, I);
	    Pc(Lib, ", " & Compile_Evaluation(Ith(S.E, I)));
	 end loop;
	 Plc(Lib, ");");
      else
	 for I in 1..Length(S.E) loop
	    E := Ith(S.E, I);
	    C := Get_True_Cls(E);
	    if I > 1 then
	       Plc(Lib, Tabs, "printf("", "");");
	    end if;
	    Plc(Lib, Tabs, Cls_Print_Func(C) & "(" &
		  Compile_Evaluation(E) & ");");
	 end loop;
      end if;
      Plc(Lib, "#endif");
   end;

end Pn.Stats.Prints;
