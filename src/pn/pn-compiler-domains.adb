with
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Config,
  Pn.Compiler.Names,
  Pn.Compiler.Util,
  Pn.Nodes,
  Pn.Vars;

use
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Config,
  Pn.Compiler.Names,
  Pn.Compiler.Util,
  Pn.Nodes,
  Pn.Vars;

package body Pn.Compiler.Domains is

   --==========================================================================
   --  Elements generated for a color domain
   --==========================================================================

   function Dom_Type
     (D: in Dom) return Ustring is
      Result: Ustring;
   begin
      if Size(D) = 0 then
         Result := To_Ustring("empty_dom");
      else
         Result := To_Ustring("dom");
         for I in 1..Size(D) loop
            Result := Result & "_" & Cls_Name(Ith(D, I));
         end loop;
      end if;
      return Result & "_t";
   end;

   function Dom_Ith_Comp_Name
     (I: in Natural) return Ustring is
   begin
      return "comp" & I;
   end;

   --  bit-width function
   function Dom_Bit_Width_Func
     (D: in Dom) return Ustring is
   begin
      return Dom_Type(D) & "_bit_width";
   end;

   procedure Gen_Dom_Bit_Width_Func
     (D  : in Dom;
      Lib: in Library) is
      C        : Cls;
      Comp     : Ustring;
      Width    : Natural := 0;
      Width_Str: Ustring := Null_String;
   begin
      Ph(Lib, "#define " & Dom_Bit_Width_Func(D) & "(_item) (");
      for I in 1..Size(D) loop
         C   := Ith(D, I);
         Comp := Dom_Ith_Comp_Name(I);
         if Has_Constant_Bit_Width(C) then
            Width := Width + Bit_Width(C);
         else
            if Width_Str /= Null_String then
               Width_Str := Width_Str & " + ";
            end if;
            Width_Str := Width_Str &
              Cls_Bit_Width_Func(C) & "(_item." & Comp & ")";
         end if;
      end loop;
      if Width_Str = Null_String then
         Width_Str := Width & "";
      elsif Width /= 0 then
         Width_Str := Width_Str & " + " & Width;
      end if;
      Plh(Lib, Width_Str & ")");
   end;

   --  encoding function
   function Dom_Encode_Func
     (D: in Dom) return Ustring is
   begin
      return Dom_Type(D) & "_encode";
   end;

   procedure Gen_Dom_Encode_Func
     (D  : in Dom;
      Lib: in Library) is
      C   : Cls;
      Comp: Ustring;
   begin
      Plh(Lib, "#define " & Dom_Encode_Func(D) & "(item, bits) { \");
      for I in 1..Size(D) loop
         C   := Ith(D, I);
         Comp := Dom_Ith_Comp_Name(I);
         Plh(Lib, 1,
             Cls_Encode_Func(C) & "(item." & Comp & ", bits); \");
      end loop;
      Plh(Lib, "}");
      Nlh(Lib);
   end;

   --  decoding function
   function Dom_Decode_Func
     (D : in Dom) return Ustring is
   begin
      return Dom_Type(D) & "_decode";
   end;

   procedure Gen_Dom_Decode_Func
     (D  : in Dom;
      Lib: in Library) is
      C   : Cls;
      Comp: Ustring;
      Func: Ustring;
   begin
      Plh(Lib, "#define " & Dom_Decode_Func(D) & "(bits, item) { \");
      for I in 1..Size(D) loop
         C := Ith(D, I);
         Comp := Dom_Ith_Comp_Name(I);
         Plh(Lib, 1, Cls_Decode_Func(C) & "(bits, item." & Comp & "); \");
      end loop;
      Plh(Lib, "}");
      Nlh(Lib);
   end;

   --  equal operator on two colors of a color domain
   function Dom_Eq_Func
     (D: in Dom) return Ustring is
   begin
      return Dom_Type(D) & "_eq";
   end;

   procedure Gen_Dom_Eq_Func
     (D  : in Dom;
      Lib: in Library) is
      Prototype: Ustring;
      Comp     : Ustring;
      Ci       : Cls;
   begin
      if Size(D) > 0 then
         Prototype :=
           "bool_t " & Dom_Eq_Func(D) & "_func (" & Nl &
           "   " & Dom_Type(D) & " *left," & Nl &
           "    " & Dom_Type(D) & " *right)";
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype & " {");
         Pc(Lib, 1, "return ");
         for I in 1..Size(D) loop
            Comp := Dom_Ith_Comp_Name(I);
            Ci  := Ith(D, I);
            if I > 1 then
               Pc(Lib, " && ");
            end if;
            Pc(Lib, Cls_Bin_Operator_Name(Ci, Eq_Op) &
               "(left->" & Comp & ", right->" & Comp & ")");
         end loop;
         Plc(Lib, ";");
         Plc(Lib, "}");
      end if;

      Ph(Lib, "#define " & Dom_Eq_Func(D) & "(left, right) ");
      if Size(D) > 0 then
         Plh(Lib, "(" & Dom_Eq_Func(D) & "_func(&(left), &(right)))");
      else
         Plh(Lib, "TRUE");
      end if;
   end;

   --  not equal operator on two colors of a color domain
   function Dom_Neq_Func
     (D: in Dom) return Ustring is
   begin
      return Dom_Type(D) & "_neq";
   end;

   procedure Gen_Dom_Neq_Func
     (D  : in Dom;
      Lib: in Library) is
   begin
      Plh(Lib, "#define " & Dom_Neq_Func(D) & "(left, right) " &
          "(!" & Dom_Eq_Func(D) & "(left, right))");
   end;

   --  comparison operator
   function Dom_Cmp_Func
     (D: in Dom) return Ustring is
   begin
      return Dom_Type(D) & "_cmp";
   end;

   procedure Gen_Dom_Cmp_Func
     (D  : in Dom;
      Lib: in Library) is
      Prototype: Ustring;
      Comp     : Ustring;
      C        : Cls;
   begin
      if Size(D) > 0 then
         Prototype :=
           "int " & Dom_Cmp_Func(D) & "_func" & Nl &
           "(" & Dom_Type(D) & " *left," & Nl &
           " " & Dom_Type(D) & " *right)";
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype & " {");
         Plc(Lib, 1, "int cmp;");
         for I in 1..Size(D) loop
            C   := Ith(D, I);
            Comp := Dom_Ith_Comp_Name(I);
            Plc(Lib, 1, "cmp = " & Cls_Cmp_Operator_Name(C) &
                "(left->" & Comp & ", right->" & Comp & ");");
            Plc(Lib, 1, "if(EQUAL != cmp) return cmp;");
         end loop;
         Plc(Lib, 1, "return EQUAL;");
         Plc(Lib, "}");
      end if;
      Ph(Lib, "#define " & Dom_Cmp_Func(D) & "(left, right) ");
      if Size(D) > 0 then
         Plh(Lib, "(" & Dom_Cmp_Func(D) & "_func(&(left), &(right)))");
      else
         Plh(Lib, "EQUAL");
      end if;
   end;

   --  hash function
   function Dom_Hash_Func
     (D: in Dom) return Ustring is
   begin
      return Dom_Type(D) & "_hash";
   end;

   procedure Gen_Dom_Hash_Func
     (D  : in Dom;
      Lib: in Library) is
      Comp: Ustring;
      C   : Cls;
   begin
      Plh(Lib, "#define " & Dom_Hash_Func(D) & "(_item, _result) { \");
      for I in 1..Size(D) loop
	 C := Ith(D, I);
	 Comp := Dom_Ith_Comp_Name(I);
	 Plh(Lib, 1, Cls_Hash_Func(C) & "(_item." & Comp & ", _result); \");
      end loop;
      Plh(Lib, "}");
   end;

   procedure Gen_Dom_Type
     (D  : in Dom;
      Lib: in Library) is
      Index_Of_Func    : Ustring;
      Index_Type       : Ustring;
      Item_At_Func     : Ustring;
      Init_Func        : Ustring;
      Free_Func        : Ustring;
   begin
      Plh(Lib, "typedef struct {");
      if Size(D) > 0 then
         for I in 1..Size(D) loop
	    Plh(Lib, 1, Cls_Name(Ith(D, I)) & " " &
		  Dom_Ith_Comp_Name(I) & ";");
         end loop;
      else
         Plh(Lib, 1, "char dummy;");
      end if;
      Plh(Lib, "} " & Dom_Type(D) & ";");
      Gen_Dom_Eq_Func(D, Lib);
      Gen_Dom_Neq_Func(D, Lib);
      Gen_Dom_Cmp_Func(D, Lib);
      Gen_Dom_Hash_Func(D, Lib);
      Gen_Dom_Bit_Width_Func(D, Lib);
      Gen_Dom_Encode_Func(D, Lib);
      Gen_Dom_Decode_Func(D, Lib);
   end;



   --==========================================================================
   --  Elements generated for the color domain of a place
   --==========================================================================

   function Place_Dom_Type
     (P: in Place) return Ustring is
   begin
      return Dom_Type(Get_Dom(P));
   end;

   function Place_Dom_Bit_Width_Func
     (P: in Place) return Ustring is
   begin
      return Dom_Bit_Width_Func(Get_Dom(P));
   end;

   function Place_Dom_Encode_Func
     (P: in Place) return Ustring is
   begin
      return Dom_Encode_Func(Get_Dom(P));
   end;

   function Place_Dom_Decode_Func
     (P: in Place) return Ustring is
   begin
      return Dom_Decode_Func(Get_Dom(P));
   end;

   function Place_Dom_Eq_Func
     (P: in Place) return Ustring is
   begin
      return Dom_Eq_Func(Get_Dom(P));
   end;

   function Place_Dom_Neq_Func
     (P: in Place) return Ustring is
   begin
      return Dom_Neq_Func(Get_Dom(P));
   end;

   function Place_Dom_Cmp_Func
     (P: in Place) return Ustring is
   begin
      return Dom_Cmp_Func(Get_Dom(P));
   end;

   function Place_Dom_Hash_Func
     (P: in Place) return Ustring is
   begin
      return Dom_Hash_Func(Get_Dom(P));
   end;

   function Place_Dom_Print_Func
     (P: in Place) return Ustring is
   begin
      return Place_Name(P) & "_print_token";
   end;

   procedure Gen_Print_Place_Dom_Func
     (P  : in Place;
      Lib: in Library) is
      D        : constant Dom := Get_Dom(P);
      Func_Name: constant Ustring := Place_Dom_Print_Func(P);
      C        : Cls;
      Comp     : Ustring;
   begin
      Plh(Lib, "#define " & Func_Name & "(color) { \");
      if Size(D) > 0 then
         Plh(Lib, 1, "printf(""<(""); \");
         for I in 1..Size(D) loop
            if I > 1 then
               Plh(Lib, 1, "printf("", ""); \");
            end if;
            C := Ith(D, I);
            Comp := Dom_Ith_Comp_Name(I);
            Plh(Lib, 1, Cls_Print_Func(C) & "(color." & Comp & "); \");
         end loop;
         Plh(Lib, 1,
             "printf("")>""); \");
      else
         Plh(Lib, 1, "printf(""epsilon""); \");
      end if;
      Plh(Lib, "}");
      Nlh(Lib);
   end;

   procedure Gen_Place_Domain
     (P  : in Place;
      Lib: in Library) is
   begin
      Gen_Print_Place_Dom_Func(P, Lib);
   end;



   --==========================================================================
   --  Elements generated for the color domain of a transition
   --==========================================================================

   function Trans_Dom_Type
     (T: in Trans) return Ustring is
   begin
      return Dom_Type(Get_Dom(T));
   end;

   function Trans_Dom_Bit_Width_Func
     (T: in Trans) return Ustring is
   begin
      return Dom_Bit_Width_Func(Get_Dom(T));
   end;

   function Trans_Dom_Encode_Func
     (T: in Trans) return Ustring is
   begin
      return Dom_Encode_Func(Get_Dom(T));
   end;

   function Trans_Dom_Decode_Func
     (T: in Trans) return Ustring is
   begin
      return Dom_Decode_Func(Get_Dom(T));
   end;

   function Trans_Dom_Eq_Func
     (T: in Trans) return Ustring is
   begin
      return Dom_Eq_Func(Get_Dom(T));
   end;

   function Trans_Dom_Neq_Func
     (T: in Trans) return Ustring is
   begin
      return Dom_Neq_Func(Get_Dom(T));
   end;

   function Trans_Dom_Cmp_Func
     (T: in Trans) return Ustring is
   begin
      return Dom_Cmp_Func(Get_Dom(T));
   end;

   function Trans_Dom_Hash_Func
     (T: in Trans) return Ustring is
   begin
      return Dom_Hash_Func(Get_Dom(T));
   end;

   function Trans_Dom_Print_Func
     (T: in Trans) return Ustring is
   begin
      return Trans_Name(T) & "_print_binding";
   end;

   procedure Gen_Trans_Dom_Print_Func
     (T  : in Trans;
      Lib: in Library) is
      D        : constant Dom := Get_Dom(T);
      Vars     : constant Var_List := Get_Vars(T);
      Func_Name: constant Ustring := Trans_Dom_Print_Func(T);
      C        : Cls;
      V        : Var;
      Comp     : Ustring;
   begin
      Plh(Lib, "#define " & Func_Name & "(color) { \");
      Plh(Lib, 1, "printf(""[""); \");
      for I in 1..Size(D) loop
         if I > 1 then
            Plh(Lib, 1, "printf("", ""); \");
         end if;
         C := Ith(D, I);
         V := Ith(Vars, I);
         Comp := Dom_Ith_Comp_Name(I);
         Plh(Lib, 1, "printf(""" & Get_Name(V) & "=""); \");
         Plh(Lib, 1, Cls_Print_Func(C) & "(color." & Comp & "); \");
      end loop;
      Plh(Lib, 1, "printf(""]""); \");
      Plh(Lib, "}");
      Nlh(Lib);
   end;

   procedure Gen_Trans_Domain
     (T  : in Trans;
      Lib: in Library) is
   begin
      Gen_Trans_Dom_Print_Func(T, Lib);
   end;



   --==========================================================================
   --  Some useful functions and procedures
   --==========================================================================

   function Encoded_Size
     (D   : in Dom;
      Item: in Ustring) return Ustring is
      Result: Ustring;
   begin
      if Has_Constant_Bit_Width(D) then
         Result := Pn.Classes.Bit_Width(D) & "";
      else
         Result := Dom_Bit_Width_Func(D) & "(" & Item & ")";
      end if;
      return Result;
   end;

   procedure Add_Dom
     (D: in Dom) is
   begin
      if not Dom_Set_Pkg.Contains(Doms, D) then
         Dom_Set_Pkg.Insert(Doms, D);
      end if;
   end;



   --==========================================================================
   --  Main generation procedure
   --==========================================================================

   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      Comment  : constant String :=
        "This library contains the definition of the color domains of the " &
        "net.";
      Lib      : Library;
      D        : Dom;
      Prototype: Ustring;
   begin
      Init_Library(Domains_Lib, To_Ustring(Comment), Path, Lib);
      Plh(Lib, "#include ""colors.h""");
      --  add the domains of all the places to the set of domains
      for I in 1..P_Size(N) loop
         D := Get_Dom(Ith_Place(N, I));
         if not Dom_Set_Pkg.Contains(Doms, D) then
            Dom_Set_Pkg.Insert(Doms, D);
         end if;
      end loop;
      --  add the domains of all the transitions to the set of domains
      for I in 1..T_Size(N) loop
         D := Get_Dom(Ith_Trans(N, I));
         if not Dom_Set_Pkg.Contains(Doms, D) then
            Dom_Set_Pkg.Insert(Doms, D);
         end if;
      end loop;
      --  generate the domains
      for I in 1..Dom_Set_Pkg.Card(Doms) loop
         D := Dom_Set_Pkg.Ith(Doms, I);
         Gen_Dom_Type(D, Lib);
      end loop;
      for I in 1..P_Size(N) loop
         Gen_Place_Domain(Ith_Place(N, I), Lib);
      end loop;
      for I in 1..T_Size(N) loop
         Gen_Trans_Domain(Ith_Trans(N, I), Lib);
      end loop;
      Prototype :=
	"void " & Lib_Init_Func(Domains_Lib) & Nl &
	"()";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, "}");
      Prototype :=
	"void " & Lib_Free_Func(Domains_Lib) & Nl &
	"()";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, "}");
      End_Library(Lib);
   end;

end Pn.Compiler.Domains;
