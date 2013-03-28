--=============================================================================
--
--  Package: Pn.Exprs.List_Slices
--
--  This package implements list slices, e.g., l[3..5].  This expression is
--  the list | l[3], l[4], l[5] |.
--
--=============================================================================


package Pn.Exprs.List_Slices is

   --=====
   --  Type: List_Slice_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type List_Slice_Record is new Expr_Record with private;

   --=====
   --  Type: List_Slice
   --=====
   type List_Slice is access all List_Slice_Record;


   --=====
   --  Function: New_List_Slice
   --  List slice constructor.
   --
   --  Parameters:
   --  L     - the list of which we take a slice
   --  First - index of the first element of the slice
   --  Last  - index of the last element of the slice
   --  C     - class of the expression constructed
   --=====
   function New_List_Slice
     (L    : in Expr;
      First: in Expr;
      Last: in Expr;
      C    : in Cls) return Expr;


private


   type List_Slice_Record is new Expr_Record with
      record
         L    : Expr;  --  the list of which we take a slice
         First: Expr;  --  index of the first element of the slice
         Last: Expr;  --  index of the last element of the slice
      end record;

   procedure Free
     (E: in out List_Slice_Record);

   function Copy
     (E: in List_Slice_Record) return Expr;

   function Get_Type
     (E: in List_Slice_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     List_Slice_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in List_Slice_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in List_Slice_Record) return Boolean;

   function Is_Basic
     (E: in List_Slice_Record) return Boolean;

   function Get_True_Cls
     (E: in List_Slice_Record) return Cls;

   function Can_Overflow
     (E: in List_Slice_Record) return Boolean;

   procedure Evaluate
     (E     : in     List_Slice_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in List_Slice_Record;
      Right: in List_Slice_Record) return Boolean;

   function Compare
     (Left: in List_Slice_Record;
      Right: in List_Slice_Record) return Comparison_Result;

   function Vars_In
     (E: in List_Slice_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in List_Slice_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     List_Slice_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in List_Slice_Record) return Ustring;

   function Compile_Evaluation
     (E: in List_Slice_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in List_Slice_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.List_Slices;
