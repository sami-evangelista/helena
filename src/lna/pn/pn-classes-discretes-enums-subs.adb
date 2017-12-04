package body Pn.Classes.Discretes.Enums.Subs is

   function New_Enum_Sub_Cls
     (Name      : in Ustring;
      Parent    : in Cls;
      Constraint: in Range_Spec) return Cls is
      Result: Enum_Sub_Cls;
   begin
      --===
      --  - the parent must be an enumeration color
      --  - the range must be statically evaluable and positive
      --===
      pragma Assert((Get_Type(Parent) = A_Enum_Cls) and then
                    (Constraint = null or else
                     (Is_Static(Constraint) and then
                      Is_Positive(Constraint))));

      Result := new Enum_Sub_Cls_Record;
      Initialize(Result, Name);
      Result.Parent := Parent;
      Result.Constraint := Constraint;
      return Cls(Result);
   end;

   procedure Free
     (C: in out Enum_Sub_Cls_Record) is
   begin
      Free(C.Constraint);
   end;

   function Colors_Used
     (C: in Enum_Sub_Cls_Record) return Cls_Set is
   begin
      return New_Cls_Set((1 => C.Parent));
   end;

   function Get_Root_Cls
     (C: in Enum_Sub_Cls_Record) return Cls is
   begin
      return Get_Root_Cls(C.Parent);
   end;

   function Is_Sub_Cls
     (C     : in     Enum_Sub_Cls_Record;
      Parent: access Cls_Record'Class) return Boolean is
   begin
      return C.Parent = Parent or else Is_Sub_Cls(C.Parent, Parent);
   end;

   function Get_Root_Values
     (E: in Enum_Sub_Cls_Record) return Ustring_List is
   begin
      return Get_Root_Values(Enum_Cls(E.Parent));
   end;

   function Get_Low
     (E: in Enum_Sub_Cls_Record) return Num_Type is
   begin
      if E.Constraint = null then
         return Get_Low(Discrete_Cls(E.Parent));
      else
         return Get_Low_Value_Index(E.Constraint) - 1;
      end if;
   end;

   function Get_High
     (E: in Enum_Sub_Cls_Record) return Num_Type is
   begin
      if E.Constraint = null then
         return Get_High(Discrete_Cls(E.Parent));
      else
         return Get_High_Value_Index(E.Constraint) - 1;
      end if;
   end;

end Pn.Classes.Discretes.Enums.Subs;
