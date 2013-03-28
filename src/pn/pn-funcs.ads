--=============================================================================
--
--  Package: Pn.Funcs
--
--  This package implements functions that can appear in the color
--  mappings of the net.  A function has parameters, a return type,
--  and a body which is a statement.  We say that a function is
--  incomplete if its parameters, its return type, or its body is not
--  specified.
--
--  See also:
--  o <Pn.Stats> which defines statements
--  o <Pn.Vars> which defines variables and parameters
--
--=============================================================================


with
  Generic_Array,
  Pn.Stats;

use
  Pn.Stats;

package Pn.Funcs is

   type Func is private;

   type Func_List is private;

   type Func_Array is array(Positive range <>) of Func;


   --==========================================================================
   --  Group: Function
   --==========================================================================

   function New_Func
     (Name     : in Ustring;
      Ret_Cls  : in Cls;
      Params   : in Var_List;
      Func_Stat: in Stat;
      Imported : in Boolean) return Func;

   function New_Func
     (Name: in Ustring) return Func;

   procedure Free
     (F: in out Func);

   function Get_Name
     (F: in Func) return Ustring;

   procedure Set_Name
     (F   : in Func;
      Name: in Ustring);

   function Get_Ret_Cls
     (F: in Func) return Cls;

   procedure Set_Ret_Cls
     (F      : in Func;
      Ret_Cls: in Cls);

   function Get_Params
     (F: in Func) return Var_List;

   procedure Set_Params
     (F     : in Func;
      Params: in Var_List);

   function Params_Size
     (F: in Func) return Natural;

   function Is_Param
     (F: in Func;
      P: in Ustring) return Boolean;

   function Get_Param
     (F: in Func;
      P: in Ustring) return Var;

   function Get_Func_Stat
     (F: in Func) return Stat;

   procedure Set_Func_Stat
     (F        : in Func;
      Func_Stat: in Stat);

   function Get_Imported
     (F: in Func) return Boolean;

   procedure Set_Imported
     (F       : in Func;
      Imported: in Boolean);

   function Get_Dom
     (F: in Func) return Dom;

   function Is_Incomplete
     (F: in Func) return Boolean;

   procedure Compile_Prototype
     (F  : in Func;
      Lib: in Library);

   procedure Compile_Body
     (F  : in Func;
      Lib: in Library);

   Null_Func: constant Func;



   --==========================================================================
   --  Group: Function list
   --==========================================================================

   function New_Func_List return Func_List;

   function New_Func_List
     (F: in Func_Array) return Func_List;

   procedure Free_All
     (F: in out Func_List);

   procedure Free
     (F: in out Func_List);

   function Length
     (F: in Func_List) return Count_Type;

   function Ith
     (F: in Func_List;
      I: in Index_Type) return Func;

   function Contains
     (F: in Func_List;
      G: in Ustring) return Boolean;

   procedure Delete
     (F: in Func_List;
      G: in Ustring);

   procedure Append
     (F: in Func_List;
      G: in Func);

   function Get
     (F: in Func_List;
      G: in Ustring) return Func;


private


   --==========================================================================
   --  Function
   --==========================================================================

   type Func_Record is tagged
      record
         Name     : Ustring;   --  name of the function
         Ret_Cls  : Cls;       --  return type of the function
         Params   : Var_List;  --  parameter list
         Domain   : Dom;       --  domain of the function (redundant with
                               --  Params)
         Func_Stat: Stat;      --  statement corresponding to the function
         Imported : Boolean;   --  if the function imported from C code
      end record;
   type Func is access all Func_Record;

   Null_Func: constant Func := null;



   --==========================================================================
   --  Function list
   --==========================================================================

   package Func_Array_Pkg is new Generic_Array(Func, Null_Func, "=");

   type Func_List_Record is
      record
         Funcs: Func_Array_Pkg.Array_Type;
      end record;
   type Func_List is access all Func_List_Record;

end Pn.Funcs;
