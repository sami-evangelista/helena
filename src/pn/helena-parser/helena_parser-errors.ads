--=============================================================================
--
--  Package: Helena_Parser.Errors
--
--  This file manages parsing errors.
--
--=============================================================================


private package Helena_Parser.Errors is

   procedure Add_Error
     (E  : in Element;
      Msg: in String);

   procedure Add_Error
     (E  : in Element;
      Msg: in Ustring);

   procedure Add_Error
     (Line: in Line_Number;
      File: in String;
      Msg : in String);

   procedure Add_Error
     (Msg: in String);

   procedure Set_Error_Msg
     (Str: in String);
   --  set the error message

   function Get_Error_Msg return Ustring;
   --  return the error message


private


   Error_Msg: Ustring;

end Helena_Parser.Errors;
