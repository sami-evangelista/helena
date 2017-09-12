with
  Pn.Compiler,
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Names,
  Pn.Compiler.Config,
  Pn.Compiler.Util,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Bin_Ops,
  Utils.Math;

use
  Pn.Compiler,
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Names,
  Pn.Compiler.Config,
  Pn.Compiler.Util,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Bin_Ops,
  Utils.Math;

package body Pn.Classes.Discretes is

   function Elements_Size
     (C: in Discrete_Cls_Record) return Natural is
   begin
      return 1;
   end;

   function Basic_Elements_Size
     (C: in Discrete_Cls_Record) return Natural is
   begin
      return 1;
   end;

   function Has_Constant_Bit_Width
     (C: in Discrete_Cls_Record) return Boolean is
   begin
      return True;
   end;

   function Bit_Width
     (C: in Discrete_Cls_Record) return Natural is
      Cc   : Card_Type;
      State: Count_State;
   begin
      Card(C.Me, Cc, State);
      pragma Assert(Is_Success(State));
      return Bit_Width(Big_Int(Cc));
   end;

   procedure Compile_Type_Definition
     (C  : in Discrete_Cls_Record;
      Lib: in Library) is
      Low      : constant Num_Type := Get_Low (Discrete_Cls(C.Me));
      High     : constant Num_Type := Get_High(Discrete_Cls(C.Me));
      Type_Name: Ustring;
      function C_Int_Min return Num_Type is
      begin return Num_Type(Interfaces.C.Int'First); end;
      function C_Int_Max return Num_Type is
      begin return Num_Type(Interfaces.C.Int'Last); end;
   begin
      if C.Me /= Get_Root_Cls(C.Me) then
         Plh(Lib, "typedef " & Cls_Name(Get_Root_Cls(C.Me)) & " " &
             Cls_Name(C.Me) & ";");
      else

         --===
         --  determine the C type in which we will map the discrete color
         --===
         if
           Low  >= Num_Type(Interfaces.C.Schar_Min) and
           High <= Num_Type(Interfaces.C.Schar_Max)
         then
            Type_Name := To_Ustring("char");
         elsif
           Low  >= Num_Type(Interfaces.C.Short'First) and
           High <= Num_Type(Interfaces.C.Short'Last)
         then
            Type_Name := To_Ustring("short");
         elsif Low >= C_Int_Min and High <= C_Int_Max then
            Type_Name := To_Ustring("int");
         else
            Type_Name := To_Ustring("long");
         end if;

         --===
         --  type definition
         --===
         Plh(Lib, "typedef " & Type_Name & " " & Cls_Name(C.Me) & ";");
      end if;
   end;

   procedure Compile_Operators
     (C  : in Discrete_Cls_Record;
      Lib: in Library) is
      Root     : constant Discrete_Cls := Discrete_Cls(Get_Root_Cls(C.Me));
      Root_High: constant Num_Type    := Get_High(Root);
      Me       : constant Discrete_Cls := Discrete_Cls(C.Me);

      procedure Compile_Check_Func
        (Func_Name: in String;
         Error_Str: in String) is
         Prototype: constant Ustring :=
           Cls_Name(C.Me) & " " & Func_Name & Nl &
           "(long long int val)";
      begin
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype & " {");
         Plc(Lib, Tab &
             "if((val > " & Cls_Last_Const_Name(C.Me) & ") || " &
             "(val < " & Cls_First_Const_Name(C.Me) & ")) {");
         Plc(Lib, 2*Tab &"raise_error(""" & Error_Str & """);");
         Plc(Lib, 2*Tab & "return " & Cls_First_Const_Name(C.Me) & ";");
         Plc(Lib, Tab & "}");
         Plc(Lib, Tab & "return val;");
         Plc(Lib, "}");
      end;

   begin

      --===
      --  check
      --===
      if not Get_Run_Time_Checks or else (Is_Circular(Me) and Me = Root) then
         Plh(Lib, "#define " & Cls_Check_Func(C.Me) & "(val) (val)");
      else
         Compile_Check_Func(To_String(Cls_Check_Func(C.Me)) & "_func",
                            "expression out of range");
         Plh(Lib,
             "#define " & Cls_Check_Func(C.Me) & "(val) " &
             Cls_Check_Func(C.Me) & "_func(((long long int) (val)))");
      end if;

      --===
      --  cast
      --===
      if Get_Run_Time_Checks then
         Compile_Check_Func(To_String(Cls_Cast_Func(C.Me)) & "_func",
                            "cast failed");
         Plh(Lib,
             "#define " & Cls_Cast_Func(C.Me) & "(val) " &
             Cls_Cast_Func(C.Me) & "_func(((long long int) (val)))");
      else
         Plh(Lib, "#define " &
             Cls_Cast_Func(C.Me) & "(right) (right)");
      end if;

      --===
      --  normalization
      --===
      if Is_Circular(Discrete_Cls(C.Me)) then
         Plh(Lib, "#define " &
             Cls_Normalize_Func(C.Me) &
             "(val) (((val) < 0) ? (((val) + " &
             (Root_High + 1) & " * (1 + (-(val)) / " &
             (Root_High + 1) & ")) % " &
             (Root_High + 1) & "): ((val) % " &
             (Root_High + 1) & "))");
      else
         Plh(Lib, "#define " & Cls_Normalize_Func(C.Me) & "(val) (val)");
      end if;

      if Is_Circular(Discrete_Cls(C.Me)) then

         --===
         --  succ and pred for a circular class
         --===
         Plh(Lib, "#define " & Cls_Un_Operator_Name(C.Me, Succ_Op) &
             "(right) (((right) == " &
             Cls_Last_Const_Name(C.Me)  & ") ? " &
             Cls_First_Const_Name(C.Me) & ": ((right) + 1))");
         Plh(Lib, "#define " & Cls_Un_Operator_Name(C.Me, Pred_Op) &
             "(right) (((right) == " &
             Cls_First_Const_Name(C.Me) & ") ? " &
             Cls_Last_Const_Name(C.Me)  & ": ((right) - 1))");

      else

         --===
         --  succ and pred for a non circular class
         --===
         Plh(Lib, "#define " & Cls_Un_Operator_Name(C.Me, Succ_Op) &
             "(right) (" & Cls_Check_Func(C.Me) & "(right + 1))");
         Plh(Lib, "#define " & Cls_Un_Operator_Name(C.Me, Pred_Op) &
             "(right) (" & Cls_Check_Func(C.Me) & "(right - 1))");

      end if;

      --===
      --  boolean operators
      --===
      for Op in Bin_Operator loop
         if Op in Bool_Bin_Operator or Op in Comparison_Bin_Operator then
           Plh(Lib, "#define " & Cls_Bin_Operator_Name(C.Me, Op) &
               "(_left, _right) (((_left) " & Compile(Op) & " (_right)) ? " &
               Cls_Enum_Const_Name(Bool_Cls, True_Const_Name) & ": " &
               Cls_Enum_Const_Name(Bool_Cls, False_Const_Name) & ")");
         end if;
      end loop;

      --===
      --  comparison operator
      --===
      Plh(Lib, "#define " & Cls_Cmp_Operator_Name(C.Me) & "(_left, _right) " &
            "((_left) > (_right) ? GREATER: (((_left) < (_right)) ? " &
            "LESS : EQUAL))");
   end;

   procedure Compile_Encoding_Functions
     (C  : in Discrete_Cls_Record;
      Lib: in Library) is
      B   : constant Natural := Bit_Width(C);
      Var : constant Ustring := Cls_Encode_Func(C.Me) & "_tmp";
      Low : Num_Type;
      High: Num_Type;
   begin
      --===
      --  get the range of the values of the color class
      --===
      Get_Values_Range(Discrete_Cls(C.Me), Low, High);

      --===
      --  bit width
      --===
      Plh(Lib, "#define " & Cls_Bit_Width_Func(C.Me) & "(_item) " & B);

      --===
      --  encoding function
      --===
      Plh(Lib, "#define " & Cls_Encode_Func(C.Me) & "(e, bits) { \");
      if Low /= 0 then
         Plh(Lib, 1, "unsigned long long int " &
	       Var & " = (unsigned long long int) e - " &
	       Cls_First_Const_Name(C.Me) & "; \");
         Plh(Lib, 1, Bit_Stream_Set_Func(B) & "(bits, " & Var & "); \");
      else
         Plh(Lib, 1, Bit_Stream_Set_Func(B) & "(bits, e); \");
      end if;
      Plh(Lib, "}");

      --===
      -- decoding functions
      --===
      Plh(Lib, "#define " & Cls_Decode_Func(C.Me) & "(bits, e) { \");
      Plh(Lib, 1, Bit_Stream_Get_Func(B) & "(bits, e); \");
      if Low /= 0 then
         Plh(Lib, 1, "e += " & Cls_First_Const_Name(C.Me) & "; \");
      end if;
      Plh(Lib, "}");
   end;

   procedure Compile_Hash_Function
     (C  : in Discrete_Cls_Record;
      Lib: in Library) is
   begin
      Plh(Lib, "#define " & Cls_Hash_Func(C.Me) & "(expr, result) { \");
      Plh(Lib, 1, "(*result) = ((*result) << 5) + (*result) + expr + 720; \");
      Plh(Lib, "}");
   end;

   procedure Get_Values_Range
     (D   : access Discrete_Cls_Record'Class;
      Low :    out Num_Type;
      High:    out Num_Type) is
   begin
      Low := Get_Low(D);
      High := Get_High(D);
   end;

   function Get_Low
     (D: access Discrete_Cls_Record'Class) return Num_Type is
   begin
      return Get_Low(D.all);
   end;

   function Get_High
     (D: access Discrete_Cls_Record'Class) return Num_Type is
   begin
      return Get_High(D.all);
   end;

   function Is_Circular
     (D: access Discrete_Cls_Record'Class) return Boolean is
   begin
      return Is_Circular(D.all);
   end;

   function From_Num_Value
     (D: access Discrete_Cls_Record'Class;
      N: in     Num_Type) return Expr is
   begin
      return From_Num_Value(D.all, N);
   end;

end Pn.Classes.Discretes;
