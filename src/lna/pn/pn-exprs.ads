--=============================================================================
--
--  Package: Pn.Exprs
--
--  This is the basis package for expressions that can appear in arcs
--  mappings, functions, and properties.  Each expression has a type
--  (or color).  Expr_Record is the basis abstract type for
--  expressions, and Cls_Record is the basis abstract type for colors.
--
--=============================================================================


package Pn.Exprs is

   --==========================================================================
   --  Group: Expression
   --==========================================================================

   procedure Initialize
     (E: access Expr_Record'Class;
      C: in     Cls);

   procedure Free
     (E: in out Expr);

   function Copy
     (E: in Expr) return Expr;

   function Get_Cls
     (E: access Expr_Record'Class) return Cls;

   procedure Set_Cls
     (E: access Expr_Record'Class;
      C: in     Cls);

   function Get_Type
     (E: access Expr_Record'Class) return Expr_Type;

   procedure Color_Expr
     (E    : access Expr_Record'Class;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Possible_Colors
     (E: access Expr_Record'Class;
      Cs: in     Cls_Set) return Cls_Set;

   function Is_Assignable
     (E: access Expr_Record'Class) return Boolean;

   function Is_Static
     (E: access Expr_Record'Class) return Boolean;

   function Is_Basic
     (E: access Expr_Record'Class) return Boolean;

   function Get_True_Cls
     (E: access Expr_Record'Class) return Cls;

   function Can_Overflow
     (E: access Expr_Record'Class) return Boolean;

   procedure Evaluate
     (E     : access Expr_Record'Class;
      B     : in     Binding;
      Check : in     Boolean;
      Result:    out Expr;
      State :    out Evaluation_State);

   procedure Evaluate_Static
     (E     : access Expr_Record'Class;
      Check : in     Boolean;
      Result:    out Expr;
      State :    out Evaluation_State);

   function Is_Bool_Expr
     (E: access Expr_Record'Class) return Boolean;

   function Static_Equal
     (Left: access Expr_Record'Class;
      Right: access Expr_Record'Class) return Boolean;

   function Compare
     (Left : access Expr_Record'Class;
      Right: access Expr_Record'Class) return Comparison_Result;

   function Vars_In
     (E: access Expr_Record'Class) return Var_List;

   procedure Map_Vars
     (E    : in out Expr;
      Vars : in     Var_List;
      Nvars: in     Var_List);

   procedure Get_Sub_Exprs
     (E: access Expr_Record'Class;
      R: in     Expr_List);

   function Get_Sub_Exprs
     (E: access Expr_Record'Class) return Expr_List;

   type Expr_Predicate_Func is access function
     (E: access Expr_Record'Class) return Boolean;

   function Get_Valid_Sub_Exprs
     (E: access Expr_Record'Class;
      P: in     Expr_Predicate_Func) return Expr_List;

   function Is_Sub_Expr
     (E  : access Expr_Record'Class;
      Sub: access Expr_Record'Class) return Boolean;

   procedure Get_Observed_Places
     (E     : access Expr_Record'Class;
      Places: in out String_Set);

   function Get_Observed_Places
     (E: access Expr_Record'Class) return String_Set;

   procedure Assign
     (E  : access Expr_Record'Class;
      B  : in     Binding;
      Val: in     Expr);

   function Get_Assign_Expr
     (E  : access Expr_Record'Class;
      Val: in     Expr) return Expr;

   function To_Helena
     (E: access Expr_Record'Class) return Ustring;

   function Compile_Evaluation
     (E: access Expr_Record'Class) return Ustring;

   function Compile_Evaluation
     (E: access Expr_Record'Class;
      M: in     Var_Mapping) return Ustring;

   function Compile_Evaluation
     (E    : access Expr_Record'Class;
      R    : in     Var_Mapping;
      Check: in     Boolean) return Ustring;

   procedure Compile_Definition
     (E  : access Expr_Record'Class;
      Lib: in     Library);

   procedure Compile_Definition
     (E  : access Expr_Record'Class;
      R  : in     Var_Mapping;
      Lib: in     Library);

   function Replace_Var
     (E : access Expr_Record'Class;
      V : in     Var;
      Ne: in     Expr) return Expr;

   procedure Replace_Var
     (E : in out Expr;
      V : in     Var;
      Ne: in     Expr);



   --==========================================================================
   --  Group: Expression list
   --==========================================================================

   function New_Expr_List return Expr_List;

   function New_Expr_List
     (E: in Expr_Array) return Expr_List;

   procedure Free
     (E: in out Expr_List);

   procedure Free_All
     (E: in out Expr_List);

   function Copy
     (E: in Expr_List) return Expr_List;

   function Length
     (E: in Expr_List) return Count_Type;

   function Ith
     (E: in Expr_List;
      I: in Index_Type) return Expr;

   procedure Append
     (E: in Expr_List;
      Ex: in Expr);

   procedure Append
     (E: in Expr_List;
      F: in Expr_List);

   procedure Insert
     (E: in Expr_List;
      Ex: in Expr;
      I: in Index_Type);

   procedure Delete
     (E   : in Expr_List;
      I   : in Index_Type;
      Free: in Boolean);

   procedure Delete_Last
     (E   : in Expr_List;
      Free: in Boolean);

   procedure Replace
     (E   : in Expr_List;
      I   : in Index_Type;
      Ex  : in Expr;
      Free: in Boolean);

   procedure Color_Expr_List
     (E    : in     Expr_List;
      D    : in     Dom;
      Cs   : in     Cls_Set;
      State:    out Coloring_State);

   function Is_Static
     (E: in Expr_List) return Boolean;

   function Is_Basic
     (E: in Expr_List) return Boolean;

   procedure Evaluate
     (E     : in     Expr_List;
      B     : in     Binding;
      Check : in     Boolean;
      Result:    out Expr_List;
      State :    out Evaluation_State);

   function Static_Equal
     (Left : in Expr_List;
      Right: in Expr_List) return Boolean;

   function Compare
     (Left : in Expr_List;
      Right: in Expr_List) return Comparison_Result;

   function Vars_In
     (E: in Expr_List) return Var_List;

   function Vars_At_Top
     (E: in Expr_List) return Var_List;

   function Replace_Var
     (E : in Expr_List;
      V : in Var;
      Ne: in Expr) return Expr_List;

   procedure Replace_Var
     (E : in Expr_List;
      V : in Var;
      Ne: in Expr);

   procedure Map_Vars
     (E    : in Expr_List;
      Vars : in Var_List;
      Nvars: in Var_List);

   procedure Get_Sub_Exprs
     (E: in Expr_List;
      R: in Expr_List);

   function Get_Valid_Sub_Exprs
     (E: in Expr_List;
      P: in Expr_Predicate_Func) return Expr_List;

   function Is_Sub_Expr
     (E  : in     Expr_List;
      Sub: access Expr_Record'Class) return Boolean;

   procedure Get_Observed_Places
     (E     : in     Expr_List;
      Places: in out String_Set);

   function To_Helena
     (E: in Expr_List) return Ustring;

   function To_Helena
     (E  : in Expr_List;
      Sep: in Ustring) return Ustring;

   function Compile_Evaluation
     (E    : in Expr_List;
      R    : in Var_Mapping;
      Check: in Boolean) return Ustring;

end Pn.Exprs;
