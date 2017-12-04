with
  Ada.Strings,
  Ada.Strings.Fixed;

use
  Ada.Strings,
  Ada.Strings.Fixed;

package body Utils.Generics is

   function Generic_Ite
     (B     : in Boolean;
      Etrue : in Element;
      Efalse: in Element) return Element is
      Result: Element;
   begin
      if B then
         Result := Etrue;
      else
         Result := Efalse;
      end if;
      return Result;
   end;

   package body Generic_String_Conversion is

      function To_Unbounded_String
        (E: in T) return Unbounded_String is
      begin
         return To_Unbounded_String(Trim(T'Image(E), Both));
      end;

      function To_String
        (E: in T) return String is
      begin
         return Trim(T'Image(E), Both);
      end;

      function "&"
        (E: in T;
         S: in String) return Unbounded_String is
      begin
         return To_String(E) & To_Unbounded_String(S);
      end;

      function "&"
        (S: in String;
         E: in T) return Unbounded_String is
      begin
         return To_Unbounded_String(S) & To_String(E);
      end;

      function "&"
        (E: in T;
         S: in Unbounded_String) return Unbounded_String is
      begin
         return To_String(E) & S;
      end;

      function "&"
        (S: in Unbounded_String;
         E: in T) return Unbounded_String is
      begin
         return S & To_String(E);
      end;

   end Generic_String_Conversion;

end Utils.Generics;
