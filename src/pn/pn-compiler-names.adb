with
  Ada.Unchecked_Deallocation,
  Pn.Classes,
  Pn.Funcs,
  Pn.Vars;

use
  Pn.Classes,
  Pn.Funcs,
  Pn.Vars;

package body Pn.Compiler.Names is

   --==========================================================================
   --  a generic array package
   --==========================================================================

   generic
      type Element is private;
      with function "="(E1, E2: in Element) return Boolean;
   package Generic_Array is
      type Element_Array is array (Positive range <>) of Element;
      type Elements is access all Element_Array;
      Empty_Elements: constant Elements := null;
      procedure Get_Index
        (E    : in out Elements;
         El   : in     Element;
         Index:    out Positive);
   end Generic_Array;
   package body Generic_Array is
      procedure Get_Index
        (E    : in out Elements;
         El   : in     Element;
         Index:    out Positive) is
         procedure Deallocate is new Ada.Unchecked_Deallocation(Element_Array,
                                                                Elements);
         New_E: Elements;
         Found: Boolean;
      begin
         if E = null then
            E    := new Element_Array(1..1);
            E(1) := El;
            Index := 1;
         else
            Found := False;
            for I in E'Range loop
               if E(I) = El then
                  Index := I;
                  Found := True;
                  exit;
               end if;
            end loop;
            if not Found then
               New_E            := new Element_Array(1..E'Last+1);
               New_E(E'Range)   := E(E'Range);
               New_E(New_E'Last) := El;
               Index            := New_E'Last;
               Deallocate(E);
               E := New_E;
            end if;
         end if;
      end;
   end Generic_Array;



   --==========================================================================
   --  color classes
   --==========================================================================

   package Cls_Array_Pkg is new Generic_Array(Cls, "=");
   All_Cls: Cls_Array_Pkg.Elements := Cls_Array_Pkg.Empty_Elements;

   function Simple_Name
     (C: in Cls) return Ustring is
      Index: Positive;
   begin
      Cls_Array_Pkg.Get_Index(All_Cls, C, Index);
      case Get_Type(C) is
         when A_Product_Cls => return "" & Index;
         when others        => return Get_Name(C);
      end case;
   end;

   function Cls_Name
     (C: in Cls) return Ustring is
   begin
      return "TYPE_" & Simple_Name(C);
   end;



   --==========================================================================
   --  places
   --==========================================================================

   package Place_Array_Pkg is new Generic_Array(Place, "=");
   All_Places: Place_Array_Pkg.Elements := Place_Array_Pkg.Empty_Elements;

   function Place_Name
     (P: in Place) return Ustring is
      Index: Positive;
   begin
      Place_Array_Pkg.Get_Index(All_Places, P, Index);
      return "P" & Index;
   end;



   --==========================================================================
   --  transitions
   --==========================================================================

   package Trans_Array_Pkg is new Generic_Array(Trans, "=");
   All_Trans: Trans_Array_Pkg.Elements := Trans_Array_Pkg.Empty_Elements;

   function Trans_Name
     (T: in Trans) return Ustring is
      Index: Positive;
   begin
      Trans_Array_Pkg.Get_Index(All_Trans, T, Index);
      return "T" & Index;
   end;



   --==========================================================================
   --  variables
   --==========================================================================

   package Var_Array_Pkg is new Generic_Array(Var, "=");
   All_Vars: Var_Array_Pkg.Elements := Var_Array_Pkg.Empty_Elements;

   function Var_Name
     (V: in Var) return Ustring is
      Index: Positive;
   begin
      Var_Array_Pkg.Get_Index(All_Vars, V, Index);
      case Get_Type(V) is
         when A_Net_Const => return "CONSTANT_" & Get_Name(V);
         when others      => return "V" & Index;
      end case;
   end;



   --==========================================================================
   --  functions
   --==========================================================================

   package Func_Array_Pkg is new Generic_Array(Func, "=");
   All_Funcs: Func_Array_Pkg.Elements := Func_Array_Pkg.Empty_Elements;

   function Func_Name
     (F: in Func) return Ustring is
      Index: Positive;
   begin
      Func_Array_Pkg.Get_Index(All_Funcs, F, Index);
      return "FUNCTION_" & Get_Name(F);
   end;

   function Imported_Func_Name
     (F: in Func) return Ustring is
   begin
      return "IMPORTED_FUNCTION_" & Get_Name(F);
   end;



   --==========================================================================
   --  expressions
   --==========================================================================

   package Expr_Array_Pkg is new Generic_Array(Expr, "=");
   All_Exprs: Expr_Array_Pkg.Elements := Expr_Array_Pkg.Empty_Elements;

   function Expr_Name
     (E: in Expr) return Ustring is
      Index: Positive;
   begin
      Expr_Array_Pkg.Get_Index(All_Exprs, E, Index);
      return "E" & Index;
   end;



   --==========================================================================
   --  Constants generated for color classes
   --==========================================================================

   function Cls_First_Const_Name
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FIRST_CONST_" & Simple_Name(C);
   end;

   function Cls_Last_Const_Name
     (C: in Cls) return Ustring is
   begin
      return "TYPE__LAST_CONST_" & Simple_Name(C);
   end;

   function Cls_Empty_Const_Name
     (C: in Cls) return Ustring is
   begin
      pragma Assert(Is_Container_Cls(C));
      return "TYPE__EMPTY_CONST_" & Simple_Name(C);
   end;

   function Cls_Card_Const_Name
     (C: in Cls) return Ustring is
   begin
      return "TYPE__CARD_CONST_" & Simple_Name(C);
   end;

   function Cls_Enum_Const_Name
     (C    : in Cls;
      Const: in Ustring) return Ustring is
   begin
      return "TYPE__ENUM_CONST_" & Simple_Name(C) & "__" & Const;
   end;



   --==========================================================================
   --  Operators generated for color classes
   --==========================================================================

   function Cls_Bin_Operator_Name
     (C : in Cls;
      Op: in Bin_Operator) return Ustring is
   begin
      return Cls_Bin_Operator_Name(C, C, Op);
   end;

   function Cls_Bin_Operator_Name
     (Lc: in Cls;
      Rc: in Cls;
      Op: in Bin_Operator) return Ustring is
   begin
      return "TYPE__OP_" &
        Simple_Name(Rc) & "__" &
        To_Ustring(Bin_Operator'Image(Op)) & "__" &
        Simple_Name(Lc);
   end;

   function Cls_Un_Operator_Name
     (C : in Cls;
      Op: in Un_Operator) return Ustring is
   begin
      return "TYPE__OP_" & Simple_Name(C) & "_" &
        To_Ustring(Un_Operator'Image(Op));
   end;

   function Cls_Cmp_Operator_Name
     (C: in Cls) return Ustring is
   begin
      return "TYPE__OP_" & Simple_Name(C) & "_cmp";
   end;



   --==========================================================================
   --  Functions generated for color classes
   --==========================================================================

   function Cls_Init_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_init";
   end;

   function Cls_Bit_Width_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_bit_width";
   end;

   function Cls_Encode_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_encode";
   end;

   function Cls_Decode_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_decode";
   end;

   function Cls_Print_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_print";
   end;

   function Cls_To_Xml_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_to_xml";
   end;

   function Cls_Assign_Comp_Func
     (C: in Cls;
      F: in Ustring) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_assign_" &
        Cls_Struct_Comp_Name(F);
   end;

   function Cls_Assign_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_assign";
   end;

   function Cls_Normalize_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_normalize";
   end;

   function Cls_Check_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_check";
   end;

   function Cls_Cast_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_cast";
   end;

   function Cls_Hash_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_hash";
   end;

   function Cls_Constructor_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_construct";
   end;

   function Cls_Prefix_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_firsts";
   end;

   function Cls_Suffix_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_lasts";
   end;

   function Cls_Slice_Func
     (C: in Cls) return Ustring is
   begin
      return "TYPE__FUNC_" & Simple_Name(C) & "_slice";
   end;



   --==========================================================================
   --  Other stuffs generated
   --==========================================================================

   function Cls_Struct_Comp_Name
     (Comp: in Ustring) return Ustring is
   begin
      return Comp;
   end;


end Pn.Compiler.Names;
