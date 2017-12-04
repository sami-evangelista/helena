with
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Exprs;

use
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Exprs;

package body Pn.Vars.Func_Vars is

   function New_Func_Var
     (Name : in Ustring;
      C    : in Cls;
      Init : in Expr;
      Const: in Boolean) return Var is
      Result: constant Func_Var := new Func_Var_Record;
   begin
      Initialize(Result, Name, C);
      Result.Init := Init;
      Result.Const := Const;
      return Var(Result);
   end;

   procedure Free
     (V: in out Func_Var_Record) is
   begin
      if V.Init /= null then
         Free(V.Init);
      end if;
   end;

   function Copy
     (V: in Func_Var_Record) return Var is
      Init: Expr;
   begin
      if V.Init /= null then
         Init := Copy(V.Init);
      end if;
      return New_Func_Var(V.Name, V.C, Init, V.Const);
   end;

   function Is_Const
     (V: in Func_Var_Record) return Boolean is
   begin
      return V.Const;
   end;

   function Is_Static
     (V: in Func_Var_Record) return Boolean is
   begin
      return Is_Static(V.Init);
   end;

   function Get_Init
     (V: in Func_Var_Record) return Expr is
   begin
      return V.Init;
   end;

   function Get_Type
     (V: in Func_Var_Record) return Var_Type is
   begin
      return A_Func_Var;
   end;

   procedure Replace_Var_In_Def
     (V: in out Func_Var_Record;
      R: in     Var;
      E: in     Expr) is
   begin
      if V.Init /= null then
         Replace_Var(V.Init, R, E);
      end if;
   end;

   function To_Helena
     (V: in Func_Var_Record) return Ustring is
      Result: Ustring := Null_Unbounded_String;
   begin
      if V.Const then
         Result := Result & "constant";
      end if;
      Result := Result & Get_Name(Get_Cls(V.Me)) & " " & Get_Name(V.Me);
      if V.Init /= null then
         Result := Result & " := " & To_Helena(V.Init);
      end if;
      Result := Result & ";";
      return Result;
   end;

   procedure Compile_Definition
     (V   : in Func_Var_Record;
      Tabs: in Natural;
      File: in File_Type) is
   begin
      Put(File, Tabs*Tab);
      if V.Const then
         Put(File, "const ");
      end if;
      Put(File, Cls_Name(V.C) & " " & Var_Name(V.Me));
      if V.Init = null then
         --===
         --  if the variable is not initialized we give it the first value of
         --  its color class
         --===
         Put(File, " = " & Cls_First_Const_Name(V.C));
      else
         Put(File, " = " & Compile_Evaluation(V.Init));
      end if;
      Put_Line(File, ";");
   end;

   function Compile_Access
     (V: in Func_Var_Record) return Ustring is
   begin
      return Var_Name(V.Me);
   end;

end Pn.Vars.Func_Vars;
