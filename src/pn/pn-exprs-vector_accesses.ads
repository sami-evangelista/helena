--=============================================================================
--
--  Package: Pn.Exprs.Vector_Accesses
--
--  This package implements access to vector element expressions, e.g.,
--  t[1, true].
--
--=============================================================================


package Pn.Exprs.Vector_Accesses is

   --=====
   --  Type: Vector_Access_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Vector_Access_Record is new Expr_Record with private;

   --=====
   --  Type: Vector_Access
   --=====
   type Vector_Access is access all Vector_Access_Record;


   --=====
   --  Function: New_Vector_Access
   --  Access constructor.
   --
   --  Parameters:
   --  V - accessed vector
   --  I - index of the element accessed
   --  C - color class of the expression constructed
   --=====
   function New_Vector_Access
     (V: in Expr;
      I: in Expr_List;
      C: in Cls) return Expr;


private


   type Vector_Access_Record is new Expr_Record with
      record
         V: Expr;       --  the vector which is accessed
         I: Expr_List;  --  list of the indexes
      end record;

   procedure Free
     (E: in out Vector_Access_Record);

   function Copy
     (E: in Vector_Access_Record) return Expr;

   function Get_Type
     (E: in Vector_Access_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Vector_Access_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Vector_Access_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Assignable
     (E: in Vector_Access_Record) return Boolean;

   function Is_Static
     (E: in Vector_Access_Record) return Boolean;

   function Is_Basic
     (E: in Vector_Access_Record) return Boolean;

   function Get_True_Cls
     (E: in Vector_Access_Record) return Cls;

   function Can_Overflow
     (E: in Vector_Access_Record) return Boolean;

   procedure Evaluate
     (E     : in     Vector_Access_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Vector_Access_Record;
      Right: in Vector_Access_Record) return Boolean;

   function Compare
     (Left: in Vector_Access_Record;
      Right: in Vector_Access_Record) return Comparison_Result;

   function Vars_In
     (E: in Vector_Access_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Vector_Access_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Vector_Access_Record;
      Places: in out String_Set);

   procedure Assign
     (E  : in Vector_Access_Record;
      B  : in Binding;
      Val: in Expr);

   function Get_Assign_Expr
     (E  : in Vector_Access_Record;
      Val: in Expr) return Expr;

   function To_Helena
     (E: in Vector_Access_Record) return Ustring;

   function Compile_Evaluation
     (E: in Vector_Access_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Vector_Access_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Vector_Accesses;
