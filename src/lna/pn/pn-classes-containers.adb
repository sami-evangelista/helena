with
  Pn.Compiler,
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Exprs.Num_Consts,
  Pn.Exprs.Containers,
  Utils.Math;

use
  Pn.Compiler,
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Exprs.Num_Consts,
  Pn.Exprs.Containers,
  Utils.Math;

package body Pn.Classes.Containers is

   procedure Initialize
     (C       : access Container_Cls_Record'Class;
      Name    : in     Ustring;
      Elements: in     Cls;
      Capacity: in     Expr) is
   begin
      --===
      --  the capacity must be statically evaluable
      --===
      pragma Assert(Is_Static(Capacity));

      Initialize(C, Name);
      C.Elements := Elements;
      C.Capacity := Capacity;
   end;

   function Get_Elements_Cls
     (C: access Container_Cls_Record) return Cls is
   begin
      return C.Elements;
   end;

   function Get_Capacity_Value
     (C: access Container_Cls_Record) return Num_Type is
      State : Evaluation_State;
      Const : Expr;
      Result: Num_Type;
   begin
      pragma Assert(C.Capacity /= null);
      Evaluate_Static(E      => C.Capacity,
		      Check  => False,
		      Result => Const,
		      State  => State);
      pragma Assert(Is_Success(State));
      Result := Get_Const(Num_Const(Const));
      Free(Const);
      pragma Assert(Result <= Max_Container_Capacity);
      return Result;
   end;

   procedure Free
     (C: in out Container_Cls_Record) is
   begin
      if C.Capacity /= null then
         Free(C.Capacity);
      end if;
   end;

   function Low_Value
     (C: in Container_Cls_Record) return Expr is
   begin
      return null;
   end;

   function High_Value
     (C: in Container_Cls_Record) return Expr is
   begin
      return null;
   end;

   procedure Card
     (C     : in     Container_Cls_Record;
      Result:    out Card_Type;
      State :    out Count_State) is
   begin
      State := Count_Infinite;
      Result := 0;
   end;

   function Ith_Value
     (C: in Container_Cls_Record;
      I: in Card_Type) return Expr is
   begin
      return null;
   end;

   function Get_Value_Index
     (C: in     Container_Cls_Record;
      E: access Expr_Record'Class) return Card_Type is
   begin
      return 0;
   end;

   function Elements_Size
     (C: in Container_Cls_Record) return Natural is
   begin
      return Natural(Get_Capacity_Value(Container_Cls(C.Me)));
   end;

   function Basic_Elements_Size
     (C: in Container_Cls_Record) return Natural is
   begin
      return Elements_Size(C) * Basic_Elements_Size(C.Elements);
   end;

   function Is_Const_Of_Cls
     (C: in     Container_Cls_Record;
      E: access Expr_Record'Class) return Boolean is
      Result: Boolean := True;
      L     : Expr_List;
      Ex    : Expr;
      Cap   : constant Num_Type := Get_Capacity_Value(Container_Cls(C.Me));
   begin
      --===
      --  1 - the expression must be a container
      --  2 - its length must not exceed the capacity of the list class
      --  3 - all the elements of the list must be constants of the element
      --      class of C
      --===
      if Get_Type(E) /= A_Container then  -- 1
         Result := False;
      else
         L := Get_Expr_List(Container(E));
         if Num_Type(Length(L)) > Cap then  -- 2
            Result := False;
         else
            for I in 1..Length(L) loop  -- 3
               Ex := Ith(L, I);
               if not Is_Const_Of_Cls(C.Elements, Ex) then
                  Result := False;
                  exit;
               end if;
            end loop;
         end if;
      end if;
      return Result;
   end;

   function Colors_Used
     (C: in Container_Cls_Record) return Cls_Set is
   begin
      return New_Cls_Set((1 => C.Elements));
   end;

   function Has_Constant_Bit_Width
     (C: in Container_Cls_Record) return Boolean is
   begin
      return False;
   end;

   function Bit_Width
     (C: in Container_Cls_Record) return Natural is
   begin
      pragma Assert(False);
      return 0;
   end;

   procedure Compile_Type_Definition
     (C  : in Container_Cls_Record;
      Lib: in Library) is
      Me : constant Container_Cls := Container_Cls(C.Me);
      Cap: constant Num_Type := Get_Capacity_Value(Me);
   begin
      Plh(Lib, "typedef struct {");
      Plh(Lib, 1, Cls_Name(C.Elements) & " items[" & Cap & "];");
      Plh(Lib, 1, "unsigned int length;");
      Plh(Lib, "} " & Cls_Name(C.Me) & ";");
   end;

   procedure Compile_Constants
     (C  : in Container_Cls_Record;
      Lib: in Library) is
   begin
      --===
      --  constants of the type: first, last and empty
      --===
      Plh(Lib, Cls_Name(C.Me) & " " & Cls_First_Const_Name(C.Me) & ";");
      Plh(Lib, Cls_Name(C.Me) & " " & Cls_Last_Const_Name(C.Me)  & ";");
      Plh(Lib, Cls_Name(C.Me) & " " & Cls_Empty_Const_Name(C.Me) & ";");
   end;

   procedure Compile_Operators
     (C  : in Container_Cls_Record;
      Lib: in Library) is
      function Get_Prot
        (Op: in Bin_Operator) return Ustring is
      begin
         return
           Cls_Name(Bool_Cls) & " " & Cls_Bin_Operator_Name(C.Me, Op) &
           "_func" & Nl &
           "(" & Cls_Name(C.Me) & " left," & Nl &
           " " & Cls_Name(C.Me) & " right)";
      end;

      False_Str: constant Ustring :=
        Cls_Enum_Const_Name(Bool_Cls, False_Const_Name);
      True_Str: constant Ustring :=
        Cls_Enum_Const_Name(Bool_Cls, True_Const_Name);
      Prototype: Ustring;
   begin
      Plh(Lib, "#define " & Cls_Normalize_Func(C.Me) & "(_val) (_val)");
      Plh(Lib, "#define " & Cls_Check_Func(C.Me) & "(_val) (_val)");
      Plh(Lib, "#define " & Cls_Cast_Func(C.Me) & "(_val) (_val)");

      --===
      --  =
      --===
      Plh(Lib, Get_Prot(Eq_Op) & ";");
      Plc(Lib, Get_Prot(Eq_Op) & "{");
      Plc(Lib, 1, "unsigned int i = 0;");
      Plc(Lib, 1, "for(; i < left.length; i++) {");
      Plc(Lib, 2, "if(" & Cls_Bin_Operator_Name(C.Elements, Neq_Op) &
          "(left.items[i], right.items[i]))");
      Plc(Lib, 3, "return " & False_Str & ";");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "return " & True_Str & ";");
      Plc(Lib, "}");
      Plh(Lib, "#define " & Cls_Bin_Operator_Name(C.Me, Eq_Op) &
          "(_left, _right) (((_left).length == (_right).length) && " &
          Cls_Bin_Operator_Name(C.Me, Eq_Op) & "_func(_left, _right))");

      --===
      --  /=
      --===
      Plh(Lib, "#define " & Cls_Bin_Operator_Name(C.Me, Neq_Op) &
          "(_left, _right) " &
          "(!" & Cls_Bin_Operator_Name(C.Me, Eq_Op) & "(_left, _right))");

      --===
      --  comparison operator
      --===
      Prototype :=
        "int " & Cls_Cmp_Operator_Name(C.Me) & "_func" & Nl &
        "(" & Cls_Name(C.Me) & " *left," & Nl &
        " " & Cls_Name(C.Me) & " *right)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & "{");
      Plc(Lib, 1, "unsigned int i = 0;");
      Plc(Lib, 1, "for(; i < left->length; i++) {");
      Plc(Lib, 2, "switch(" & Cls_Cmp_Operator_Name(C.Elements) &
          "(left->items[i], right->items[i])) {");
      Plc(Lib, 3, "case GREATER: return GREATER;");
      Plc(Lib, 3, "case LESS   : return LESS;");
      Plc(Lib, 2, "}");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "return EQUAL;");
      Plc(Lib, "}");
      Plh(Lib, "#define " & Cls_Cmp_Operator_Name(C.Me) & "(_left, _right) " &
	    "(((_left).length > (_right).length) ? GREATER: " &
	    "((_left).length < (_right).length ? LESS: " &
	    Cls_Cmp_Operator_Name(C.Me) & "_func(&(_left), &(_right))))");

      --===
      --  in operator
      --===
      Prototype :=
        "bool_t " & Cls_Bin_Operator_Name(C.Elements, C.Me, In_Op) & Nl &
        "(" & Cls_Name(C.Elements) & " item," & Nl &
        " " & Cls_Name(C.Me) & " container)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & "{");
      Plc(Lib, 1, "int i = 0;");
      Plc(Lib, 1, "for(; i < container.length; i++) {");
      Plc(Lib, 2, "if(" & Cls_Bin_Operator_Name(C.Elements, Eq_Op) &
          "(container.items[i], item))");
      Plc(Lib, 2, "return TRUE;");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "return FALSE;");
      Plc(Lib, "}");
   end;

   procedure Compile_Encoding_Functions
     (C  : in Container_Cls_Record;
      Lib: in Library) is
      Cap_Size : constant Natural :=
	Bit_Width(Big_Nat(Get_Capacity_Value(Container_Cls(C.Me))) + 1);
      Var      : Ustring;
      Prototype: Ustring;
   begin
      --===
      --  bit width
      --===
      if Has_Constant_Bit_Width(C.Elements) then
         Plh(Lib, "#define " & Cls_Bit_Width_Func(C.Me) & "(_item) " &
             "((_item.length * " & Bit_Width(C.Elements) & ") + " &
             (2 * Cap_Size) & ")");
      else
         Prototype :=
           "unsigned int " & Cls_Bit_Width_Func(C.Me) & "_func" &
           "(" & Cls_Name(C.Me) & " *item)";
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype & "{");
         Plc(Lib, 1, "unsigned int result = " & (2 * Cap_Size) & ", i = 0;");
         Plc(Lib, 1, "for(; i<item->length; i++) {");
         Plc(Lib, 2, "result += " & Cls_Bit_Width_Func(C.Elements) &
             "(item->items[i]);");
         Plc(Lib, 1, "}");
         Plc(Lib, 1, "return result;");
         Plc(Lib, "}");
         Plh(Lib, "#define " & Cls_Bit_Width_Func(C.Me) & "(_item) " &
             Cls_Bit_Width_Func(C.Me) & "_func(&_item)");
      end if;

      --===
      --  encoding function
      --===
      Var := Cls_Encode_Func(C.Me) & "_i";
      Plh(Lib, "#define " & Cls_Encode_Func(C.Me) & "(_item, _v) \");
      Plh(Lib, "{ \");
      Plh(Lib, 1, "unsigned int " & Var & "; \");
      Plh(Lib, 1, Bit_Stream_Set_Func(Cap_Size) & "(_v, _item.length); \");
      Plh(Lib, 1, "for(" & Var & " = 0; " & Var & " < _item.length; " & Var &
          " ++) { \");
      Plh(Lib, 2,
          Cls_Encode_Func(C.Elements) & "(_item.items[" & Var & "], _v); \");
      Plh(Lib, 1, "} \");
      Plh(Lib, 1, Bit_Stream_Set_Func(Cap_Size) & "(_v, _item.length); \");
      Plh(Lib, "}");

      --===
      --  decoding function
      --===
      Var := Cls_Decode_Func(C.Me) & "_i";
      Plh(Lib, "#define " & Cls_Decode_Func(C.Me) & "(_v, _item) \");
      Plh(Lib, "{ \");
      Plh(Lib, 1, "int " & Var & "; \");
      Plh(Lib, 1, Bit_Stream_Get_Func(Cap_Size) &
	    "(_v, _item.length); \");
      Plh(Lib, 1, "for(" & Var & " = 0; " & Var &
	    " < _item.length; " & Var & "++) \");
      Plh(Lib, 1, "{ \");
      Plh(Lib, 2, Cls_Decode_Func(C.Elements) &
	    "(_v, _item.items[" & Var & "]); \");
      Plh(Lib, 1, "} \");
      Plh(Lib, 1, "bit_stream_move(_v, " & Cap_Size & "); \");
      Plh(Lib, "}");
   end;

   procedure Compile_Io_Functions
     (C  : in Container_Cls_Record;
      Lib: in Library) is
      Prototype: Ustring;
   begin
      --===
      --  print function
      --===
      Prototype :=
        "void " & Cls_Print_Func(C.Me) & Nl &
        "(" & Cls_Name(C.Me) & " expr)";
      Plh(Lib, Prototype  & ";");
      Plc(Lib, Prototype);
      Plc(Lib, "{");
      Plc(Lib, 1, "int i = 0;");
      Plc(Lib, 2, "if(expr.length == 0) {");
      Plc(Lib, 2, "printf(""empty"");");
      Plc(Lib, 2, "return;");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "printf(""|"");");
      Plc(Lib, 1, "for(; i < expr.length; i++) {");
      Plc(Lib, 2, "if(i > 0)");
      Plc(Lib, 3, "printf("","");");
      Plc(Lib, 2, Cls_Print_Func(C.Elements) & "(expr.items[i]);");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "printf(""|"");");
      Plc(Lib, "}");

      --===
      --  to xml function
      --===
      Prototype :=
        "void " & Cls_To_Xml_Func(C.Me) & " (" & Nl &
	"   " & Cls_Name(C.Me) & " expr," & Nl &
        "   FILE * out)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & "{");
      Plc(Lib, 1, "int i = 0;");
      Plc(Lib, 1, "fprintf (out, ""<container>\n<exprList>\n"");");
      Plc(Lib, 1, "for(; i < expr.length; i++)");
      Plc(Lib, 2, Cls_To_Xml_Func(C.Elements) & " (expr.items[i], out);");
      Plc(Lib, 1, "fprintf (out, ""</exprList>\n</container>\n"");");
      Plc(Lib, "}");
   end;

   procedure Compile_Hash_Function
     (C  : in Container_Cls_Record;
      Lib: in Library) is
      V: constant Ustring := Cls_Hash_Func(C.Me) & "_idx";
   begin
      Plh(Lib, "#define " & Cls_Hash_Func(C.Me) & "(expr, result) { \");
      Plh(Lib, 1, "int " & V & " = 0; \");
      Plh(Lib, 1,
	  "(*result) = ((*result) << 5) + (*result) + expr.length + 720; \");
      Plh(Lib, 1, "for(; " & V & " < expr.length; " & V & "++) { \");
      Plh(Lib, 2, Cls_Hash_Func(C.Elements) &
	    "(expr.items[" & V & "], result); \");
      Plh(Lib, 1, "} \");
      Plh(Lib, "}");
   end;

   procedure Compile_Others
     (C  : in Container_Cls_Record;
      Lib: in Library) is
      Prototype: constant Ustring :=
        "void " & Cls_Init_Func(C.Me) & Nl & "()";
      Assigned : Ustring;
   begin
      --===
      --  initialization function of the type: initialize the first constant
      --===
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, Cls_First_Const_Name(C.Me) & ".length = 0;");
      Plc(Lib, 1, Cls_Last_Const_Name(C.Me)  & ".length = 0;");
      Plc(Lib, 1, Cls_Empty_Const_Name(C.Me) & ".length = 0;");
      Plc(Lib, "}");
   end;

end Pn.Classes.Containers;
