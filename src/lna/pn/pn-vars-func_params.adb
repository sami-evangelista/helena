with
  Pn.Compiler.Names;

use
  Pn.Compiler.Names;

package body Pn.Vars.Func_Params is

   function New_Func_Param
     (Name: in Ustring;
      C   : in Cls) return Var is
      Result: constant Func_Param := new Func_Param_Record;
   begin
      Initialize(Result, Name, C);
      return Var(Result);
   end;

   procedure Free
     (V: in out Func_Param_Record) is
   begin
      null;
   end;

   function Copy
     (V: in Func_Param_Record) return Var is
   begin
      return New_Func_Param(V.Name, V.C);
   end;

   function Is_Const
     (V: in Func_Param_Record) return Boolean is
   begin
      return True;
   end;

   function Is_Static
     (V: in Func_Param_Record) return Boolean is
   begin
      return False;
   end;

   function Get_Init
     (V: in Func_Param_Record) return Expr is
   begin
      pragma Assert(False);
      return null;
   end;

   function Get_Type
     (V: in Func_Param_Record) return Var_Type is
   begin
      return A_Func_Param;
   end;

   function To_Helena
     (V: in Func_Param_Record) return Ustring is
   begin
      return Cls_Name(V.C) & " " & Var_Name(V.Me);
   end;

   procedure Compile_Definition
     (V   : in Func_Param_Record;
      Tabs: in Natural;
      File: in File_Type) is
   begin
      Put_Line(File, Tabs*Tab &
               Cls_Name(Get_Cls(V.Me)) & " " & Var_Name(V.Me) & ";");
   end;

   function Compile_Access
     (V: in Func_Param_Record) return Ustring is
   begin
      return Var_Name(V.Me);
   end;

end Pn.Vars.Func_Params;
