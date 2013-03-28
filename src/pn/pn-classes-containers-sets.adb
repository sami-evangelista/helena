with
  Pn.Compiler.Names,
  Pn.Compiler.Vectors,
  Pn.Exprs,
  Pn.Exprs.Containers,
  Pn.Exprs.Num_Consts;

use
  Pn.Compiler.Names,
  Pn.Compiler.Vectors,
  Pn.Exprs,
  Pn.Exprs.Containers,
  Pn.Exprs.Num_Consts;

package body Pn.Classes.Containers.Sets is

   function New_Set_Cls
     (Name    : in Ustring;
      Elements: in Cls;
      Capacity: in Expr) return Cls is
      Result: constant Set_Cls := new Set_Cls_Record;
   begin
      Initialize(Result, Name, Elements, Capacity);
      return Cls(Result);
   end;

   function Get_Type
     (C: in Set_Cls_Record) return Cls_Type is
   begin
      return A_Set_Cls;
   end;

   function Colors_Used
     (C: in Set_Cls_Record) return Cls_Set is
   begin
      return New_Cls_Set((1 => C.Elements));
   end;

   procedure Compile_Operators
     (C  : in Set_Cls_Record;
      Lib: in Library) is
      Prototype   : Ustring;
      Cc          : constant Container_Cls := Container_Cls(C.Me);
      Elements_Cls: constant Cls := Get_Elements_Cls(Cc);
      Subset_Func : constant USTRING := Cls_Name(C.Me) & "_subset";
      Cap         : constant Num_Type := Get_Capacity_Value(Cc);
   begin
      Compile_Operators(Container_Cls_Record(C), Lib);

      Plh(Lib, "#define " & Cls_Name(C.Me) & "_shiftLR(_set, _index) { \");
      Plh(Lib, 1, "int _i = _set.length; \");
      Plh(Lib, 1, "for(; _i > _index; _i --) { \");
      Plh(Lib, 2, "_set.items[_i] = _set.items[_i - 1]; \");
      Plh(Lib, 1, "} \");
      Plh(Lib, 1, "_set.length ++; \");
      Plh(Lib, "}");
      Plh(Lib, "#define " & Cls_Name(C.Me) & "_shiftRL(_set, _index) { \");
      Plh(Lib, 1, "int _i = _index; \");
      Plh(Lib, 1, "for(; _i < _set.length - 1; _i ++) { \");
      Plh(Lib, 2, "_set.items[_i] = _set.items[_i + 1]; \");
      Plh(Lib, 1, "} \");
      Plh(Lib, 1, "_set.length --; \");
      Plh(Lib, "}");

      --===
      --  or
      --===
      Prototype :=
        Cls_Name(C.Me) & " " & Cls_Bin_Operator_Name(C.Me, C.Me, Or_Op) & Nl &
        "(" & Cls_Name(C.Me) & " left," & Nl &
        " " & Cls_Name(C.Me) & " right)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "bool_t insert;");
      Plc(Lib, 1, Cls_Name(C.Me) & " result = left;");
      Plc(Lib, 1, "int i = 0, j = 0, cmp ;");
      Plc(Lib, 1, "for(; i < right.length; i++) {");
      Plc(Lib, 2, "insert = TRUE;");
      Plc(Lib, 2, "for(; j < result.length; j++) {");
      Plc(Lib, 3, "cmp = " & Cls_Cmp_Operator_Name(C.Elements) &
          "(right.items[i], result.items[j]);");
      Plc(Lib, 3, "if(LESS == cmp) break;");
      Plc(Lib, 3, "else if(EQUAL == cmp) { insert = FALSE; break; }");
      Plc(Lib, 2, "}");
      Plc(Lib, 2, "if(insert) {");
      Plc(Lib, 3, "if(result.length + 1 > " & Cap & ") {");
      Plc(Lib, 4, "raise_error(""container capacity exceeded"");");
      Plc(Lib, 4, "return " & Cls_First_Const_Name(C.Me) & ";");
      Plc(Lib, 3, "}");
      Plc(Lib, 3, Cls_Name(C.Me) & "_shiftLR(result, j);");
      Plc(Lib, 3, "result.items[j] = right.items[i];");
      Plc(Lib, 2, "}");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
      Prototype :=
        Cls_Name(C.Me) & " " & Cls_Bin_Operator_Name(C.Me, C.Elements, Or_Op) &
        Nl &
        "(" & Cls_Name(C.Me) & " left," & Nl &
        " " & Cls_Name(C.Elements) & " right)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "bool_t insert;");
      Plc(Lib, 1, Cls_Name(C.Me) & " result = left;");
      Plc(Lib, 1, "int i = 0, cmp ;");
      Plc(Lib, 1, "insert = TRUE;");
      Plc(Lib, 1, "for(; i < result.length; i++) {");
      Plc(Lib, 2, "cmp = " & Cls_Cmp_Operator_Name(C.Elements) &
          "(right, result.items[i]);");
      Plc(Lib, 2, "if(LESS == cmp) break;");
      Plc(Lib, 2, "else if(EQUAL == cmp) { insert = FALSE; break; }");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "if(insert) {");
      Plc(Lib, 2, "if(result.length + 1 > " & Cap & ") {");
      Plc(Lib, 3, "raise_error(""container capacity exceeded"");");
      Plc(Lib, 3, "return " & Cls_First_Const_Name(C.Me) & ";");
      Plc(Lib, 2, "}");
      Plc(Lib, 2, Cls_Name(C.Me) & "_shiftLR(result, i);");
      Plc(Lib, 2, "result.items[i] = right;");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
      Plh(Lib, "#define "  & Cls_Bin_Operator_Name(C.Elements, C.Me, Or_Op) &
          "(left, right) " & Cls_Bin_Operator_Name(C.Me, C.Elements, Or_Op) &
          "(right, left)");

      --===
      --  and
      --===
      Prototype :=
        Cls_Name(C.Me) & " " &
        Cls_Bin_Operator_Name(C.Me, C.Me, And_Op) & Nl &
        "(" & Cls_Name(C.Me) & " left," & Nl &
        " " & Cls_Name(C.Me) & " right)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "bool_t delete;");
      Plc(Lib, 1, Cls_Name(C.Me) & " result = left;");
      Plc(Lib, 1, "int i = 0, j = 0, cmp;");
      Plc(Lib, 1, "for(; i < result.length; i++) {");
      Plc(Lib, 2, "delete = TRUE;");
      Plc(Lib, 2, "for(; j < right.length; j++) {");
      Plc(Lib, 3, "cmp = " & Cls_Cmp_Operator_Name(C.Elements) &
          "(result.items[i], right.items[j]);");
      Plc(Lib, 3, "if(LESS == cmp) break;");
      Plc(Lib, 3, "else if(EQUAL == cmp) { delete = FALSE; break; }");
      Plc(Lib, 2, "}");
      Plc(Lib, 2, "if(delete) {");
      Plc(Lib, 3, Cls_Name(C.Me) & "_shiftRL(result, i);");
      Plc(Lib, 3, "i --;");
      Plc(Lib, 2, "}");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
      Prototype :=
        Cls_Name(C.Me) & " " &
        Cls_Bin_Operator_Name(C.Me, C.Elements, And_Op) & Nl &
        "(" & Cls_Name(C.Me) & " left," & Nl &
        " " & Cls_Name(C.Elements) & " right)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, Cls_Name(C.Me) & " result;");
      Plc(Lib, 1, "int i = 0, j = 0, cmp = LESS;");
      Plc(Lib, 1, "for(; i < left.length; i++) {");
      Plc(Lib, 2, "cmp = " & Cls_Cmp_Operator_Name(C.Elements) &
          "(right, left.items[i]);");
      Plc(Lib, 2, "if((GREATER == cmp) || (EQUAL == cmp)) break;");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "if(EQUAL == cmp) {");
      Plc(Lib, 2, "result.length = 1;");
      Plc(Lib, 2, "result.items[0] = right;");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "else {");
      Plc(Lib, 2, "result.length = 0;");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
      Plh(Lib, "#define "  & Cls_Bin_Operator_Name(C.Elements, C.Me, And_Op) &
          "(left, right) " & Cls_Bin_Operator_Name(C.Me, C.Elements, And_Op) &
          "(right, left)");

      --===
      --  - (difference of two sets)
      --===
      Prototype :=
        Cls_Name(C.Me) & " " &
        Cls_Bin_Operator_Name(C.Me, C.Me, Minus_Op) & Nl &
        "(" & Cls_Name(C.Me) & " left," & Nl &
        " " & Cls_Name(C.Me) & " right)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "bool_t delete;");
      Plc(Lib, 1, Cls_Name(C.Me) & " result = left;");
      Plc(Lib, 1, "int i, j, cmp ;");
      Plc(Lib, 1, "for(i = 0; i < right.length; i++) {");
      Plc(Lib, 2, "delete = FALSE;");
      Plc(Lib, 2, "for(j = 0; j < result.length; j++) {");
      Plc(Lib, 3, "cmp = " & Cls_Cmp_Operator_Name(C.Elements) &
          "(right.items[i], result.items[j]);");
      Plc(Lib, 3, "if(LESS == cmp) break;");
      Plc(Lib, 3, "else if(EQUAL == cmp) { delete = TRUE; break; }");
      Plc(Lib, 2, "}");
      Plc(Lib, 2, "if(delete) {");
      Plc(Lib, 3, Cls_Name(C.Me) & "_shiftRL(result, j);");
      Plc(Lib, 2, "}");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");

      --===
      --  - (difference of a set and an item)
      --===
      Prototype :=
        Cls_Name(C.Me) & " " &
        Cls_Bin_Operator_Name(C.Me, C.Elements, Minus_Op) & Nl &
        "(" & Cls_Name(C.Me) & " left," & Nl &
        " " & Cls_Name(C.Elements) & " right)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "bool_t delete;");
      Plc(Lib, 1, Cls_Name(C.Me) & " result = left;");
      Plc(Lib, 1, "int i, j, cmp ;");
      Plc(Lib, 1, "delete = FALSE;");
      Plc(Lib, 1, "for(j = 0; j < result.length; j++) {");
      Plc(Lib, 2, "cmp = " & Cls_Cmp_Operator_Name(C.Elements) &
          "(right, result.items[j]);");
      Plc(Lib, 2, "if(LESS == cmp) break;");
      Plc(Lib, 2, "else if(EQUAL == cmp) { delete = TRUE; break; }");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "if(delete) {");
      Plc(Lib, 2, Cls_Name(C.Me) & "_shiftRL(result, j);");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");

      --===
      --  subset function used by the comparison operators
      --===
      Prototype :=
        "bool_t " & Subset_Func & Nl &
        "(" & Cls_Name(C.Me) & " left," & Nl &
        " " & Cls_Name(C.Me) & " right," & Nl &
        " bool_t strict)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "int i = 0, j = 0, cmp;");
      Plc(Lib, 1, "if(left.length > right.length");
      Plc(Lib, 1, "|| (strict && left.length == right.length)) return FALSE;");
      Plc(Lib, 1, "for(; i < left.length; i++) {");
      Plc(Lib, 2, "for(; j < right.length; j++) {");
      Plc(Lib, 3, "cmp = " & Cls_Cmp_Operator_Name(C.Elements) &
          "(left.items[i], right.items[j]);");
      Plc(Lib, 3, "if(LESS == cmp) return FALSE;");
      Plc(Lib, 3, "if(EQUAL  == cmp) break;");
      Plc(Lib, 2, "}");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "return TRUE;");
      Plc(Lib, "}");

      --===
      --  >=
      --===
      Plh(Lib, "#define " & Cls_Bin_Operator_Name(C.Me, Sup_Eq_Op) &
          "(_left, _right) (" & Subset_Func & "(_right, _left, FALSE))");

      --===
      --  >
      --===
      Plh(Lib, "#define " & Cls_Bin_Operator_Name(C.Me, Sup_Op) &
          "(_left, _right) (" & Subset_Func & "(_right, _left, TRUE))");

      --===
      --  <=
      --===
      Plh(Lib, "#define " & Cls_Bin_Operator_Name(C.Me, Inf_Eq_Op) &
          "(_left, _right) " & Cls_Bin_Operator_Name(C.Me, Sup_Eq_Op) &
          "(_right, _left)");

      --===
      --  <
      --===
      Plh(Lib, "#define " & Cls_Bin_Operator_Name(C.Me, Inf_Op) &
          "(_left, _right) " & Cls_Bin_Operator_Name(C.Me, Sup_Op) &
          "(_right, _left)");
   end;

   procedure Compile_Others
     (C  : in Set_Cls_Record;
      Lib: in Library) is
      Prototype: Ustring;
      Assigned : Ustring;
      Cap      : constant Num_Type := Get_Capacity_Value(Container_Cls(C.Me));
   begin
      Compile_Others(Container_Cls_Record(C), Lib);

      --===
      --  construction function
      --===
      Prototype :=
        Cls_Name(C.Me) & " " & Cls_Constructor_Func(C.Me) & " (" & Nl &
        "   int args_nb," & Nl &
        "   ...)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "int cmp;");
      Plc(Lib, 1, "bool_t insert;");
      Plc(Lib, 1, Cls_Name(C.Me) & " result;");
      Plc(Lib, 1, Cls_Name(C.Elements) & " item;");
      Plc(Lib, 1, "va_list argp;");
      Plc(Lib, 1, "unsigned int i = 0, j = 0;");
      Plc(Lib, 1, "va_start(argp, args_nb);");
      Plc(Lib, 1, "result.length = 0;");
      Plc(Lib, 1, "for(; i != args_nb; i++) {");
      if Is_Discrete(C.Elements) then
         Assigned := "(" & Cls_Name(C.Elements) & ") va_arg(argp, int)";
      else
         Assigned := "va_arg(argp, " & Cls_Name(C.Elements) & ")";
      end if;
      Plc(Lib, 2, "item = " & Assigned & ";");
      Plc(Lib, 2, "insert = TRUE;");
      Plc(Lib, 2, "for(j = 0; j != result.length; j++) {");
      Plc(Lib, 3, "cmp = " & Cls_Cmp_Operator_Name(C.Elements) &
          "(item, result.items[j]);");
      Plc(Lib, 3, "if(LESS == cmp) break;");
      Plc(Lib, 3, "else if(EQUAL == cmp) { insert = FALSE; break; }");
      Plc(Lib, 2, "}");
      Plc(Lib, 2, "if(insert) {");
      Plc(Lib, 3, "if(result.length + 1 > " & Cap & ") {");
      Plc(Lib, 4, "raise_error(""container capacity exceeded"");");
      Plc(Lib, 4, "return " & Cls_First_Const_Name(C.Me) & ";");
      Plc(Lib, 3, "}");
      Plc(Lib, 3, Cls_Name(C.Me) & "_shiftLR(result, j);");
      Plc(Lib, 2, "}");
      Plc(Lib, 2, "result.items[j] = item;");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
   end;

end Pn.Classes.Containers.Sets;
