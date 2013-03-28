with
  Pn.Classes,
  Pn.Classes.Structs,
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Structs;

use
  Pn.Classes,
  Pn.Classes.Structs,
  Pn.Compiler,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Structs;

package body Pn.Classes.Structs is

   --==========================================================================
   --  Component of a structured class
   --==========================================================================

   function New_Struct_Comp
     (Name: in Ustring;
      C   : in Cls) return Struct_Comp is
   begin
      return (Name, C);
   end;

   function Get_Name
     (C: in Struct_Comp) return Ustring is
   begin
      return C.Name;
   end;

   procedure Set_Name
     (C   : in out Struct_Comp;
      Name: in     Ustring) is
   begin
      C.Name := Name;
   end;

   function Get_Cls
     (C: in Struct_Comp) return Cls is
   begin
      return C.C;
   end;

   procedure Set_Cls
     (C: in out Struct_Comp;
      Cl: in     Cls) is
   begin
      C.C := Cl;
   end;

   procedure Compile
     (C  : in Struct_Comp;
      Lib: in Library) is
   begin
      Plh(Lib, Tab & Cls_Name(C.C) & " " &
          Cls_Struct_Comp_Name(C.Name) & ";");
   end;



   --==========================================================================
   --  Component list of a structured class
   --==========================================================================

   package SCAP renames Struct_Comp_Array_Pkg;

   function New_Struct_Comp_List return Struct_Comp_List is
      Result: constant Struct_Comp_List :=
        new Struct_Comp_List_Record;
   begin
      Result.Components := SCAP.Empty_Array;
      return Result;
   end;

   function New_Struct_Comp_List
     (C: in Struct_Comp_Array) return Struct_Comp_List is
      Result: constant Struct_Comp_List :=
        new Struct_Comp_List_Record;
   begin
      Result.Components := SCAP.New_Array(SCAP.Element_Array(C));
      return Result;
   end;

   procedure Free
     (C: in out Struct_Comp_List) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Struct_Comp_List_Record,
                                        Struct_Comp_List);
   begin
      Deallocate(C);
      C := null;
   end;

   function Length
     (C: in Struct_Comp_List) return Count_Type is
   begin
      return SCAP.Length(C.Components);
   end;

   function Get_Component
     (C   : in Struct_Comp_List;
      Name: in Ustring) return Struct_Comp is
      function Is_Comp
        (C: in Struct_Comp) return Boolean is
      begin
         return C.Name = Name;
      end;
      function Get_Component is
         new SCAP.Generic_Get_First_Satisfying_Element(Is_Comp);
   begin
      return Get_Component(C.Components);
   end;

   function Get_Index
     (C   : in Struct_Comp_List;
      Name: in Ustring) return Index_Type is
      function Is_Comp
        (C: in Struct_Comp) return Boolean is
      begin
         return C.Name = Name;
      end;
      function Get_Index is
         new SCAP.Generic_Get_First_Satisfying_Element_Index(Is_Comp);
   begin
      return Get_Index(C.Components);
   end;

   function Ith
     (C: in Struct_Comp_List;
      I: in Index_Type) return Struct_Comp is
   begin
      return SCAP.Ith(C.Components, I);
   end;

   function Contains
     (C    : in Struct_Comp_List;
      Name: in Ustring) return Boolean is
      function Is_N
        (Component: in Struct_Comp) return Boolean is
      begin
         return Get_Name(Component) = Name;
      end;
      function Contains is new SCAP.Generic_Exists(Is_N);
   begin
      return Contains(C.Components);
   end;

   procedure Append
     (C   : in Struct_Comp_List;
      Comp: in Struct_Comp) is
   begin
      pragma Assert(not Contains(C, Comp.Name));
      SCAP.Append(C.Components, Comp);
   end;

   procedure Compile
     (C  : in Struct_Comp_List;
      Lib: in Library) is
      procedure Compile
        (C: in out Struct_Comp) is
      begin
         Compile(C, Lib);
      end;
      procedure Compile is new SCAP.Generic_Apply(Compile);
   begin
      Compile(C.Components);
   end;



   --==========================================================================
   --  Structured class
   --==========================================================================

   function New_Struct_Cls
     (Name      : in Ustring;
      Components: in Struct_Comp_List) return Cls is
      Result: constant Struct_Cls := new Struct_Cls_Record;
   begin
      Initialize(Cls(Result), Name);
      Result.Components := Components;
      return Cls(Result);
   end;

   procedure Free
     (C: in out Struct_Cls_Record) is
   begin
      Free(C.Components);
   end;

   function Get_Type
     (C: in Struct_Cls_Record) return Cls_Type is
   begin
      return A_Struct_Cls;
   end;

   procedure Card
     (C     : in     Struct_Cls_Record;
      Result:    out Card_Type;
      State:    out Count_State) is
      Comps: constant Struct_Comp_List :=
        Get_Components(Struct_Cls(C.Me));
      Sc   : Card_Type;
   begin
      Result := 1;
      State := Count_Success;
      for I in 1..Length(Comps) loop
         Card(Get_Cls(Ith(Comps, I)), Sc, State);
         if Is_Success(State) then
            Result := Result * Sc;
            if Result = 0 then
               raise Constraint_Error;
            end if;
         else
            return;
         end if;
      end loop;
   exception
      when Constraint_Error =>
         State := Count_Too_Large;
   end;

   generic
      with function Get_Value(C: access Cls_Record'Class) return Expr;
   function Generic_Get_Value
     (C: in Struct_Cls_Record) return Expr;
   function Generic_Get_Value
     (C: in Struct_Cls_Record) return Expr is
      Comps: constant Struct_Comp_List :=
        Get_Components(Struct_Cls(C.Me));
      El   : constant Expr_List := New_Expr_List;
   begin
      for I in 1..Length(Comps) loop
         Append(El, Get_Value(Get_Cls(Ith(Comps, I))));
      end loop;
      return New_Struct(El, C.Me);
   end;

   function Low_Value
     (C: in Struct_Cls_Record) return Expr is
      function Get_Value is new Generic_Get_Value(Low_Value);
   begin
      return Get_Value(C);
   end;

   function High_Value
     (C: in Struct_Cls_Record) return Expr is
      function Get_Value is new Generic_Get_Value(High_Value);
   begin
      return Get_Value(C);
   end;

   function Sub_Card
     (C: in Struct_Cls_Record;
      I: in Natural) return Card_Type is
      Comps: constant Struct_Comp_List :=
        Get_Components(Struct_Cls(C.Me));
      Result: Card_Type := 1;
      Sc    : Card_Type;
      State: Count_State;
   begin
      for J in I..Length(Comps) loop
         Card(Get_Cls(Ith(Comps, J)), Sc, State);
         pragma Assert(Is_Success(State));
         Result := Result * Sc;
      end loop;
      return Result;
   end;

   function Ith_Value
     (C: in Struct_Cls_Record;
      I: in Card_Type) return Expr is
      Comps: constant Struct_Comp_List :=
        Get_Components(Struct_Cls(C.Me));
      El   : constant Expr_List := New_Expr_List;
      E    : Expr;
      Fc   : Cls;
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
      for J in 1..Length(Comps) loop
         Fc := Get_Cls(Ith(Comps, J));
         Sub := Sub_Card(C, J + 1);
         Pos := Round_Up(Still, Sub);
         Still := Still - ((Pos - 1) * Sub);
         E := Ith_Value(Fc, Pos);
         Append(El, E);
      end loop;
      return New_Struct(El, null);
   end;

   function Get_Value_Index
     (C: in     Struct_Cls_Record;
      E: access Expr_Record'Class) return Card_Type is
      Comps : constant Struct_Comp_List :=
        Get_Components(Struct_Cls(C.Me));
      Result: Card_Type := 1;
      Fc    : Cls;
      Ex    : Expr;
      E_Pos : Card_Type;
      El    : Expr_List;
   begin
      pragma Assert(Get_Type(E) = A_Struct);

      El := Get_Components(Pn.Exprs.Structs.Struct(E));
      for I in 1..Length(Comps) loop
         Fc := Get_Cls(Ith(Comps, I));
         Ex := Ith(El, I);
         E_Pos := Get_Value_Index(Fc, Ex);
         Result := Result + (E_Pos - 1) * Sub_Card(C, I + 1);
      end loop;
      return Result;
   end;

   function Elements_Size
     (C: in Struct_Cls_Record) return Natural is
   begin
      return Length(Get_Components(Struct_Cls(C.Me)));
   end;

   function Basic_Elements_Size
     (C: in Struct_Cls_Record) return Natural is
      Comps : constant Struct_Comp_List := Get_Components(Struct_Cls(C.Me));
      Result: Natural := 0;
   begin
      for I in 1..Length(Comps) loop
         Result := Result + Basic_Elements_Size(Get_Cls(Ith(Comps, I)));
      end loop;
      return Result;
   end;

   function Is_Const_Of_Cls
     (C: in     Struct_Cls_Record;
      E: access Expr_Record'Class) return Boolean is
      Comps : constant Struct_Comp_List := Get_Components(Struct_Cls(C.Me));
      Result: Boolean;
      El    : Expr_List;
   begin
      if Get_Type(E) /= A_Struct then
         Result := False;
      else
         El := Get_Components(Pn.Exprs.Structs.Struct(E));
         Result := Length(El) = Length(Comps);
         if Result then
            for I in 1..Length(El) loop
               Result := (Result and
                          Is_Const_Of_Cls(Get_Cls(Ith(Comps, I)), Ith(El, I)));
            end loop;
         end if;
      end if;
      return Result;
   end;

   function Colors_Used
     (C: in Struct_Cls_Record) return Cls_Set is
      Result: constant Cls_Set := New_Cls_Set;
   begin
      for I in 1..Length(C.Components) loop
         Insert(Result, Get_Cls(Ith(C.Components, I)));
      end loop;
      return Result;
   end;

   function Has_Constant_Bit_Width
     (C: in Struct_Cls_Record) return Boolean is
      Comps: constant Struct_Comp_List := Get_Components(Struct_Cls(C.Me));
   begin
      for I in 1..Length(Comps) loop
         if not Has_Constant_Bit_Width(Get_Cls(Ith(Comps, I))) then
            return False;
         end if;
      end loop;
      return True;
   end;

   function Bit_Width
     (C: in Struct_Cls_Record) return Natural is
      Comps : constant Struct_Comp_List := Get_Components(Struct_Cls(C.Me));
      Result: Natural := 0;
   begin
      for I in 1..Length(Comps) loop
         Result := Result + Bit_Width(Get_Cls(Ith(Comps, I)));
      end loop;
      return Result;
   end;

   procedure Compile_Type_Definition
     (C  : in Struct_Cls_Record;
      Lib: in Library) is
   begin
      --===
      --  type definition. if the class is a sub class we do not define another
      --  type
      --===
      if not Is_Sub_Cls(C.Me) then
         Plh(Lib, "typedef struct {");
         Compile(Get_Components(Struct_Cls(C.Me)), Lib);
         Plh(Lib, "} " & Cls_Name(C.Me) & ";");
      else
         Plh(Lib, "typedef " &
             Cls_Name(Get_Root_Cls(C.Me)) & " " &
             Cls_Name(C.Me) & ";");
      end if;
   end;

   procedure Compile_Constants
     (C  : in Struct_Cls_Record;
      Lib: in Library) is
   begin
      --===
      --  constants of the type: first and last
      --===
      Plh(Lib, Cls_Name(C.Me) & " " & Cls_First_Const_Name(C.Me) & ";");
      Plh(Lib, Cls_Name(C.Me) & " " & Cls_Last_Const_Name(C.Me) & ";");
   end;

   procedure Compile_Operators
     (C  : in Struct_Cls_Record;
      Lib: in Library) is
      Comp     : Struct_Comp;
      Name     : Ustring;
      Test     : Ustring := Null_String;
      Prototype: Ustring;
      C_Comp   : Cls;
      Comps    : constant Struct_Comp_List := Get_Components(Struct_Cls(C.Me));
   begin
      Plh(Lib, "#define " & Cls_Normalize_Func(C.Me) & "(val) (val)");
      Plh(Lib, "#define " & Cls_Check_Func(C.Me) & "(val) (val)");
      Plh(Lib, "#define " & Cls_Cast_Func(C.Me) & "(val) (val)");

      --===
      --  =, /=
      --===
      for I in 1..Length(Comps) loop
         Comp := Ith(Comps, I);
         Name := Cls_Struct_Comp_Name(Get_Name(Comp));
         if Test /= Null_String then
            Test := Test & " && ";
         end if;
         Test := Test & Cls_Bin_Operator_Name(Get_Cls(Comp), Eq_Op) &
	   "(_left." & Name & ", _right." & Name & ")";
      end loop;
      Plh(Lib, "#define " &
          Cls_Bin_Operator_Name(C.Me, Eq_Op) &
          "(_left, _right) ((" & Test & ") ? " &
          Cls_Enum_Const_Name(Bool_Cls, True_Const_Name) & ": " &
          Cls_Enum_Const_Name(Bool_Cls, False_Const_Name) & ")");
      Plh(Lib, "#define " &
          Cls_Bin_Operator_Name(C.Me, Neq_Op) &
          "(_left, _right) ((" & Test & ") ? " &
          Cls_Enum_Const_Name(Bool_Cls, False_Const_Name) & ": " &
          Cls_Enum_Const_Name(Bool_Cls, True_Const_Name) & ")");

      --===
      --  comparison operator
      --===
      Prototype :=
        "int " & Cls_Cmp_Operator_Name(C.Me) & "_func" & Nl &
        "(" & Cls_Name(C.Me) & " *left," & Nl &
        " " & Cls_Name(C.Me) & " *right)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype);
      Plc(Lib, "{");
      Plc(Lib, 1, "int cmp;");
      for I in 1..Length(Comps) loop
         Comp  := Ith(Comps, I);
         Name  := Cls_Struct_Comp_Name(Get_Name(Comp));
         C_Comp := Get_Cls(Comp);
         Plc(Lib, 1, "cmp = " & Cls_Cmp_Operator_Name(C_Comp) &
             "(left->" & Name & ", right->" & Name & ");");
         Plc(Lib, 1, "if(EQUAL != cmp) return cmp;");
      end loop;
      Plc(Lib, 1, "return EQUAL;");
      Plc(Lib, "}");
      Plh(Lib, "#define " & Cls_Cmp_Operator_Name(C.Me) & "(_left, _right) " &
          "(" & Cls_Cmp_Operator_Name(C.Me) & "_func(&(_left), &(_right)))");
   end;

   procedure Compile_Encoding_Functions
     (C  : in Struct_Cls_Record;
      Lib: in Library) is
      Comps    : constant Struct_Comp_List := Get_Components(Struct_Cls(C.Me));
      Comp     : Struct_Comp;
      Name     : Ustring;
      Width    : Natural := 0;
      Width_Str: Ustring := Null_String;
      C_Comp   : Cls;
      I        : Natural;
   begin
      --===
      --  bit width
      --===
      Ph(Lib, "#define " & Cls_Bit_Width_Func(C.Me) & "(_item) (");
      for I in 1..Length(Comps) loop
         Comp  := Ith(Comps, I);
         Name  := Cls_Struct_Comp_Name(Get_Name(Comp));
         C_Comp := Get_Cls(Comp);
         if Has_Constant_Bit_Width(Get_Cls(Comp)) then
            Width := Width + Bit_Width(C_Comp);
         else
            if Width_Str /= Null_String then
               Width_Str := Width_Str & " + ";
            end if;
            Width_Str := Width_Str &
              Cls_Bit_Width_Func(C_Comp) & "(_item." & Name & ")";
         end if;
      end loop;
      if Width_Str = Null_String then
         Width_Str := Width & "";
      elsif Width /= 0 then
         Width_Str := Width_Str & " + " & Width;
      end if;
      Plh(Lib, Width_Str & ")");

      --===
      --  encoding function
      --===
      Plh(Lib, "#define " & Cls_Encode_Func(C.Me) & "(e, bits) \");
      Plh(Lib, "{ \");
      for I in 1..Length(Comps) loop
         Comp := Ith(Comps, I);
         Name := Cls_Struct_Comp_Name(Get_Name(Comp));
         Plh(Lib, Tab & Cls_Encode_Func(Get_Cls(Comp)) &
             "(e." & Name & ", bits); \");
      end loop;
      Plh(Lib, "}");

      --===
      --  decoding functions
      --===
      Plh(Lib, "#define " & Cls_Decode_Func(C.Me) & "(bits, e) \");
      Plh(Lib, "{ \");
      I := 1;
      while I in 1..Length(Comps) loop
	 Comp := Ith(Comps, I);
	 Name := Cls_Struct_Comp_Name(Get_Name(Comp));
	 Plh(Lib, Tab & Cls_Decode_Func(Get_Cls(Comp)) &
	       "(bits, e." & Name & "); \");
	 I := I + 1;
      end loop;
      Plh(Lib, "}");
   end;

   procedure Compile_Io_Functions
     (C  : in Struct_Cls_Record;
      Lib: in Library) is
      Comps    : constant Struct_Comp_List := Get_Components(Struct_Cls(C.Me));
      Prototype: Ustring;
      Comp     : Struct_Comp;
      Name     : Ustring;
   begin
      --===
      --  print function
      --===
      Prototype :=
        "void " & Cls_Print_Func(C.Me) & Nl &
        "(" & Cls_Name(C.Me) & " expr)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype);
      Plc(Lib, "{");
      Plc(Lib, Tab & "printf(""{"");");
      for I in 1..Length(Comps) loop
         if I > 1 then
            Plc(Lib, Tab & "printf("","");");
         end if;
         Comp := Ith(Comps, I);
         Name := Cls_Struct_Comp_Name(Get_Name(Comp));
         Plc(Lib, Tab & Cls_Print_Func(Get_Cls(Comp)) &
             "(expr." & Name & ");");
      end loop;
      Plc(Lib, Tab & "printf(""}"");");
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
      Plc(Lib, 1, "fprintf (out, ""<struct><exprList>"");");
      for I in 1..Length(Comps) loop
         Comp := Ith(Comps, I);
         Name := Cls_Struct_Comp_Name(Get_Name(Comp));
         Plc(Lib, Tab & Cls_To_Xml_Func(Get_Cls(Comp)) &
             "(expr." & Name & ", out);");
      end loop;
      Plc(Lib, 1, "fprintf (out, ""</exprList></struct>"");");
      Plc(Lib, "}");
   end;

   procedure Compile_Hash_Function
     (C  : in Struct_Cls_Record;
      Lib: in Library) is
      Comps: constant Struct_Comp_List := Get_Components(Struct_Cls(C.Me));
      Comp : Struct_Comp;
      Name : Ustring;
   begin
      Plh(Lib, "#define " & Cls_Hash_Func(C.Me) & "(expr, result) { \");
      for I in 1..Length(Comps) loop
         Comp := Ith(Comps, I);
         Name := Cls_Struct_Comp_Name(Get_Name(Comp));
         Plh(Lib, 1, Cls_Hash_Func(Get_Cls(Comp)) &
	       "(expr." & Name & ", result); \");
      end loop;
      Plh(Lib, "}");
   end;

   procedure Compile_Others
     (C  : in Struct_Cls_Record;
      Lib: in Library) is
      Comps    : constant Struct_Comp_List :=
        Get_Components(Struct_Cls(C.Me));
      Prototype: Ustring;
      Comp     : Struct_Comp;
      Name     : Ustring;
      Test     : Ustring := Null_String;
   begin
      --===
      --  initialization function of the type: initialize the first and last
      --  constants
      --===
      Prototype :=
        "void " & Cls_Init_Func(C.Me) & Nl &
        "()";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & Nl);
      Plc(Lib, "{");
      for I in 1..Length(Comps) loop
         Comp := Ith(Comps, I);
         Plc(Lib, Tab & Cls_First_Const_Name(C.Me) & "." &
             Cls_Struct_Comp_Name(Get_Name(Comp)) & " = " &
             Cls_First_Const_Name(Get_Cls(Comp)) & ";");
         Plc(Lib, Tab & Cls_Last_Const_Name(C.Me) & "." &
             Cls_Struct_Comp_Name(Get_Name(Comp)) & " = " &
             Cls_Last_Const_Name(Get_Cls(Comp)) & ";");
      end loop;
      Plc(Lib, "}");

      --===
      --  construction function
      --===
      Prototype :=
        Cls_Name(C.Me) & " " &
        Cls_Constructor_Func(C.Me) & Nl & "(";
      for I in 1..Length(Comps) loop
         if I > 1 then
            Prototype := Prototype & "," & Nl & " ";
         end if;
         Comp := Ith(Comps, I);
         Prototype :=
           Prototype & Cls_Name(Get_Cls(Comp)) & " " &
           Cls_Struct_Comp_Name(Get_Name(Comp));
      end loop;
      Prototype := Prototype & ")";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & Nl & "{");
      Pc(Lib, Tab & Cls_Name(C.Me) & " result = {");
      for I in 1..Length(Comps) loop
         if I > 1 then
            Pc(Lib, ", ");
         end if;
         Comp := Ith(Comps, I);
         Pc(Lib, Cls_Struct_Comp_Name(Get_Name(Comp)));
      end loop;
      Plc(Lib, "};");
      Plc(Lib, Tab & "return result;");
      Plc(Lib, "}");

      --===
      --  assignement functions
      --===
      for I in 1..Length(Comps) loop
         Comp := Ith(Comps, I);
         Prototype :=
           Cls_Name(C.Me) & " " &
           Cls_Assign_Comp_Func(C.Me, Get_Name(Comp)) & Nl &
           "(" & Cls_Name(C.Me) & " s," & Nl &
           " " & Cls_Name(Get_Cls(Comp)) & " val)";
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype & Nl);
         Plc(Lib, "{");
         Plc(Lib, Tab & Cls_Name(C.Me) & " result = s;");
         Plc(Lib, Tab & "result." &
             Cls_Struct_Comp_Name(Get_Name(Comp)) & " = val;");
         Plc(Lib, Tab & "return result;");
         Plc(Lib, "}");
      end loop;
   end;

   function Get_Components
     (S: in Struct_Cls) return Struct_Comp_List is
   begin
      return S.Components;
   end;

   function Contains_Component
     (S: in Struct_Cls;
      C: in Ustring) return Boolean is
   begin
      return Contains(S.Components, C);
   end;

   function Get_Component_Index
     (S: in Struct_Cls;
      C: in Ustring) return Index_Type is
   begin
      return Get_Index(S.Components, C);
   end;

   function Get_Component
     (S: in Struct_Cls;
      C: in Ustring) return Struct_Comp is
   begin
      return Get_Component(S.Components, C);
   end;

   function Ith_Component
     (S: in Struct_Cls;
      I: in Index_Type) return Struct_Comp is
   begin
      return Ith(S.Components, I);
   end;

end Pn.Classes.Structs;
