--=============================================================================
--
--  Package: Pn.Vars.Trans_Vars
--
--  This package implements variables of transitions.
--
--=============================================================================


package Pn.Vars.Trans_Vars is

   type Trans_Var_Record is new Var_Record with private;

   type Trans_Var is access all Trans_Var_Record'Class;


   function New_Trans_Var
     (Name: in Ustring;
      C   : in Cls) return Var;


private


   type Trans_Var_Record is new Var_Record with
      record
         null;
      end record;

   procedure Free
     (V: in out Trans_Var_Record);

   function Copy
     (V: in Trans_Var_Record) return Var;

   function Is_Const
     (V: in Trans_Var_Record) return Boolean;

   function Is_Static
     (V: in Trans_Var_Record) return Boolean;

   function Get_Init
     (V: in Trans_Var_Record) return Expr;

   function Get_Type
     (V: in Trans_Var_Record) return Var_Type;

   procedure Replace_Var_In_Def
     (V: in out Trans_Var_Record;
      R: in     Var;
      E: in     Expr) is null;

   function To_Helena
     (V: in Trans_Var_Record) return Ustring;

   procedure Compile_Definition
     (V   : in Trans_Var_Record;
      Tabs: in Natural;
      File: in File_Type);

   function Compile_Access
     (V: in Trans_Var_Record) return Ustring;

end Pn.Vars.Trans_Vars;
