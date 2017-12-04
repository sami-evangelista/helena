--=============================================================================
--
--  Package: Pn.Compiler.Names
--
--  This package allows to give an unique name in the generated code
--  to each element (place, transition, variable, ...).  By this we
--  guarantee that there will have no conflict name in the generated
--  code.
--
--=============================================================================


package Pn.Compiler.Names is

   function Cls_Name
     (C: in Cls) return Ustring;

   function Place_Name
     (P: in Place) return Ustring;

   function Trans_Name
     (T: in Trans) return Ustring;

   function Var_Name
     (V: in Var) return Ustring;

   function Func_Name
     (F: in Func) return Ustring;

   function Imported_Func_Name
     (F: in Func) return Ustring;

   function Expr_Name
     (E: in Expr) return Ustring;



   --==========================================================================
   --  Group: Constants generated for color classes
   --==========================================================================

   function Cls_First_Const_Name
     (C: in Cls) return Ustring;

   function Cls_Last_Const_Name
     (C: in Cls) return Ustring;

   function Cls_Empty_Const_Name
     (C: in Cls) return Ustring;

   function Cls_Card_Const_Name
     (C: in Cls) return Ustring;

   function Cls_Enum_Const_Name
     (C    : in Cls;
      Const: in Ustring) return Ustring;



   --==========================================================================
   --  Group: Operators generated for color classes
   --==========================================================================

   function Cls_Bin_Operator_Name
     (C: in Cls;
      Op: in Bin_Operator) return Ustring;

   function Cls_Bin_Operator_Name
     (Lc: in Cls;
      Rc: in Cls;
      Op: in Bin_Operator) return Ustring;

   function Cls_Un_Operator_Name
     (C: in Cls;
      Op: in Un_Operator) return Ustring;

   function Cls_Cmp_Operator_Name
     (C: in Cls) return Ustring;



   --==========================================================================
   --  Group: Functions generated for color classes
   --==========================================================================

   function Cls_Init_Func
     (C: in Cls) return Ustring;

   function Cls_Bit_Width_Func
     (C: in Cls) return Ustring;

   function Cls_Encode_Func
     (C: in Cls) return Ustring;

   function Cls_Decode_Func
     (C: in Cls) return Ustring;

   function Cls_Print_Func
     (C: in Cls) return Ustring;

   function Cls_To_Xml_Func
     (C: in Cls) return Ustring;

   function Cls_Assign_Comp_Func
     (C: in Cls;
      F: in Ustring) return Ustring;

   function Cls_Assign_Func
     (C: in Cls) return Ustring;

   function Cls_Constructor_Func
     (C: in Cls) return Ustring;

   function Cls_Cast_Func
     (C: in Cls) return Ustring;

   function Cls_Normalize_Func
     (C: in Cls) return Ustring;

   function Cls_Check_Func
     (C: in Cls) return Ustring;

   function Cls_Hash_Func
     (C: in Cls) return Ustring;

   function Cls_Prefix_Func
     (C: in Cls) return Ustring;

   function Cls_Suffix_Func
     (C: in Cls) return Ustring;

   function Cls_Slice_Func
     (C: in Cls) return Ustring;



   --==========================================================================
   --  Group: Other stuffs generated for color classes
   --==========================================================================

   function Cls_Struct_Comp_Name
     (Comp: in Ustring) return Ustring;

end Pn.Compiler.Names;
