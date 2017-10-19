with
  Pn.Compiler.Domains,
  Pn.Compiler.Names,
  Pn.Compiler.State,
  Pn.Guards,
  Pn.Mappings,
  Pn.Nodes,
  Pn.Vars;

use
  Pn.Compiler.Domains,
  Pn.Compiler.Names,
  Pn.Compiler.State,
  Pn.Guards,
  Pn.Mappings,
  Pn.Nodes,
  Pn.Vars;

package body Pn.Compiler.Mappings is

   --==========================================================================
   --  Functions generated
   --==========================================================================

   function M0_Func
     (P: in Place;
      M: in Mapping_Mode) return Ustring is
      Result: Ustring;
   begin
      Result := Place_Name(P) & "_initial";
      case M is
         when Add    => Result := "add_" & Result;
         when Remove => Result := "rem_" & Result;
      end case;
      return Result;
   end;

   function Arc_Mapping_Func
     (P: in Place;
      T: in Trans;
      A: in Arc_Type;
      M: in Mapping_Mode) return Ustring is
      Result: Ustring;
   begin
      Result := Place_Name(P) & "_" & Trans_Name(T);
      case A is
         when Pre     => Result := "pre_" & Result;
         when Post    => Result := "post_" & Result;
	 when Inhibit => pragma Assert(False); null;
      end case;
      case M is
         when Add    => Result := "add_" & Result;
         when Remove => Result := "rem_" & Result;
      end case;
      return Result;
   end;

   procedure Gen_Mapping
     (M   : in Mapping;
      Mode: in Mapping_Mode;
      P   : in Place;
      Func: in Ustring;
      Vars: in Var_List;
      Lib : in Library) is

      Tabs: Natural := 1;
      R   : Var_Mapping(1 .. Length(Vars));

      --===
      --  declarations to instantiate the generic unfolding procedure of the
      --  tuple
      --===
      procedure Gen_Simple_Tuple
        (Tup    : in Tuple;
         First  : in Card_Type;
         Last   : in Card_Type;
         Current: in Card_Type) is
         F     : constant Mult_Type := Get_Factor(Tup);
         Factor: Ustring := To_Ustring(F);
      begin
         if F > 0 then
            if Mode = Remove then
               Factor := "- " & Factor;
            end if;
            Plh(Lib, Tabs, Local_State_Add_Tokens_Func(P) &
                  "(s->" & State_Component_Name(P) & ", col, " & Factor &
		  "); \");
         end if;
      end;
      procedure On_Expr_Before
        (Ex: in Expr;
         I : in Index_Type) is
      begin
         Plh(Lib, Tabs, "col." &
             Dom_Ith_Comp_Name(I) & " = " & Compile_Evaluation(Ex, R) & "; \");
      end;
      procedure On_Expr_After
        (Ex: in Expr;
         I : in Index_Type) is
      begin
         null;
      end;
      procedure On_Guard_Before
        (G: in Guard) is
      begin
         if G /= True_Guard then
            Plh(Lib, Tabs, "if(" & Compile_Evaluation(G, R) & ") { \");
            Tabs := Tabs + 1;
         end if;
      end;
      procedure On_Guard_After
        (G: in Guard) is
      begin
         if G /= True_Guard then
            Tabs := Tabs - 1;
            Plh(Lib, Tabs, "} \");
         end if;
      end;

      --===
      --  instantiate the generic unfold procedure
      --===
      procedure Unfold_Tuple is new Pn.Mappings.Generic_Unfold_And_Handle
        (Apply           => Gen_Simple_Tuple,
         On_Expr_Before  => On_Expr_Before,
         On_Expr_After   => On_Expr_After,
         On_Guard_Before => On_Guard_Before,
         On_Guard_After  => On_Guard_After);

      Tup: Tuple;

   begin
      --===
      --  replace variables of the transition
      --===
      for I in R'Range loop
         R(I) := (V    => Ith(Vars, I),
                  Expr => "c." & Dom_Ith_Comp_Name(I));
      end loop;
      Plh(Lib, "/*");
      Plh(Lib, " * " & To_Helena(M));
      Plh(Lib, " */");
      Plh(Lib, "#define " & Func & "(s, c) { \");
      if not Is_Empty(M) then
         Plh(Lib, 1, Place_Dom_Type(P) & " col; \");
         for I in 1..Size(M) loop
            Tup := Ith(M, I);
            Unfold_Tuple(Tup);
         end loop;
      end if;
      Plh(Lib, "}");
      Nlh(Lib);
   end;

   procedure Gen_Net_Mappings
     (N  : in Net;
      Lib: in Library) is
      M   : Mapping;
      P   : Place;
      T   : Trans;
      Vars: Var_List := New_Var_List;
   begin
      --===
      --  generate initial markings
      --===
      Section_Start_Comment(Lib, "initial markings");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         M := Get_M0(P);
         for Mode in Mapping_Mode loop
            Gen_Mapping(M, Mode, P, M0_Func(P, Mode), Vars, Lib);
         end loop;
      end loop;
      Free(Vars);
      Section_End_Comment(Lib);

      --===
      --  generate all the arc mappings
      --===
      Section_Start_Comment(Lib, "arc mappings");
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         for J in 1..T_Size(N) loop
            T := Ith_Trans(N, J);
            for A in Update_Arc_Type loop
               M := Get_Arc_Label(N, A, P, T);
               if not Is_Empty(M) then
                  for Mode in Mapping_Mode loop
		     Plh(Lib, "/*");
		     Plh(Lib, " * P: " & To_String(Get_Name(P)));
		     Plh(Lib, " * T: " & To_String(Get_Name(T)));
		     Plh(Lib, "*/");
                     Gen_Mapping
                       (M, Mode, P,
                        Arc_Mapping_Func(P, T, A, Mode),
                        Get_Vars(T), Lib);
                  end loop;
               end if;
            end loop;
         end loop;
      end loop;
      Section_End_Comment(Lib);
   end;



   --==========================================================================
   --  Main generation procedure
   --==========================================================================

   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      Lib      : Library;
      Prototype: Ustring;
      Comment  : constant Ustring :=
        To_Ustring("This library implements the mappings of the net.");
   begin
      Init_Library(Mappings_Lib, Comment, Path, Lib);
      Gen_Net_Mappings(N, Lib);
      Prototype := "void " & Lib_Init_Func(Mappings_Lib) & Nl & "()";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {}");
      End_Library(Lib);
   end;

end Pn.Compiler.Mappings;
