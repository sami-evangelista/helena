--=============================================================================
--
--  Package: Pn.Exprs.Struct_Accesses
--
--  This package implements access-to-struct-component expressions,
--  e.g., my_struct.my_component
--
--=============================================================================


package Pn.Exprs.Struct_Accesses is

   --=====
   --  Type: Struct_Access_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Struct_Access_Record is new Expr_Record with private;

   --=====
   --  Type: Struct_Access
   --=====
   type Struct_Access is access all Struct_Access_Record;


   --=====
   --  Function: New_Struct_Access
   --  Access-to-struct-component constructor.
   --
   --  Parameters:
   --  Struct - the structured expression accessed
   --  F      - name of the component accessed
   --  C      - color class of the expression constructed
   --=====
   function New_Struct_Access
     (Struct: in Expr;
      Comp  : in Ustring;
      C     : in Cls) return Expr;

   --=====
   --  Function: Get_Accessed_Component_Name
   --
   --  Return:
   --  the name of the accessed component of access S.
   --=====
   function Get_Accessed_Component_Name
     (S: in Struct_Access) return Ustring;


private


   type Struct_Access_Record is new Expr_Record with
      record
         Struct: Expr;     --  the structure accessed
         Comp  : Ustring;  --  name of the accessed component
      end record;

   procedure Free
     (E: in out Struct_Access_Record);

   function Copy
     (E: in Struct_Access_Record) return Expr;

   function Get_Type
     (E: in Struct_Access_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Struct_Access_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Struct_Access_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Assignable
     (E: in Struct_Access_Record) return Boolean;

   function Is_Static
     (E: in Struct_Access_Record) return Boolean;

   function Is_Basic
     (E: in Struct_Access_Record) return Boolean;

   function Get_True_Cls
     (E: in Struct_Access_Record) return Cls;

   function Can_Overflow
     (E: in Struct_Access_Record) return Boolean;

   procedure Evaluate
     (E     : in     Struct_Access_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Struct_Access_Record;
      Right: in Struct_Access_Record) return Boolean;

   function Compare
     (Left: in Struct_Access_Record;
      Right: in Struct_Access_Record) return Comparison_Result;

   function Vars_In
     (E: in Struct_Access_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Struct_Access_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Struct_Access_Record;
      Places: in out String_Set);

   procedure Assign
     (E  : in Struct_Access_Record;
      B  : in Binding;
      Val: in Expr);

   function Get_Assign_Expr
     (E  : in Struct_Access_Record;
      Val: in Expr) return Expr;

   function To_Helena
     (E: in Struct_Access_Record) return Ustring;

   function Compile_Evaluation
     (E: in Struct_Access_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Struct_Access_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Struct_Accesses;
