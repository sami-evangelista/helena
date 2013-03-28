package body Prop is

   --==========================================================================
   --  Property
   --==========================================================================

   procedure Deallocate is
      new Ada.Unchecked_Deallocation(Property_Record'Class, Property);

   procedure Initialize
     (P   : access Property_Record'Class;
      Name: in     Ustring) is
   begin
      P.Name := Name;
   end;

   function Get_Type
     (P: in Property) return Property_Type is
   begin
      return Get_Type(P.all);
   end;

   function Get_Name
     (P: in Property) return Ustring is
   begin
      return P.Name;
   end;

   procedure Set_Name
     (P   : in Property;
      Name: in Ustring) is
   begin
      P.Name := Name;
   end;

   function To_Helena
     (P: in Property) return Ustring is
   begin
      return To_Helena(P.all);
   end;

   procedure Compile_Definition
     (P  : in Property;
      Lib: in Library;
      Dir: in String) is
   begin
      Compile_Definition(P.all, Lib, Dir);
   end;

   function Get_Propositions
     (P: in Property) return Ustring_List is
   begin
      return Get_Propositions(P.all);
   end;



   --==========================================================================
   --  Property list
   --==========================================================================

   package PAP renames Property_Array_Pkg;

   function New_Property_List return Property_List is
      Result: constant Property_List := new Property_List_Record;
   begin
      Result.Properties := Pap.Empty_Array;
      return Result;
   end;

   function New_Property_List
     (P: in Property_Array) return Property_List is
      Result: constant Property_List := new Property_List_Record;
   begin
      Result.Properties := PAP.New_Array(PAP.Element_Array(P));
      return Result;
   end;

   function Length
     (P: in Property_List) return Natural is
   begin
      return PAP.Length(P.Properties);
   end;

   function Ith
     (P: in Property_List;
      I: in Natural) return Property is
   begin
      return PAP.Ith(P.Properties, I);
   end;

   procedure Append
     (P: in Property_List;
      Q: in Property) is
   begin
      PAP.Append(P.Properties, Q);
   end;

   function Contains
     (P   : in Property_List;
      Name: in Ustring) return Boolean is
      function Is_P
        (P: in Property) return Boolean is
      begin
         return Get_Name(P) = Name;
      end;
      function Contains is new PAP.Generic_Exists(Is_P);
   begin
      return Contains(P.Properties);
   end;

   function Get
     (P   : in Property_List;
      Name: in Ustring) return Property is
      function Is_P
        (P: in Property) return Boolean is
      begin
         return Get_Name(P) = Name;
      end;
      function Get is new PAP.Generic_Get_First_Satisfying_Element(Is_P);
      Result: Property;
   begin
      Result := Get(P.Properties);
      pragma Assert(Result /= null);
      return Result;
   end;

   function To_Helena
     (P: in Property_List) return Ustring is
      function To_Helena
        (P: in Property) return String is
      begin
         return To_String(To_Helena(P));
      end;
      function To_Helena is
         new PAP.Generic_To_String(To_String => To_Helena,
                                   Separator => (1 => Nl),
                                   Empty     => "");
   begin
      return To_Ustring(To_Helena(P.Properties));
   end;

end Prop;
