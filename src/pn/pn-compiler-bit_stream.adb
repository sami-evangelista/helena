with
  Utils.Math;

use
  Utils.Math;

package body Pn.Compiler.Vectors is

   subtype Vector_Shift is Natural range 0 .. Bits_Per_Slot - 1;
   --  possible shift in a slot of a vector


   --==========================================================================
   --  some useful functions
   --==========================================================================

   function Is_Power_Of
     (Num: in Big_Int;
      Pow: in Big_Int) return Boolean is
   begin
      if Num = 1 or Num = 0 then
         return True;
      else
         return Num mod Pow = 0 and then Is_Power_Of(Num / Pow, Pow);
      end if;
   end;

   function Get_Division_Expr
     (Expr: in Unbounded_String;
      Div : in Natural) return Unbounded_String is
      Log   : Float;
      Result: Unbounded_String;
   begin
      if Is_Power_Of(Big_Nat(Div), 2) then
         Log := Float(Log2(Big_Nat(Div)));
         Result := "((" & Expr & ") >> " & Natural(Log) & ")";
      else
         Result := "((" & Expr & ") / " & Div & ")";
      end if;
      return Result;
   end;

   function Get_Mult_Expr
     (Expr: in Unbounded_String;
      Mult: in Natural) return Unbounded_String is
      Log   : Float;
      Result: Unbounded_String;
   begin
      if Is_Power_Of(Big_Nat(Mult), 2) then
         Log := Float(Log2(Big_Nat(Mult)));
         Result := "((" & Expr & ") << " & Natural(Log) & ")";
      else
         Result := "((" & Expr & ") * " & Mult & ")";
      end if;
      return Result;
   end;

   function Get_Modulo_Expr
     (Expr  : in Unbounded_String;
      Modulo: in Natural) return Unbounded_String is
      Result: Unbounded_String;
   begin
      if Is_Power_Of(Big_Nat(Modulo), 2) then
         Result := "((" & Expr & ") & " & (Modulo - 1) & ")";
      else
         Result := "((" & Expr & ") % " & Modulo & ")";
      end if;
      return Result;
   end;

   function Slots_For_Bits
     (Bits: in Natural) return Natural is
      Result: Natural := Bits / Bits_Per_Slot;
   begin
      if Bits mod Bits_Per_Slot /= 0 then
         Result := Result + 1;
      end if;
      return Result;
   end;

   --  slots for bits
   function Slots_For_Bits_Func return Unbounded_String is
   begin
      return To_Unbounded_String("slots_for_bits");
   end;

   procedure Gen_Slots_For_Bits_Func
     (Lib: in Library) is
      Mod_Expr: constant Unbounded_String :=
        Get_Modulo_Expr(To_Unbounded_String("b"), Bits_Per_Slot);
      Div_Expr: constant Unbounded_String :=
        Get_Division_Expr(To_Unbounded_String("b"), Bits_Per_Slot);
   begin
      Plh(Lib, "#define " & Slots_For_Bits_Func &
          "(b) ((" & Mod_Expr & ") ? ((" & Div_Expr &
          ") + 1): (" & Div_Expr & "))");
   end;

   --  return the mask which enables to get the bits in specific intervals
   function Get_Mask
     (R: in Ranges) return Unbounded_String is

      subtype Bit is Natural range 0..1;
      Max: constant Natural := Natural'Max(Item_Width'Last, Bits_Per_Slot);
      type Int_Base2 is array (1..Max) of Bit;

      function To_Hexa
        (Bits: in Int_Base2) return String is
         Result: Unbounded_String := Null_String;
         function To_Hexa
           (Low: in Natural;
            Up: in Natural) return Character is
         begin
            if    Bits(Low..Up) = (0,0,0,0) then return '0';
            elsif Bits(Low..Up) = (0,0,0,1) then return '1';
            elsif Bits(Low..Up) = (0,0,1,0) then return '2';
            elsif Bits(Low..Up) = (0,0,1,1) then return '3';
            elsif Bits(Low..Up) = (0,1,0,0) then return '4';
            elsif Bits(Low..Up) = (0,1,0,1) then return '5';
            elsif Bits(Low..Up) = (0,1,1,0) then return '6';
            elsif Bits(Low..Up) = (0,1,1,1) then return '7';
            elsif Bits(Low..Up) = (1,0,0,0) then return '8';
            elsif Bits(Low..Up) = (1,0,0,1) then return '9';
            elsif Bits(Low..Up) = (1,0,1,0) then return 'a';
            elsif Bits(Low..Up) = (1,0,1,1) then return 'b';
            elsif Bits(Low..Up) = (1,1,0,0) then return 'c';
            elsif Bits(Low..Up) = (1,1,0,1) then return 'd';
            elsif Bits(Low..Up) = (1,1,1,0) then return 'e';
            elsif Bits(Low..Up) = (1,1,1,1) then return 'f';
            else
               return 'f';
            end if;
         end;
      begin
         for I in 1..Max/4 loop
            Result := Result & To_Hexa(4 * (I - 1) + 1, 4 * I);
         end loop;
         return To_String(Result);
      end;
      Result: Int_Base2 := (others => 0);

   begin
      for I in R'Range loop
         if R(I).Up >= R(I).Low then
            Result(Max - R(I).Up .. Max - R(I).Low) := (others => 1);
         end if;
      end loop;
      return To_Unbounded_String("0x" & To_Hexa(Result));
   end;

   function Get_Mask
     (Low: in Natural;
      Up: in Natural) return Unbounded_String is
   begin
      return Get_Mask((1 => (Low => Low, Up => Up)));
   end;



   --==========================================================================
   --  vector of bits
   --==========================================================================

   --  constructs a vector
   procedure Gen_Vector_New_Func
     (Lib: in Library) is
   begin
      Plh(Lib, "#define VECTOR_new(bits, size) { \");
      Plh(Lib, 1, "int i = 0; \");
      Plh(Lib, 1, "bits.slot_size = " & Slots_For_Bits_Func & "(size); \");
      Plh(Lib, 1, "MALLOC(bits.vector, " & Slot_Type & " *, " &
	    " sizeof(" & Slot_Type & ") * bits.slot_size); \");
      Plh(Lib, 1, "for(; i < bits.slot_size; i++) bits.vector[i] = 0; \");
      Plh(Lib, 1, "bits.pos = bits.shift = 0; \");
      Plh(Lib, 1, "bits.bit_size = size; \");
      Plh(Lib, "}");
   end;

   --  start a vector
   procedure Gen_Vector_Start_Func
     (Lib: in Library) is
   begin
      Plh(Lib, "#define VECTOR_start(_v) { _v.pos = _v.shift = 0; }");
   end;

   --  set bits of a vector. size and shift are known
   function Vector_Set_Func
     (Size : in Item_Width;
      Shift: in Vector_Shift) return Unbounded_String is
   begin
      return "VECTOR_set_size" & Size & "_shift" & Shift;
   end;

   procedure Gen_Vector_Set_Func
     (Size : in Item_Width;
      Shift: in Vector_Shift;
      Lib  : in Library) is
      New_Shift: Natural;
      I        : Natural;
      J        : Natural;
      Mask     : Unbounded_String;
      Prototype: Unbounded_String;
      function Pj return Unbounded_String is
         Result: Unbounded_String;
      begin
         if J = 0 then
            Result := Null_String;
         else
            Result := " + " & J;
         end if;
         return Result;
      end;
   begin
      Prototype := "void " & Vector_Set_Func(Size, Shift) & Nl &
        "(vector *v," & Nl &
        " unsigned long val)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype);
      Plc(Lib, "{");
      if Size = 0 then
         Plc(Lib, "}");
         return;
      end if;
      if Shift > 0 then
         I := Bits_Per_Slot - Shift;
         J := 1;
         if Shift + Size >= Bits_Per_Slot then
            Mask := Get_Mask(0, Shift-1);
         else
            Mask := Get_Mask(((0, Shift - 1),
                              (Shift + Size, Bits_Per_Slot - 1)));
         end if;
         Plc(Lib, 1, "v->vector[v->pos] = (v->vector[v->pos] & " &
             Mask & ") | ((val & " &
             Get_Mask(0, Natural'Min(Size - 1, Bits_Per_Slot - Shift - 1)) &
             ") << " & Shift & ");");
      else
         I := 0;
         J := 0;
      end if;
      while I < Size loop
         Pc(Lib, 1, "v->vector[v->pos" & Pj & "] =  (val");
         if I > 0 then
            Pc(Lib, " >> " & I);
         end if;
         Pc(Lib, ")");
         I := I + Bits_Per_Slot;
         if I > Size then
            Pc(Lib, " | (v->vector[v->pos" & Pj & "] & " &
               Get_Mask(Bits_Per_Slot-I+Size, Bits_Per_Slot-1) & ")");
         end if;
         Plc(Lib, ";");
         J := J + 1;
      end loop;
      if ((Shift + Size) / Bits_Per_Slot) /= 0 then
         Plc(Lib, 1,
             "v->pos += " & ((Shift + Size) / Bits_Per_Slot) & ";");
      end if;
      New_Shift := (Size + Shift) mod Bits_Per_Slot;
      if New_Shift /= Shift then
         Plc(Lib, 1, "v->shift = " & New_Shift & ";");
      end if;
      Plc(Lib, "}");
   end;

   --  set bits of a vector. size is known
   function Vector_Set_Func
     (Size: in Item_Width) return Unbounded_String is
   begin
      return "VECTOR_set_size" & Size;
   end;

   procedure Gen_Vector_Set_Func
     (Size: in Item_Width;
      Lib : in Library) is
      Table: constant Unbounded_String := Vector_Set_Func(Size) & "_table";
   begin
      --===
      --  the macro simply calls the appropriate function of the table
      --===
      Plh(Lib, "#define " & Vector_Set_Func(Size) &
          "(_v, _val) { (* " & Table & "[_v.shift])(&_v, _val); }");
   end;

   --  set bits of a vector
   procedure Gen_Vector_Set_Func
     (Lib: in Library) is
   begin
      --===
      --  the macro simply calls the appropriate function of the table
      --===
      Plh(Lib, "#define VECTOR_set(_v, _val, _size) { " &
          "(* VECTOR_set_table[_size][_v.shift])(&_v, _val); }");
   end;

   --  get bits of a vector. size and shift are known
   function Vector_Get_Func
     (Size : in Item_Width;
      Shift: in Vector_Shift) return Unbounded_String is
   begin
      return "VECTOR_get_size" & Size & "_shift" & Shift;
   end;

   procedure Gen_Vector_Get_Func
     (Size : in Item_Width;
      Shift: in Vector_Shift;
      Lib  : in Library) is
      New_Shift: Natural;
      I        : Natural;
      J        : Natural;
      Pipe     : Boolean;
      Prototype: Unbounded_String;
   begin
      Prototype :=
        "unsigned long " & Vector_Get_Func(Size, Shift) & Nl &
        "(vector *v)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype);
      Plc(Lib, "{");
      if Size = 0 then
         Plc(Lib, 1, "return 0;");
         Plc(Lib, "}");
         return;
      end if;
      Pc(Lib, 1, "unsigned long result = ");
      if Shift > 0 then
         Pc(Lib, "((v->vector[v->pos] >> " & Shift & ") & " &
            Get_Mask(0, Natural'Min(Size - 1, Bits_Per_Slot - Shift - 1)) &
            ")");
         I := Bits_Per_Slot - Shift;
         J := 1;
         Pipe := True;
      else
         I := 0;
         J := 0;
         Pipe := False;
      end if;
      while I < Size loop
         if Pipe then
            Pc(Lib, " | ");
         else
            Pipe := True;
         end if;
         Pc(Lib, "((v->vector[v->pos");
         if J > 0 then
            Pc(Lib, " + " & J);
         end if;
         Pc(Lib, "]");
         if I > 0 then
            Pc(Lib, " << " & I & ")");
         else
            Pc(Lib, ")");
         end if;
         Pc(Lib, " & " &
              Get_Mask(I, Natural'Min(I + Bits_Per_Slot - 1, Size - 1)) & ")");
         I := I + Bits_Per_Slot;
         J := J + 1;
      end loop;
      Plc(Lib, ";");
      if ((Shift + Size) / Bits_Per_Slot) /= 0 then
         Plc(Lib, 1, "v->pos   += " & ((Shift + Size) / Bits_Per_Slot) &
             ";");
      end if;
      New_Shift := (Size + Shift) mod Bits_Per_Slot;
      Plc(Lib, 1, "v->shift = " & New_Shift & ";");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
   end;

   --  get bits of a vector. size is known
   function Vector_Get_Func
     (Size: in Item_Width) return Unbounded_String is
   begin
      return "VECTOR_get_size" & Size;
   end;

   procedure Gen_Vector_Get_Func
     (Size: in Item_Width;
      Lib : in Library) is
      Table: constant Unbounded_String := Vector_Get_Func(Size) & "_table";
   begin
      --===
      --  the macro simply calls the appropriate function of the table
      --===
      Plh(Lib, "#define " & Vector_Get_Func(Size) &
          "(_v, _val) { _val = (* " & Table & "[_v.shift])(&_v); }");
   end;

   --  get bits from vector
   procedure Gen_Vector_Get_Func
     (Lib: in Library) is
   begin
      --===
      --  the macro simply calls the appropriate function of the table
      --===
      Plh(Lib, "#define VECTOR_get(_v, _val, _size) { _val = " &
          "(* VECTOR_get_table[_size][_v.shift])(&_v); }");
   end;

   --  get bits of a vector backwardly. size and shift are known
   function Vector_Get_Back_Func
     (Size : in Item_Width;
      Shift: in Vector_Shift) return Unbounded_String is
   begin
      return "VECTOR_get_back_size" & Size & "_shift" & Shift;
   end;

   procedure Gen_Vector_Get_Back_Func
     (Size : in Item_Width;
      Shift: in Vector_Shift;
      Lib  : in Library) is
      New_Shift: Natural;
      I        : Natural;
      J        : Natural;
      Move     : Natural;
      Pipe     : Boolean;
      Prototype: Unbounded_String;
   begin
      Prototype :=
        "unsigned long " & Vector_Get_Back_Func(Size, Shift) & Nl &
        "(vector *v)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype);
      Plc(Lib, "{");
      if Size = 0 then
         Plc(Lib, 1, "return 0;");
         Plc(Lib, "}");
         return;
      end if;
      Plc(Lib, 1, "unsigned long result;");
      Move := (Size + (Bits_Per_Slot - 1 - Shift)) / Bits_Per_Slot;
      if Move > 0 then
         Plc(Lib, 1, "v->pos -= " & Move & ";");
      end if;
      New_Shift := (Shift - Size) mod Bits_Per_Slot;
      Plc(Lib, 1, "v->shift = " & New_Shift & ";");
      Pc(Lib, 1, "result = ");
      if New_Shift > 0 then
         Pc(Lib, "((v->vector[v->pos] >> " & New_Shift & ") & " &
            Get_Mask(0, Natural'Min(Size - 1,
                                    Bits_Per_Slot - New_Shift - 1)) & ")");
         I := Bits_Per_Slot - New_Shift;
         J := 1;
         Pipe := True;
      else
         I := 0;
         J := 0;
         Pipe := False;
      end if;
      while I < Size loop
         if Pipe then
            Pc(Lib, " | ");
         else
            Pipe := True;
         end if;
         Pc(Lib, "((v->vector[v->pos");
         if J > 0 then
            Pc(Lib, " + " & J);
         end if;
         Pc(Lib, "]");
         if I > 0 then
            Pc(Lib, " << " & I & ")");
         else
            Pc(Lib, ")");
         end if;
         Pc(Lib, " & " &
            Get_Mask(I, Natural'Min(I + Bits_Per_Slot - 1, Size - 1)) & ")");
         I := I + Bits_Per_Slot;
         J := J + 1;
      end loop;
      Plc(Lib, ";");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
   end;

   --  get bits of a vector backwardly. size is known
   function Vector_Get_Back_Func
     (Size: in Item_Width) return Unbounded_String is
   begin
      return "VECTOR_get_back_size" & Size;
   end;

   procedure Gen_Vector_Get_Back_Func
     (Size: in Item_Width;
      Lib: in Library) is
      Table: constant Unbounded_String :=
	Vector_Get_Back_Func(Size) & "_table";
   begin
      --===
      --  the macro simply calls the appropriate function of the table
      --===
      Plh(Lib, "#define " & Vector_Get_Back_Func(Size) &
          "(_v, _val) { _val = (* " & Table & "[_v.shift])(&_v); }");
   end;

   --  get bits of a vector backward
   procedure Gen_Vector_Get_Back_Func
     (Lib: in Library) is
   begin
      --===
      --  the macro simply calls the appropriate function of the table
      --===
      Plh(Lib, "#define VECTOR_get_back(_v, _val, _size) { _val = " &
          "(* VECTOR_get_back_table[_size][_v.shift])(&_v); }");
   end;

   --  free a vector
   procedure Gen_Vector_Free_Func
     (Lib: in Library) is
   begin
      Plh(Lib, "#define VECTOR_free(_v) { free(_v.vector); }");
   end;

   --  key function of a vector
   procedure Gen_Vector_Key_Func
     (Lib: in Library) is
      Prototype: constant String :=
        "uint32_t VECTOR_key (" & Nl &
        "   vector v)";
      function Compute_No_Chars return Natural is
      begin
	 return Bits_Per_Slot / Bits_Per_Char;
      end;
      No_Chars : constant Natural := Compute_No_Chars;
   begin
      Plh(Lib, Prototype & ";");
      Plc(Lib, "uint32_t crc32_tab[] =");
      Plc(Lib, "{");
      Plc(Lib, Null_String &
          "   0x00000000,0x77073096,0xee0e612c,0x990951ba,0x076dc419," & Nl &
          "   0x706af48f,0xe963a535,0x9e6495a3,0x0edb8832,0x79dcb8a4," & Nl &
          "   0xe0d5e91e,0x97d2d988,0x09b64c2b,0x7eb17cbd,0xe7b82d07," & Nl &
          "   0x90bf1d91,0x1db71064,0x6ab020f2,0xf3b97148,0x84be41de," & Nl &
          "   0x1adad47d,0x6ddde4eb,0xf4d4b551,0x83d385c7,0x136c9856," & Nl &
          "   0x646ba8c0,0xfd62f97a,0x8a65c9ec,0x14015c4f,0x63066cd9," & Nl &
          "   0xfa0f3d63,0x8d080df5,0x3b6e20c8,0x4c69105e,0xd56041e4," & Nl &
          "   0xa2677172,0x3c03e4d1,0x4b04d447,0xd20d85fd,0xa50ab56b," & Nl &
          "   0x35b5a8fa,0x42b2986c,0xdbbbc9d6,0xacbcf940,0x32d86ce3," & Nl &
          "   0x45df5c75,0xdcd60dcf,0xabd13d59,0x26d930ac,0x51de003a," & Nl &
          "   0xc8d75180,0xbfd06116,0x21b4f4b5,0x56b3c423,0xcfba9599," & Nl &
          "   0xb8bda50f,0x2802b89e,0x5f058808,0xc60cd9b2,0xb10be924," & Nl &
          "   0x2f6f7c87,0x58684c11,0xc1611dab,0xb6662d3d,0x76dc4190," & Nl &
          "   0x01db7106,0x98d220bc,0xefd5102a,0x71b18589,0x06b6b51f," & Nl &
          "   0x9fbfe4a5,0xe8b8d433,0x7807c9a2,0x0f00f934,0x9609a88e," & Nl &
          "   0xe10e9818,0x7f6a0dbb,0x086d3d2d,0x91646c97,0xe6635c01," & Nl &
          "   0x6b6b51f4,0x1c6c6162,0x856530d8,0xf262004e,0x6c0695ed," & Nl &
          "   0x1b01a57b,0x8208f4c1,0xf50fc457,0x65b0d9c6,0x12b7e950," & Nl &
          "   0x8bbeb8ea,0xfcb9887c,0x62dd1ddf,0x15da2d49,0x8cd37cf3," & Nl &
          "   0xfbd44c65,0x4db26158,0x3ab551ce,0xa3bc0074,0xd4bb30e2," & Nl &
          "   0x4adfa541,0x3dd895d7,0xa4d1c46d,0xd3d6f4fb,0x4369e96a," & Nl &
          "   0x346ed9fc,0xad678846,0xda60b8d0,0x44042d73,0x33031de5," & Nl &
          "   0xaa0a4c5f,0xdd0d7cc9,0x5005713c,0x270241aa,0xbe0b1010," & Nl &
          "   0xc90c2086,0x5768b525,0x206f85b3,0xb966d409,0xce61e49f," & Nl &
          "   0x5edef90e,0x29d9c998,0xb0d09822,0xc7d7a8b4,0x59b33d17," & Nl &
          "   0x2eb40d81,0xb7bd5c3b,0xc0ba6cad,0xedb88320,0x9abfb3b6," & Nl &
          "   0x03b6e20c,0x74b1d29a,0xead54739,0x9dd277af,0x04db2615," & Nl &
          "   0x73dc1683,0xe3630b12,0x94643b84,0x0d6d6a3e,0x7a6a5aa8," & Nl &
          "   0xe40ecf0b,0x9309ff9d,0x0a00ae27,0x7d079eb1,0xf00f9344," & Nl &
          "   0x8708a3d2,0x1e01f268,0x6906c2fe,0xf762575d,0x806567cb," & Nl &
          "   0x196c3671,0x6e6b06e7,0xfed41b76,0x89d32be0,0x10da7a5a," & Nl &
          "   0x67dd4acc,0xf9b9df6f,0x8ebeeff9,0x17b7be43,0x60b08ed5," & Nl &
          "   0xd6d6a3e8,0xa1d1937e,0x38d8c2c4,0x4fdff252,0xd1bb67f1," & Nl &
          "   0xa6bc5767,0x3fb506dd,0x48b2364b,0xd80d2bda,0xaf0a1b4c," & Nl &
          "   0x36034af6,0x41047a60,0xdf60efc3,0xa867df55,0x316e8eef," & Nl &
          "   0x4669be79,0xcb61b38c,0xbc66831a,0x256fd2a0,0x5268e236," & Nl &
          "   0xcc0c7795,0xbb0b4703,0x220216b9,0x5505262f,0xc5ba3bbe," & Nl &
          "   0xb2bd0b28,0x2bb45a92,0x5cb36a04,0xc2d7ffa7,0xb5d0cf31," & Nl &
          "   0x2cd99e8b,0x5bdeae1d,0x9b64c2b0,0xec63f226,0x756aa39c," & Nl &
          "   0x026d930a,0x9c0906a9,0xeb0e363f,0x72076785,0x05005713," & Nl &
          "   0x95bf4a82,0xe2b87a14,0x7bb12bae,0x0cb61b38,0x92d28e9b," & Nl &
          "   0xe5d5be0d,0x7cdcefb7,0x0bdbdf21,0x86d3d2d4,0xf1d4e242," & Nl &
          "   0x68ddb3f8,0x1fda836e,0x81be16cd,0xf6b9265b,0x6fb077e1," & Nl &
          "   0x18b74777,0x88085ae6,0xff0f6a70,0x66063bca,0x11010b5c," & Nl &
          "   0x8f659eff,0xf862ae69,0x616bffd3,0x166ccf45,0xa00ae278," & Nl &
          "   0xd70dd2ee,0x4e048354,0x3903b3c2,0xa7672661,0xd06016f7," & Nl &
          "   0x4969474d,0x3e6e77db,0xaed16a4a,0xd9d65adc,0x40df0b66," & Nl &
          "   0x37d83bf0,0xa9bcae53,0xdebb9ec5,0x47b2cf7f,0x30b5ffe9," & Nl &
          "   0xbdbdf21c,0xcabac28a,0x53b39330,0x24b4a3a6,0xbad03605," & Nl &
          "   0xcdd70693,0x54de5729,0x23d967bf,0xb3667a2e,0xc4614ab8," & Nl &
          "   0x5d681b02,0x2a6f2b94,0xb40bbe37,0xc30c8ea1,0x5a05df1b," & Nl &
          "   0x2d02ef8d");
      Plc(Lib, "};");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "unsigned int i  = 0;");
      Plc(Lib, 1, "uint32_t result = 0;");
      Plc(Lib, 1, "for(; i < v.slot_size; i++)");
      Plc(Lib, 1, "{");
      for I in 1..No_Chars loop
         if I > 1 then
            Plc(Lib, 2,
                "result = crc32_tab[(result ^ (v.vector[i] >> " &
                (I-1) * 8 & ")) & 0xff] ^ (result >> " & Bits_Per_Char & ");");
         else
            Plc(Lib, 2,
                "result = crc32_tab[(result ^ (v.vector[i])) & 0xff] ^" &
                " (result >> " & Bits_Per_Char & ");");
         end if;
      end loop;
      Plc(Lib, 1, "}");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
   end;

   --  move into a bit vector
   procedure Gen_Vector_Move_Func
     (Lib: in Library) is
      Div_Expr: constant Unbounded_String :=
        Get_Division_Expr
        (To_Unbounded_String("(_v.shift + _move)"), Bits_Per_Slot);
      Mod_Expr: constant Unbounded_String :=
        Get_Modulo_Expr
        (To_Unbounded_String("(_v.shift + _move)"), Bits_Per_Slot);
   begin
      Plh(Lib, "#define VECTOR_move(_v, _move) \");
      Plh(Lib, "{ \");
      Plh(Lib, 1, "_v.pos  += " & Div_Expr & "; \");
      Plh(Lib, 1, "_v.shift = " & Mod_Expr & "; \");
      Plh(Lib, "}");
   end;

   --  move backward into a bit vector
   procedure Gen_Vector_Move_Back_Func
     (Lib: in Library) is
      Div_Expr: constant Unbounded_String :=
        Get_Division_Expr
        ("(_move + " & (Bits_Per_Slot - 1) & " - _v.shift)", Bits_Per_Slot);
      Mod_Expr: constant Unbounded_String :=
        Get_Modulo_Expr(To_Unbounded_String("_move"), Bits_Per_Slot);
   begin
      Plh(Lib, "#define VECTOR_move_back(_v, _move) \");
      Plh(Lib, "{ \");
      Plh(Lib, 1, "_v.pos -= " & Div_Expr & "; \");
      Plh(Lib, 1, "_v.shift -= " & Mod_Expr & "; \");
      Plh(Lib, 1, "if(_v.shift < 0) \");
      Plh(Lib, 2, "_v.shift += " & Bits_Per_Slot & "; \");
      Plh(Lib, "}");
   end;

   --  check if the current position is the start position
   procedure Gen_Vector_At_Start_Func
     (Lib: in Library) is
   begin
      Plh(Lib, "#define VECTOR_at_start(_v) ((_v.pos==0) && (_v.shift==0))");
   end;

   procedure Gen_Vector_Type
     (Lib: in Library) is
      Shift_Card: constant Natural :=
        1 + Vector_Shift'Last - Vector_Shift'First;
      Size_Card: constant Natural :=
        1 + Item_Width'Last - Item_Width'First;
   begin
      Plh(Lib, "typedef struct {");
      Plh(Lib, 1, Slot_Type & " *vector;");
      Plh(Lib, 1, "unsigned int pos;");
      Plh(Lib, 1, "int shift;");
      Plh(Lib, 1, "unsigned int slot_size;");
      Plh(Lib, 1, "unsigned int bit_size;");
      Plh(Lib, "} vector;");
      Plh(Lib, "typedef void (* vector_set_func) (vector *, unsigned long);");
      Plh(Lib, "typedef unsigned long (* vector_get_func) (vector *);");
      Gen_Slots_For_Bits_Func(Lib);
      Gen_Vector_New_Func(Lib);
      Gen_Vector_Free_Func(Lib);
      Gen_Vector_Start_Func(Lib);
      Gen_Vector_At_Start_Func(Lib);
      Gen_Vector_Key_Func(Lib);
      Gen_Vector_Move_Func(Lib);
      Gen_Vector_Move_Back_Func(Lib);
      for Size in Item_Width loop
         for Shift in Vector_Shift loop
            Gen_Vector_Set_Func(Size, Shift, Lib);
            Gen_Vector_Get_Func(Size, Shift, Lib);
            Gen_Vector_Get_Back_Func(Size, Shift, Lib);
         end loop;
         Gen_Vector_Set_Func(Size, Lib);
         Gen_Vector_Get_Func(Size, Lib);
         Gen_Vector_Get_Back_Func(Size, Lib);
      end loop;
      Gen_Vector_Set_Func(Lib);
      Gen_Vector_Get_Func(Lib);
      Gen_Vector_Get_Back_Func(Lib);
      for Size in Item_Width loop
         Plh(Lib,
             "vector_set_func " & Vector_Set_Func(Size) &
             "_table[" & Shift_Card & "];");
         Plh(Lib,
             "vector_get_func " & Vector_Get_Func(Size) &
             "_table[" & Shift_Card & "];");
         Plh(Lib,
             "vector_get_func " & Vector_Get_Back_Func(Size) &
             "_table[" & Shift_Card & "];");
      end loop;
      Plh(Lib,
          "vector_set_func VECTOR_set_table" &
          "[" & Size_Card & "][" & Shift_Card & "];");
      Plh(Lib,
          "vector_get_func VECTOR_get_table" &
          "[" & Size_Card & "][" & Shift_Card & "];");
      Plh(Lib,
          "vector_get_func VECTOR_get_back_table" &
          "[" & Size_Card & "][" & Shift_Card & "];");
   end;



   procedure Gen
     (Lib : in String;
      Path: in String) is
      L: Library;
      procedure Gen_Lib_Init_Func is
	 Prototype : constant String := "void init_" & Lib & " ()";
	 Shift_Card: constant Natural :=
	   1 + Vector_Shift'Last - Vector_Shift'First;
      begin
	 Plh(L, Prototype & ";");
	 Plc(L, Prototype & " {");

	 --===
	 --  initialize the arrays which contain the function pointers
	 --===
	 for Size in Item_Width loop
	    for Shift in Vector_Shift loop
	       Plc(L, 1,
		   Vector_Set_Func(Size) & "_table[" & Shift & "] = " &
		     "&" & Vector_Set_Func(Size, Shift) & ";");
	       Plc(L, 1,
		   "VECTOR_set_table[" & Size & "][" & Shift &
		     "] = &" & Vector_Set_Func(Size, Shift) & ";");
	       Plc(L, 1,
		   Vector_Get_Func(Size) & "_table[" & Shift & "] = " &
		     "&" & Vector_Get_Func(Size, Shift) & ";");
	       Plc(L, 1,
		   "VECTOR_get_table[" & Size & "][" & Shift &
		     "] = &" & Vector_Get_Func(Size, Shift) & ";");
	       Plc(L, 1,
		   Vector_Get_Back_Func(Size) & "_table[" & Shift & "] = " &
		     "&" & Vector_Get_Back_Func(Size, Shift) & ";");
	       Plc(L, 1,
		   "VECTOR_get_back_table[" & Size & "][" & Shift &
		     "] = &" & Vector_Get_Back_Func(Size, Shift) & ";");
	    end loop;
	 end loop;
	 Plc(L, "}");
      end;
      procedure Gen_Lib_Free_Func is
	 Prototype: constant String := "void free_" & Lib & " ()";
      begin
	 Plh(L, Prototype & ";");
	 Plc(L, Prototype & " {}");
      end;
      Comment: constant String :=
        "This library contains bit vector type description as well as " &
        "functions to manipulate these.";
   begin
      Init_Library(Lib, Comment, Path, L);
      Plh(L, "#include ""stdint.h""");
      Gen_Vector_Type(L);
      Gen_Lib_Init_Func;
      Gen_Lib_Free_Func;
      End_Library(L);
   end;

end Pn.Compiler.Vectors;
