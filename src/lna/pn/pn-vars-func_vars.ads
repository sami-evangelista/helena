--=============================================================================
--
--  Package: Pn.Vars.Func_Vars
--
--  This package implements variables of functions.  These can be
--  declared in block statement.
--
--=============================================================================


with
  Pn.Funcs;

use
  Pn.Funcs;

package Pn.Vars.Func_Vars is

   type Func_Var_Record is new Var_Record with private;

   type Func_Var is access all Func_Var_Record'Class;


   function New_Func_Var
     (Name : in Ustring;
      C    : in Cls;
      Init : in Expr;
      Const: in Boolean) return Var;


private


   type Func_Var_Record is new Var_Record with
      record
         Init : Expr;    --  initial value of the variable (possibly null)
         Const: Boolean; --  is it a constant?
      end record;

   procedure Free
     (V: in out Func_Var_Record);

   function Copy
     (V: in Func_Var_Record) return Var;

   function Is_Const
     (V: in Func_Var_Record) return Boolean;

   function Is_Static
     (V: in Func_Var_Record) return Boolean;

   function Get_Init
     (V: in Func_Var_Record) return Expr;

   function Get_Type
     (V: in Func_Var_Record) return Var_Type;

   procedure Replace_Var_In_Def
     (V: in out Func_Var_Record;
      R: in     Var;
      E: in     Expr);

   function To_Helena
     (V: in Func_Var_Record) return Ustring;

   procedure Compile_Definition
     (V   : in Func_Var_Record;
      Tabs: in Natural;
      File: in File_Type);

   function Compile_Access
     (V: in Func_Var_Record) return Ustring;

end Pn.Vars.Func_Vars;
