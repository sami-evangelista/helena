--=============================================================================
--
--  Package: Pn.Exprs.Vector_Assigns
--
--  This package implements assignment-to-vector expressions, e.g.
--  V:: ([1] := not V[2]).  This expression has the value of vector V except
--  that the element at index 1 is replaced by "not V[2]".
--
--=============================================================================


package Pn.Exprs.Vector_Assigns is

   --=====
   --  Type: Vector_Assign_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Vector_Assign_Record is new Expr_Record with private;

   --=====
   --  Type: Vector_Assign
   --=====
   type Vector_Assign is access all Vector_Assign_Record;


   --=====
   --  Function: New_Vector_Assign
   --  Assignment-to-vector constructor.
   --
   --  Parameters:
   --  V - the vector which is "assigned" the value
   --  I - index of the modified element
   --  E - expression assigned
   --  C - color class of the constructed expression
   --=====
   function New_Vector_Assign
     (V: in Expr;
      I: in Expr_List;
      E: in Expr;
      C: in Cls) return Expr;


private


   type Vector_Assign_Record is new Expr_Record with
      record
         V: Expr;       --  the assigned vector
         I: Expr_List;  --  the indexes of the assigned item
         E: Expr;       --  the assigned expression
      end record;

   procedure Free
     (E: in out Vector_Assign_Record);

   function Copy
     (E: in Vector_Assign_Record) return Expr;

   function Get_Type
     (E: in Vector_Assign_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Vector_Assign_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Vector_Assign_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Vector_Assign_Record) return Boolean;

   function Is_Basic
     (E: in Vector_Assign_Record) return Boolean;

   function Get_True_Cls
     (E: in Vector_Assign_Record) return Cls;

   function Can_Overflow
     (E: in Vector_Assign_Record) return Boolean;

   procedure Evaluate
     (E     : in     Vector_Assign_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Vector_Assign_Record;
      Right: in Vector_Assign_Record) return Boolean;

   function Compare
     (Left: in Vector_Assign_Record;
      Right: in Vector_Assign_Record) return Comparison_Result;

   function Vars_In
     (E: in Vector_Assign_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Vector_Assign_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Vector_Assign_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Vector_Assign_Record) return Ustring;

   function Compile_Evaluation
     (E: in Vector_Assign_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Vector_Assign_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Vector_Assigns;
