package body Prop.State is

   --==========================================================================
   --  State property
   --==========================================================================

   function New_State_Property
     (Name   : in Ustring;
      Reject : in State_Property_Comp;
      Accepts: in State_Property_Comp_List) return Property is
      Result: constant State_Property := new State_Property_Record;
   begin
      Initialize(Result, Name);
      Result.Reject := Reject;
      Result.Accepts := Accepts;
      return Property(Result);
   end;

   function Get_Type
     (P: in State_Property_Record) return Property_Type is
   begin
      if P.Reject.all.Deadlock then
         return A_Deadlock_Property;
      else
         return A_State_Property;
      end if;
   end;

   procedure Compile_Definition
     (P  : in State_Property_Record;
      Lib: in Library;
      Dir: in String) is
      Prototype: constant String :=
	"bool_t state_check_property" & Nl &
	"(mstate_t prop_state," & Nl &
	" list_t prop_en)";
      Test     : Ustring := Compile_Evaluation(P.Reject);
   begin
      for I in 1..Length(P.Accepts) loop
	 Test := Test &
	   " && (! " & Compile_Evaluation(Ith(P.Accepts, I)) & ")";
      end loop;
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "return (" & Test & ") ? TRUE : FALSE;");
      Plc(Lib, "}");
   end;

   function Get_Propositions
     (P: in State_Property_Record) return Ustring_List is
      Result: Ustring_List := String_List_Pkg.Empty_Array;
      C     : State_Property_Comp;
   begin
      if not P.Reject.Deadlock then
	 String_List_Pkg.Append(Result, P.Reject.Prop);
      end if;
      for I in 1..Length(P.Accepts) loop
	 C := Ith(P.Accepts, I);
	 if not C.Deadlock then
	    String_List_Pkg.Append(Result, C.Prop);
	 end if;
      end loop;
      return Result;
   end;



   --==========================================================================
   --  Component of a state property
   --==========================================================================

   function New_Deadlock return State_Property_Comp is
      Result: constant State_Property_Comp := new State_Property_Comp_Record;
   begin
      Result.Deadlock := True;
      Result.Prop := Null_String;
      return Result;
   end;

   function New_Predicate
     (Prop: in Ustring) return State_Property_Comp is
      Result: constant State_Property_Comp := new State_Property_Comp_Record;
   begin
      Result.Deadlock := False;
      Result.Prop := Prop;
      return Result;
   end;

   function Compile_Evaluation
     (C: in State_Property_Comp) return Ustring is
   begin
      if C.Deadlock then
	 return To_Ustring("list_is_empty(prop_en)");
      else
	 return "state_proposition_" & C.Prop & " (prop_state)";
      end if;
   end;



   --==========================================================================
   --  Component list
   --==========================================================================

   package SPCAP renames State_Property_Comp_Array_Pkg;

   function New_State_Property_Comp_List return State_Property_Comp_List is
      Result: constant State_Property_Comp_List :=
        new State_Property_Comp_List_Record;
   begin
      Result.Comps := SPCAP.Empty_Array;
      return Result;
   end;

   function Length
     (L: in State_Property_Comp_List) return Natural is
   begin
      return SPCAP.Length(L.Comps);
   end;

   function Ith
     (L: in State_Property_Comp_List;
      I: in Natural) return State_Property_Comp is
   begin
      return SPCAP.Ith(L.Comps, I);
   end;

   procedure Append
     (L: in State_Property_Comp_List;
      C: in State_Property_Comp) is
   begin
      SPCAP.Append(L.Comps, C);
   end;

end Prop.State;
