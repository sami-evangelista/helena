with
  Pn.Compiler,
  Pn.Compiler.Domains,
  Pn.Compiler.Names;

use
  Pn.Compiler,
  Pn.Compiler.Domains,
  Pn.Compiler.Names;

package body Pn.Classes.Products is

   function New_Product_Cls
     (D: in Dom) return Cls is
      Result: constant Product_Cls := new Product_Cls_Record;
   begin
      Initialize(Result, Null_String);
      Result.Name := Get_Product_Cls_Name(D);
      Result.D   := D;
      return Cls(Result);
   end;

   function Get_Product_Cls_Name
     (D: in Dom) return Ustring is
   begin
      return "product " & To_Helena(D);
   end;

   procedure Free
     (C: in out Product_Cls_Record) is
   begin
      Free(C.D);
   end;

   function Get_Type
     (C: in Product_Cls_Record) return Cls_Type is
   begin
      return A_Product_Cls;
   end;

   function Low_Value
     (C: in Product_Cls_Record) return Expr is
   begin
      pragma Assert(False);
      return null;
   end;

   function High_Value
     (C: in Product_Cls_Record) return Expr is
   begin
      pragma Assert(False);
      return null;
   end;

   procedure Card
     (C     : in     Product_Cls_Record;
      Result:    out Card_Type;
      State:    out Count_State) is
   begin
      Card(C.D, Result, State);
   end;

   function Ith_Value
     (C: in Product_Cls_Record;
      I: in Card_Type) return Expr is
   begin
      pragma Assert(False);
      return null;
   end;

   function Get_Value_Index
     (C: in     Product_Cls_Record;
      E: access Expr_Record'Class) return Card_Type is
   begin
      pragma Assert(False);
      return 0;
   end;

   function Elements_Size
     (C: in Product_Cls_Record) return Natural is
   begin
      return Size(C.D);
   end;

   function Basic_Elements_Size
     (C: in Product_Cls_Record) return Natural is
      Result: Natural := 0;
   begin
      for I in 1..Size(C.D) loop
         Result := Result + Basic_Elements_Size(Ith(C.D, I));
      end loop;
      return Result;
   end;

   function Is_Const_Of_Cls
     (C: in     Product_Cls_Record;
      E: access Expr_Record'Class) return Boolean is
   begin
      return False;
   end;

   function Colors_Used
     (C: in Product_Cls_Record) return Cls_Set is
   begin
      return New_Cls_Set;
   end;

   function Has_Constant_Bit_Width
     (C: in Product_Cls_Record) return Boolean is
   begin
      return True;
   end;

   function Bit_Width
     (C: in Product_Cls_Record) return Natural is
   begin
      return 0;
   end;

   procedure Compile_Type_Definition
     (C  : in Product_Cls_Record;
      Lib: in Library) is
   begin
      --===
      --  add the domain of C to the set of color domains to generate
      --===
      Pn.Compiler.Domains.Add_Dom(C.D);
      Plh(Lib, "#define " & Cls_Name(C.Me) & " " & Dom_Type(C.D));
   end;

   procedure Compile_Constants
     (C  : in Product_Cls_Record;
      Lib: in Library) is
   begin
      null;
   end;

   procedure Compile_Operators
     (C  : in Product_Cls_Record;
      Lib: in Library) is
   begin
      Plh(Lib, "#define " & Cls_Normalize_Func(C.Me) & "(val) (val)");
      Plh(Lib, "#define " & Cls_Check_Func(C.Me) & "(val) (val)");
      Plh(Lib, "#define " & Cls_Bin_Operator_Name(C.Me, Eq_Op) & " " &
	    Dom_Eq_Func(C.D));
      Plh(Lib, "#define " & Cls_Bin_Operator_Name(C.Me, Neq_Op) & " " &
	    Dom_Neq_Func(C.D));
      Plh(Lib, "#define " & Cls_Cmp_Operator_Name(C.Me) & " " &
          Dom_Cmp_Func(C.D));
   end;

   procedure Compile_Encoding_Functions
     (C  : in Product_Cls_Record;
      Lib: in Library) is
   begin
      null;
   end;

   procedure Compile_Io_Functions
     (C  : in Product_Cls_Record;
      Lib: in Library) is
   begin
      null;
   end;

   procedure Compile_Hash_Function
     (C  : in Product_Cls_Record;
      Lib: in Library) is
   begin
      null;
   end;

   procedure Compile_Others
     (C  : in Product_Cls_Record;
      Lib: in Library) is
      Prototype: Ustring;
   begin
      --===
      --  initialization function of the type
      --===
      Prototype :=
        "void " & Cls_Init_Func(C.Me) & Nl &
        "()";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {}");
      Nlh(Lib);
   end;

   function Get_Dom
     (P: in Product_Cls) return Dom is
   begin
      return P.D;
   end;

end Pn.Classes.Products;
