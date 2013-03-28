--=============================================================================
--
--  Package: Pn.Exprs.If_Then_Elses
--
--  This package implements if-then-else expressions (as in the C language),
--  e.g., (a > b) ? a: b.
--
--=============================================================================


package Pn.Exprs.If_Then_Elses is

   --=====
   --  Type: If_Then_Else_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type If_Then_Else_Record is new Expr_Record with private;

   --=====
   --  Type: If_Then_Else
   --=====
   type If_Then_Else is access all If_Then_Else_Record;


   --=====
   --  Function: New_If_Then_Else
   --  If-then-else constructor.
   --
   --  Parameters:
   --  If_Cond    - expression evaluated
   --  True_Expr  - value of the expression if If_Cond is evaluated to True
   --  False_Expr - value of the expression if If_Cond is evaluated to False
   --  C          - color class of the expression constructed
   --=====
   function New_If_Then_Else
     (If_Cond   : in Expr;
      True_Expr: in Expr;
      False_Expr: in Expr) return Expr;


private


   type If_Then_Else_Record is new Expr_Record with
      record
         If_Cond   : Expr;  --  evaluated expression
         True_Expr: Expr;  --  value of the expression if If_Cond is true
         False_Expr: Expr;  --  value of the expression if If_Cond is false
      end record;

   procedure Free
     (E: in out If_Then_Else_Record);

   function Copy
     (E: in If_Then_Else_Record) return Expr;

   function Get_Type
     (E: in If_Then_Else_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     If_Then_Else_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in If_Then_Else_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in If_Then_Else_Record) return Boolean;

   function Is_Basic
     (E: in If_Then_Else_Record) return Boolean;

   function Get_True_Cls
     (E: in If_Then_Else_Record) return Cls;

   function Can_Overflow
     (E: in If_Then_Else_Record) return Boolean;

   procedure Evaluate
     (E     : in     If_Then_Else_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in If_Then_Else_Record;
      Right: in If_Then_Else_Record) return Boolean;

   function Compare
     (Left: in If_Then_Else_Record;
      Right: in If_Then_Else_Record) return Comparison_Result;

   function Vars_In
     (E: in If_Then_Else_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in If_Then_Else_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     If_Then_Else_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in If_Then_Else_Record) return Ustring;

   function Compile_Evaluation
     (E: in If_Then_Else_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in If_Then_Else_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.If_Then_Elses;
