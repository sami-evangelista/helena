--=============================================================================
--
--  Package: Pn.Exprs.Containers
--
--  This package implements container constructors, e.g., | a, b, c |.  This
--  expression is a container, e.g., a list, a set, which contains the three
--  elements a, b and c.
--
--=============================================================================


package Pn.Exprs.Containers is

   --=====
   --  Type: Container_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Container_Record is new Expr_Record with private;

   --=====
   --  Type: Container
   --=====
   type Container is access all Container_Record;


   --=====
   --  Function: New_Container
   --  Container constructor.
   --
   --  Parameters:
   --  E - expression list which define the resulting container
   --  C - color class of the expression constructed
   --=====
   function New_Container
     (E: in Expr_List;
      C: in Cls) return Expr;

   --=====
   --  Function: Get_Expr_List
   --
   --  Return:
   --  the expression list which defines the expression
   --=====
   function Get_Expr_List
     (C: in Container) return Expr_List;

   --=====
   --  Procedure: Replace_Element
   --  Replace the Ith element of Container C by expression E.  The replaced
   --  expression is freed.
   --=====
   procedure Replace_Element
     (C: in Container;
      E: in Expr;
      I: in Index_Type);


private


   type Container_Record is new Expr_Record with
      record
         E: Expr_List;  --  expression list of the container
      end record;

   procedure Free
     (E: in out Container_Record);

   function Copy
     (E: in Container_Record) return Expr;

   function Get_Type
     (E: in Container_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Container_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Container_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Container_Record) return Boolean;

   function Is_Basic
     (E: in Container_Record) return Boolean;

   function Get_True_Cls
     (E: in Container_Record) return Cls;

   function Can_Overflow
     (E: in Container_Record) return Boolean;

   procedure Evaluate
     (E     : in     Container_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Container_Record;
      Right: in Container_Record) return Boolean;

   function Compare
     (Left: in Container_Record;
      Right: in Container_Record) return Comparison_Result;

   function Vars_In
     (E: in Container_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Container_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Container_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Container_Record) return Ustring;

   function Compile_Evaluation
     (E: in Container_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Container_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Containers;
