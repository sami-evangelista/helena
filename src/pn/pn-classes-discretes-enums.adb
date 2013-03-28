with
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Exprs.Enum_Consts,
  Pn.Classes;

use
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Exprs.Enum_Consts,
  Pn.Classes;

package body Pn.Classes.Discretes.Enums is

   function Get_Type
     (C: in Enum_Cls_Record) return Cls_Type is
   begin
      return A_Enum_Cls;
   end;

   procedure Card
     (C     : in     Enum_Cls_Record;
      Result:    out Card_Type;
      State :    out Count_State) is
      Low : Num_Type;
      High: Num_Type;
   begin
      State := Count_Success;
      Get_Values_Range(Enum_Cls(C.Me), Low, High);
      Result := Card_Type(High - Low + 1);
   exception
      when Constraint_Error =>
         State := Count_Too_Large;
   end;

   function Low_Value
     (C: in Enum_Cls_Record) return Expr is
      Values: constant Ustring_List := Get_Root_Values(Enum_Cls(C.Me));
      Low   : Num_Type;
      High  : Num_Type;
      Value : Ustring;
   begin
      Get_Values_Range(Enum_Cls(C.Me), Low, High);
      Value := String_List_Pkg.Ith(Values, Integer(Low + 1));
      return New_Enum_Const(Value, C.Me);
   end;

   function High_Value
     (C: in Enum_Cls_Record) return Expr is
      Values: constant Ustring_List := Get_Root_Values(Enum_Cls(C.Me));
      Low   : Num_Type;
      High  : Num_Type;
      Value : Ustring;
   begin
      Get_Values_Range(Enum_Cls(C.Me), Low, High);
      Value := String_List_Pkg.Ith(Values, Integer(High + 1));
      return New_Enum_Const(Value, C.Me);
   end;

   function Ith_Value
     (C: in Enum_Cls_Record;
      I: in Card_Type) return Expr is
      Values: constant Ustring_List := Get_Root_Values(Enum_Cls(C.Me));
      Low   : Num_Type;
      High  : Num_Type;
      Value: Ustring;
   begin
      Get_Values_Range(Enum_Cls(C.Me), Low, High);
      Value := String_List_Pkg.Ith(Values, Integer(I + Card_Type(Low)));
      return New_Enum_Const(Value, C.Me);
   end;

   function Get_Value_Index
     (C: in     Enum_Cls_Record;
      E: access Expr_Record'Class) return Card_Type is
      Values: constant Ustring_List := Get_Root_Values(Enum_Cls(C.Me));
      Low   : Num_Type;
      High  : Num_Type;
      Str   : Ustring;
   begin
      --===
      --  the expression must be an enumeration constant
      --===
      pragma Assert(Get_Type(E) = A_Enum_Const);

      Get_Values_Range(Enum_Cls(C.Me), Low, High);
      Str := Get_Const(Enum_Const(E));
      for I in Low..High loop
         if String_List_Pkg.Ith(Values, Integer(I + 1)) = Str then
            return Card_Type(I - Low + 1);
         end if;
      end loop;

      pragma Assert(False);
      return 0;
   end;

   function Is_Const_Of_Cls
     (C: in     Enum_Cls_Record;
      E: access Expr_Record'Class) return Boolean is
   begin
      return (Get_Type(E) = A_Enum_Const and then
              Is_Of_Cls(Enum_Cls(C.Me), Get_Const(Enum_Const(E))));
   end;

   procedure Compile_Type_Definition
     (C  : in Enum_Cls_Record;
      Lib: in Library) is
      Values: constant Ustring_List := Get_Root_Values(Enum_Cls(C.Me));
      Const : Ustring;
   begin
      Compile_Type_Definition(Discrete_Cls_Record(C), Lib);

      --===
      --  define the values of the color
      --===
      for I in 1..String_List_Pkg.Length(Values) loop
         Const := String_List_Pkg.Ith(Values, I);
         Plh(Lib,
             "#define " & Cls_Enum_Const_Name(C.Me, Const) & " " & (I - 1));
      end loop;
   end;

   procedure Compile_Constants
     (C  : in Enum_Cls_Record;
      Lib: in Library) is
      Values: constant Ustring_List := Get_Root_Values(Enum_Cls(C.Me));
      Card  : Card_Type;
      Const : Ustring;
      State : Count_State;
      Low   : Num_Type;
      High  : Num_Type;
   begin
      --===
      --  get the range of the values of the color class
      --===
      Get_Values_Range(Enum_Cls(C.Me), Low, High);

      --===
      --  compute the cardinal of the color
      --===
      Pn.Classes.Card(C.Me, Card, State);
      pragma Assert(Is_Success(State));

      --===
      --  constants related to the type
      --===
      Const := String_List_Pkg.Ith(Values, Natural(Low + 1));
      Plh(Lib, "#define " & Cls_First_Const_Name(C.Me) & " " &
          Cls_Enum_Const_Name(C.Me, Const));
      Const := String_List_Pkg.Ith(Values, Natural(High + 1));
      Plh(Lib, "#define " & Cls_Last_Const_Name(C.Me) & " " &
          Cls_Enum_Const_Name(C.Me, Const));
      Plh(Lib, "#define " & Cls_Card_Const_Name(C.Me) & " " &
          To_Ustring(To_String(Card)));
   end;

   procedure Compile_Operators
     (C  : in Enum_Cls_Record;
      Lib: in Library) is
   begin
      Compile_Operators(Discrete_Cls_Record(C), Lib);

      --===
      --  not
      --===
      Plh(Lib, "#define " & Cls_Un_Operator_Name(C.Me, Not_Op) &
          "(right) ((right) ? " &
          Cls_Enum_Const_Name(Bool_Cls, False_Const_Name) & ": " &
          Cls_Enum_Const_Name(Bool_Cls, True_Const_Name) & ")");
   end;

   procedure Compile_Io_Functions
     (C  : in Enum_Cls_Record;
      Lib: in Library) is
      Values   : constant Ustring_List := Get_Root_Values(Enum_Cls(C.Me));
      Prototype: Ustring;
      Const    : Ustring;
      Low      : Num_Type;
      High     : Num_Type;
   begin
      --===
      --  get the range of the values of the color class
      --===
      Get_Values_Range(Enum_Cls(C.Me), Low, High);

      --===
      --  generate the strings which correspond to the constant values of the
      --  types (generate them only if the color is the root color)
      --===
      if Get_Root_Cls(C.Me) = C.Me then
         Plc(Lib, Tab & "const char *" & Cls_Name(C.Me) & "_values[] = ");
         Plc(Lib, Tab & "{");
         for I in 1..String_List_Pkg.Length(Values) loop
            Const := String_List_Pkg.Ith(Values, I);
            if I > 1 then
               Plc(Lib, ",");
            end if;
            Pc(Lib, Tab & Tab & """" &  Const & """");
         end loop;
         Nlc(Lib);
         Plc(Lib, Tab & "};");
      end if;

      --===
      --  print function
      --===
      Prototype :=
        "void " & Cls_Print_Func(C.Me) & Nl &
        "(" & Cls_Name(C.Me) & " expr)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "printf(""%s"", " &
	    Cls_Name(Get_Root_Cls(C.Me)) & "_values[expr]);");
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
      Plc(Lib, 1, "fprintf (out, ""<enum>%s</enum>"", " &
	    Cls_Name(Get_Root_Cls(C.Me)) & "_values[expr]);");
      Plc(Lib, "}");
   end;

   procedure Compile_Others
     (C  : in Enum_Cls_Record;
      Lib: in Library) is
      Prototype: constant Ustring :=
        "void " & Cls_Init_Func(C.Me) & Nl &
        "()";
   begin
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {}");
   end;

   function Is_Of_Cls
     (E  : access Enum_Cls_Record'Class;
      Str: in     Ustring) return Boolean is
      Low   : Num_Type;
      High  : Num_Type;
      Values: constant Ustring_List := Get_Root_Values(Enum_Cls(E));
   begin
      Get_Values_Range(E, Low, High);
      for I in Low..High loop
         if String_List_Pkg.Ith(Values, Natural(I + 1)) = Str then
            return True;
         end if;
      end loop;
      return False;
   end;

   function Is_Circular
     (D: in Enum_Cls_Record) return Boolean is
   begin
      return True;
   end;

   function From_Num_Value
     (D: in Enum_Cls_Record;
      N: in Num_Type) return Expr is
      Values: constant Ustring_List := Get_Root_Values(Enum_Cls(D.Me));
   begin
      pragma Assert(Integer(N) in 1..String_List_Pkg.Length(Values));
      return New_Enum_Const(String_List_Pkg.Ith(Values, Natural(N)), D.Me);
   end;

   function Get_Root_Values
     (E: access Enum_Cls_Record'Class) return Ustring_List is
   begin
      return Get_Root_Values(E.all);
   end;

end Pn.Classes.Discretes.Enums;
