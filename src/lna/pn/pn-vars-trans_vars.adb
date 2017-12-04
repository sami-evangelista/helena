with
  Pn.Compiler.Names;

use
  Pn.Compiler.Names;

package body Pn.Vars.Trans_Vars is

   function New_Trans_Var
     (Name: in Ustring;
      C   : in Cls) return Var is
      Result: constant Trans_Var := new Trans_Var_Record;
   begin
      Initialize(Result, Name, C);
      return Var(Result);
   end;

   procedure Free
     (V: in out Trans_Var_Record) is
   begin
      null;
   end;

   function Copy
     (V: in Trans_Var_Record) return Var is
   begin
      return New_Trans_Var(V.Name, V.C);
   end;

   function Is_Const
     (V: in Trans_Var_Record) return Boolean is
   begin
      return False;
   end;

   function Is_Static
     (V: in Trans_Var_Record) return Boolean is
   begin
      return False;
   end;

   function Get_Init
     (V: in Trans_Var_Record) return Expr is
   begin
      pragma Assert(False);
      return null;
   end;

   function Get_Type
     (V: in Trans_Var_Record) return Var_Type is
   begin
      return A_Trans_Var;
   end;

   function To_Helena
     (V: in Trans_Var_Record) return Ustring is
   begin
      return V.Name;
   end;

   procedure Compile_Definition
     (V   : in Trans_Var_Record;
      Tabs: in Natural;
      File: in File_Type) is
   begin
      Put_Line(File, Tabs*Tab &
               Cls_Name(Get_Cls(V.Me)) & " " & Var_Name(V.Me) & ";");
   end;

   function Compile_Access
     (V: in Trans_Var_Record) return Ustring is
   begin
      return Var_Name(V.Me);
   end;

end Pn.Vars.Trans_Vars;
