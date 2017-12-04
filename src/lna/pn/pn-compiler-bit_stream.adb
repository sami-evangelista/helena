with
  Utils.Math;

use
  Utils.Math;

package body Pn.Compiler.Bit_Stream is

   subtype Bit_Stream_Shift is Natural range 0 .. Bits_Per_Slot - 1;
   --  possible shift in a slot of a stream


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
   --  stream of bits
   --==========================================================================

   --  set bits of a stream. size and shift are known
   function Bit_Stream_Set_Func
     (Size : in Item_Width;
      Shift: in Bit_Stream_Shift) return Unbounded_String is
   begin
      return "bit_stream_set_size" & Size & "_shift" & Shift;
   end;

   procedure Gen_Bit_Stream_Set_Func
     (Size : in Item_Width;
      Shift: in Bit_Stream_Shift;
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
      Prototype := "void " & Bit_Stream_Set_Func(Size, Shift) & Nl &
        "(bit_stream_t *v," & Nl &
        " uint64_t val)";
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
         Plc(Lib, 1, "v->stream[v->pos] = (v->stream[v->pos] & " &
             Mask & ") | ((val & " &
             Get_Mask(0, Natural'Min(Size - 1, Bits_Per_Slot - Shift - 1)) &
             ") << " & Shift & ");");
      else
         I := 0;
         J := 0;
      end if;
      while I < Size loop
         Pc(Lib, 1, "v->stream[v->pos" & Pj & "] =  (val");
         if I > 0 then
            Pc(Lib, " >> " & I);
         end if;
         Pc(Lib, ")");
         I := I + Bits_Per_Slot;
         if I > Size then
            Pc(Lib, " | (v->stream[v->pos" & Pj & "] & " &
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

   --  set bits of a bit_stream. size is known
   function Bit_Stream_Set_Func
     (Size: in Item_Width) return Unbounded_String is
   begin
      return "bit_stream_set_size" & Size;
   end;

   procedure Gen_Bit_Stream_Set_Func
     (Size: in Item_Width;
      Lib : in Library) is
      Table: constant Unbounded_String := Bit_Stream_Set_Func(Size) & "_table";
   begin
      --===
      --  the macro simply calls the appropriate function of the table
      --===
      Plh(Lib, "#define " & Bit_Stream_Set_Func(Size) &
          "(_v, _val) { (* " & Table & "[_v.shift])(&_v, _val); }");
   end;

   --  set bits of a bit_stream
   procedure Gen_Bit_Stream_Set_Func
     (Lib: in Library) is
   begin
      --===
      --  the macro simply calls the appropriate function of the table
      --===
      Plh(Lib, "#define bit_stream_set(_v, _val, _size) { " &
          "(* bit_stream_set_table[_size][_v.shift])(&_v, _val); }");
   end;

   --  get bits of a bit_stream. size and shift are known
   function Bit_Stream_Get_Func
     (Size : in Item_Width;
      Shift: in Bit_Stream_Shift) return Unbounded_String is
   begin
      return "bit_stream_get_size" & Size & "_shift" & Shift;
   end;

   procedure Gen_Bit_Stream_Get_Func
     (Size : in Item_Width;
      Shift: in Bit_Stream_Shift;
      Lib  : in Library) is
      New_Shift: Natural;
      I        : Natural;
      J        : Natural;
      Pipe     : Boolean;
      Prototype: Unbounded_String;
   begin
      Prototype :=
        "uint64_t " & Bit_Stream_Get_Func(Size, Shift) & Nl &
        "(bit_stream_t *v)";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype);
      Plc(Lib, "{");
      if Size = 0 then
         Plc(Lib, 1, "return 0;");
         Plc(Lib, "}");
         return;
      end if;
      Pc(Lib, 1, "uint64_t result = ");
      if Shift > 0 then
         Pc(Lib, "((v->stream[v->pos] >> " & Shift & ") & " &
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
         Pc(Lib, "((((uint64_t) v->stream[v->pos");
         if J > 0 then
            Pc(Lib, " + " & J);
         end if;
         Pc(Lib, "])");
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

   --  get bits of a bit_stream. size is known
   function Bit_Stream_Get_Func
     (Size: in Item_Width) return Unbounded_String is
   begin
      return "bit_stream_get_size" & Size;
   end;

   procedure Gen_Bit_Stream_Get_Func
     (Size: in Item_Width;
      Lib : in Library) is
      Table: constant Unbounded_String := Bit_Stream_Get_Func(Size) & "_table";
   begin
      --===
      --  the macro simply calls the appropriate function of the table
      --===
      Plh(Lib, "#define " & Bit_Stream_Get_Func(Size) &
          "(_v, _val) { _val = (* " & Table & "[_v.shift])(&_v); }");
   end;

   --  get bits from bit_stream
   procedure Gen_Bit_Stream_Get_Func
     (Lib: in Library) is
   begin
      --===
      --  the macro simply calls the appropriate function of the table
      --===
      Plh(Lib, "#define bit_stream_get(_v, _val, _size) { _val = " &
          "(* bit_stream_get_table[_size][_v.shift])(&_v); }");
   end;

   --  free a bit_stream
   procedure Gen_Bit_Stream_Free_Func
     (Lib: in Library) is
   begin
      Plh(Lib, "#define bit_stream_free(_v) { free(_v.stream); }");
   end;

   --  move into a bit bit_stream
   procedure Gen_Bit_Stream_Move_Func
     (Lib: in Library) is
      Div_Expr: constant Unbounded_String :=
        Get_Division_Expr
        (To_Unbounded_String("(_v.shift + _move)"), Bits_Per_Slot);
      Mod_Expr: constant Unbounded_String :=
        Get_Modulo_Expr
        (To_Unbounded_String("(_v.shift + _move)"), Bits_Per_Slot);
   begin
      Plh(Lib, "#define bit_stream_move(_v, _move) \");
      Plh(Lib, "{ \");
      Plh(Lib, 1, "_v.pos  += " & Div_Expr & "; \");
      Plh(Lib, 1, "_v.shift = " & Mod_Expr & "; \");
      Plh(Lib, "}");
   end;

   --  init a stream
   procedure Gen_Bit_Stream_Init_Func
     (Lib: in Library) is
   begin
      Plh(Lib, "#define bit_stream_init(_v, _bits) \");
      Plh(Lib, "   { _v.stream = _bits; _v.pos = _v.shift = 0; }");
   end;

   --  start a stream
   procedure Gen_Bit_Stream_Start_Func
     (Lib: in Library) is
   begin
      Plh(Lib, "#define bit_stream_start(_v) { _v.pos = _v.shift = 0; }");
   end;

   --  check if the current position is the start position
   procedure Gen_Bit_Stream_At_Start_Func
     (Lib: in Library) is
   begin
      Plh(Lib, "#define bit_stream_at_start(_v) \");
      Plh(Lib, "((_v.pos==0) && (_v.shift==0))");
   end;

   procedure Gen_Bit_Stream_Type
     (Lib: in Library) is
      Shift_Card: constant Natural :=
        1 + Bit_Stream_Shift'Last - Bit_Stream_Shift'First;
      Size_Card: constant Natural :=
        1 + Item_Width'Last - Item_Width'First;
   begin
      Plh(Lib, "typedef struct {");
      Plh(Lib, 1, Slot_Type & " * stream;");
      Plh(Lib, 1, "unsigned int pos;");
      Plh(Lib, 1, "int shift;");
      Plh(Lib, 1, "unsigned int slot_size;");
      Plh(Lib, 1, "unsigned int bit_size;");
      Plh(Lib, "} bit_stream_t;");
      Ph(Lib, "typedef void (* bit_stream_set_func) ");
      Plh(Lib, "(bit_stream_t *, uint64_t);");
      Ph(Lib, "typedef uint64_t (* bit_stream_get_func) ");
      Plh(Lib, "(bit_stream_t *);");
      Gen_Slots_For_Bits_Func(Lib);
      Gen_Bit_Stream_Free_Func(Lib);
      Gen_Bit_Stream_Init_Func(Lib);
      Gen_Bit_Stream_Start_Func(Lib);
      Gen_Bit_Stream_At_Start_Func(Lib);
      Gen_Bit_Stream_Move_Func(Lib);
      for Size in Item_Width loop
         for Shift in Bit_Stream_Shift loop
            Gen_Bit_Stream_Set_Func(Size, Shift, Lib);
            Gen_Bit_Stream_Get_Func(Size, Shift, Lib);
         end loop;
         Gen_Bit_Stream_Set_Func(Size, Lib);
         Gen_Bit_Stream_Get_Func(Size, Lib);
      end loop;
      Gen_Bit_Stream_Set_Func(Lib);
      Gen_Bit_Stream_Get_Func(Lib);
      for Size in Item_Width loop
         Plh(Lib,
             "bit_stream_set_func " & Bit_Stream_Set_Func(Size) &
             "_table[" & Shift_Card & "];");
         Plh(Lib,
             "bit_stream_get_func " & Bit_Stream_Get_Func(Size) &
             "_table[" & Shift_Card & "];");
      end loop;
      Plh(Lib,
          "bit_stream_set_func bit_stream_set_table" &
          "[" & Size_Card & "][" & Shift_Card & "];");
      Plh(Lib,
          "bit_stream_get_func bit_stream_get_table" &
          "[" & Size_Card & "][" & Shift_Card & "];");
   end;



   procedure Gen
     (Lib : in String;
      Path: in String) is
      L: Library;
      procedure Gen_Lib_Init_Func is
	 Prototype : constant String := "void init_" & Lib & " ()";
	 Shift_Card: constant Natural :=
	   1 + Bit_Stream_Shift'Last - Bit_Stream_Shift'First;
      begin
	 Plh(L, Prototype & ";");
	 Plc(L, Prototype & " {");

	 --===
	 --  initialize the arrays which contain the function pointers
	 --===
	 for Size in Item_Width loop
	    for Shift in Bit_Stream_Shift loop
	       Plc(L, 1,
		   Bit_Stream_Set_Func(Size) & "_table[" & Shift & "] = " &
		     "&" & Bit_Stream_Set_Func(Size, Shift) & ";");
	       Plc(L, 1,
		   "bit_stream_set_table[" & Size & "][" & Shift &
		     "] = &" & Bit_Stream_Set_Func(Size, Shift) & ";");
	       Plc(L, 1,
		   Bit_Stream_Get_Func(Size) & "_table[" & Shift & "] = " &
		     "&" & Bit_Stream_Get_Func(Size, Shift) & ";");
	       Plc(L, 1,
		   "bit_stream_get_table[" & Size & "][" & Shift &
		     "] = &" & Bit_Stream_Get_Func(Size, Shift) & ";");
	    end loop;
	 end loop;
	 Plc(L, "}");
      end;
      Comment: constant String :=
        "This library contains bit stream type description as well as " &
        "functions to manipulate these.";
   begin
      Init_Library(Lib, Comment, Path, L);
      Plh(L, "#include ""stdint.h""");
      Gen_Bit_Stream_Type(L);
      Gen_Lib_Init_Func;
      End_Library(L);
   end;

end Pn.Compiler.Bit_Stream;
