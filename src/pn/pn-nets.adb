with
  Pn.Classes,
  Pn.Compiler,
  Pn.Exprs.Num_Consts,
  Pn.Nodes,
  Pn.Vars,
  Utils.Math;

use
  Pn.Classes,
  Pn.Compiler,
  Pn.Exprs.Num_Consts,
  Pn.Nodes,
  Pn.Vars,
  Utils.Math;

package body Pn.Nets is

   use String_Set_Pkg;


   --==========================================================================
   --  General sub-programs
   --==========================================================================

   procedure Deallocate is new Ada.Unchecked_Deallocation(Net_Record, Net);

   function New_Net
     (Name: in Ustring) return Net is
      Result: constant Net := new Net_Record;
   begin
      Result.Name := Name;
      Result.P := New_Place_Vector;
      Result.T := New_Trans_Vector;
      Result.C := New_Cls_Set;
      Result.Consts := New_Var_List;
      Result.F := New_Func_List;
      Result.Props := New_State_Proposition_List;
      Result.Params := String_List_Pkg.Empty_Array;
      return Result;
   end;

   procedure Free_All
     (N: in out Net) is
   begin
      Free_All(N.P);
      Free_All(N.T);
      Free_All(N.C);
      Free_All(N.Consts);
      Free_All(N.F);
      Deallocate(N);
      N := null;
   end;

   procedure Free
     (N: in out Net) is
   begin
      Free(N.P);
      Free(N.T);
      Free(N.C);
      Free(N.Consts);
      Free(N.F);
      Free(N.Props);
      Deallocate(N);
      N := null;
   end;

   function Get_Name
     (N: in Net) return Ustring is
   begin
      return N.Name;
   end;

   procedure Set_Name
     (N   : in Net;
      Name: in Ustring) is
   begin
      N.Name := Name;
   end;



   --==========================================================================
   --  Places
   --==========================================================================

   function P_Size
     (N: in Net) return Count_Type is
   begin
      return Size(N.P);
   end;

   function Get_Places
     (N: in Net) return Place_Vector is
   begin
      return N.P;
   end;

   procedure Set_Places
     (N: in Net;
      P: in Place_Vector) is
   begin
      N.P := P;
   end;

   function Is_Place
     (N: in Net;
      P: in Ustring) return Boolean is
   begin
      return Contains(N.P, P);
   end;

   function Ith_Place
     (N: in Net;
      I: in Index_Type) return Place is
   begin
      return Ith(N.P, I);
   end;

   function Get_Index
     (N: in Net;
      P: in Place) return Extended_Index_Type is
   begin
      return Get_Index(N.P, P);
   end;

   procedure Add_Place
     (N: in Net;
      P: in Place) is
   begin
      Append(N.P, P);
   end;

   procedure Delete_Place
     (N: in Net;
      P: in Place) is
   begin
      Delete_Arcs(P);
      Delete(N.P, P);
   end;

   function Get_Place
     (N: in Net;
      P: in Ustring) return Place is
   begin
      return Get(N.P, P);
   end;

   function Pre_Post_Set
     (N: in Net;
      P: in Place;
      A: in Arc_Type) return Trans_Vector is
      Result: constant Trans_Vector := New_Trans_Vector;
      T     : Trans;
   begin
      for I in 1..Size(N.T) loop
         T := Ith(N.T, I);
         if not Is_Empty(Get_Arc_Label(N, A, P, T)) then
            Append(Result, T);
         end if;
      end loop;
      return Result;
   end;

   function Pre_Set
     (N: in Net;
      P: in Place) return Trans_Vector is
   begin
      return Pre_Post_Set(N, P, Post);
   end;

   function Post_Set
     (N: in Net;
      P: in Place) return Trans_Vector is
   begin
      return Pre_Post_Set(N, P, Pre);
   end;

   function Pre_Post_Set
     (N: in Net;
      P: in Place_Vector;
      A: in Arc_Type) return Trans_Vector is
      Result: constant Trans_Vector := New_Trans_Vector;
      Pi    : Place;
      Tj    : Trans;
   begin
      for I in 1..Size(P) loop
         Pi := Ith(P, I);
         for J in 1..Size(N.T) loop
            Tj := Ith(N.T, J);
            if (not Is_Empty(Get_Arc_Label(N, A, Pi, Tj)) and then
                not Contains(Result, Tj))
            then
               Append(Result, Tj);
            end if;
         end loop;
      end loop;
      return Result;
   end;

   function Pre_Set
     (N: in Net;
      P: in Place_Vector) return Trans_Vector is
   begin
      return Pre_Post_Set(N, P, Post);
   end;

   function Post_Set
     (N: in Net;
      P: in Place_Vector) return Trans_Vector is
   begin
      return Pre_Post_Set(N, P, Pre);
   end;

   function Bit_To_Encode_Pid
     (N: in Net) return Natural is
   begin
      return Bit_Width(Big_Int(P_Size(N)));
   end;



   --==========================================================================
   --  Transitions
   --==========================================================================

   function T_Size
     (N: in Net) return Count_Type is
   begin
      return Size(N.T);
   end;

   function Get_Trans
     (N: in Net) return Trans_Vector is
   begin
      return N.T;
   end;

   procedure Set_Trans
     (N: in Net;
      T: in Trans_Vector) is
   begin
      N.T := T;
   end;

   function Ith_Trans
     (N: in Net;
      I: in Index_Type) return Trans is
   begin
      return Ith(N.T, I);
   end;

   function Get_Index
     (N: in Net;
      T: in Trans) return Index_Type is
   begin
      return Get_Index(N.T, T);
   end;

   function Is_Trans
     (N: in Net;
      T: in Ustring) return Boolean is
   begin
      return Contains(N.T, T);
   end;

   procedure Add_Trans
     (N: in Net;
      T: in Trans) is
   begin
      Append(N.T, T);
   end;

   procedure Delete_Trans
     (N: in Net;
      T: in Trans) is
   begin
      Delete_Arcs(T);
      Delete(N.T, T);
   end;

   function Get_Trans
     (N: in Net;
      T: in Ustring) return Trans is
   begin
      return Get(N.T, T);
   end;

   function Pre_Post_Set
     (N: in Net;
      T: in Trans;
      A: in Arc_Type) return Place_Vector is
      Result: constant Place_Vector := New_Place_Vector;
      P     : Place;
   begin
      for I in 1..Size(N.P) loop
         P := Ith(N.P, I);
         if not Is_Empty(Get_Arc_Label(N, A, P, T)) then
            Append(Result, P);
         end if;
      end loop;
      return Result;
   end;

   function Pre_Post_Set
     (N: in Net;
      T: in Trans_Vector;
      A: in Arc_Type) return Place_Vector is
      Result: constant Place_Vector := New_Place_Vector;
      Ti    : Trans;
      Pj    : Place;
   begin
      for I in 1..Size(T) loop
         Ti := Ith(T, I);
         for J in 1..Size(N.P) loop
            Pj := Ith(N.P, J);
            if (not Is_Empty(Get_Arc_Label(N, A, Pj, Ti)) and then
                not Contains(Result, Pj))
            then
               Append(Result, Pj);
            end if;
         end loop;
      end loop;
      return Result;
   end;

   function Pre_Set
     (N: in Net;
      T: in Trans) return Place_Vector is
   begin
      return Pre_Post_Set(N, T, Pre);
   end;

   function Post_Set
     (N: in Net;
      T: in Trans) return Place_Vector is
   begin
      return Pre_Post_Set(N, T, Post);
   end;

   function Pre_Set
     (N: in Net;
      T: in Trans_Vector) return Place_Vector is
   begin
      return Pre_Post_Set(N, T, Pre);
   end;

   function Post_Set
     (N: in Net;
      T: in Trans_Vector) return Place_Vector is
   begin
      return Pre_Post_Set(N, T, Post);
   end;

   function Inhib_Set
     (N: in Net;
      T: in Trans) return Place_Vector is
   begin
      return Pre_Post_Set(N, T, Inhibit);
   end;

   function Inhib_Set
     (N: in Net;
      T: in Trans_Vector) return Place_Vector is
   begin
      return Pre_Post_Set(N, T, Inhibit);
   end;

   function Is_Unifiable
     (N: in Net;
      T: in Trans) return Boolean is
      Scheduling: Tuple_Scheduling := New_Tuple_Scheduling;
      P         : Place;
      Pre_P_T   : Mapping;
      Result    : Boolean;
   begin
      for I in 1..P_Size(N) loop
         P       := Ith_Place(N, I);
         Pre_P_T := Get_Arc_Label(N, Pre, P, T);
         for J in 1..Size(Pre_P_T) loop
            Append(Scheduling, Ith(Pre_P_T, J));
         end loop;
      end loop;
      Result := Exist_Valid_Permutation(Scheduling);
      Free(Scheduling);
      return Result;
   end;

   procedure Replace_Var
     (N: in Net;
      T: in Trans;
      V: in Var;
      E: in Expr) is
      procedure Replace_Var_In_Mapping
        (M: in Mapping) is
      begin
         Replace_Var(M, V, E);
      end;
      procedure Replace_Var is
         new Generic_Apply_Arcs_Labels(Action => Replace_Var_In_Mapping);
   begin
      Replace_Var(T);
      Replace_Var(T, V, E, True);
   end;

   procedure Map_Vars
     (N    : in Net;
      T    : in Trans;
      V_Old: in Var_List;
      V_New: in Var_List) is
      procedure Map_Vars
        (M: in Mapping) is
      begin
         Map_Vars(M, V_Old, V_New);
      end;
      procedure Map is new Generic_Apply_Arcs_Labels(Action => Map_Vars);
   begin
      pragma Assert(Length(V_New) = Length(V_Old));
      Map(T);
      Map_Vars(T, V_Old, V_New);
   end;

   function Bit_To_Encode_Tid
     (N: in Net) return Natural is
   begin
      return Bit_Width(Big_Int(T_Size(N)));
   end;



   --==========================================================================
   --  Color classes
   --==========================================================================

   function Cls_Size
     (N: in Net) return Count_Type is
   begin
      return Card(N.C);
   end;

   function Ith_Cls
     (N: in Net;
      I: in Index_Type) return Cls is
   begin
      return Ith(N.C, I);
   end;

   function Get_Cls
     (N: in Net) return Cls_Set is
   begin
      return N.C;
   end;

   procedure Set_Cls
     (N: in Net;
      C: in Cls_Set) is
   begin
      N.C := C;
   end;

   procedure Add_Cls
     (N: in Net;
      C: in Cls) is
   begin
      Insert(N.C, C);
   end;

   function Get_Cls
     (N: in Net;
      C: in Ustring) return Cls is
   begin
      return Get(N.C, C);
   end;

   function Is_Cls
     (N: in Net;
      C: in Ustring) return Boolean is
   begin
      return Contains(N.C, C);
   end;



   --==========================================================================
   --  Arcs
   --==========================================================================

   procedure Add_Arc_Label
     (N: in Net;
      A: in Arc_Type;
      P: in Place;
      T: in Trans;
      M: in Mapping) is
   begin
      Add_To_Arc_Label(T, P, A, M);
   end;

   procedure Add_Arc_Label
     (N  : in Net;
      A  : in Arc_Type;
      P  : in Place;
      T  : in Trans;
      Tup: in Tuple) is
   begin
      Add_To_Arc_Label(T, P, A, Tup);
   end;

   function Get_Arc_Label
     (N: in Net;
      A: in Arc_Type;
      P: in Place;
      T: in Trans) return Mapping is
   begin
      return Get_Arc_Label(T, P, A);
   end;

   procedure Set_Arc_Label
     (N: in Net;
      A: in Arc_Type;
      P: in Place;
      T: in Trans;
      M: in Mapping) is
      T_Vars: constant Var_List := Get_Vars(T);
      I_Vars: constant Var_List := Get_Ivars(T);
      L_Vars: constant Var_List := Get_Lvars(T);
      Vars  : Var_List := New_Var_List;
      M_Vars: Var_List := Vars_In(M);
   begin
      Union(Vars, I_Vars);
      Union(Vars, T_Vars);
      Union(Vars, L_Vars);
      pragma Assert(Included(M_Vars, Vars));
      Free(Vars);
      Free(M_Vars);
      Set_Arc_Label(T, P, A, M);
   end;



   --==========================================================================
   --  Constants
   --==========================================================================

   function Get_Consts
     (N: in Net) return Var_List is
   begin
      return N.Consts;
   end;

   procedure Set_Consts
     (N: in Net;
      C: in Var_List) is
   begin
      N.Consts := C;
   end;

   procedure Add_Const
     (N: in Net;
      C: in Var) is
   begin
      Append(N.Consts, C);
   end;

   function Is_Const
     (N: in Net;
      C: in Ustring) return Boolean is
   begin
      return Contains(N.Consts, C);
   end;

   function Get_Const
     (N: in Net;
      C: in Ustring) return Var is
   begin
      return Get(N.Consts, C);
   end;



   --==========================================================================
   --  Parameters
   --==========================================================================

   function Get_Parameters
     (N: in Net) return Ustring_List is
   begin
      return N.Params;
   end;

   procedure Add_Parameter
     (N: in Net;
      P: in Ustring) is
   begin
      String_List_Pkg.Append(N.Params, P);
   end;

   function Is_Parameter
     (N: in Net;
      P: in Ustring) return Boolean is
   begin
      for I in 1..String_List_Pkg.Length(N.Params) loop
	 if String_List_Pkg.Ith(N.Params, I) = P then
	    return True;
	 end if;
      end loop;
      return False;
   end;

   function Get_Parameter_Value
     (N: in Net;
      P: in Ustring) return Expr is
      V: constant Var := Get_Const(N, P);
   begin
      return Get_Init(V);
   end;

   procedure Set_Parameter_Value
     (N: in Net;
      P: in Ustring;
      V: in Num_Type) is
      C: Var;
      I: Expr;
   begin
      if Is_Parameter(N, P) then
	 C := Get_Const(N, P);
	 I := Get_Init(C);
	 Free(I);
	 Set_Init(C, New_Num_Const(V, Int_Cls));
      end if;
   end;



   --==========================================================================
   --  Functions
   --==========================================================================

   function Get_Funcs
     (N: in Net) return Func_List is
   begin
      return N.F;
   end;

   procedure Set_Funcs
     (N: in Net;
      F: in Func_List) is
   begin
      N.F := F;
   end;

   procedure Add_Func
     (N: in Net;
      F: in Func) is
   begin
      Append(N.F, F);
   end;

   procedure Delete_Func
     (N: in Net;
      F: in Ustring) is
   begin
      Delete(N.F, F);
   end;

   function Is_Func
     (N: in Net;
      F: in Ustring) return Boolean is
   begin
      return Contains(N.F, F);
   end;

   function Get_Func
     (N: in Net;
      F: in Ustring) return Func is
   begin
      return Get(N.F, F);
   end;

   function Funcs_Card
     (N: in Net) return Count_Type is
   begin
      return Length(N.F);
   end;

   function Ith_Func
     (N: in Net;
      I: in Index_Type) return Func is
   begin
      return Ith(N.F, I);
   end;



   --==========================================================================
   --  Priorities
   --==========================================================================

   function With_Priority
     (N: in Net) return Boolean is
   begin
      for I in 1..T_Size(N) loop
	 if Get_Priority(Ith_Trans(N, I)) /= No_Priority then
	    return True;
	 end if;
      end loop;
      return False;
   end;



   --==========================================================================
   --  Propositions
   --==========================================================================

   function Is_Proposition
     (N   : in Net;
      Prop: in Ustring) return Boolean is
   begin
      return Contains(N.Props, Prop);
   end;

   function Get_Propositions
     (N: in Net) return State_Proposition_List is
   begin
      return N.Props;
   end;

   function Get_Proposition
     (N   : in Net;
      Prop: in Ustring) return State_Proposition is
   begin
      return Get(N.Props, Prop);
   end;

   procedure Add_Proposition
     (N   : in Net;
      Prop: in State_Proposition) is
   begin
      Append(N.Props, Prop);
   end;

   function Get_Observed_Places
     (N: in Net) return Place_Vector is
      Result: constant Place_Vector := New_Place_Vector;
      P     : State_Proposition;
      Names : String_Set;
   begin
      for I in 1..Length(N.Props) loop
	 P := Ith(N.Props, I);
	 if Is_Observed(P) then
	    Names := Get_Places_In(P);
	    for J in 1..String_Set_Pkg.Card(Names) loop
	       Append(Result, Get_Place(N, String_Set_Pkg.Ith(Names, J)));
	    end loop;
	 end if;
      end loop;
      return Result;
   end;

   function Is_Observed
     (N: in Net;
      P: in Place) return Boolean is
      Result  : Boolean;
      Observed: Place_Vector := Get_Observed_Places(N);
   begin
      Result := Contains(Observed, P);
      Free(Observed);
      return Result;
   end;



   --==========================================================================
   --  Others
   --==========================================================================

   procedure Get_Statistics
     (N         : in     Net;
      Places    :    out Natural;
      Trans     :    out Natural;
      Arcs      :    out Natural;
      In_Arcs   :    out Natural;
      Out_Arcs  :    out Natural;
      Inhib_Arcs:    out Natural) is
      Set: Place_Vector;
      T  : Pn.Nodes.Transitions.Trans;
   begin
      Places := P_Size(N);
      Trans := T_Size(N);
      In_Arcs := 0;
      Out_Arcs := 0;
      Inhib_Arcs := 0;
      for I in 1..T_Size(N) loop
	 T := Ith_Trans(N, I);
	 Set := Pre_Set(N, T);
	 In_Arcs := In_Arcs + Size(Set);
	 Free(Set);
	 Set := Post_Set(N, T);
	 Out_Arcs := Out_Arcs + Size(Set);
	 Free(Set);
	 Set := Inhib_Set(N, T);
	 Inhib_Arcs := Inhib_Arcs + Size(Set);
	 Free(Set);
      end loop;
      Arcs := In_Arcs + Out_Arcs + Inhib_Arcs;
   end;

end Pn.Nets;
