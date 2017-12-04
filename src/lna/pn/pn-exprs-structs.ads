--=============================================================================
--
--  Package: Pn.Exprs.Structs
--
--  This package implements structured expressions, e.g., {10, true}.
--
--=============================================================================


package Pn.Exprs.Structs is

   --=====
   --  Type: Struct_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Struct_Record is new Expr_Record with private;

   --=====
   --  Type: Struct
   --=====
   type Struct is access all Struct_Record;


   --=====
   --  Function: New_Struct
   --  Structured expression constructor.
   --
   --  Parameters:
   --  E - list of expressions which define the structure
   --  C - color class of the expression constructed
   --=====
   function New_Struct
     (E: in Expr_List;
      C: in Cls) return Expr;

   --=====
   --  Function: Get_Components
   --
   --  Return:
   --  the component list in structure S
   --=====
   function Get_Components
     (S: in Struct) return Expr_List;

   --=====
   --  Procedure: Append
   --  Add expression E in the structured expression S at the last position.
   --=====
   procedure Append
     (S: in Struct;
      E: in Expr);

   --=====
   --  Function: Get_Component
   --
   --  Return:
   --  the value of the component named Comp in the strucure S
   --
   --  Pre-Conditions:
   --  o the structured color class of S has a component named Comp
   --=====
   function Get_Component
     (S   : in Struct;
      Comp: in Ustring) return Expr;

   --=====
   --  Procedure: Replace_Component
   --  Substitue component named Comp of structure S by expression E.  The
   --  replaced expression is freed.
   --
   --  Pre-Conditions:
   --  o the structured color class of S has a component named Comp
   --=====
   procedure Replace_Component
     (S   : in Struct;
      Comp: in Ustring;
      E   : in Expr);


private


   type Struct_Record is new Expr_Record with
      record
         E: Expr_List;  --  list of the expressions in the structure
      end record;

   procedure Free
     (E: in out Struct_Record);

   function Copy
     (E: in Struct_Record) return Expr;

   function Get_Type
     (E: in Struct_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Struct_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Struct_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Struct_Record) return Boolean;

   function Is_Basic
     (E: in Struct_Record) return Boolean;

   function Get_True_Cls
     (E: in Struct_Record) return Cls;

   function Can_Overflow
     (E: in Struct_Record) return Boolean;

   procedure Evaluate
     (E     : in     Struct_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Struct_Record;
      Right: in Struct_Record) return Boolean;

   function Compare
     (Left: in Struct_Record;
      Right: in Struct_Record) return Comparison_Result;

   function Vars_In
     (E: in Struct_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Struct_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Struct_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Struct_Record) return Ustring;

   function Compile_Evaluation
     (E: in Struct_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Struct_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Structs;
