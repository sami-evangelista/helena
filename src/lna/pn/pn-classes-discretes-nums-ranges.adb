with
  Pn.Classes.Discretes.Nums.Subs,
  Pn.Exprs.Num_Consts;

use
  Pn.Classes.Discretes.Nums.Subs,
  Pn.Exprs.Num_Consts;

package body Pn.Classes.Discretes.Nums.Ranges is

   function New_Range_Cls
     (Name: in Ustring;
      R   : in Range_Spec) return Cls is
      Result: Range_Cls;
   begin
      --===
      --  the range must be statically evaluable and positive
      --===
      pragma Assert(Is_Static(R) and then Is_Positive(R));

      Result := new Range_Cls_Record;
      Initialize(Result, Name);
      Result.R := R;
      return Cls(Result);
   end;

   procedure Free
     (C: in out Range_Cls_Record) is
   begin
      Free(C.R);
   end;

   function Colors_Used
     (C: in Range_Cls_Record) return Cls_Set is
   begin
      return New_Cls_Set;
   end;

   function Get_Low
     (C: in Range_Cls_Record) return Num_Type is
   begin
      return Get_Low_Value_Index(C.R);
   end;

   function Get_High
     (C: in Range_Cls_Record) return Num_Type is
   begin
      return Get_High_Value_Index(C.R);
   end;

   function Is_Circular
     (C: in Range_Cls_Record) return Boolean is
   begin
      return False;
   end;

   function Normalize_Value
     (C: in Range_Cls_Record;
      I: in Num_Type) return Num_Type is
   begin
      return I;
   end;


begin

   declare
      R: Range_Spec;
   begin

      --===
      --  create the predefined numerical color classes: int, nat, short and
      --  ushort
      --===
      R := New_Low_High_Range(New_Num_Const(Num_Type'First, null),
                              New_Num_Const(Num_Type'Last, null));
      Add_Predefined_Cls(New_Range_Cls(Int_Cls_Name, R));

      R := New_Low_High_Range(New_Num_Const(0, Int_Cls),
                              New_Num_Const(Num_Type'Last, null));
      Add_Predefined_Cls(New_Num_Sub_Cls(Nat_Cls_Name, Int_Cls, R));

      R := New_Low_High_Range(New_Num_Const(- 2**15, Int_Cls),
                              New_Num_Const(2**15 - 1, Int_Cls));
      Add_Predefined_Cls(New_Num_Sub_Cls(Short_Cls_Name, Int_Cls, R));

      R := New_Low_High_Range(New_Num_Const(0, Int_Cls),
                              New_Num_Const(2**16 - 1, Int_Cls));
      Add_Predefined_Cls(New_Num_Sub_Cls(Unsigned_Short_Cls_Name, Int_Cls, R));

   end;

end Pn.Classes.Discretes.Nums.Ranges;
