--=============================================================================
--
--  Package: Pn.Exprs.Struct_Assigns
--
--  This package implements assignment-to-struct expressions, e.g.
--  my_struct:: (comp := true).  The value of this expression is the value of
--  my_struct in which component comp has been replaced by true.
--
--=============================================================================


package Pn.Exprs.Struct_Assigns is

   --=====
   --  Type: Struct_Assign_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Struct_Assign_Record is new Expr_Record with private;

   --=====
   --  Type: Struct_Assign
   --=====
   type Struct_Assign is access all Struct_Assign_Record;


   --=====
   --  Function: New_Struct_Assign
   --  Assignment-to-struct-component constructor.
   --
   --  Parameters:
   --  Struct - structured expression which is assigned a value
   --  Comp   - name of the component which is assigned a value
   --  Value  - value assigned to the component
   --  C      - color class of the expression constructed
   --=====
   function New_Struct_Assign
     (Struct: in Expr;
      Comp  : in Ustring;
      Value: in Expr;
      C     : in Cls) return Expr;


private


   type Struct_Assign_Record is new Expr_Record with
      record
         Struct: Expr;     --  the assigned structure
         Comp  : Ustring;  --  the number of the component assigned
         Value: Expr;     --  the assigned expression
      end record;

   procedure Free
     (E: in out Struct_Assign_Record);

   function Copy
     (E: in Struct_Assign_Record) return Expr;

   function Get_Type
     (E: in Struct_Assign_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Struct_Assign_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Struct_Assign_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Struct_Assign_Record) return Boolean;

   function Is_Basic
     (E: in Struct_Assign_Record) return Boolean;

   function Get_True_Cls
     (E: in Struct_Assign_Record) return Cls;

   function Can_Overflow
     (E: in Struct_Assign_Record) return Boolean;

   procedure Evaluate
     (E     : in     Struct_Assign_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Struct_Assign_Record;
      Right: in Struct_Assign_Record) return Boolean;

   function Compare
     (Left: in Struct_Assign_Record;
      Right: in Struct_Assign_Record) return Comparison_Result;

   function Vars_In
     (E: in Struct_Assign_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Struct_Assign_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Struct_Assign_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Struct_Assign_Record) return Ustring;

   function Compile_Evaluation
     (E: in Struct_Assign_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Struct_Assign_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Struct_Assigns;
