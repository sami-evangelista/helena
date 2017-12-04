package body Pn.Propositions is

   --==========================================================================
   --  State proposition
   --==========================================================================

   function New_State_Proposition
     (Name: in Ustring;
      Prop: in Expr) return State_Proposition is
      Result: constant State_Proposition := new State_Proposition_Record;
   begin
      Result.Name := Name;
      Result.Prop := Prop;
      Result.Observed := False;
      return Result;
   end;

   procedure Free
     (P: in out State_Proposition) is
      procedure Deallocate is
	 new Ada.Unchecked_Deallocation(State_Proposition_Record,
					State_Proposition);
   begin
      Free(P.Prop);
      Deallocate(P);
      P := null;
   end;

   function Get_Name
     (P: in State_Proposition) return Ustring is
   begin
      return P.Name;
   end;

   procedure Set_Name
     (P   : in State_Proposition;
      Name: in Ustring) is
   begin
      P.Name := Name;
   end;

   function Is_Observed
     (P: in State_Proposition) return Boolean is
   begin
      return P.Observed;
   end;

   procedure Set_Observed
     (P       : in State_Proposition;
      Observed: in Boolean) is
   begin
      P.Observed := Observed;
   end;

   function Get_Places_In
     (P: in State_Proposition) return String_Set is
   begin
      return Get_Observed_Places(P.Prop);
   end;

   procedure Compile
     (P  : in State_Proposition;
      Lib: in Library) is
      Prototype: constant Ustring :=
	"bool_t state_proposition_" & Get_Name(P) & " (" & Nl &
	"   mstate_t prop_state)";
      Places   : constant String_Set := Get_Places_In(P);
   begin
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, "   return " & Compile_Evaluation(P.Prop) & ";");
      Plc(Lib, "}");
   end;



   --==========================================================================
   --  State proposition list
   --==========================================================================

   package SPAP renames State_Proposition_Array_Pkg;

   function New_State_Proposition_List return State_Proposition_List is
      Result: constant State_Proposition_List :=
	new State_Proposition_List_Record;
   begin
      Result.Propositions := SPAP.Empty_Array;
      return Result;
   end;

   procedure Free
     (P: in out State_Proposition_List) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(State_Proposition_List_Record,
                                        State_Proposition_List);
   begin
      Deallocate(P);
      P := null;
   end;

   procedure Free_All
     (P: in out State_Proposition_List) is
      procedure Free is new SPAP.Generic_Apply(Free);
   begin
      Free(P.Propositions);
      Free(P);
   end;

   function Length
     (P: in State_Proposition_List) return Natural is
   begin
      return SPAP.Length(P.Propositions);
   end;

   function Ith
     (P: in State_Proposition_List;
      I: in Index_Type) return State_Proposition is
   begin
      return SPAP.Ith(P.Propositions, I);
   end;

   procedure Append
     (P: in State_Proposition_List;
      Q: in State_Proposition) is
   begin
      SPAP.Append(P.Propositions, Q);
   end;

   function Contains
     (P   : in State_Proposition_List;
      Name: in Ustring) return Boolean is
      function Is_P
        (P: in State_Proposition) return Boolean is
      begin
         return Get_Name(P) = Name;
      end;
      function Contains is new SPAP.Generic_Exists(Is_P);
   begin
      return Contains(P.Propositions);
   end;

   function Get
     (P   : in State_Proposition_List;
      Name: in Ustring) return State_Proposition is
      function Is_P
        (P: in State_Proposition) return Boolean is
      begin
         return Get_Name(P) = Name;
      end;
      function Get is new SPAP.Generic_Get_First_Satisfying_Element(Is_P);
      Result: State_Proposition;
   begin
      Result := Get(P.Propositions);
      pragma Assert(Result /= null);
      return Result;
   end;

   procedure Compile
     (P  : in State_Proposition_List;
      Lib: in Library) is
      Prop     : State_Proposition;
      Prototype: Ustring;
      Checks   : Ustring := Null_String;
      Dispatch : Ustring := Null_String;
   begin
      for I in 1..Length(P) loop
	 Prop := Ith(P, I);
	 Checks := Checks &
	   "   if (!strcmp (prop_name, """ &
	   Get_Name(Prop) & """)) { return TRUE; }" & Nl;
	 Dispatch := Dispatch &
	   "   if (!strcmp (prop_name, """ & Get_Name(Prop) & """)) {" & Nl &
	   "      return state_proposition_" & Get_Name(Prop) & " (s); " & Nl &
	   "   }" & Nl;
	 Compile(Prop, Lib);
      end loop;
      --=======================================================================
      Prototype := To_Ustring("bool_t model_check_state_proposition (" & Nl &
				"   char *   prop_name," & Nl &
				"   mstate_t s)");
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, Dispatch & "   return FALSE;");
      Plc(Lib, "}");
      --=======================================================================
      Prototype := To_Ustring("bool_t model_is_state_proposition (" & Nl &
				"   char * prop_name)");
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, Checks & "   return FALSE;");
      Plc(Lib, "}");
      --=======================================================================
   end;

end Pn.Propositions;
