with
  Helena_Lex;

use
  Helena_Lex;

package body Helena_Parser.Errors is

   procedure Add_Error
     (Line: in Line_Number;
      File: in String;
      Msg : in String) is
   begin
      if Error_Msg /= Null_String then
         Error_Msg := Error_Msg & Nl;
      end if;
      Error_Msg := Error_Msg & File & ":" & Line & ": " & Msg;
   end;

   procedure Add_Error
     (Msg: in String) is
   begin
      Add_Error(Helena_Lex.Get_Line_Number,
		To_String(Helena_Lex.Get_File), Msg);
   end;

   procedure Add_Error
     (E  : in Element;
      Msg: in String) is
   begin Add_Error(E.Line, To_String(E.File), Msg); end;

   procedure Add_Error
     (E  : in Element;
      Msg: in Ustring) is
   begin Add_Error(E.Line, To_String(E.File), To_String(Msg)); end;

   procedure Set_Error_Msg
     (Str: in String) is
   begin Error_Msg := To_Unbounded_String(Str); end;

   function Get_Error_Msg return Ustring is
   begin return Error_Msg; end;

begin

   Error_Msg := Null_String;

end Helena_Parser.Errors;
