--=============================================================================
--
--  Package: Pn.Vars.Func_Params
--
--  This package implements parameters of functions.
--
--=============================================================================


package Pn.Vars.Func_Params is

   type Func_Param_Record is new Var_Record with private;

   type Func_Param is access all Func_Param_Record'Class;


   function New_Func_Param
     (Name: in Ustring;
      C   : in Cls) return Var;


private


   type Func_Param_Record is new Var_Record with
      record
         null;
      end record;

   procedure Free
     (V: in out Func_Param_Record);

   function Copy
     (V: in Func_Param_Record) return Var;

   function Is_Const
     (V: in Func_Param_Record) return Boolean;

   function Is_Static
     (V: in Func_Param_Record) return Boolean;

   function Get_Init
     (V: in Func_Param_Record) return Expr;

   function Get_Type
     (V: in Func_Param_Record) return Var_Type;

   procedure Replace_Var_In_Def
     (V: in out Func_Param_Record;
      R: in     Var;
      E: in     Expr) is null;

   function To_Helena
     (V: in Func_Param_Record) return Ustring;

   procedure Compile_Definition
     (V   : in Func_Param_Record;
      Tabs: in Natural;
      File: in File_Type);

   function Compile_Access
     (V: in Func_Param_Record) return Ustring;

end Pn.Vars.Func_Params;
