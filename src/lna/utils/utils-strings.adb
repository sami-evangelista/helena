with
  Ada.Characters.Handling,
  Ada.Strings,
  Ada.Strings.Fixed;

use
  Ada.Characters.Handling,
  Ada.Strings,
  Ada.Strings.Fixed;

package body Utils.Strings is

   function To_Ustring
     (Str: in String) return Ustring is
   begin
      return To_Unbounded_String(Str);
   end;

   function To_String_Mapping
     (From: in String;
      To  : in String) return String_Mapping is
   begin
      return (From => To_Unbounded_String(From),
              To   => To_Unbounded_String(To));
   end;

   function Replace
     (Str: in String;
      Map: in String_Mapping) return String is

      To     : constant String  := To_String(Map.To);
      From   : constant String  := To_String(Map.From);
      From_Lg: constant Natural := 1 + From'Last - From'First;

      function Replace_Rec
        (I: in Natural) return String is
      begin
         if I > Str'Last then
            return "";
         else
            if
              I + From_Lg - 1 <= Str'Last and then
              Str(I .. I + From_Lg - 1) = From
            then
               return To & Replace_Rec(I + From_Lg);
            else
               return Str(I) & Replace_Rec(I + 1);
            end if;
         end if;
      end;

   begin
      return Replace_Rec(Str'First);
   end;

   function Replace
     (Str  : in String;
      Map  : in String_Mapping;
      First: in Natural;
      Last : in Natural) return String is
   begin
      if First > Last then
         return Str;
      else
         return
           Str(Str'First .. First - 1) &
           Replace(Str(First .. Last), Map) &
           Str(Last + 1 .. Str'Last);
      end if;
   end;

   function Replace
     (Str    : in String;
      Map_Set: in String_Mapping_Set) return String is
      Result: Unbounded_String := To_Unbounded_String(Str);
   begin
      for I in Map_Set'Range loop
         Result := To_Unbounded_String(Replace(To_String(Result), Map_Set(I)));
      end loop;
      return To_String(Result);
   end;

   function To_Upper
     (Str: in Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String(To_Upper(To_String(str)));
   end;

   function To_Lower
     (Str: in Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String(To_Lower(To_String(str)));
   end;

   function Trim
     (S: in String) return String is
   begin
      return Ada.Strings.Fixed.Trim(S, Both);
   end;

   function Trim
     (S: in Unbounded_String) return Unbounded_String is
   begin
      return Ada.Strings.Unbounded.Trim(S, Both);
   end;

   function Split
     (S  : in String;
      Sep: in Char_Set := Blanks) return Unbounded_String_Array is
      Empty_Array : constant Unbounded_String_Array :=
        (1..0 => To_Unbounded_String(""));
      function Rec_Split
        (Current: in String;
         Index  : in Positive) return Unbounded_String_Array is
      begin
         if Index > S'Last then
            if Current /= "" then
               return (1 => To_Unbounded_String(Current));
            else
               return Empty_Array;
            end if;
         elsif Sep(S(Index)) then
            if Current /= "" then
               return (1 => To_Unbounded_String(Current)) &
                 Rec_Split("", Index + 1);
            else
               return Rec_Split("", Index + 1);
            end if;
         else
            return Rec_Split(Current & S(Index), Index + 1);
         end if;
      end;
   begin
      return Rec_Split("", 1);
   end;

end Utils.Strings;
