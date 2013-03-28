--=============================================================================
--
--  Package: Pn.Vars.Net_Consts
--
--  This package implements constants of nets.
--
--=============================================================================


with
  Pn.Nets;

use
  Pn.Nets;

package Pn.Vars.Net_Consts is

   type Net_Const_Record is new Var_Record with private;

   type Net_Const is access all Net_Const_Record'Class;


   function New_Net_Const
     (Name: in Ustring;
      C   : in Cls;
      Init: in Expr) return Var;


private


   type Net_Const_Record is new Var_Record with
      record
         Init: Expr;
      end record;

   procedure Free
     (V: in out Net_Const_Record);

   function Copy
     (V: in Net_Const_Record) return Var;

   function Is_Const
     (V: in Net_Const_Record) return Boolean;

   function Is_Static
     (V: in Net_Const_Record) return Boolean;

   function Get_Init
     (V: in Net_Const_Record) return Expr;

   procedure Set_Init
     (V: in out Net_Const_Record;
      E: in     Expr);

   function Get_Type
     (V: in Net_Const_Record) return Var_Type;

   procedure Replace_Var_In_Def
     (V: in out Net_Const_Record;
      R: in     Var;
      E: in     Expr);

   function To_Helena
     (V: in Net_Const_Record) return Ustring;

   procedure Compile_Definition
     (V   : in Net_Const_Record;
      Tabs: in Natural;
      File: in File_Type);

   function Compile_Access
     (V: in Net_Const_Record) return Ustring;

end Pn.Vars.Net_Consts;
