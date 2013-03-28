package body Utils.Math is

   function Log2
     (I: in Big_Nat) return Natural is
      J     : Big_Int := I;
      Result: Natural := 0;
   begin
      while J > 1 loop
         Result := Result + 1;
         if J mod 2 = 0 then
            J := J / 2;
         else
            J := (J + 1) / 2;
         end if;
      end loop;
      return Result;
   end;

   function Bit_Width
     (I: in Big_Nat) return Natural is
   begin
      return Log2(I);
   end;

end;
