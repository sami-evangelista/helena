--=============================================================================
--
--  Package: Pn.Exprs.List_Accesses
--
--  This package implements access-to-list expressions, e.g., l[2].
--
--=============================================================================


package Pn.Exprs.List_Accesses is

   --=====
   --  Type: List_Access_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type List_Access_Record is new Expr_Record with private;

   --=====
   --  Type: List_Access
   --=====
   type List_Access is access all List_Access_Record;


   --=====
   --  Function: New_List_Access
   --  List access constructor.
   --
   --  Parameters:
   --  L - the list accessed
   --  I - index of the element accessed
   --  C - color class of the expression constructed
   --=====
   function New_List_Access
     (L: in Expr;
      I: in Expr;
      C: in Cls) return Expr;


private


   type List_Access_Record is new Expr_Record with
      record
         L: Expr;  --  the list which is accessed
         I: Expr;  --  the index of the element accessed
      end record;

   procedure Free
     (E: in out List_Access_Record);

   function Copy
     (E: in List_Access_Record) return Expr;

   function Get_Type
     (E: in List_Access_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     List_Access_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in List_Access_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Assignable
     (E: in List_Access_Record) return Boolean;

   function Is_Static
     (E: in List_Access_Record) return Boolean;

   function Is_Basic
     (E: in List_Access_Record) return Boolean;

   function Get_True_Cls
     (E: in List_Access_Record) return Cls;

   function Can_Overflow
     (E: in List_Access_Record) return Boolean;

   procedure Evaluate
     (E     : in     List_Access_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in List_Access_Record;
      Right: in List_Access_Record) return Boolean;

   function Compare
     (Left: in List_Access_Record;
      Right: in List_Access_Record) return Comparison_Result;

   function Vars_In
     (E: in List_Access_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in List_Access_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     List_Access_Record;
      Places: in out String_Set);

   procedure Assign
     (E  : in List_Access_Record;
      B  : in Binding;
      Val: in Expr);

   function Get_Assign_Expr
     (E  : in List_Access_Record;
      Val: in Expr) return Expr;

   function To_Helena
     (E: in List_Access_Record) return Ustring;

   function Compile_Evaluation
     (E: in List_Access_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in List_Access_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.List_Accesses;
