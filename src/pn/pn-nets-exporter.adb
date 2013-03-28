with
  Ada.Calendar,
  Gnat.Calendar.Time_Io,
  Gnat.Os_Lib,
  Pn.Classes,
  Pn.Guards,
  Pn.Mappings,
  Pn.Nodes,
  Pn.Vars;

use
  Ada.Calendar,
  Gnat.Calendar.Time_Io,
  Gnat.Os_Lib,
  Pn.Classes,
  Pn.Guards,
  Pn.Mappings,
  Pn.Nodes,
  Pn.Vars;

package body Pn.Nets.Exporter is

   procedure Put_Header_Comment
     (N            : in Net;
      File         : in File_Type;
      Tool_Name    : in String;
      Start_Comment: in String;
      End_Comment  : in String) is
      Now: constant Time := Clock;
   begin
      Put_Line(File, Start_Comment &
               "  This file has been created by Helena from net " & N.Name &
               " to " & Tool_Name & "  " & End_Comment);
      Put_Line(File, Start_Comment &  "  Date: " &
               Image(Now, "%B, %d, %Y at %H:%M:%S") & "  " & End_Comment);
      New_Line(File);
   end;

   function Compute_Mult_Type
     (M0: in Mapping) return Mult_Type is
      Result: Mult_Type := 0;
      Tup   : Tuple;
   begin
      for I in 1..Size(M0) loop
         Tup := Ith(M0, I);
         Result := Result + Get_Factor(Tup);
      end loop;
      return Result;
   end;

   procedure To_Pnml
     (N     : in     Net;
      File  : in     String;
      Unfold: in     Boolean;
      Result:    out Export_Result) is
      Vars   : String_Set := String_Set_Pkg.Empty_Set;
      Types  : String_Set := String_Set_Pkg.Empty_Set;
      F      : File_Type;
      Pnet   : Net;
      procedure L(Str: in Ustring) is begin Put_Line(F, Str); end;
      procedure L(Str: in String)  is begin Put_Line(F, Str); end;
      function Replace(Str: in String) return String is
	 Map: constant String_Mapping_Set :=
	   (1 => To_String_Mapping(From => "<", To => "&lt;"),
	    2 => To_String_Mapping(From => ">", To => "&gt;"));
      begin
	 return Replace(Str, Map);
      end;
      function Replace_Dom(Str: in String) return String is
	 Map: constant String_Mapping_Set :=
	   (1 => To_String_Mapping(From => "<",   To => "&lt;"),
	    2 => To_String_Mapping(From => ">",   To => "&gt;"),
	    3 => To_String_Mapping(From => " * ", To => "-"));
      begin
	 return Replace(Str, Map);
      end;
      function Replace(Str: in Ustring) return String is
      begin return Replace(To_String(Str)); end;
      function Get_Place_Id(P: in Place) return Ustring is
      begin return "P-" & Get_Name(P); end;
      function Get_Trans_Id(T: in Trans) return Ustring is
      begin return "T-" & Get_Name(T); end;
      function Get_Dom_Id(D: in Dom) return Ustring is
	 Result: Ustring := Null_String;
      begin
	 for I in 1..Size(D) loop
	    Result := Result & "-" & Get_Name(Ith(D, I));
	 end loop;
	 return "T" & Result;
      end;
      procedure To_Pnml_Place(P: in Place) is
	 M0: constant Mapping := Get_M0(P);
	 D : constant Dom := Get_Dom(P);
      begin
	 L("<place id=""" & Get_Place_Id(P) & """>");
	 L("  <name><text>" & Get_Name(P) & "</text></name>");
	 L("  <type>");
	 L("    <text>" & Replace(To_Helena(D)) & "</text>");
	 L("    <structure>");
	 L("      <usersort declaration=""" & Get_Dom_Id(D) & """/>");
	 L("    </structure>");
	 L("  </type>");
	 if not Is_Empty(M0) then
	    L("  <hlinitialMarking>");
	    L("    <text>" & Replace(To_Helena(M0)) & "</text>");
	    L("    <structure>");
	    begin
	       L("      " & To_Pnml(M0));
	    exception
	       when Export_Exception =>
		  L("      CANNOT EXPORT");
	    end;
	    L("    </structure>");
	    L("  </hlinitialMarking>");
	 end if;
	 L("</place>");
      end;
      procedure To_Pnml_Trans(T: in Trans) is
	 G: constant Guard := Get_Guard(T);
      begin
	 L("<transition id=""" & Get_Trans_Id(T) & """>");
	 L("  <name><text>" & Get_Name(T) & "</text></name>");
	 if G /= True_Guard then
	    L("  <condition>");
	    L("    <text>" & Replace(To_Helena(G)) & "</text>");
	    L("    <structure>");
	    begin
	       L("      " & To_Pnml(G));
	    exception
	       when Export_Exception =>
		  L("      CANNOT EXPORT");
	    end;
	    L("    </structure>");
	    L("  </condition>");
	 end if;
	 L("</transition>");
      end;
      procedure To_Pnml_Arc(M   : in Mapping;
			    Src : in Ustring;
			    Dest: in Ustring) is
	 Name: constant Ustring := Src & "-to-" & Dest;
      begin
	 L("<arc " &
	     "id=""" & Name & """ " &
	     "source=""" & Src & """ " &
	     "target=""" & Dest & """>");
	 L("  <name><text>" & Name & "</text></name>");
	 L("  <hlinscription>");
	 L("    <text>" & Replace(To_Helena(M)) & "</text>");
	 L("    <structure>");
	 begin
	    L("      " & To_Pnml(M));
	 exception
	    when Export_Exception =>
	       L("      CANNOT EXPORT");
	 end;
	 L("    </structure>");
	 L("  </hlinscription>");
	 L("</arc>");
      end;
      function Get_Cls_Id(C: in Cls) return Ustring is
      begin
	 return "T-" & Get_Name(C);
      end;
      procedure To_Pnml_Cls(C: in Cls) is
	 Id  : constant Ustring := Get_Cls_Id(C);
	 Name: constant Ustring := Get_Name(C);
      begin
	 if (not Is_Predefined_Cls(Get_Name(C)) or C = Bool_Cls)
	   and not String_Set_Pkg.Contains(Types, Id)
	 then
	    L("<namedsort " & "id=""" & Id & """ name=""" & Name & """>");
	    begin
	       L("  " & To_Pnml(C));
	    exception
	       when Export_Exception =>
		  L("  CANNOT EXPORT");
	    end;
	    L("</namedsort>");
	    String_Set_Pkg.Insert(Types, Id);
	 end if;
      end;
      procedure To_Pnml_Dom(P: in Place) is
	 D   : constant Dom := Get_Dom(P);
	 Id  : constant Ustring := Get_Dom_Id(D);
	 Name: constant Ustring := To_Helena(D);
      begin
	 if not String_Set_Pkg.Contains(Types, Id) then
	    L("<namedsort " & "id=""" & Id & """ name=""" & Name & """>");
	    L("  <productsort>");
	    for I in 1..Size(D) loop
	       L("    <usersort declaration=""T-" &
		   Get_Name(Ith(D, I)) & """/>");
	    end loop;
	    L("  </productsort>");
	    L("</namedsort>");
	    String_Set_Pkg.Insert(Types, Id);
	 end if;
      end;
      procedure To_Pnml_Vars(T: in Trans) is
	 Tv: constant Var_List := Get_Vars(T);
	 V : Var;
	 N : Ustring;
      begin
	 for I in 1..Length(Tv) loop
	    V := Ith(Tv, I);
	    N := Get_Name(V) & "-" & Get_Name(Get_Cls(V));
	    if not String_Set_Pkg.Contains(Vars, N) then
	       String_Set_Pkg.Insert(Vars, N);
	       L("<variabledecl " &
		   "id=""V-" & N & """ " &
		   "name=""" & Get_Name(V) & """>");
	       L("  <usersort declaration=""" &
		   Get_Cls_Id(Get_Cls(V)) & """/>");
	       L("</variabledecl>");
	    end if;
	 end loop;
      end;
      P: Place;
      T: Trans;
      M: Mapping;
   begin
      pragma Assert(Unfold);
      Pnet := N;
      Create(F, Out_File, Normalize_Pathname(File));
      L("<?xml version=""1.0""?>");
      L("<pnml xmlns=""http://www.pnml.org/version-2009/grammar/pnml"">");
      L("<net id=""" & Get_Name(Pnet) & """ " &
	  "type=""http://www.pnml.org/version-2009/grammar/symmetricnet"">");
      L("<page id=""" & Get_Name(Pnet) & "-page"">");
      for I in 1..P_Size(Pnet) loop
	 To_Pnml_Place(Ith_Place(Pnet, I));
      end loop;
      for I in 1..T_Size(Pnet) loop
	 To_Pnml_Trans(Ith_Trans(Pnet, I));
      end loop;
      for I in 1..T_Size(Pnet) loop
	 T := Ith_Trans(Pnet, I);
	 for J in 1..P_Size(Pnet) loop
	    P := Ith_Place(Pnet, J);
	    M := Get_Arc_Label(Pnet, Pre, P, T);
	    if not Is_Empty(M) then
	       To_Pnml_Arc(M, Get_Place_Id(P), Get_Trans_Id(T));
	    end if;
	    M := Get_Arc_Label(Pnet, Post, P, T);
	    if not Is_Empty(M) then
	       To_Pnml_Arc(M, Get_Trans_Id(T), Get_Place_Id(P));
	    end if;
	 end loop;
      end loop;
      L("</page>");
      L("<name><text>" & Get_Name(Pnet) & "</text></name>");
      L("<declaration>");
      L("<structure>");
      L("<declarations>");
      for I in 1..Cls_Size(Pnet) loop
	 To_Pnml_Cls(Ith_Cls(Pnet, I));
      end loop;
      for I in 1..P_Size(Pnet) loop
	 To_Pnml_Dom(Ith_Place(Pnet, I));
      end loop;
      for I in 1..T_Size(Pnet) loop
	 To_Pnml_Vars(Ith_Trans(Pnet, I));
      end loop;
      L("</declarations>");
      L("</structure>");
      L("</declaration>");
      L("</net>");
      L("</pnml>");
      Close(F);
      Result := Export_Success;
   exception
      when Name_Error
        |  Use_Error
        |  Status_Error =>
         Result := Export_Io_Error;
   end;

end Pn.Nets.Exporter;
