with
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts;

use
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts;

package body Pn.Classes.Discretes.Enums.Roots is

   function New_Enum_Cls
     (Name  : in Ustring;
      Values: in String_Array) return Cls is
      Result   : Enum_Root_Cls;
      List     : Ustring_List := String_List_Pkg.Empty_Array;
      Not_Empty: Boolean := False;
   begin
      --===
      --  the same constant does not appear twice in the type
      --===
      for I in Values'Range loop
         for J in Values'Range loop
            if I /= J and Values(I) = Values(J) then
               pragma Assert(False);
               null;
            end if;
         end loop;
         String_List_Pkg.Append(List, Values(I));
         Not_Empty := True;
      end loop;

      --===
      --  at least one value in the type
      --===
      pragma Assert(Not_Empty);

      Result := new Enum_Root_Cls_Record;
      Initialize(Cls(Result), Name);
      Result.Values := List;
      return Cls(Result);
   end;

   procedure Free
     (C: in out Enum_Root_Cls_Record) is
   begin
      null;
   end;

   function Colors_Used
     (C: in Enum_Root_Cls_Record) return Cls_Set is
   begin
      return New_Cls_Set;
   end;

   function To_Pnml
     (C: in Enum_Root_Cls_Record) return Ustring is
      Result: Ustring := Null_String;
      Len   : constant Natural := String_List_Pkg.Length(C.Values);
      Val   : Ustring;
   begin
      for I in 1..Len loop
	 Val := String_List_Pkg.Ith(C.Values, I);
	 Result := Result &
	   "<feconstant " &
	   "id=""C-" & C.Name & "-" & Val & """ " &
	   "name=""" & Val & """>" & "</feconstant>";
      end loop;
      return "<finiteenumeration>" & Result & "</finiteenumeration>";
   end;

   function Get_Root_Values
     (E: in Enum_Root_Cls_Record) return Ustring_List is
   begin
      return E.Values;
   end;

   function Get_Low
     (E: in Enum_Root_Cls_Record) return Num_Type is
   begin
      return 0;
   end;

   function Get_High
     (E: in Enum_Root_Cls_Record) return Num_Type is
   begin
      return Num_Type(String_List_Pkg.Length(E.Values)) - 1;
   end;


begin


   --===
   --  create the predefined boolean color classe
   --===
   Add_Predefined_Cls(New_Enum_Cls(Bool_Cls_Name, (1 => False_Const_Name,
                                                   2 => True_Const_Name)));

end Pn.Classes.Discretes.Enums.Roots;
