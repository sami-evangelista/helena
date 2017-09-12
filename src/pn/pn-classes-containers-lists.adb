with
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Exprs.Containers,
  Pn.Exprs.Num_Consts;

use
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Exprs.Containers,
  Pn.Exprs.Num_Consts;

package body Pn.Classes.Containers.Lists is

   function New_List_Cls
     (Name    : in Ustring;
      Elements: in Cls;
      Index   : in Cls;
      Capacity: in Expr) return Cls is
   begin
      --===
      --  the index class must be a discrete color class
      --===
      pragma Assert(Is_Discrete(Index));

      declare
         Result: constant List_Cls := new List_Cls_Record;
      begin
         Initialize(Result, Name, Elements, Capacity);
         Result.Index := Index;
         return Cls(Result);
      end;
   end;

   function Get_Type
     (C: in List_Cls_Record) return Cls_Type is
   begin
      return A_List_Cls;
   end;

   function Colors_Used
     (C: in List_Cls_Record) return Cls_Set is
   begin
      return New_Cls_Set((C.Elements, C.Index));
   end;

   procedure Compile_Operators
     (C  : in List_Cls_Record;
      Lib: in Library) is
      Prototype   : Ustring;
      Cc          : constant Container_Cls := Container_Cls(C.Me);
      Elements_Cls: constant Cls := Get_Elements_Cls(Cc);
      Cap         : constant Num_Type := Get_Capacity_Value(Cc);
   begin
      Compile_Operators(Container_Cls_Record(C), Lib);

      --===
      --  concatenation operators
      --===
      Prototype :=
        Cls_Name(C.Me) & " " &
        Cls_Bin_Operator_Name(C.Me, C.Me, Concat_Op) & Nl &
        "(" & Cls_Name(C.Me) & " left," & Nl &
        " " & Cls_Name(C.Me) & " right)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & "{");
      Plc(Lib, 1, Cls_Name(C.Me) & " result = left;");
      Plc(Lib, 1, "if(left.length + right.length > " & Cap &
            ") {");
      Plc(Lib, 2, "raise_error(""list overflow"");");
      Plc(Lib, 2, "return " & Cls_First_Const_Name(C.Me) & ";");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "unsigned int i = 0;");
      Plc(Lib, 1, "for(; i<right.length; i++)");
      Plc(Lib, 2, "result.items[i + result.length] = right.items[i];");
      Plc(Lib, 1, "result.length += right.length;");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
      Prototype :=
        Cls_Name(C.Me) & " " &
        Cls_Bin_Operator_Name(Elements_Cls, C.Me, Concat_Op) & Nl &
        "(" & Cls_Name(Elements_Cls) & " left," & Nl &
        " " & Cls_Name(C.Me) & " right)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & "{");
      Plc(Lib, 1, Cls_Name(C.Me) & " result;");
      Plc(Lib, 1, "unsigned int i = 0;");
      Plc(Lib, 1, "if(right.length + 1 > " & Cap & ") {");
      Plc(Lib, 2, "raise_error(""list overflow"");");
      Plc(Lib, 2, "return " & Cls_First_Const_Name(C.Me) & ";");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "result.length = 1 + right.length;");
      Plc(Lib, 1, "result.items[0] = left;");
      Plc(Lib, 1, "for(; i<right.length; i++)");
      Plc(Lib, 2, "result.items[i + 1] = right.items[i];");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
      Prototype :=
        Cls_Name(C.Me) & " " &
        Cls_Bin_Operator_Name(C.Me, Elements_Cls, Concat_Op) & Nl &
        "(" & Cls_Name(C.Me) & " left," & Nl &
        " " & Cls_Name(Elements_Cls) & " right)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & "{");
      Plc(Lib, 1, Cls_Name(C.Me) & " result = left;");
      Plc(Lib, 1, "if(left.length + 1 > " & Cap & ") {");
      Plc(Lib, 2, "raise_error(""list overflow"");");
      Plc(Lib, 2, "return " & Cls_First_Const_Name(C.Me) & ";");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "result.items[result.length] = right;");
      Plc(Lib, 1, "result.length ++;");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
   end;

   procedure Compile_Others
     (C  : in List_Cls_Record;
      Lib: in Library) is
      Prototype: Ustring;
      Assigned: Ustring;
      S        : Expr := Low_Value(C.Index);
      Shift    : constant Ustring :=
        Compile_Evaluation(S, Empty_Var_Mapping, False);
      Cap      : constant Num_Type := Get_Capacity_Value(Container_Cls(C.Me));
   begin
      Free(S);
      Compile_Others(Container_Cls_Record(C), Lib);

      --===
      --  construction function
      --===
      Prototype :=
        Cls_Name(C.Me) & " " & Cls_Constructor_Func(C.Me) & Nl &
        "(int args_nb," & Nl &
        " ...)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & "{");
      Plc(Lib, 1, Cls_Name(C.Me) & " result;");
      Plc(Lib, 1, "va_list argp;");
      Plc(Lib, 1, "unsigned int i = 0;");
      Plc(Lib, 1, "va_start(argp, args_nb);");
      Plc(Lib, 1, "if(args_nb > " & Cap & ") {");
      Plc(Lib, 2, "raise_error(""container capacity exceeded"");");
      Plc(Lib, 2, "return " & Cls_First_Const_Name(C.Me) & ";");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "if(args_nb < 1)");
      Plc(Lib, 2, "return " & Cls_First_Const_Name(C.Me) & ";");
      Plc(Lib, 1, "result.length = args_nb;");
      Plc(Lib, 1, "for(; i != args_nb; i++) {");
      if Is_Discrete(C.Elements) then
         Assigned := "(" & Cls_Name(C.Elements) & ") va_arg(argp, int)";
      else
         Assigned := "va_arg(argp, " & Cls_Name(C.Elements) & ")";
      end if;
      Plc(Lib, 2, "result.items[i] = " & Assigned & ";");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "va_end(argp);");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");

      --===
      --  prefix function
      --===
      Prototype :=
        Cls_Name(C.Me) & " " & Cls_Prefix_Func(C.Me) & Nl &
        "(" & Cls_Name(C.Me) & " expr)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & "{");
      Plc(Lib, 1, Cls_Name(C.Me) & " result = expr;");
      Plc(Lib, 1, "if(result.length == 0) {");
      Plc(Lib, 2, "raise_error(""getting first elements of an empty list"");");
      Plc(Lib, 2, "return " & Cls_First_Const_Name(C.Me) & ";");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "result.length --;");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");

      --===
      --  suffix function
      --===
      Prototype :=
        Cls_Name(C.Me) & " " & Cls_Suffix_Func(C.Me) & Nl &
        "(" & Cls_Name(C.Me) & " expr)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & "{");
      Plc(Lib, 1, Cls_Name(C.Me) & " result = expr;");
      Plc(Lib, 1, "unsigned int i = 0;");
      Plc(Lib, 1, "if(result.length == 0) {");
      Plc(Lib, 2, "raise_error(""getting last elements of an empty list"");");
      Plc(Lib, 2, "return " & Cls_First_Const_Name(C.Me) & ";");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "for(; i < expr.length - 1; i ++)");
      Plc(Lib, 2, "result.items[i] = expr.items[i + 1];");
      Plc(Lib, 1, "result.length --;");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");

      --===
      --  slice function
      --===
      Prototype :=
        Cls_Name(C.Me) & " " & Cls_Slice_Func(C.Me) & Nl &
        "(" & Cls_Name(C.Me)    & " expr,"  & Nl &
        " " & Cls_Name(C.Index) & " first," & Nl &
        " " & Cls_Name(C.Index) & " last)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & "{");
      Plc(Lib, 1, Cls_Name(C.Me) & " result;");
      Plc(Lib, 1, "unsigned int i;");
      Plc(Lib, 1, "unsigned long F = first - " & Shift & ";");
      Plc(Lib, 1, "unsigned long L = last  - " & Shift & ";");
      Plc(Lib, 1, "if(F >= expr.length) {");
      Plc(Lib, 2, "raise_error(""invalid first index for list slice"");");
      Plc(Lib, 2, "return " & Cls_First_Const_Name(C.Me) & ";");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "if(L >= expr.length) {");
      Plc(Lib, 2, "raise_error(""invalid last index for list slice"");");
      Plc(Lib, 2, "return " & Cls_First_Const_Name(C.Me) & ";");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "for(i = F; i <= L; i ++)");
      Plc(Lib, 2, "result.items[i - F] = expr.items[i];");
      Plc(Lib, 1, "result.length = (L >= F) ? (L - F + 1): 0;");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");

      --===
      --  assignement function
      --===
      Prototype :=
        Cls_Name(C.Me) & " " &
        Cls_Assign_Func(C.Me) & Nl &
        "(" & Cls_Name(C.Me) & " list," & Nl &
        " " & Cls_Name(C.Elements) & " val," & Nl &
        " " & Cls_Name(C.Index) & " index)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & "{");
      Plc(Lib, 1, Cls_Name(C.Me) & " result = list;");
      Plc(Lib, 1, "unsigned long I = index - " & Shift & ";");
      Plc(Lib, 1, "if(I >= list.length) {");
      Plc(Lib, 2, "raise_error(""invalid list index"");");
      Plc(Lib, 2, "return " & Cls_First_Const_Name(C.Me) & ";");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "result.items[I] = val;");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
   end;

   function Get_Index_Cls
     (L: in List_Cls) return Cls is
   begin
      return L.Index;
   end;

end Pn.Classes.Containers.Lists;
