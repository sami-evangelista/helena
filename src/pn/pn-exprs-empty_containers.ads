--=============================================================================
--
--  Package: Pn.Exprs.Empty_Containers
--
--  This package implements empty containers, e.g., empty set, empty list.
--
--=============================================================================


package Pn.Exprs.Empty_Containers is

   --=====
   --  Type: Empty_Container_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Empty_Container_Record is new Expr_Record with private;

   --=====
   --  Type: Empty_Container
   --=====
   type Empty_Container is access all Empty_Container_Record;


   --=====
   --  Function: New_Empty_Container
   --  Empty container constructor.
   --
   --  Parameters:
   --  C - color class of the container
   --=====
   function New_Empty_Container
     (C: in Cls) return Expr;


private


   type Empty_Container_Record is new Expr_Record with
      record
         null;
      end record;

   procedure Free
     (E: in out Empty_Container_Record);

   function Copy
     (E: in Empty_Container_Record) return Expr;

   function Get_Type
     (E: in Empty_Container_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Empty_Container_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Empty_Container_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Empty_Container_Record) return Boolean;

   function Is_Basic
     (E: in Empty_Container_Record) return Boolean;

   function Get_True_Cls
     (E: in Empty_Container_Record) return Cls;

   function Can_Overflow
     (E: in Empty_Container_Record) return Boolean;

   procedure Evaluate
     (E     : in     Empty_Container_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Empty_Container_Record;
      Right: in Empty_Container_Record) return Boolean;

   function Compare
     (Left: in Empty_Container_Record;
      Right: in Empty_Container_Record) return Comparison_Result;

   function Vars_In
     (E: in Empty_Container_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Empty_Container_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Empty_Container_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Empty_Container_Record) return Ustring;

   function Compile_Evaluation
     (E: in Empty_Container_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Empty_Container_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Empty_Containers;
