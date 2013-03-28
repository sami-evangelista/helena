--=============================================================================
--
--  Package: Pn.Exprs.Attributes.Lists
--
--  This package implements lists attributes, i.e., attributes that can be
--  applied on a list.  Different kinds of attribute are possible:
--  - *l'first* is the first element of l (an error is raised if l is empty)
--  - *l'last* is the last element of l (an error is raised if l is empty)
--  - *l'prefix* is the sub-list of l which consists of all its element except
--    the last one
--  - *l'suffix* is the sub-list of l which consists of all its element except
--    the first one
--  - *l'first_index* is the index of the first element of l (an error is
--    raised if l is empty)
--  - *l'last_index* is the index of the last element of l (an error is
--    raised if l is empty)
--
--=============================================================================


package Pn.Exprs.Attributes.Lists is

   --=====
   --  Type: List_Attribute_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type List_Attribute_Record is new Attribute_Record with private;

   --=====
   --  Type: List_Attribute
   --=====
   type List_Attribute is access all List_Attribute_Record;


   --=====
   --  Function: New_List_Attribute
   --  List attribute constructor.
   --
   --  Parameters:
   --  L         - list on which the attribute is applied
   --  Attribute - the attribute
   --  C         - color class of the expression constructed
   --=====
   function New_List_Attribute
     (L        : in Expr;
      Attribute: in Attribute_Type;
      C        : in Cls) return Expr;


private


   type List_Attribute_Record is new Attribute_Record with
      record
         L: Expr;  --  the list on which the attribute is applied
      end record;

   procedure Free
     (E: in out List_Attribute_Record);

   function Copy
     (E: in List_Attribute_Record) return Expr;

   procedure Color_Expr
     (E    : in     List_Attribute_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in List_Attribute_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in List_Attribute_Record) return Boolean;

   function Is_Basic
     (E: in List_Attribute_Record) return Boolean;

   function Get_True_Cls
     (E: in List_Attribute_Record) return Cls;

   function Can_Overflow
     (E: in List_Attribute_Record) return Boolean;

   procedure Evaluate
     (E     : in     List_Attribute_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in List_Attribute_Record;
      Right: in List_Attribute_Record) return Boolean;

   function Vars_In
     (E: in List_Attribute_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in List_Attribute_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     List_Attribute_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in List_Attribute_Record) return Ustring;

   function Compile_Evaluation
     (E: in List_Attribute_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in List_Attribute_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Attributes.Lists;
