with
  Pn.Classes,
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Vectors;

use
 Pn.Classes,
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Vectors;

package body Pn.Classes.Vectors is

   function New_Vector_Cls
     (Name    : in Ustring;
      Index   : in Vector_Index;
      Elements: in Cls) return Cls is
      Result: Vector_Cls;
   begin
      --===
      --  check that color classes of the index are discrete
      --===
      for I in 1..Size(Index) loop
         pragma Assert(Is_Discrete(Ith(Index, I)));
         null;
      end loop;

      Result := new Vector_Cls_Record;
      Initialize(Cls(Result), Name);
      Result.Index   := Index;
      Result.Elements := Elements;
      return Cls(Result);
   end;

   procedure Free
     (C: in out Vector_Cls_Record) is
   begin
      Free(C.Index);
   end;

   function Get_Type
     (C: in Vector_Cls_Record) return Cls_Type is
   begin
      return A_Vector_Cls;
   end;

   function Index_Card
     (C: access Vector_Cls_Record'Class;
      I: in     Index_Type) return Card_Type is
      Result: Card_Type;
      State: Count_State;
   begin
      Card(Ith(C.Index, I), Result, State);
      pragma Assert(Is_Success(State));
      return Result;
   end;

   procedure Card
     (C     : in     Vector_Cls_Record;
      Result:    out Card_Type;
      State :    out Count_State) is
      Card    : Card_Type;
      function Pow
        (I: in Card_Type;
         J: in Card_Type) return Card_Type is
         Result: Card_Type := 1;
      begin
         for K in 1..J loop
            Result := Result * I;
         end loop;
         return Result;
      end;
   begin
      Result := 1;
      State := Count_Success;
      for I in 1..Size(C.Index) loop
         Classes.Card(Ith(C.Index, I), Card, State);
         if Is_Success(State) then
            Result := Result * Card;
            if Result = 0 then
               raise Constraint_Error;
            end if;
         else
            return;
         end if;
      end loop;
      Classes.Card(C.Elements, Card, State);
      if Is_Success(State) then
         Result := Pow(Card, Result);
      end if;
   exception
      when Constraint_Error =>
         State := Count_Too_Large;
   end;

   generic
      with function Get_Value(C: access Cls_Record'Class) return Expr;
   function Generic_Get_Value
     (C: in Vector_Cls_Record) return Expr;
   function Generic_Get_Value
     (C: in Vector_Cls_Record) return Expr is
      El: constant Expr_List := New_Expr_List;

      --===
      --  the vector is incomplete => we iterate on all the color classes of
      --  the index and add at the end of the vector the low value of the
      --  element
      --===
      procedure Add_Value
        (I: in Natural) is
      begin
         for J in 1..Index_Card(Vector_Cls(C.Me), I) loop
            if I = Size(C.Index) then
               Append(El, Get_Value(C.Elements));
            else
               Add_Value(I + 1);
            end if;
         end loop;
      end;
   begin
      Add_Value(1);
      return New_Vector(El, C.Me);
   end;

   function Low_Value
     (C: in Vector_Cls_Record) return Expr is
      function Low_Value is new Generic_Get_Value(Low_Value);
   begin
      return Low_Value(C);
   end;

   function High_Value
     (C: in Vector_Cls_Record) return Expr is
      function High_Value is new Generic_Get_Value(High_Value);
   begin
      return High_Value(C);
   end;

   function Sub_Card
     (C: in Vector_Cls_Record;
      I: in Natural) return Card_Type is
      Result       : Card_Type := 1;
      Elements_Card: Card_Type;
      State        : Count_State;
   begin
      Card(C.Elements, Elements_Card, State);
      pragma Assert(Is_Success(State));
      for J in I..Elements_Size(C) loop
         Result := Result * Elements_Card;
      end loop;
      return Result;
   end;

   function Ith_Value
     (C: in Vector_Cls_Record;
      I: in Card_Type) return Expr is
      El   : constant Expr_List := New_Expr_List;
      E    : Expr;
      Still: Card_Type := I;
      Pos  : Card_Type;
      Sub  : Card_Type;
      function Round_Up
        (Num: in Card_Type;
         Div: in Card_Type) return Card_Type is
         Result: Card_Type := Num / Div;
      begin
         if (Num mod Div) /= 0 then
            Result := Result + 1;
         end if;
         return Result;
      end;
   begin
      for J in 1..Elements_Size(C) loop
         Sub  := Sub_Card(C, J + 1);
         Pos  := Round_Up(Still, Sub);
         Still := Still - ((Pos - 1) * Sub);
         E    := Ith_Value(C.Elements, Pos);
         Append(El, E);
      end loop;
      return New_Vector(El, null);
   end;

   function Get_Value_Index
     (C: in     Vector_Cls_Record;
      E: access Expr_Record'Class) return Card_Type is
      Result: Card_Type := 1;
      Ex    : Expr;
      E_Pos: Card_Type;
   begin
      pragma Assert(Get_Type(E) = A_Vector);

      for I in 1..Elements_Size(C) loop
         Ex    := Get_Element(Pn.Exprs.Vectors.Vector(E), I);
         E_Pos := Get_Value_Index(C.Elements, Ex);
         Result := Result + (E_Pos - 1) * Sub_Card(C, I + 1);
      end loop;
      return Result;
   end;

   function Elements_Size
     (C: in Vector_Cls_Record) return Natural is
      Result: Natural;
   begin
      if Size(C.Index) > 0 then
         Result := 1;
         for I in 1..Size(C.Index) loop
            Result := Result * Natural(Index_Card(Vector_Cls(C.Me), I));
         end loop;
      else
         Result := 0;
      end if;
      return Result;
   end;

   function Basic_Elements_Size
     (C: in Vector_Cls_Record) return Natural is
   begin
      return Elements_Size(C) * Basic_Elements_Size(C.Elements);
   end;

   function Is_Const_Of_Cls
     (C: in     Vector_Cls_Record;
      E: access Expr_Record'Class) return Boolean is
      Result  : Boolean;
      Elements: Expr_List;
      Ex      : Expr;
   begin
      if Get_Type(E) /= A_Vector then
         Result := False;
      else
         Elements := Get_Elements(Pn.Exprs.Vectors.Vector(E));
         Result  := Length(Elements) <= Elements_Size(C);
         for I in 1..Length(Elements) loop
            Ex    := Ith(Elements, I);
            Result := Result and Is_Const_Of_Cls(C.Elements, Ex);
         end loop;
      end if;
      return Result;
   end;

   function Colors_Used
     (C: in Vector_Cls_Record) return Cls_Set is
      Result: constant Cls_Set := New_Cls_Set;
   begin
      Insert(Result, C.Elements);
      for I in 1..Size(C.Index) loop
         Insert(Result, Ith(C.Index, I));
      end loop;
      return Result;
   end;

   function Has_Constant_Bit_Width
     (C: in Vector_Cls_Record) return Boolean is
   begin
      return Has_Constant_Bit_Width(C.Elements);
   end;

   function Bit_Width
     (C: in Vector_Cls_Record) return Natural is
   begin
      return Bit_Width(C.Elements) * Elements_Size(C);
   end;

   procedure Generate_Indexes_Declaration
     (C     : in Vector_Cls;
      Prefix: in String;
      Tabs  : in Natural;
      Lib   : in Library;
      In_C  : in Boolean) is
      Me  : constant Vector_Cls := Vector_Cls(C.Me);
      Line: Ustring;
   begin
      for I in 1..Size(C.Index) loop
	 Line := "unsigned int " & Prefix & I & ";";
	 if In_C then
	    Plc(Lib, Tabs, Line);
	 else
	    Plh(Lib, Tabs, Line & " \");
	 end if;
      end loop;
   end;

   procedure Generate_Loops
     (C      : in     Vector_Cls;
      Prefix : in     String;
      Tabs   : in     Natural;
      Lib    : in     Library;
      In_C   : in     Boolean;
      Index  :    out Ustring;
      Is_Last:    out Ustring) is
      Me  : constant Vector_Cls := Vector_Cls(C.Me);
      Var : Ustring;
      Line: Ustring;
   begin
      Index  := Null_String;
      Is_Last := Null_String;
      for I in 1..Size(Get_Index_Dom(Me)) loop
         Var := Prefix & I;
	 Line := "for(" & Var & " = 0; " & Var & " < " &
	   Index_Card(Me, I) & "; " & Var & "++)";
	 if In_C then
	    Plc(Lib, Tabs, Line);
	 else
	    Plh(Lib, Tabs, Line & " \");
	 end if;
         Index := Index & "[" & Var & "]";

         if Is_Last /= Null_String then
            Is_Last := Is_Last & " && ";
         end if;
         Is_Last := Is_Last &
           "(" & Var & " == " & (Index_Card(Me, I) - 1) & ")";
      end loop;
   end;

   procedure Generate_Loops
     (C     : in     Vector_Cls;
      Prefix: in     String;
      Tabs  : in     Natural;
      Lib   : in     Library;
      In_C  : in     Boolean;
      Index :    out Ustring) is
      Is_Last: Ustring;
   begin
      Generate_Loops(C, Prefix, Tabs, Lib, In_C, Index, Is_Last);
   end;

   procedure Compile_Type_Definition
     (C  : in Vector_Cls_Record;
      Lib: in Library) is
      Me: constant Vector_Cls := Vector_Cls(C.Me);
   begin
      --===
      --  type definition. if the class is a sub class we do not define another
      --  type
      --===
      if not Is_Sub_Cls(C.Me) then
         Plh(Lib, "typedef struct {");
         Ph(Lib, 1, Cls_Name(C.Elements) & " vector");
         for I in 1..Size(C.Index) loop
            Ph(Lib, "[" & Integer(Index_Card(Me, I)) & "]");
         end loop;
         Plh(Lib, ";");
         Plh(Lib, "} " & Cls_Name(C.Me) & ";");
      else
         Plh(Lib, "typedef " &
             Cls_Name(Get_Root_Cls(C.Me)) & " " &
             Cls_Name(C.Me) & ";");
      end if;
   end;

   procedure Compile_Constants
     (C  : in Vector_Cls_Record;
      Lib: in Library) is
   begin
      --===
      --  constants of the type: first and last
      --===
      Plh(Lib, Cls_Name(C.Me) & " " & Cls_First_Const_Name(C.Me) & ";");
      Plh(Lib, Cls_Name(C.Me) & " " & Cls_Last_Const_Name(C.Me) & ";");
   end;

   procedure Compile_Operators
     (C  : in Vector_Cls_Record;
      Lib: in Library) is
      Me       : constant Vector_Cls := Vector_Cls(C.Me);
      Indexes  : Ustring;
      Prototype: Ustring;

      function Get_Prot
        (Op: in Bin_Operator) return Ustring is
      begin
         return
           Cls_Name(Bool_Cls) & " " & Cls_Bin_Operator_Name(C.Me, Op) & Nl &
           "(" & Cls_Name(C.Me) & " left," & Nl &
           " " & Cls_Name(C.Me) & " right)";
      end;

      procedure Make_Body
        (True_Const: in Ustring;
         False_Const: in Ustring) is
         Indexes: Ustring := Null_String;
      begin
         Generate_Indexes_Declaration(Me, "i", 1, Lib, True);
         Generate_Loops(Me, "i", 1, Lib, True, Indexes);
         Plc(Lib, 2, "if(" & Cls_Bin_Operator_Name(C.Elements, Neq_Op) &
             "(left.vector" & Indexes & ", right.vector" & Indexes & "))");
         Plc(Lib, 3, "return " & False_Const & ";");
         Plc(Lib, 1, "return " & True_Const & ";");
      end;

   begin
      --===
      --  normalization, check, cast
      --===
      Plh(Lib, "#define " & Cls_Normalize_Func(C.Me) & "(val) (val)");
      Plh(Lib, "#define " & Cls_Check_Func(C.Me) & "(val) (val)");
      Plh(Lib, "#define " & Cls_Cast_Func(C.Me) & "(val) (val)");

      --===
      --  =, /=
      --===
      Plh(Lib, Get_Prot(Eq_Op) & ";");
      Plc(Lib, Get_Prot(Eq_Op) & " {");
      Make_Body(Cls_Enum_Const_Name(Bool_Cls, True_Const_Name),
                Cls_Enum_Const_Name(Bool_Cls, False_Const_Name));
      Plc(Lib, "}");
      Plh(Lib, Get_Prot(Neq_Op) & ";");
      Plc(Lib, Get_Prot(Neq_Op) & " {");
      Make_Body(Cls_Enum_Const_Name(Bool_Cls, False_Const_Name),
                Cls_Enum_Const_Name(Bool_Cls, True_Const_Name));
      Plc(Lib, "}");

      --===
      --  comparison operator
      --===
      Prototype :=
        "int " & Cls_Cmp_Operator_Name(C.Me) & "_func" & Nl &
        "(" & Cls_Name(C.Me) & " *left," & Nl &
        " " & Cls_Name(C.Me) & " *right)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & "{");
      Plc(Lib, 1, "int cmp;");
      Generate_Indexes_Declaration(Me, "i", 1, Lib, True);
      Generate_Loops(Me, "i", 1, Lib, True, Indexes);
      Plc(Lib, 1, "{");
      Plc(Lib, 2, "cmp = " & Cls_Cmp_Operator_Name(C.Elements) &
          "(left->vector" & Indexes & ", right->vector" & Indexes & ");");
      Plc(Lib, 2, "if(cmp != EQUAL) return cmp;");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "return EQUAL;");
      Plc(Lib, "}");
      Plh(Lib, "#define " & Cls_Cmp_Operator_Name(C.Me) & "(_left, _right) " &
          "(" & Cls_Cmp_Operator_Name(C.Me) & "_func(&(_left), &(_right)))");
   end;

   procedure Compile_Encoding_Functions
     (C  : in Vector_Cls_Record;
      Lib: in Library) is
      Me         : constant Vector_Cls := Vector_Cls(C.Me);
      Indexes_Val: array(1..Size(C.Index)) of Ustring;
      Refs       : Ustring;
      Prototype  : Ustring;
      Indexes    : Ustring;
   begin
      --===
      --  bit width
      --===
      if Has_Constant_Bit_Width(C.Elements) then
         Plh(Lib, "#define " & Cls_Bit_Width_Func(C.Me) & "(_item) " &
             Bit_Width(C.Me));
      else
         Prototype :=
           "unsigned int " & Cls_Bit_Width_Func(C.Me) & "_func" &
           "(" & Cls_Name(C.Me) & " *item)";
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype);
         Plc(Lib, "{");
         Plc(Lib, 1, "unsigned int result = 0;");
         Generate_Indexes_Declaration(Me, "i", 1, Lib, True);
         Generate_Loops(Me, "i", 1, Lib, True, Indexes);
         Plc(Lib, 1, "{");
         Plc(Lib, 2, "result += " & Cls_Bit_Width_Func(C.Elements) &
             "(item->vector" & Indexes & ");");
         Plc(Lib, 1, "}");
         Plc(Lib, 1, "return result;");
         Plc(Lib, "}");
         Plh(Lib, "#define " & Cls_Bit_Width_Func(C.Me) & "(_item) " &
              Cls_Bit_Width_Func(C.Me) & "_func(&_item)");
      end if;

      --===
      --  encoding function
      --===
      Plh(Lib, "#define " & Cls_Encode_Func(C.Me) & "(e, bits) \");
      Plh(Lib, "{ \");
      for I in 1..Size(C.Index) loop
         Indexes_Val(I) := Cls_Encode_Func(C.Me) & "_var_" & I;
         Plh(Lib, 1, Cls_Name(Ith(C.Index, I)) & " " & Indexes_Val(I) & "; \");
      end loop;
      Refs := Null_String;
      for I in 1..Size(C.Index) loop
         Plh(Lib, 1, "for(" & Indexes_Val(I) & " = 0; " & Indexes_Val(I) &
             " < " & Index_Card(Me, I) & "; " &
             Indexes_Val(I) & "++) \");
         Refs := Refs & "[" & Indexes_Val(I) & "]";
      end loop;
      Plh(Lib, 1, "{ \");
      Plh(Lib, 2,
          Cls_Encode_Func(C.Elements) & "(e.vector" & Refs & ", bits); \");
      Plh(Lib, 1, "} \");
      Plh(Lib, "}");

      --===
      --  decoding function
      --===
      Plh(Lib, "#define " & Cls_Decode_Func(C.Me) & "(bits, e) { \");
      for I in 1..Size(C.Index) loop
	 Indexes_Val(I) := Cls_Decode_Func(C.Me) & "_var_" & I;
	 Plh(Lib, 1, Cls_Name(Ith(C.Index, I)) & " " &
	       Indexes_Val(I) & "; \");
      end loop;
      Refs := Null_String;
      for I in 1..Size(C.Index) loop
	 Plh(Lib, 1, "for(" & Indexes_Val(I) & " = 0; " &
	       Indexes_Val(I) & " < " & Index_Card(Me, I) & "; " &
	       Indexes_Val(I) & "++) \");
	 Refs := Refs & "[" & Indexes_Val(I) & "]";
      end loop;
      Plh(Lib, 1, "{ \");
      Plh(Lib, 2, Cls_Decode_Func(C.Elements) &
	    "(bits, e.vector" & Refs & "); \");
      Plh(Lib, 1, "} \");
      Plh(Lib, "}");
   end;

   procedure Compile_Io_Functions
     (C  : in Vector_Cls_Record;
      Lib: in Library) is
      Me       : constant Vector_Cls := Vector_Cls(C.Me);
      Prototype: Ustring;
      Test     : Ustring;
      Indexes  : Ustring;
   begin
      --===
      --  print function
      --===
      Prototype :=
        "void " & Cls_Print_Func(C.Me) & Nl &
        "(" & Cls_Name(C.Me) & " expr)";
      Plh(Lib, Prototype  & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "printf(""["");");
      Plc(Lib, 1, "{");
      Generate_Indexes_Declaration(Me, "i", 1, Lib, True);
      Generate_Loops(Me, "i", 1, Lib, True, Indexes, Test);
      Plc(Lib, 1, "{");
      Plc(Lib, 2, Cls_Print_Func(C.Elements) &
          "(expr.vector" & Indexes & ");");
      Plc(Lib, 2, "if(!(" & Test & ")) printf("","");");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "printf(""]"");");
      Plc(Lib, "}");

      --===
      --  to xml function
      --===
      Prototype :=
        "void " & Cls_To_Xml_Func(C.Me) & " (" & Nl &
	"   " & Cls_Name(C.Me) & " expr," & Nl &
        "   FILE * out)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Generate_Indexes_Declaration(Me, "i", 1, Lib, True);
      Plc(Lib, 1, "fprintf (out, ""<vector>\n<exprList>\n"");");
      Generate_Loops(Me, "i", 1, Lib, True, Indexes);
      Plc(Lib, 1, "{");
      Plc(Lib, 2,
          Cls_To_Xml_Func(C.Elements) & "(expr.vector" & Indexes & ", out);");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "fprintf (out, ""</exprList>\n</vector>\n"");");
      Plc(Lib, "}");
   end;

   procedure Compile_Hash_Function
     (C  : in Vector_Cls_Record;
      Lib: in Library) is
      Indexes: Ustring;
      Me     : constant Vector_Cls := Vector_Cls(C.Me);
      V      : constant Ustring :=  Cls_Hash_Func(C.Me) & "_idx";
   begin
      Plh(Lib, "#define " & Cls_Hash_Func(C.Me) & "(expr, result) { \");
      Generate_Indexes_Declaration(Me, To_String(V), 1, Lib, False);
      Generate_Loops(Me, To_String(V), 1, Lib, False, Indexes);
      Plh(Lib, 1, "{ \");
      Plh(Lib, 2, Cls_Hash_Func(C.Elements) &
	    "(expr.vector" & Indexes & ", result); \");
      Plh(Lib, 1, "} \");
      Plh(Lib, "}");
   end;

   procedure Compile_Others
     (C  : in Vector_Cls_Record;
      Lib: in Library) is
      Me       : constant Vector_Cls := Vector_Cls(C.Me);
      C_Name   : constant Ustring   := Cls_Name(C.Me);
      Prototype: Ustring;
      Test     : Ustring;
      Indexes  : Ustring;
      Assigned : Ustring;
      Shift    : Expr;
   begin
      --===
      --  initialization function of the type: initialize the first and last
      --  constants
      --===
      Prototype :=
        "void " & Cls_Init_Func(C.Me) & Nl &
        "()";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Generate_Indexes_Declaration(Me, "i", 1, Lib, True);
      Generate_Loops(Me, "i", 1, Lib, True, Indexes);
      Plc(Lib, 1, "{");
      Plc(Lib, 2, Cls_First_Const_Name(C.Me) & ".vector" & Indexes &
          " = " & Cls_First_Const_Name(C.Elements) & ";");
      Plc(Lib, 2, Cls_Last_Const_Name(C.Me) & ".vector" & Indexes &
          " = " & Cls_Last_Const_Name(C.Elements) & ";");
      Plc(Lib, 1, "}");
      Plc(Lib, "}");
      Nlh(Lib);

      --===
      --  construction function
      --===
      Prototype :=
        Cls_Name(C.Me) & " " & Cls_Constructor_Func(C.Me) & Nl &
        "(int args_nb," & Nl &
        " ...)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & Nl & "{");
      Plc(Lib, 1, Cls_Name(C.Me) & " result;");
      Plc(Lib, 1, Cls_Name(C.Elements) & " last;");
      Plc(Lib, 1, "int arg = 0;");
      Plc(Lib, 1, "va_list argp;");
      Generate_Indexes_Declaration(Me, "i", 1, Lib, True);
      Plc(Lib, 1, "va_start(argp, args_nb);");
      Plc(Lib, 1, "if(args_nb < 1)");
      Plc(Lib, 2, "return " & Cls_First_Const_Name(C.Me) & ";");
      Generate_Loops(Me, "i", 1, Lib, True, Indexes);
      Plc(Lib, 1, "{");
      Plc(Lib, 2, "if(arg == args_nb)");
      Plc(Lib, 3, "result.vector" & Indexes & " = last;");
      Plc(Lib, 2, "else");
      Plc(Lib, 2, "{");
      if Is_Discrete(C.Elements) then
         Assigned := "(" & Cls_Name(C.Elements) & ") va_arg(argp, int)";
      else
         Assigned := "va_arg(argp, " & Cls_Name(C.Elements) & ")";
      end if;
      Plc(Lib, 3, "last = result.vector" & Indexes & " = " & Assigned & ";");
      Plc(Lib, 3, "arg++;");
      Plc(Lib, 2, "}");
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "va_end(argp);");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");

      --===
      --  assignement function
      --===
      Prototype :=
        Cls_Name(C.Me) & " " &
        Cls_Assign_Func(C.Me) & Nl &
        "(" & Cls_Name(C.Me) & " v," & Nl &
        " " & Cls_Name(C.Elements) & " val";
      Assigned := To_Ustring("result.vector");
      for I in 1..Size(C.Index) loop
         Shift := Low_Value(Ith(C.Index, I));
         Prototype :=
           Prototype & "," & Nl &
           " " & Cls_Name(Ith(C.Index, I)) & " i" & I;
         Assigned := Assigned & "[i" & I & " - " &
           Compile_Evaluation(Shift, Empty_Var_Mapping, False) & "]";
         Free(Shift);
      end loop;
      Prototype := Prototype & ")";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & Nl);
      Plc(Lib, "{");
      Plc(Lib, 1, Cls_Name(C.Me) & " result = v;");
      Plc(Lib, 1, Assigned & " = val;");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
   end;

   function Get_Index_Position
     (V: in Vector_Cls;
      I: in Expr_List) return Card_Type is
      Result  : Card_Type := 1;
      C       : Cls;
      Index   : Expr;
      Sub_Card: Card_Type := 1;
      Card    : Card_Type;
      State   : Count_State;
   begin
      --===
      --  compute the position in the vector of the accessed element
      --===
      for J in reverse 1..Length(I) loop
         Index := Ith(I, J);
         C    := Ith(V.Index, J);
         Classes.Card(C, Card, State);
         pragma Assert(Is_Success(State));
         Result := Result + Sub_Card * (Get_Value_Index(C, Index) - 1);
         Sub_Card := Sub_Card * Card;
      end loop;
      return Result;
   end;

   function Get_Elements_Cls
     (V: in Vector_Cls) return Cls is
   begin
      return V.Elements;
   end;

   function Get_Index_Dom
     (V: in Vector_Cls) return Vector_Index is
   begin
      return V.Index;
   end;

end Pn.Classes.Vectors;
