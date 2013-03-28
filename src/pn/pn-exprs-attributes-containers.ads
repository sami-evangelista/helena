--=============================================================================
--
--  Package: Pn.Exprs.Attributes.Containers
--
--  This package implements container attributes, i.e., attributes that can be
--  applied on a container.  Different kinds of attribute are possible:
--  - *c'full* is a boolean which specifies if the container is full
--  - *c'empty* is a boolean which specifies if the container is empty
--  - *c'capacity* is the capacity of c, i.e., the maximal number of elements
--    it can contain
--  - *c'space* is the remaining space in c, i.e., the number of elements that
--    can still be inserted in c
--  - *c'size* is the size of the set, e.e., the number of elements currently
--    in the set.
--
--=============================================================================


package Pn.Exprs.Attributes.Containers is

   --=====
   --  Type: Container_Attribute_Record
   --
   --  See also:
   --  o <Pn> to see all the primitive operations overridden by this type
   --=====
   type Container_Attribute_Record is new Attribute_Record with private;

   --=====
   --  Type: Container_Attribute
   --=====
   type Container_Attribute is access all Container_Attribute_Record;


   --=====
   --  Function: New_Container_Attribute
   --  Container attribute constructor.
   --
   --  Parameters:
   --  Cont      - container on which the attribute is applied
   --  Attribute - the attribute
   --  C         - color class of the expression constructed
   --=====
   function New_Container_Attribute
     (Cont     : in Expr;
      Attribute: in Attribute_Type;
      C        : in Cls) return Expr;


private


   type Container_Attribute_Record is new Attribute_Record with
      record
         Cont: Expr;  --  the container on which the attribute is applied
      end record;

   procedure Free
     (E: in out Container_Attribute_Record);

   function Copy
     (E: in Container_Attribute_Record) return Expr;

   procedure Color_Expr
     (E    : in     Container_Attribute_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: in Container_Attribute_Record;
      Cs: in Cls_Set) return Cls_Set;

   function Is_Static
     (E: in Container_Attribute_Record) return Boolean;

   function Is_Basic
     (E: in Container_Attribute_Record) return Boolean;

   function Get_True_Cls
     (E: in Container_Attribute_Record) return Cls;

   function Can_Overflow
     (E: in Container_Attribute_Record) return Boolean;

   procedure Evaluate
     (E     : in     Container_Attribute_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State);

   function Static_Equal
     (Left: in Container_Attribute_Record;
      Right: in Container_Attribute_Record) return Boolean;

   function Vars_In
     (E: in Container_Attribute_Record) return Var_List;

   procedure Get_Sub_Exprs
     (E: in Container_Attribute_Record;
      R: in Expr_List);

   procedure Get_Observed_Places
     (E     : in     Container_Attribute_Record;
      Places: in out String_Set);

   function To_Helena
     (E: in Container_Attribute_Record) return Ustring;

   function Compile_Evaluation
     (E: in Container_Attribute_Record;
      M: in Var_Mapping) return Ustring;

   function Replace_Var
     (E: in Container_Attribute_Record;
      V: in Var;
      Ne: in Expr) return Expr;

end Pn.Exprs.Attributes.Containers;
