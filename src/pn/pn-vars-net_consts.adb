with
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Exprs;

use
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Exprs;

package body Pn.Vars.Net_Consts is

   function New_Net_Const
     (Name: in Ustring;
      C   : in Cls;
      Init: in Expr) return Var is
      Result: constant Net_Const := new Net_Const_Record;
   begin
      Initialize(Result, Name, C);
      Result.Init := Init;
      return Var(Result);
   end;

   procedure Free
     (V: in out Net_Const_Record) is
   begin
      Free(V.Init);
   end;

   function Copy
     (V: in Net_Const_Record) return Var is
   begin
      return New_Net_Const(V.Name, V.C, Copy(V.Init));
   end;

   function Is_Const
     (V: in Net_Const_Record) return Boolean is
   begin
      return True;
   end;

   function Is_Static
     (V: in Net_Const_Record) return Boolean is
   begin
      return Is_Static(V.Init);
   end;

   function Get_Init
     (V: in Net_Const_Record) return Expr is
   begin
      return V.Init;
   end;

   procedure Set_Init
     (V: in out Net_Const_Record;
      E: in     Expr) is
   begin
      V.Init := E;
   end;

   function Get_Type
     (V: in Net_Const_Record) return Var_Type is
   begin
      return A_Net_Const;
   end;

   procedure Replace_Var_In_Def
     (V: in out Net_Const_Record;
      R: in     Var;
      E: in     Expr) is
   begin
      Replace_Var(V.Init, R, E);
   end;

   function To_Helena
     (V: in Net_Const_Record) return Ustring is
      Result: Ustring := Null_Unbounded_String;
   begin
      Result :=
        "constant " & Get_Name(Get_Cls(V.Me)) & " " &
        Get_Name(V.Me) & " := " & To_Helena(V.Init) & ";";
      return Result;
   end;

   procedure Compile_Definition
     (V   : in Net_Const_Record;
      Tabs: in Natural;
      File: in File_Type) is
   begin
      Put_Line(File, Tabs*Tab &
               Cls_Name(Get_Cls(V.Me)) & " " & Var_Name(V.Me) & ";");
   end;

   function Compile_Access
     (V: in Net_Const_Record) return Ustring is
   begin
      return Var_Name(V.Me);
   end;

end Pn.Vars.Net_Consts;
