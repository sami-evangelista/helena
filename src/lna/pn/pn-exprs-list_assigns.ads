--=============================================================================
--
--  Package: Pn.Exprs.List_Assigns
--
--  This package implements assignment-to-list expressions, e.g.
--  L:: ([1] := not L[2]).  This expression has the value of list L except
--  that the element at index 1 is replaced by "not L[2]".
--
--=============================================================================


package Pn.Exprs.List_Assigns is

   --=====
   --  Type: List_Assign_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type List_Assign_Record is new Expr_Record with private;

   --=====
   --  Type: List_Assign
   --=====
   type List_Assign is access all List_Assign_Record;


   --=====
   --  Function: New_List_Assign
   --  Assignment-to-list constructor.
   --
   --  Parameters:
   --  L - the list which is "assigned" the value
   --  I - index of the modified element
   --  E - expression assigned
   --  C - color class of the constructed expression
   --=====
   function New_List_Assign
     (L: in Expr;
      I: in Expr;
      E: in Expr;
      C: in Cls) return Expr;


private


   type List_Assign_Record is new Expr_Record with
      record
         L: Expr;  --  the assigned list
         I: Expr;  --  the index of the assigned item
         E: Expr;  --  the assigned expression
      end record;

   procedure Free
     (E: in out List_Assign_Record);

   function Copy
     (E: in List_Assign_Record) return Expr;

   function Get_Type
     (E: in List_Assign_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     List_Assign_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in List_Assign_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in List_Assign_Record) return Boolean;

   function Is_Basic
     (E: in List_Assign_Record) return Boolean;

   function Get_True_Cls
     (E: in List_Assign_Record) return Cls;

   function Can_Overflow
     (E: in List_Assign_Record) return Boolean;

   procedure Evaluate
     (E     : in     List_Assign_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in List_Assign_Record;
      Right: in List_Assign_Record) return Boolean;

   function Compare
     (Left: in List_Assign_Record;
      Right: in List_Assign_Record) return Comparison_Result;

   function Vars_In
     (E: in List_Assign_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in List_Assign_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     List_Assign_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in List_Assign_Record) return Ustring;

   function Compile_Evaluation
     (E: in List_Assign_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in List_Assign_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.List_Assigns;
