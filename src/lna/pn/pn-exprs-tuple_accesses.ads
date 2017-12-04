--=============================================================================
--
--  Package: Pn.Exprs.Tuple_Accesses
--
--  This package implements access-to-tuple expressions.  If tup is an element
--  of A*B*C then tup->2 is an access to tuple tup and has type B.  It is equal
--  to the second component of tup.
--
--=============================================================================


package Pn.Exprs.Tuple_Accesses is

   --=====
   --  Type: Tuple_Access_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Tuple_Access_Record is new Expr_Record with private;

   --=====
   --  Type: Tuple_Access
   --=====
   type Tuple_Access is access all Tuple_Access_Record;


   --=====
   --  Function: New_Tuple_Access
   --  Access-to-tuple constructor.
   --
   --  Parameters:
   --  T    - tuple accessed
   --  Comp - index of the component accessed
   --  C    - color class of the expression constructed
   --=====
   function New_Tuple_Access
     (T   : in Expr;
      Comp: in Natural;
      C   : in Cls) return Expr;


private


   type Tuple_Access_Record is new Expr_Record with
      record
         T   : Expr;     --  the token accessed
         Comp: Natural;  --  index of the accessed component
      end record;

   procedure Free
     (E: in out Tuple_Access_Record);

   function Copy
     (E: in Tuple_Access_Record) return Expr;

   function Get_Type
     (E: in Tuple_Access_Record) return Expr_Type;

   procedure Color_Expr
     (E    : in     Tuple_Access_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Tuple_Access_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Tuple_Access_Record) return Boolean;

   function Is_Basic
     (E: in Tuple_Access_Record) return Boolean;

   function Get_True_Cls
     (E: in Tuple_Access_Record) return Cls;

   function Can_Overflow
     (E: in Tuple_Access_Record) return Boolean;

   procedure Evaluate
     (E     : in     Tuple_Access_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Tuple_Access_Record;
      Right: in Tuple_Access_Record) return Boolean;

   function Compare
     (Left: in Tuple_Access_Record;
      Right: in Tuple_Access_Record) return Comparison_Result;

   function Vars_In
     (E: in Tuple_Access_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Tuple_Access_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Tuple_Access_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Tuple_Access_Record) return Ustring;

   function Compile_Evaluation
     (E: in Tuple_Access_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Tuple_Access_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Tuple_Accesses;
