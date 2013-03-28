--=============================================================================
--
--  Package: Pn.Exprs.Func_Calls
--
--  This package implements function calls, e.g., f(1, b).
--
--=============================================================================


with
  Pn.Funcs;

use
  Pn.Funcs;

package Pn.Exprs.Func_Calls is

   --=====
   --  Type: Func_Call_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Func_Call_Record is new Expr_Record with private;

   --=====
   --  Type: Func_Call
   --=====
   type Func_Call is access all Func_Call_Record;


   --=====
   --  Function: New_Func_Call
   --  Function call constructor
   --
   --  Parameters:
   --  F - function called
   --  P - parameter list of the call
   --=====
   function New_Func_Call
     (F: in Func;
      P: in Expr_List) return Expr;

   --=====
   --  Function: Get_Func
   --
   --  Return:
   --  the function of call F
   --=====
   function Get_Func
     (F: in Func_Call) return Func;


private


   type Func_Call_Record is new Expr_Record with
      record
         F: Func;       --  called function
         P: Expr_List;  --  parameters list
      end record;

   procedure Free
     (E: in out Func_Call_Record);

   function Copy
     (E: in Func_Call_Record) return Expr;

   function Get_Type
     (E: in Func_Call_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Func_Call_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Func_Call_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Func_Call_Record) return Boolean;

   function Is_Basic
     (E: in Func_Call_Record) return Boolean;

   function Get_True_Cls
     (E: in Func_Call_Record) return Cls;

   function Can_Overflow
     (E: in Func_Call_Record) return Boolean;

   procedure Evaluate
     (E     : in     Func_Call_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Func_Call_Record;
      Right: in Func_Call_Record) return Boolean;

   function Compare
     (Left: in Func_Call_Record;
      Right: in Func_Call_Record) return Comparison_Result;

   function Vars_In
     (E: in Func_Call_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Func_Call_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Func_Call_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Func_Call_Record) return Ustring;

   function Compile_Evaluation
     (E: in Func_Call_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Func_Call_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Func_Calls;
