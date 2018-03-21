with
  Gnat.Directory_Operations,
  Gnat.Os_Lib,
  Pn.Compiler.Config,
  Pn.Propositions;

use
  Gnat.Directory_Operations,
  Gnat.Os_Lib,
  Pn.Compiler.Config,
  Pn.Propositions;

package body Pn.Compiler.Model is

   package Expr_Set_Pkg is new Generic_Set(Element_Type => Expr,
                                           Null_Element => null,
                                           "="          => "=");
   subtype Expr_Set is Expr_Set_Pkg.Set_Type;

   Done   : Expr_Set := Expr_Set_Pkg.Empty_Set;
   Pending: Expr_Set := Expr_Set_Pkg.Empty_Set;

   procedure Add_Expr
     (E: in Expr) is
   begin
      if (not Expr_Set_Pkg.Contains(Pending, E) and
          not Expr_Set_Pkg.Contains(Done,    E))
      then
         Expr_Set_Pkg.Insert(Pending, E);
      end if;
   end;

   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      Prototype: Ustring;
      L        : Library;
      E        : Expr;
      V        : Ustring;
      P        : Ustring;
      H        : constant Ustring := Header_Extension;
      C        : constant Ustring := Code_Extension;
      O        : constant Ustring := Object_Extension;
      Macro    : constant Ustring := To_Upper(Model_Lib) & "_" & To_Upper(H);
      Props    : constant State_Proposition_List := Get_Propositions(N);
      Libs     : constant array (Natural range <>)  of Unbounded_String :=
	(Util_Lib,
	 Colors_Lib,
	 Constants_Lib,
	 Domains_Lib,
	 Funcs_Lib,
	 State_Lib,
	 Mappings_Lib,
	 Event_Lib,
	 Enabling_Test_Lib);
      Comment  : constant String :=
	"This library contains functions generated for a model.";
      Params   : constant Ustring_List := Get_Parameters(N);
   begin
      Init_Library(Model_Lib, To_Ustring(Comment), Path, L);
      --=======================================================================
      Plh(L, "#define MODEL_HAS_EVENT_UNDOABLE");
      Plh(L, "#define MODEL_HAS_GRAPH_ROUTINES");
      Plh(L, "#define MODEL_HAS_XML_PARAMETERS");
      Plh(L, "#define MODEL_HAS_STATE_COMPRESSION");
      Nlh(L);
      --=======================================================================
      for I in Libs'Range loop
	 Plh(L, "#include """ & Libs(I) & ".h""");
      end loop;
      Compile(Props, L);
      --=======================================================================
      while not Expr_Set_Pkg.Is_Empty(Pending) loop
	 E := Expr_Set_Pkg.Ith(Pending, 1);
	 Compile_Definition(E, L);
	 Expr_Set_Pkg.Delete(Pending, E);
	 Expr_Set_Pkg.Insert(Done, E);
      end loop;
      --=======================================================================
      Prototype := "void " & Lib_Init_Func(Model_Lib) & " ()";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      for I in Libs'Range loop
	 Plc(L, 1, Lib_Init_Func(Libs(I)) & " ();");
      end loop;
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring("void finalise_model()");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring("void model_xml_parameters (FILE * out)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      if String_List_Pkg.Length(Params) > 0 then
	 Plc(L, 1, "fprintf (out, ""<modelParameters>"");");
	 for I in 1..String_List_Pkg.Length(Params) loop
	    P := String_List_Pkg.Ith(Params, I);
	    V := To_Helena(Get_Parameter_Value(N, P));
	    Plc(L, 1, "fprintf (out, ""<modelParameter>"");");
	    Plc(L, 1, "fprintf (out, ""<modelParameterName>" & P &
		  "</modelParameterName>"");");
	    Plc(L, 1, "fprintf (out, ""<modelParameterValue>" & V &
		  "</modelParameterValue>"");");
	    Plc(L, 1, "fprintf (out, ""</modelParameter>"");");
	 end loop;
	 Plc(L, 1, "fprintf (out, ""</modelParameters>"");");
      end if;
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring("void model_xml_statistics (FILE * out)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      declare
	 Places    : Natural;
	 Trans     : Natural;
	 Arcs      : Natural;
	 In_Arcs   : Natural;
	 Out_Arcs  : Natural;
	 Inhib_Arcs: Natural;
         Pr        : constant String := "fprintf (out, """;
      begin
	 Get_Statistics(N, Places, Trans, Arcs, In_Arcs, Out_Arcs, Inhib_Arcs);
	 Plc(L, 1, Pr & "<places>" & Places & "</places>"");");
	 Plc(L, 1, Pr & "<transitions>" & Trans & "</transitions>"");");
	 Plc(L, 1, Pr & "<netArcs>" & Arcs & "</netArcs>"");");
	 Plc(L, "}");
      end;
      --=======================================================================
      Prototype := To_Ustring("char * model_name ()");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "return """ & Get_Printable_String(Get_Name(N)) & """;");
      Plc(L, "}");
      --=======================================================================
      End_Library(L);
   end;

end;
