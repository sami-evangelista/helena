with
  Pn.Exprs.Num_Consts;

use
  Pn.Exprs.Num_Consts;

package body Pn.Classes.Discretes.Nums.Subs is

   function New_Num_Sub_Cls
     (Name      : in Ustring;
      Parent    : in Cls;
      Constraint: in Range_Spec) return Cls is
      Result: Num_Sub_Cls;
   begin
      --===
      --  - the parent must be a numerical class
      --  - the range must be statically evaluable and positive
      --===
      pragma Assert((Get_Type(Parent) = A_Num_Cls) and then
                    (Constraint = null or else
                     (Is_Static(Constraint) and then
                      Is_Positive(Constraint))));

      Result := new Num_Sub_Cls_Record;
      Initialize(Result, Name);
      Result.Parent := Parent;
      Result.Constraint := Constraint;
      return Cls(Result);
   end;

   procedure Free
     (C: in out Num_Sub_Cls_Record) is
   begin
      Free(C.Constraint);
   end;

   function Colors_Used
     (C: in Num_Sub_Cls_Record) return Cls_Set is
   begin
      return New_Cls_Set((1 => C.Parent));
   end;

   function Get_Root_Cls
     (C: in Num_Sub_Cls_Record) return Cls is
   begin
      return Get_Root_Cls(C.Parent);
   end;

   function Is_Sub_Cls
     (C     : in     Num_Sub_Cls_Record;
      Parent: access Cls_Record'Class) return Boolean is
   begin
      return C.Parent = Parent or else Is_Sub_Cls(C.Parent, Parent);
   end;

   function Get_Low
     (C: in Num_Sub_Cls_Record) return Num_Type is
      Result: Num_Type;
   begin
      if C.Constraint = null then
         Result := Get_Low(Num_Cls(C.Parent));
      else
         Result := Get_Low_Value_Index(C.Constraint);
      end if;
      return Result;
   end;

   function Get_High
     (C: in Num_Sub_Cls_Record) return Num_Type is
      Result: Num_Type;
   begin
      if C.Constraint = null then
         Result := Get_High(Num_Cls(C.Parent));
      else
         Result := Get_High_Value_Index(C.Constraint);
      end if;
      return Result;
   end;

   function Is_Circular
     (C: in Num_Sub_Cls_Record) return Boolean is
   begin
      return Is_Circular(Num_Cls(C.Parent));
   end;

   function Normalize_Value
     (C: in Num_Sub_Cls_Record;
      I: in Num_Type) return Num_Type is
   begin
      return Normalize_Value(Num_Cls(C.Parent), I);
   end;

end Pn.Classes.Discretes.Nums.Subs;
