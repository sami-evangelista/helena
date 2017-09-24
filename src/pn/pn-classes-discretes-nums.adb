with
  Pn.Compiler,
  Pn.Compiler.Config,
  Pn.Compiler.Util,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Exprs.Bin_Ops,
  Pn.Exprs.Num_Consts,
  Pn.Exprs.Un_Ops,
  Pn.Classes;

use
  Pn.Compiler,
  Pn.Compiler.Config,
  Pn.Compiler.Util,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Exprs.Bin_Ops,
  Pn.Exprs.Num_Consts,
  Pn.Exprs.Un_Ops,
  Pn.Classes;

package body Pn.Classes.Discretes.Nums is

   function Get_Type
     (C: in Num_Cls_Record) return Cls_Type is
   begin
      return A_Num_Cls;
   end;

   procedure Card
     (C     : in     Num_Cls_Record;
      Result:    out Card_Type;
      State :    out Count_State) is
   begin
      Result := 1 +
        Card_Type(Big_Int(Get_High(Num_Cls(C.Me))) -
                 Big_Int(Get_Low(Num_Cls(C.Me))));
      if Result = 0 then
         raise Constraint_Error;
      end if;
      State := Count_Success;
   exception
      when Constraint_Error =>
         State := Count_Too_Large;
   end;

   function Low_Value
     (C: in Num_Cls_Record) return Expr is
      Low   : constant Num_Type := Get_Low(Num_Cls(C.Me));
      Result: constant Expr := New_Num_Const(Low, C.Me);
   begin
      return Result;
   end;

   function High_Value
     (C: in Num_Cls_Record) return Expr is
      Low   : constant Num_Type := Get_High(Num_Cls(C.Me));
      Result: constant Expr := New_Num_Const(Low, C.Me);
   begin
      return Result;
   end;

   function Ith_Value
     (C: in Num_Cls_Record;
      I: in Card_Type) return Expr is
      Val: constant Num_Type :=
        Num_Type(Big_Int(Get_Low(Num_Cls(C.Me))) + Big_Int(I) - 1);
   begin
      return New_Num_Const(Val, C.Me);
   end;

   function Get_Value_Index
     (C: in     Num_Cls_Record;
      E: access Expr_Record'Class) return Card_Type is
      Result: Big_Int;
   begin
      pragma Assert(Get_Type(E) = A_Num_Const);
      Result :=
        Big_Int(Get_Const(Num_Const(E))) -
        Big_Int(Get_Low(Num_Cls(C.Me))) + 1;
      return Card_Type(Result);
   end;

   function Is_Const_Of_Cls
     (C: in     Num_Cls_Record;
      E: access Expr_Record'Class) return Boolean is
      Result: Boolean;
      Val   : Num_Type;
   begin
      if Get_Type(E) /= A_Num_Const then
         Result := False;
      else
         Val    := Get_Const(Num_Const(E));
         Result := Val in Get_Low(Num_Cls(C.Me)) .. Get_High(Num_Cls(C.Me));
      end if;
      return Result;
   end;

   procedure Compile_Constants
     (C  : in Num_Cls_Record;
      Lib: in Library) is
      Cc   : Card_Type;
      State: Count_State;
      Low  : Ustring := To_Helena(Get_Low(Num_Cls(C.Me)));
   begin
      --===
      --  compute the cardinal of the type
      --===
      Card(C.Me, Cc, State);
      pragma Assert(Is_Success(State));

      --===
      --  constants related to the type
      --===
      if To_String(Low) = Interfaces.C.Int'Image(Int'First) then
	 Low := To_Ustring(Interfaces.C.Int'Image(Int'First + 1) & "-1");
      end if;
      Plh(Lib, "#define " & Cls_First_Const_Name(C.Me) & " " &
	    "(" & To_Helena(Get_Low(Num_Cls(C.Me))) & ")");
      Plh(Lib, "#define " & Cls_Last_Const_Name(C.Me) & " " &
	    "(" & To_Helena(Get_High(Num_Cls(C.Me))) & ")");
      Plh(Lib, "#define " & Cls_Card_Const_Name(C.Me) & " " &
	    "(" & Cc & ")");
   end;

   procedure Compile_Operators
     (C  : in Num_Cls_Record;
      Lib: in Library) is
      Prototype: Ustring;
   begin
      Compile_Operators(Discrete_Cls_Record(C), Lib);

      --===
      --  -
      --===
      Plh(Lib, "#define " & Cls_Un_Operator_Name(C.Me, Minus_Uop) &
          "(right) (" & Cls_Normalize_Func(C.Me) &
          "(" & Compile(Minus_Uop) & " right))");

      --===
      --  +
      --===
      Plh(Lib, "#define " & Cls_Un_Operator_Name(C.Me, Plus_Uop) &
          "(right) (right)");

      --===
      --  numerical operators
      --===
      if Get_Run_Time_Checks then
         for Op in Plus_Op..Mult_Op loop
            Plh(Lib, "#define " & Cls_Bin_Operator_Name(C.Me, Op) &
                "(left, right) (" & Cls_Normalize_Func(C.Me) &
                "(left " & Compile(Op) & " right))");
         end loop;

         --===
         --  the / and mod operators are generated separatly since they may
         --  raise an error if the divider is 0
         --===
         for Op in Div_Op..Mod_Op loop
            Prototype :=
              Cls_Name(C.Me) & " " &
              Cls_Bin_Operator_Name(C.Me, Op) & Nl &
              "(" & Cls_Name(C.Me) & " left," & Nl &
              " " & Cls_Name(C.Me) & " right)";
            Plh(Lib, Prototype & ";");
            Plc(Lib, Prototype & " {");
            Plc(Lib, 1, Cls_Name(C.Me) & " result;");
            Plc(Lib, 1, "if(!right) {");
            Plc(Lib, 2,"raise_error(""division by 0"");");
            Plc(Lib, 2, "return left;");
            Plc(Lib, 1, "}");
            Plc(Lib, 1, "else {");
            Plc(Lib, 2, "result = " &
                Cls_Normalize_Func(C.Me) &
                "(left " & Compile(Op) & " right);");
            Plc(Lib, 2, "return result;");
            Plc(Lib, 1, "}");
            Plc(Lib, "}");
         end loop;
      else
         for Op in Num_Bin_Operator loop
            Plh(Lib, "#define " & Cls_Bin_Operator_Name(C.Me, Op) &
                "(left, right) (" & Cls_Normalize_Func(C.Me) &
                "(left " & Compile(Op) & " right))");
         end loop;
      end if;
   end;

   procedure Compile_Io_Functions
     (C  : in Num_Cls_Record;
      Lib: in Library) is
      Prototype: Ustring;
   begin
      --===
      --  print function
      --===
      Prototype :=
        "void " & Cls_Print_Func(C.Me) & Nl &
        "(" & Cls_Name(C.Me) & " expr)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "printf(""%lli"", (long long int) expr);");
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
      Plc(Lib, 1, "fprintf (out, ""<num>%lli</num>\n""," &
            " (long long int) expr);");
      Plc(Lib, "}");
   end;

   procedure Compile_Others
     (C  : in Num_Cls_Record;
      Lib: in Library) is
      Prototype: constant Ustring :=
        "void " & Cls_Init_Func(C.Me) & Nl & "()";
   begin
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & Nl);
      Plc(Lib, "{}");

   end;

   function Normalize_Value
     (C: access Num_Cls_Record'Class;
      I: in     Num_Type) return Num_Type is
   begin
      return Normalize_Value(C.all, I);
   end;

   function To_Helena
     (N: in Num_Type) return Ustring is
      Result: Ustring;
   begin
      if N = Num_Type'First then
         Result := "(" & (N + 1) & " - 1)";
      else
         Result := To_Ustring(N);
      end if;
      return Result;
   end;

   function From_Num_Value
     (D: in Num_Cls_Record;
      N: in Num_Type) return Expr is
   begin
      return New_Num_Const(N, D.Me);
   end;

end Pn.Classes.Discretes.Nums;
