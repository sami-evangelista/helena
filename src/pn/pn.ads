--=============================================================================
--
--  Package: Pn
--
--  This is the top level package of the Pn library of Helena.  It
--  only contains the declarations of some the basic stuffs used
--  everywhere in the library.
--
--=============================================================================


with
  Ada.Characters.Handling,
  Ada.Float_Text_IO,
  Ada.Strings,
  Ada.Strings.Fixed,
  Ada.Strings.Unbounded,
  Ada.Strings.Unbounded.Text_Io,
  Ada.Text_Io,
  Ada.Unchecked_Deallocation,
  Generic_Array,
  Generic_Set,
  Interfaces.C,
  Libraries,
  System,
  Utils,
  Utils.Generics,
  Utils.Strings;

use
  Ada.Characters.Handling,
  Ada.Float_Text_IO,
  Ada.Strings,
  Ada.Strings.Fixed,
  Ada.Strings.Unbounded,
  Ada.Strings.Unbounded.Text_Io,
  Ada.Text_Io,
  Interfaces.C,
  Libraries,
  System,
  Utils,
  Utils.Generics,
  Utils.Strings;

package Pn is

   --==========================================================================
   --  Group: Basic types
   --==========================================================================

   type Arc_Type is (Pre, Post, Inhibit);

   subtype Update_Arc_Type is Arc_Type range Pre .. Post;

   type Num_Type is range Interfaces.C.Int'First .. Interfaces.C.Int'Last;

   type Card_Type is new Big_Int range 0 .. Big_Int'Last;

   subtype Mult_Type is Num_Type range 0 .. Num_Type'Last;

   subtype Index_Type is Positive;

   subtype Extended_Index_Type is Natural;

   subtype Count_Type is Natural;

   type Fuzzy_Boolean is
     (FTrue,
      FFalse,
      Dont_Know);

   function "or"
     (B: in Fuzzy_Boolean;
      C: in Fuzzy_Boolean) return Fuzzy_Boolean;

   function "and"
     (B: in Fuzzy_Boolean;
      C: in Fuzzy_Boolean) return Fuzzy_Boolean;



   --==========================================================================
   --  Group: Some constants
   --==========================================================================

   Num_Cls_Max_Val: constant Num_Type := Num_Type'Last;

   Num_Cls_Min_Val: constant Num_Type := Num_Type'First;

   Max_Unfoldable_Dom_Card: constant Card_Type := 2 ** 24;

   Max_Dom_Size: constant Natural := 2 ** 8;

   Max_Cls_Basic_Elements: constant Natural := 2 ** 16;

   Max_Dom_Basic_Elements: constant Natural := (Max_Dom_Size *
                                                 Max_Cls_Basic_Elements);

   Max_Vector_Index_Card: constant Natural := 2 ** 16;

   Max_Container_Capacity: constant Num_Type := 2 ** 16;

   Max_Net_Size: constant Natural := 2 ** 24;

   No_Index: constant Extended_Index_Type := 0;

   package Num_Type_String_Conversion is
      new Generic_String_Conversion(Num_Type);
   package NVSC renames Num_Type_String_Conversion;
   function To_String
     (I: in Num_Type) return String renames NVSC.To_String;
   function To_Ustring
     (I: in Num_Type) return Ustring renames NVSC.To_Unbounded_String;
   function "&"
     (Left: in String;
      Right: in Num_Type) return Ustring renames NVSC."&";
   function "&"
     (Left: in Num_Type;
      Right: in String)  return Ustring renames NVSC."&";
   function "&"
     (Left: in Ustring;
      Right: in Num_Type) return Ustring renames NVSC."&";
   function "&"
     (Left: in Num_Type;
      Right: in Ustring) return Ustring renames NVSC."&";

   package Card_Type_String_Conversion is
      new Generic_String_Conversion(Card_Type);
   package SCSC renames Card_Type_String_Conversion;
   function To_String
     (I: in Card_Type) return String renames SCSC.To_String;
   function To_Ustring
     (I: in Card_Type) return Ustring renames SCSC.To_Unbounded_String;
   function "&"
     (Left: in String;
      Right: in Card_Type) return Ustring renames SCSC."&";
   function "&"
     (Left: in Card_Type;
      Right: in String) return Ustring renames SCSC."&";
   function "&"
     (Left: in Ustring;
      Right: in Card_Type) return Ustring renames SCSC."&";
   function "&"
     (Left: in Card_Type;
      Right: in Ustring) return Ustring renames SCSC."&";

   function Ite is new Generic_Ite(Unbounded_String);

   package String_Set_Pkg is
      new Generic_Set(Unbounded_String, Null_Unbounded_String, "=");
   subtype String_Set is String_Set_Pkg.Set_Type;

   package Natural_Set_Pkg is
      new Generic_Set(Natural, 0, "=");
   subtype Natural_Set is Natural_Set_Pkg.Set_Type;



   --==========================================================================
   --  Group: Unary operator
   --==========================================================================

   type Un_Operator is
     (Pred_Op,
      Succ_Op,
      Plus_Uop,
      Minus_Uop,
      Not_Op);



   --==========================================================================
   --  Group: Binary operator
   --==========================================================================

   type Bin_Operator is
     (Plus_Op,
      Minus_Op,
      Mult_Op,
      Div_Op,
      Mod_Op,
      And_Op,
      Or_Op,
      Sup_Op,
      Sup_Eq_Op,
      Inf_Op,
      Inf_Eq_Op,
      Eq_Op,
      Neq_Op,
      Concat_Op,
      In_Op);

   subtype Num_Bin_Operator        is Bin_Operator range Plus_Op .. Mod_Op;
   subtype Bool_Bin_Operator       is Bin_Operator range And_Op  .. Or_Op;
   subtype Comparison_Bin_Operator is Bin_Operator range Sup_Op  .. Neq_Op;



   --==========================================================================
   --  Group: Type of color classe
   --==========================================================================

   type Cls_Type is
     (A_Num_Cls,
      A_Enum_Cls,
      A_Struct_Cls,
      A_Product_Cls,
      A_Vector_Cls,
      A_List_Cls,
      A_Set_Cls);

   subtype Discrete_Cls_Type  is Cls_Type range A_Num_Cls    .. A_Enum_Cls;
   subtype Composite_Cls_Type is Cls_Type range A_Struct_Cls .. A_Set_Cls;
   subtype Container_Cls_Type is Cls_Type range A_List_Cls   .. A_Set_Cls;

   type Cls_Type_Set is array (Cls_Type) of Boolean;

   function Card
     (C: in Cls_Type_Set) return Natural;



   --==========================================================================
   --  Group: Result of an expression evaluation
   --==========================================================================

   type Evaluation_State is
     (Evaluation_Assert_Failed,
      Evaluation_Cast_Failed,
      Evaluation_Div_By_Zero,
      Evaluation_List_Overflow,
      Evaluation_List_Index_Check_Failed,
      Evaluation_Out_Of_Range,
      Evaluation_Range_Check_Failed,
      Evaluation_Unbound_Variable,
      Evaluation_Failure,
      Evaluation_Success);

   function Is_Success
     (R: in Evaluation_State) return Boolean;



   --==========================================================================
   --  Group: Result of a coloring (typing of an expression)
   --==========================================================================

   type Coloring_State is
     (Coloring_Ambiguous_Expression,
      Coloring_Failure,
      Coloring_Success);

   function Is_Success
     (C: in Coloring_State) return Boolean;



   --==========================================================================
   --  Group: Result of a count, e.g., counting the cardinal of a color class
   --==========================================================================

   type Count_State is
     (Count_Infinite,
      Count_Too_Large,
      Count_Success);

   function Is_Success
     (C: in Count_State) return Boolean;



   type Binding is private;

   type Cls_Record is abstract tagged private;
   type Cls is access all Cls_Record'Class;

   type Cls_Array is array(Positive range <>) of Cls;

   type Dom is private;

   type Cls_Set_Record is private;
   type Cls_Set is access all Cls_Set_Record;

   type Expr_Record is abstract tagged private;
   type Expr is access all Expr_Record'Class;

   type Expr_List_Record is private;
   type Expr_List is access all Expr_List_Record;

   type Expr_Array is array(Positive range <>) of Expr;

   type Expr_Type;

   type Var_Record is abstract tagged private;
   type Var is access all Var_Record'Class;

   type Var_List is private;

   type Var_Array is array(Positive range <>) of Var;

   type Var_Binding_Record is private;
   type Var_Binding is access all Var_Binding_Record;



   --==========================================================================
   --  Group: Color classes
   --==========================================================================

   procedure Free
     (C: in out Cls_Record) is abstract;

   function Get_Type
     (C: in Cls_Record) return Cls_Type is abstract;

   procedure Card
     (C     : in     Cls_Record;
      Result:    out Card_Type;
      State :    out Count_State) is abstract;

   function Low_Value
     (C: in Cls_Record) return Expr is abstract;

   function High_Value
     (C: in Cls_Record) return Expr is abstract;

   function Ith_Value
     (C: in Cls_Record;
      I: in Card_Type) return Expr is abstract;

   function Get_Value_Index
     (C: in     Cls_Record;
      E: access Expr_Record'Class) return Card_Type is abstract;

   function Elements_Size
     (C: in Cls_Record) return Natural is abstract;

   function Basic_Elements_Size
     (C: in Cls_Record) return Natural is abstract;

   function Is_Const_Of_Cls
     (C: in     Cls_Record;
      E: access Expr_Record'Class) return Boolean is abstract;

   function Colors_Used
     (C: in Cls_Record) return Cls_Set is abstract;

   function Has_Constant_Bit_Width
     (C: in Cls_Record) return Boolean is abstract;

   function Bit_Width
     (C: in Cls_Record) return Natural is abstract;

   function Get_Root_Cls
     (C: in Cls_Record) return Cls;

   function Is_Sub_Cls
     (C     : in     Cls_Record;
      Parent: access Cls_Record'Class) return Boolean;

   procedure Compile_Type_Definition
     (C  : in Cls_Record;
      Lib: in Library) is abstract;

   procedure Compile_Constants
     (C  : in Cls_Record;
      Lib: in Library) is abstract;

   procedure Compile_Operators
     (C  : in Cls_Record;
      Lib: in Library) is abstract;

   procedure Compile_Encoding_Functions
     (C  : in Cls_Record;
      Lib: in Library) is abstract;

   procedure Compile_Io_Functions
     (C  : in Cls_Record;
      Lib: in Library) is abstract;

   procedure Compile_Hash_Function
     (C  : in Cls_Record;
      Lib: in Library) is abstract;

   procedure Compile_Others
     (C  : in Cls_Record;
      Lib: in Library) is abstract;



   --==========================================================================
   --  Group: Type of an expression
   --==========================================================================

   type Expr_Type is
     (A_Any,
      A_Attribute,
      A_Bin_Op,
      A_Cast,
      A_Const,
      A_Container,
      A_Empty_Container,
      A_Enum_Const,
      A_Func_Call,
      A_If_Then_Else,
      A_Inclusion_Check,
      A_Iterator,
      A_List_Access,
      A_List_Assign,
      A_List_Slice,
      A_Num_Const,
      A_Struct,
      A_Struct_Assign,
      A_Struct_Access,
      A_Tuple_Access,
      A_Un_Op,
      A_Var,
      A_Vector,
      A_Vector_Access,
      A_Vector_Assign);



   --==========================================================================
   --  Group: Result of a comparison
   --==========================================================================

   type Comparison_Result is
     (Cmp_Eq,
      Cmp_Sup,
      Cmp_Inf,
      Cmp_Error);



   --==========================================================================
   --  Group: Expressions
   --==========================================================================

   procedure Free
     (E: in out Expr_Record) is abstract;

   function Copy
     (E: in Expr_Record) return Expr is abstract;

   function Get_Type
     (E: in Expr_Record) return Expr_Type is abstract;

   procedure Color_Expr
     (E    : in     Expr_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is abstract;

   function Possible_Colors
     (E: in Expr_Record;
      Cs: in Cls_Set) return Cls_Set is abstract;

   function Is_Assignable
     (E: in Expr_Record) return Boolean;

   function Is_Static
     (E: in Expr_Record) return Boolean is abstract;

   function Is_Basic
     (E: in Expr_Record) return Boolean is abstract;

   function Get_True_Cls
     (E: in Expr_Record) return Cls is abstract;

   function Can_Overflow
     (E: in Expr_Record) return Boolean is abstract;

   procedure Evaluate
     (E     : in     Expr_Record;
      B     : in     Binding;
      Result:    out Expr;
      State :    out Evaluation_State) is abstract;

   function Static_Equal
     (Left : in Expr_Record;
      Right: in Expr_Record) return Boolean is abstract;

   function Compare
     (Left : in Expr_Record;
      Rigth: in Expr_Record) return Comparison_Result is abstract;

   function Vars_In
     (E: in Expr_Record) return Var_List is abstract;

   procedure Get_Sub_Exprs
     (E: in Expr_Record;
      R: in Expr_List) is abstract;

   procedure Get_Observed_Places
     (E     : in     Expr_Record;
      Places: in out String_Set) is abstract;

   procedure Assign
     (E  : in Expr_Record;
      B  : in Binding;
      Val: in Expr);

   function Get_Assign_Expr
     (E  : in Expr_Record;
      Val: in Expr) return Expr;

   function To_Helena
     (E: in Expr_Record) return Ustring is abstract;

   type Var_Expr is
      record
         V   : Var;
         Expr: Ustring;
      end record;
   type Var_Mapping is array(Positive range <>) of Var_Expr;
   Empty_Var_Mapping: constant Var_Mapping :=
     (1..0 => (null, Null_Unbounded_String));

   function Compile_Evaluation
     (E: in Expr_Record;
      M: in Var_Mapping) return Ustring is abstract;

   procedure Compile_Definition
     (E  : in Expr_Record;
      R  : in Var_Mapping;
      Lib: in Library);

   function Replace_Var
     (E : in Expr_Record;
      V : in Var;
      Ne: in Expr) return Expr is abstract;

   function Change_Map
     (Map: in Var_Mapping;
      V  : in Var;
      Val: in Ustring) return Var_Mapping;



   --==========================================================================
   --  Group: Type of a variable
   --==========================================================================

   type Var_Type is
     (A_Container_Iter_Var,
      A_Discrete_Cls_Iter_Var,
      A_Place_Iter_Var,
      A_Func_Param,
      A_Func_Var,
      A_Net_Const,
      A_Trans_Var,
      A_Var);

   subtype Iter_Var_Type is Var_Type
     range A_Container_Iter_Var .. A_Place_Iter_Var;

   type Var_Type_Set is array (Var_Type) of Boolean;



   --==========================================================================
   --  Group: Variables
   --==========================================================================

   procedure Free
     (V: in out Var_Record) is abstract;

   function Copy
     (V: in Var_Record) return Var is abstract;

   function Is_Const
     (V: in Var_Record) return Boolean is abstract;

   function Is_Static
     (V: in Var_Record) return Boolean is abstract;

   function Get_Init
     (V: in Var_Record) return Expr is abstract;

   procedure Set_Init
     (V: in out Var_Record;
      E: in     Expr);

   function Get_Type
     (V: in Var_Record) return Var_Type is abstract;

   procedure Replace_Var_In_Def
     (V: in out Var_Record;
      R: in     Var;
      E: in     Expr) is abstract;

   function To_Helena
     (V: in Var_Record) return Ustring is abstract;

   procedure Compile_Definition
     (V   : in Var_Record;
      Tabs: in Natural;
      File: in File_Type) is abstract;

   function Compile_Access
     (V: in Var_Record) return Ustring is abstract;


   --==========================================================================
   --  Group: exceptions
   --==========================================================================

   Export_Exception,
   Compilation_Exception: exception;


private


   --==========================================================================
   --  a color class
   --==========================================================================

   type Cls_Record is abstract tagged
      record
         Name: Ustring; --  name of the color class
         Me  : Cls;     --  pointer on itself
      end record;



   --==========================================================================
   --  a color domain
   --==========================================================================

   package Cls_Array_Pkg is
      new Generic_Array(Element_Type => Cls,
                        Null_Element => null,
                        "="          => "=");

   type Dom_Record is
      record
         Cls: Cls_Array_Pkg.Array_Type;
      end record;
   type Dom is access all Dom_Record;

   Null_Dom: constant Dom := null;



   --==========================================================================
   --  a set of color classes
   --==========================================================================

   package Cls_Set_Pkg is new Generic_Set(Cls, null, "=");

   type Cls_Set_Record is
      record
         Cls: Cls_Set_Pkg.Set_Type; --  the color classes
      end record;



   --==========================================================================
   --  an expression
   --==========================================================================

   type Expr_Record is abstract tagged
      record
         C : Cls;  --  color of the expression
         Me: Expr; --  pointer on itself
      end record;



   --==========================================================================
   --  a list of expressions
   --==========================================================================

   package Expr_Array_Pkg is
      new Generic_Array(Element_Type => Expr,
                        Null_Element => null,
                        "="          => "=");

   type Expr_List_Record is
      record
         Exprs: Expr_Array_Pkg.Array_Type; --  the expressions
      end record;



   --==========================================================================
   --  a variable
   --==========================================================================

   type Var_Record is abstract tagged
      record
         Name: Ustring; --  name of the variable
         C   : Cls;     --  color of the variable
         Me  : Var;     --  pointer on itself
      end record;

   Null_Var: constant Var := null;



   --==========================================================================
   --  a list of variables
   --==========================================================================

   package Var_Array_Pkg is
      new Generic_Array(Element_Type => Var,
                        Null_Element => Null_Var,
                        "="          => "=");

   type Var_List_Record is
      record
         Vars: Var_Array_Pkg.Array_Type; --  the variables
      end record;
   type Var_List is access all Var_List_Record;

   Null_Var_List: constant Var_List := null;



   --==========================================================================
   --  a variable binding
   --==========================================================================

   type Var_Binding_Record is
      record
         V     : Var;     --  the variable
         V_Name: Ustring; --  name of the variable if the variable object is
			  --  not known
         E     : Expr;    --  the value of the variable
      end record;



   --==========================================================================
   --  a binding
   --==========================================================================

   package Var_Binding_Array_Pkg is new Generic_Array(Var_Binding, null, "=");

   type Binding_Record is
      record
         Bindings: Var_Binding_Array_Pkg.Array_Type; --  the bindings
      end record;
   type Binding is access all Binding_Record;

   Null_Binding: constant Binding := null;

end Pn;
