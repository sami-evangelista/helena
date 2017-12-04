with
  Pn.Mappings,
  Pn.Nodes.Places,
  Pn.Nodes.Transitions;

use
  Pn.Mappings,
  Pn.Nodes.Places,
  Pn.Nodes.Transitions;

package body Pn.Struct_Analysis is

   --==========================================================================
   --  statically safe transitions computation
   --==========================================================================

   procedure Compute_Statically_Safe_Trans
     (N: in Net) is
      P      : Place;
      T      : Trans;
      Pre_T  : Place_Vector;
      S      : Fuzzy_Boolean;
      Set_Num: Natural := 1;
      Ok     : Boolean;
      Post_P : Trans_Vector;
      Inhib  : Place_Vector;
   begin
      for I in 1..T_Size(N) loop
         T := Ith_Trans(N, I);
         if Get_Safe(T) = Dont_Know then
	    declare
	       function Is_Valid_Input_Place
		 (P: in Place) return Boolean is
		  Result : Boolean := True;
		  Pre_P_U: Mapping;
		  Pre_P_T: Mapping;
		  Post_P : Trans_Vector := Post_Set(N, P);
	       begin
		  case Get_Type(P) is
		     when Buffer_Place | Shared_Place =>
			Result := False;
		     when Local_Place | Protected_Place | Ack_Place =>
			Result := True;
			--  if P is a process place then T is the only
			--  output of P or if P has an undefined type,
			--  pre(p, t) is quasi-injective and T is the
			--  only output of P
		     when Process_Place | Undefined_Place =>
			Result := Size(Post_P) = 1;
			if Get_Type(P) = Undefined_Place then
			   Pre_P_T := Get_Arc_Label(N, Pre, P, T);
			   Result := Result
			     and Is_Injective(Pre_P_T, Get_Vars(T));
			end if;
		  end case;
		  Free(Post_P);
		  return Result;
	       end;
	    begin
	       Pre_T := Pre_Set(N, T);
	       S := FTrue;
	       for J in 1..Size(Pre_T) loop
		  P := Ith(Pre_T, J);
		  if not Is_Valid_Input_Place(P) then
		     S := FFalse;
		     exit;
		  end if;
	       end loop;
	       Inhib := Inhib_Set(N, T);
	       if Size(Inhib) > 0 then
		  S := Ffalse;
	       end if;
	       Set_Safe(T, S);
	       Free(Inhib);
	       Free(Pre_T);
	    end;
         end if;
      end loop;
      for I in 1..T_Size(N) loop
         T := Ith_Trans(N, I);
         if Get_Safe_Set(T) = 0 then
	    Pre_T := Pre_Set(N, T);
	    if Size(Pre_T) = 1 then
	       declare
		  function Safe_Set_Check
		    (T: in Trans) return Boolean is
		     Result: Boolean := True;
		     Pre_T : Place_Vector;
		     M     : Mapping;
		     P     : Place;
		     Inhib : Place_Vector := Inhib_Set(N, T);
		  begin
		     Pre_T := Pre_Set(N, T);
		     Result := Size(Pre_T) = 1 and Size(Inhib) = 0;
		     if Result then
			P := Ith(Pre_T, 1);
			M := Get_Arc_Label(N, Pre, P, T);
			Result := Is_Unitary(M) and Is_Token_Unitary(M);
		     end if;
		     Free(Pre_T);
		     Free(Inhib);
		     return Result;
		  end;
	       begin
		  P := Ith(Pre_T, 1);
		  Post_P := Post_Set(N, P);
		  Ok := True;
		  for J in 1..Size(Post_P) loop
		     Ok := Ok and Safe_Set_Check(Ith(Post_P, J));
		  end loop;
		  if Ok then
		     for J in 1..Size(Post_P) loop
			Set_Safe_Set(Ith(Post_P, J), Set_Num);
		     end loop;
		     Set_Num := Set_Num + 1;
		  end if;
		  Free(Post_P);
	       end;
	    end if;
	    Free(Pre_T);
	 end if;
      end loop;
   end;



   --==========================================================================
   --  visible transitions computation
   --==========================================================================

   procedure Compute_Visible_Trans
     (N: in Net) is
      T       : Trans;
      P       : Place;
      Pre_P_T: Mapping;
      Post_P_T: Mapping;
      V       : Fuzzy_Boolean;
   begin
      for I in 1..T_Size(N) loop
         T := Ith_Trans(N, I);
         if Get_Visible(T) = Dont_Know then
            V := FFalse;
            for J in 1..P_Size(N) loop
               P       := Ith_Place(N, J);
               Pre_P_T := Get_Arc_Label(N, Pre, P, T);
               Post_P_T := Get_Arc_Label(N, Post, P, T);
               if (Is_Observed(N, P) and then
                   (not Is_Empty(Pre_P_T) or not Is_Empty(Post_P_T)) and then
                   not Static_Equal(Pre_P_T, Post_P_T))
               then
                  V := FTrue;
                  exit;
               end if;
            end loop;
            Set_Visible(T, V);
         end if;
      end loop;
   end;

end Pn.Struct_Analysis;
