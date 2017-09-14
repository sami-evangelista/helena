with
  Pn.Compiler.Config,
  Pn.Exprs.Num_Consts,
  Pn.Classes,
  Pn.Classes.Containers,
  Pn.Classes.Products,
  Pn.Compiler.Enabling_Test,
  Pn.Nodes,
  Pn.Vars,
  Helena_Parser.Classes,
  Helena_Parser.Errors,
  Helena_Parser.Exprs,
  Helena_Parser.Stats;

use
  Pn.Compiler.Config,
  Pn.Exprs.Num_Consts,
  Pn.Classes,
  Pn.Classes.Containers,
  Pn.Classes.Products,
  Pn.Compiler.Enabling_Test,
  Pn.Nodes,
  Pn.Vars,
  Helena_Parser.Classes,
  Helena_Parser.Errors,
  Helena_Parser.Exprs,
  Helena_Parser.Stats;

package body Helena_Parser.Main is

   use Element_List_Pkg;
   package VLLP renames Var_List_List_Pkg;
   package HYT renames Helena_Yacc_Tokens;

   --==========================================================================
   --  mappings
   --==========================================================================

   procedure Parse_Tuple_Guard
     (E   : in     Element;
      Vars: in out Var_List_List;
      G   :    out Guard;
      Ok  :    out Boolean) is
      Ex: Expr;
   begin
      if E = null then
         G := True_Guard;
         Ok := True;
      else
         Parse_Basic_Expr(E, Bool_Cls, Vars, Ex, Ok);
         if Ok then
            G := New_Guard(Ex);
         end if;
      end if;
   end;

   procedure Parse_Tuple_Vars
     (E   : in     Element;
      Cd  : in     Dom;
      Vars: in out Var_List;
      Ok  :    out Boolean) is
      Ith_Expr: Element;
      Name    : Ustring;
      C       : Cls;
      V       : Var;
      Sym     : Expr;
      Exprs   : Element;
      Tup_Vars: String_Set_Pkg.Set_Type;
      Vll     : Var_List_List := VLLP.Empty_Array;
   begin
      Check_Type(E, HYT.Tuple);
      if E.Tuple_Vars /= null then
         Parse_Iter_Var_List_Names(E.Tuple_Vars, Tup_Vars);
      else
         Tup_Vars := String_Set_Pkg.Empty_Set;
      end if;
      Check_Type(E.Tuple_Tuple, HYT.Simple_Tuple);
      Check_Type(E.Tuple_Tuple.Simple_Tuple_Tuple, HYT.List);
      Exprs := E.Tuple_Tuple.Simple_Tuple_Tuple;
      Ok := Size(Cd) = Length(Exprs.List_Elements);
      if not Ok then
         Add_Error(E, "Tuple has wrong arity (" & Size(Cd) &
                     " element(s) expected)");
      else
         for I in 1..Length(Exprs.List_Elements) loop
            Ith_Expr := Ith(Exprs.List_Elements, I);
            if Ith_Expr.T = Symbol then
               Parse_Symbol(Ith_Expr, Vll, False, Sym, Ok);
               if Ok then
                  Free(Sym);
               else
                  Parse_Name(Ith_Expr.Sym, Name);
                  C := Ith(Cd, I);
		  Ok := String_Set_Pkg.Contains(Tup_Vars, Name);
                  if not Ok then
                     if not Contains(Vars, Name) then
                        V := New_Trans_Var(Name => Name,
                                           C    => C);
                        Append(Vars, V);
			Ok := True;
                     else
			Ok :=
			  Get_Root_Cls(Get_Cls(Get(Vars, Name))) =
			  Get_Root_Cls(C);
                        if not Ok then
                           Redefinition(Ith_Expr,
					To_Ustring("Variable"), Name);
                           return;
                        end if;
                     end if;
                  end if;
               end if;
            end if;
         end loop;
      end if;
   end;

   procedure Parse_Mapping_Vars
     (E   : in     Element;
      Cd  : in     Dom;
      Vars: in out Var_List;
      Ok  :    out Boolean) is
      Ith_Tuple: Element;
   begin
      Check_Type(E, HYT.Mapping);
      Check_Type(E.Mapping_Tuples, HYT.List);
      for I in 1..Length(E.Mapping_Tuples.List_Elements) loop
         Ith_Tuple := Ith(E.Mapping_Tuples.List_Elements, I);
         Parse_Tuple_Vars(Ith_Tuple, Cd, Vars, Ok);
         if not Ok then
            return;
         end if;
      end loop;
   end;

   procedure Parse_Arc_Vars
     (E   : in     Element;
      Vars: in out Var_List;
      Ok  :    out Boolean) is
      P: Pn.Nodes.Places.Place;
   begin
      Check_Type(E, HYT.Arc);
      Parse_Place_Ref(E.Arc_Place, P, Ok);
      if Ok then
         Parse_Mapping_Vars(E.Arc_Mapping, Get_Dom(P), Vars, Ok);
      end if;
   end;

   procedure Parse_Simple_Tuple
     (E     : in     Element;
      Cd    : in     Dom;
      Vars  : in out Var_List_List;
      F     :    out Mult_Type;
      El    :    out Expr_List;
      Ok    :    out Boolean;
      Uscore: in     Boolean := False) is
      Vll   : Var_List_List := VLLP.Empty_Array;
      N     : Num_Type;
      Factor: Expr;
   begin
      Check_Type(E, HYT.Simple_Tuple);
      if E.Simple_Tuple_Factor = null then
         N := 1;
         Ok := True;
      else
         Parse_Static_Num_Expr(E.Simple_Tuple_Factor, Vll, Factor, N, Ok);
         if Ok then
            Free(Factor);
         end if;
      end if;
      if Ok then
	 Ok := N >= 0;
         if not Ok then
            Add_Error(E, "Positive factor expected");
            Add_Error(E, "Supplied factor is " & To_Ustring(N));
            Ok := False;
         else
            F := Mult_Type(N);
            Check_Type(E.Simple_Tuple_Tuple, HYT.List);
	    Ok := Size(Cd) = Length(E.Simple_Tuple_Tuple.List_Elements);
            if not Ok then
               Add_Error(E, "Tuple has wrong arity (" & Size(Cd) &
                         " elements expected)");
            else
               Parse_Basic_Expr_List
                 (E.Simple_Tuple_Tuple, Vars, Cd, True, El, Ok,
		  Uscore => Uscore);
            end if;
         end if;
      end if;
   end;

   procedure Parse_Tuple
     (E     : in     Element;
      Cd    : in     Dom;
      Vars  : in out Var_List_List;
      Tup   :    out Pn.Mappings.Tuple;
      Ok    :    out Boolean;
      Uscore: in     Boolean := False) is
      Factor  : Mult_Type;
      Tup_Vars: Var_List;
      El      : Expr_List;
      G       : Guard;
      Types   : constant Var_Type_Set := (A_Discrete_Cls_Iter_Var => True,
                                          others                  => False);
   begin
      Check_Type(E, HYT.Tuple);
      if E.Tuple_Vars /= null then
	 Tup_Vars := New_Var_List;
         Parse_Iter_Var_List(E.Tuple_Vars, True, Types, Vars, Tup_Vars, Ok);
	 if not Ok then
	    Free_All(Tup_Vars);
	 end if;
      else
         Ok := True;
         Tup_Vars := New_Var_List;
      end if;
      if Ok then
         VLLP.Append(Vars, Tup_Vars);
         Parse_Simple_Tuple(E.Tuple_Tuple, Cd, Vars, Factor, El, Ok,
			    Uscore => Uscore);
         if Ok then
            Parse_Tuple_Guard(E.Tuple_Guard, Vars, G, Ok);
            if Ok then
               Tup := New_Tuple(El, Tup_Vars, Factor, G);
            end if;
         end if;
         VLLP.Delete_Last(Vars);
      end if;
   end;

   procedure Parse_Mapping
     (E     : in     Element;
      Vars  : in out Var_List_List;
      Cd    : in     Dom;
      M     :    out Pn.Mappings.Mapping;
      Ok    :    out Boolean;
      Uscore: in     Boolean := False) is
      Ith_Tuple: Element;
      Tup      : Pn.Mappings.Tuple;
   begin
      Ok := True;
      M := New_Mapping;
      Check_Type(E, HYT.Mapping);
      Check_Type(E.Mapping_Tuples, HYT.List);
      for I in 1..Length(E.Mapping_Tuples.List_Elements) loop
         Ith_Tuple := Ith(E.Mapping_Tuples.List_Elements, I);
         Parse_Tuple(Ith_Tuple, Cd, Vars, Tup, Ok, Uscore => Uscore);
         if Ok then
            Add(M, Tup);
         else
            Free(M);
            return;
         end if;
      end loop;
   end;



   --==========================================================================
   --  functions
   --==========================================================================

   procedure Parse_Param
     (E    : in     Element;
      Param:    out Var;
      Ok   :    out Boolean) is
      C   : Cls;
      Name: Ustring;
   begin
      Check_Type(E, HYT.Param);
      Parse_Name(E.Param_Name, Name);
      Parse_Color_Ref(E.Param_Color, C, Ok);
      if Ok then
         Param := New_Func_Param(Name => Name,
                                 C    => C);
      end if;
   end;

   procedure Parse_Params
     (E     : in     Element;
      Params:    out Var_List;
      Ok    :    out Boolean) is
      Param: Var;
   begin
      Check_Type(E, HYT.List);
      Params := New_Var_List;
      Ok := True;
      for I in 1..Length(E.List_Elements) loop
         Parse_Param(Ith(E.List_Elements, I), Param, Ok);
         if Ok then
            if not Contains(Params, Get_Name(Param)) then
               Append(Params, Param);
            else
               Ok := False;
               Free_All(Params);
               Redefinition(E, To_Ustring("Parameter"), Get_Name(Param));
            end if;
         else
            Free_All(Params);
            Ok := False;
         end if;
         if not Ok then
            exit;
         end if;
      end loop;
   end;

   procedure Parse_Func_Prot
     (E: in Element) is
      Func_Name  : Ustring;
      Ret_Type   : Cls;
      Func_Params: Var_List;
      Vars       : Var_List_List;
      F          : Pn.Funcs.Func;
      Ok         : Boolean;
   begin
      Check_Type(E, HYT.Func_Prot);
      Parse_Name(E.Func_Prot_Name, Func_Name);
      if not Is_Func(N, Func_Name) then
         Parse_Color_Ref(E.Func_Prot_Ret, Ret_Type, Ok);
         if Ok then
            Parse_Params(E.Func_Prot_Params, Func_Params, Ok);
            if Ok then
               F := New_Func(Func_Name);
               Set_Ret_Cls(F, Ret_Type);
               Set_Params(F, Func_Params);
               Add_Func(N, F);
            end if;
         end if;
      else
         Free(F);
         Redefinition(E, To_Ustring("Function"), Func_Name);
      end if;
   end;

   procedure Parse_Func
     (E: in Element) is
      Func_Name  : Ustring;
      Ret_Type   : Cls;
      Func_Params: Var_List;
      Func_Stat  : Stat;
      Vars       : Var_List_List;
      F          : Pn.Funcs.Func;
      Has_Prot   : Boolean;
      Ok         : Boolean;
   begin
      Check_Type(E, HYT.Func);
      Parse_Name(E.Func_Name, Func_Name);
      if ((not Is_Func(N, Func_Name)) or else
          (Is_Incomplete(Get_Func(N, Func_Name))))
      then
         if Is_Func(N, Func_Name) then
            F := Get_Func(N, Func_Name);
            Has_Prot := True;
         else
            Has_Prot := False;
         end if;
         Parse_Color_Ref(E.Func_Return, Ret_Type, Ok);
         if Has_Prot and then Ret_Type /= Get_Ret_Cls(F) then
            Add_Error(E.Func_Return,
                      "Return type conflicts with prototype");
            return;
         end if;
         if Ok then
            Parse_Params(E.Func_Params, Func_Params, Ok);
            if Ok then

               --===
               --  if the function has a prototype then it is already created.
               --  otherwise we must check that the parameters of the body
               --  and the prototype match
               --===
               if not Has_Prot then
                  F := New_Func(Func_Name);
                  Set_Ret_Cls(F, Ret_Type);
                  Set_Params(F, Func_Params);
                  Add_Func(N, F);
               elsif not Equal(Get_Params(F), Func_Params) then
                  Add_Error(E.Func_Params,
                            "Parameters conflict with prototype");
                  return;
               else
                  Func_Params := Get_Params(F);
               end if;

               --===
               --  parse the body of the function.  an imported function does
               --  not have a body
               --===
               Set_Imported(F, E.Func_Imported);
               if not E.Func_Imported then
                  Vars := VLLP.New_Array(Func_Params);
                  Parse_Stat(E.Func_Stat, F, Vars, Func_Stat, Ok);
                  if Ok then
                     Set_Func_Stat(F, Func_Stat);
                  else
                     Delete_Func(N, Func_Name);
                     Free(F);
                  end if;
               end if;
            end if;
         end if;
      else
         Redefinition(E, To_Ustring("Function"), Func_Name);
      end if;
   end;



   --==========================================================================
   --  constants
   --==========================================================================

   procedure Parse_Const
     (E: in Element) is
      Vars : Var_List_List := VLLP.New_Array(Get_Consts(N));
      Ok   : Boolean;
      Name : Ustring;
      C    : Cls;
      Init : Expr;
      Const: Boolean;
   begin
      Parse_Var_Items(E, Vars, Const, Name, C, Init, Ok);
      if Ok then
         Ok := not Is_Const(N, Name);
         if Ok then
            Ok := Const;
            if Ok then
               Ok := Init /= null;
               if Ok then
                  Add_Const(N, New_Net_Const(Name, C, Init));
               else
                  Add_Error(E, "Missing initialization for constant " & Name);
               end if;
            else
               Add_Error(E, "No variable allowed at net level");
            end if;
         else
            Redefinition(E, To_Ustring("Constant"), Name);
         end if;
      end if;
   end;



   --==========================================================================
   --  places
   --==========================================================================

   procedure Parse_Dom
     (E : in     Element;
      D :    out Dom;
      Ok:    out Boolean) is
      C: Cls;
   begin
      Check_Type(E, HYT.List);
      D := New_Dom;
      for I in 1..Length(E.List_Elements) loop
         Parse_Color_Ref(Ith(E.List_Elements, I), C, Ok);
         if not Ok then
            Free(D);
            Ok := False;
            return;
         else
            Append(D, C);
         end if;
      end loop;
      Ok := True;
   end;

   procedure Parse_Capacity
     (E  : in     Element;
      Cap:    out Mult_Type;
      Ok :    out Boolean) is
      Vll: Var_List_List := VLLP.Empty_Array;
      Val: Num_Type;
      C  : Expr;
   begin
      Parse_Static_Num_Expr(E, Vll, C, Val, Ok);
      if Ok then
         Free(C);
         if Val in Mult_Type'Range then
            Ok := True;
            Cap := Mult_Type(Val);
         else
            Add_Error(E, "Incorrect value for capacity.");
            Add_Error(E, "Value must be in range " &
                      To_Ustring(Mult_Type'First) & " .. " &
                      To_Ustring(Mult_Type'Last));
         end if;
      end if;
   end;

   procedure Parse_Place_Type
     (E : in     Element;
      T :    out Pn.Nodes.Places.Place_Type;
      Ok:    out Boolean) is
      Pt: Ustring;
   begin
      Check_Type(E, HYT.Place_Type);
      Parse_Name(E.Place_Type_Type, Pt);
      Ok := True;
      if To_String(Pt) = "process" then
         T := Process_Place;
      elsif To_String(Pt) = "local" then
         T := Local_Place;
      elsif To_String(Pt) = "shared" then
         T := Shared_Place;
      elsif To_String(Pt) = "protected" then
         T := Protected_Place;
      elsif To_String(Pt) = "buffer" then
         T := Buffer_Place;
      elsif To_String(Pt) = "ack" then
         T := Ack_Place;
      else
         Undefined(E, To_Ustring("place type"), Pt);
         Ok := False;
      end if;
   end;

   procedure Parse_Place
     (E: in Element) is
      P         : Pn.Nodes.Places.Place;
      Name      : Ustring;
      D         : Dom;
      M0        : Pn.Mappings.Mapping;
      Attribute : Element;
      Ok        : Boolean := True;
      Vll       : Var_List_List := VLLP.Empty_Array;
      Capacity  : Mult_Type := Pn.Compiler.Config.Get_Capacity;
      T         : Pn.Nodes.Places.Place_Type := Undefined_Place;
      Attributes: array(Place_Attribute) of Boolean := (others => False);
   begin
      Check_Type(E, HYT.Place);
      Parse_Name(E.Place_Name, Name);
      if not Is_Place(N, Name) then
         Parse_Dom(E.Place_Dom, D, Ok);
         if Ok then

            --===
            --  parse all the attributes of the place
            --===
            Check_Type(E.Place_Attributes, HYT.List);
            for I in 1..Length(E.Place_Attributes.List_Elements) loop
               Attribute := Ith(E.Place_Attributes.List_Elements, I);
               case Place_Attribute(Attribute.T) is
                  when HYT.Place_Capacity =>
                     if Attributes(Place_Capacity) then
                        Redefinition(Attribute, To_Ustring("Capacity"),
                                     Null_String);
                        Ok := False;
                     else
                        Parse_Capacity(Attribute.Place_Capacity_Expr,
                                       Capacity, Ok);
                     end if;

                  when HYT.Place_Init =>
                     if Attributes(Place_Init) then
                        Redefinition(Attribute, To_Ustring("Initial marking"),
                                     Null_String);
                        Ok := False;
                     else
                        Parse_Mapping
                          (Attribute.Place_Init_Mapping, Vll, D, M0, Ok);
                        if not Ok then
                           exit;
                        end if;
                     end if;

                  when HYT.Place_Type =>
                     if not Attributes(HYT.Place_Type) then
                        Parse_Place_Type(Attribute, T, Ok);
                     else
                        Redefinition(Attribute, To_Ustring("Place type"),
                                     Null_String);
                        Ok := False;
                     end if;

               end case;
               if not Ok then
                  exit;
               else
                  Attributes(Place_Attribute(Attribute.T)) := True;
               end if;
            end loop;

            --===
            --  everything went fine => we create the place
            --===
            if Ok then
               P := New_Place(Name     => Name,
			      D        => D,
			      T        => T,
			      M0       => M0,
			      Capacity => Capacity);
               Add_Place(N, P);
            else
               Free(D);
            end if;
         end if;
      else
         Redefinition(E, To_Ustring("Place"), Name);
      end if;
   end;



   --==========================================================================
   --  state propositions
   --==========================================================================

   procedure Parse_Proposition
     (E: in  Element) is
      Name: Ustring;
      Ex  : Expr;
      Vll : Var_List_List := VLLP.Empty_Array;
      Ok  : Boolean;
      P   : State_Proposition;
   begin
      Parse_Expr(E.Proposition_Prop, Bool_Cls, Vll, Ex, Ok);
      if Ok then
         Parse_Name(E.Proposition_Name, Name);
	 if not Is_Proposition(N, Name) then
	    P := New_State_Proposition(Name, Ex);
	    Add_Proposition(N, P);
	 else
	    Redefinition(E, To_Ustring("Proposition"), Name);
	 end if;
      end if;
   end;



   --==========================================================================
   --  transitions
   --==========================================================================

   procedure Parse_Arc
     (E     : in Element;
      T     : in Trans;
      A     : in Arc_Type;
      Uscore: in Boolean := False) is
      P   : Pn.Nodes.Places.Place;
      Msg : Ustring;
      Vars: Var_List_List;
      A_T : Pn.Arc_Type;
      M   : Pn.Mappings.Mapping;
      Ok  : Boolean;
   begin
      Check_Type(E, HYT.Arc);
      case A is
         when Input_Arc   => A_T := Pre;
         when Output_Arc  => A_T := Post;
         when Inhibit_Arc => A_T := Inhibit;
      end case;
      Parse_Place_Ref(E.Arc_Place, P, Ok);
      if Ok then
         if Is_Empty(Get_Arc_Label(N, A_T, P, T)) then
            Vars := VLLP.New_Array((Get_Vars(T), Get_Ivars(T), Get_Lvars(T)));
            Parse_Mapping(E.Arc_Mapping, Vars, Get_Dom(P), M, Ok,
			  Uscore => Uscore);
            if Ok then
               Set_Arc_Label(N, A_T, P, T, M);
            end if;
         else
            case A is
	       when Input_Arc   => Msg := To_Ustring("in");
	       when Output_Arc  => Msg := To_Ustring("out");
	       when Inhibit_Arc => Msg := To_Ustring("inhibit");
            end case;
            Redefinition(E, Msg & "(" & Get_Name(P) & "," & Get_Name(T) & ")",
                         Null_String);
         end if;
      end if;
   end;

   procedure Parse_Arcs
     (E     : in Element;
      T     : in Trans;
      A     : in Arc_Type;
      Uscore: in Boolean := False) is
      Ith_Arc: Element;
   begin
      Check_Type(E, HYT.List);
      for I in 1..Length(E.List_Elements) loop
         Ith_Arc := Ith(E.List_Elements, I);
         Parse_Arc(Ith_Arc, T, A, Uscore => Uscore);
      end loop;
   end;

   procedure Parse_Transition_Vars
     (E    : in     Element;
      Vars :    out Var_List;
      Ivars:    out Var_List;
      Lvars:    out Var_List;
      Ok   :    out Boolean) is
      Vll   : VLLP.Array_Type := VLLP.New_Array((1 => Get_Consts(N)));
      Before: Var_List;
      procedure Free_All is
      begin
	 Free_All(Vars);
	 Free(Ivars);
	 Free(Lvars);
      end;
   begin
      Vars  := New_Var_List;
      Ivars := New_Var_List;
      Lvars := New_Var_List;
      Ok    := True;

      --===
      --  parse the variables appearing in the input arcs of the transition
      --===
      Check_Type(E.Transition_Inputs, HYT.List);
      for I in 1..Length(E.Transition_Inputs.List_Elements) loop
         Parse_Arc_Vars(Ith(E.Transition_Inputs.List_Elements, I), Vars, Ok);
         if not Ok then Free_All; return; end if;
      end loop;
      VLLP.Append(Vll, Vars);

      --===
      --  parse the variables appearing in the pick section of the transition
      --===
      Parse_Iter_Var_List(E.Transition_Pick_Vars, False,
                          (A_Discrete_Cls_Iter_Var => True,
                           A_Container_Iter_Var    => True,
                           others                  => False),
                          Vll, Vars, Ok);

      --===
      --  parse the variables appearing in the let section of the transition
      --===
      Before := Copy(Vars);
      Parse_Func_Vars(E.Transition_Let_Vars, Vll, Vars, Ok);
      if not Ok then Free_All; return; end if;
      Lvars := Copy(Vars);
      Difference(Lvars, Before);
      Free(Before);

      --===
      --  parse the variables appearing in the inhibitor arcs of the transition
      --===
      Before := Copy(Vars);
      Check_Type(E.Transition_Inhibits, HYT.List);
      for I in 1..Length(E.Transition_Inhibits.List_Elements) loop
         Parse_Arc_Vars(Ith(E.Transition_Inhibits.List_Elements, I),
			Vars, Ok);
         if not Ok then Free_All; return; end if;
      end loop;
      Ivars := Copy(Vars);
      Difference(Ivars, Before);
      Free(Before);

      --===
      --  remove let and inhibitor variables from the transitio variables
      --===
      Difference(Vars, Ivars);
      Difference(Vars, Lvars);
   end;

   procedure Parse_Transition
     (E: in Element) is
      T         : Trans;
      Name      : Ustring;
      T_Vars    : Var_List;
      T_Ivars   : Var_List;
      T_Lvars   : Var_List;
      Vars      : Var_List_List;
      G         : Expr;
      El        : Expr_List;
      P         : Priority := No_Priority;
      Tg        : Pn.Guards.Guard := True_Guard;
      Desc      : Trans_Desc := New_Empty_Trans_Desc;
      D         : Ustring;
      Safe      : Fuzzy_Boolean := Dont_Know;
      Ok        : Boolean;
      Attribute : Element;
      Vll       : constant Var_List_List := VLLP.Empty_Array;
      Visible   : constant Fuzzy_Boolean := Dont_Know;
      Attributes: array(Transition_Attribute) of Boolean := (others => False);
   begin
      Check_Type(E, HYT.Transition);
      Parse_Name(E.Transition_Name, Name);
      if not Is_Trans(N, Name) then
         Parse_Transition_Vars(E, T_Vars, T_Ivars, T_Lvars, Ok);
         if Ok then

            --===
            --  parse all the attributes of the transition
            --===
            Check_Type(E.Transition_Attributes, HYT.List);
            for I in 1..Length(E.Transition_Attributes.List_Elements) loop
               Attribute := Ith(E.Transition_Attributes.List_Elements, I);
               case Transition_Attribute(Attribute.T) is
                  when HYT.Transition_Guard =>
                     if Attributes(Transition_Guard) then
                        Redefinition(Attribute, To_Ustring("Guard"),
                                     Null_String);
                        Ok := False;
                     else
                        Vars := VLLP.New_Array((T_Vars, T_Ivars, T_Lvars));
                        Parse_Basic_Expr
                          (Attribute.Transition_Guard_Def,
                           Bool_Cls, Vars, G, Ok);
                        if Ok then
                           Tg := New_Guard(G);
                        end if;
                     end if;
                  when HYT.Transition_Safe =>
                     if Attributes(Transition_Safe) then
                        Redefinition(Attribute, To_Ustring("Safe attribute"),
                                     Null_String);
                        Ok := False;
                     else
                        Safe := FTrue;
                     end if;
                  when HYT.Transition_Priority =>
                     if Attributes(Transition_Priority) then
                        Redefinition(Attribute, To_Ustring("Priority"),
                                     Null_String);
                        Ok := False;
                     else
                        Vars := VLLP.New_Array((T_Vars, T_Lvars));
			Parse_Expr(Attribute.Transition_Priority_Def,
				   Int_Cls, Vars, P, Ok);
		     end if;
                  when HYT.Transition_Description =>
                     if Attributes(Transition_Description) then
                        Redefinition(Attribute, To_Ustring("Description"),
                                     Null_String);
                        Ok := False;
                     else
			D :=
			  Attribute.Transition_Description_Desc.String_String;
                        Vars := VLLP.New_Array((T_Vars, T_Lvars));
			Parse_Discrete_Expr_List
			  (Attribute.Transition_Description_Desc_Exprs,
			   Vars, El, Ok);
			if Ok then
			   Desc := New_Trans_Desc(D, El);
			end if;
		     end if;
               end case;
               if not Ok then
                  exit;
               end if;
               Attributes(Attribute.T) := True;
            end loop;

            --===
            --  everything went fine => we create the transition and check it
            --  can be evaluated
            --===
            if Ok then
               T := New_Trans(Name    => Name,
                              Vars    => T_Vars,
                              Ivars   => T_Ivars,
			      Lvars   => T_Lvars,
                              G       => Tg,
			      P       => P,
                              Safe    => Safe,
                              Visible => Visible,
			      Desc    => Desc);
               Add_Trans(N, T);
               Parse_Arcs(E.Transition_Inputs,   T, Input_Arc);
               Parse_Arcs(E.Transition_Outputs,  T, Output_Arc);
               Parse_Arcs(E.Transition_Inhibits, T, Inhibit_Arc);
               if not Is_Evaluable(T, N) then
                  Add_Error(E.Transition_Name,
                            "Transition " & Name &
                            " cannot be evaluated");
                  Delete_Trans(N, T);
                  Free(T);
               end if;
            end if;
         end if;
      else
         Redefinition(E, To_Ustring("Transition"), Name);
      end if;
   end;



   --==========================================================================
   --  net parameters
   --==========================================================================

   procedure Parse_Net_Parameter
     (E: in Element) is
      Name    : Ustring;
      Default : Big_Int;
      Ok      : Boolean;
      V       : Var;
      C       : Expr;
   begin
      Check_Type(E, HYT.Net_Param);
      Parse_Name(E.Net_Param_Name, Name);
      if Is_Parameter(N, Name) then
	 Redefinition(E, To_Ustring("Parameter"), Name);
      else
	 Parse_Number(E.Net_Param_Default, Default, Ok);
	 if Ok then
	    C := New_Num_Const(Num_Type(Default), Int_Cls);
	    V := New_Net_Const(Name, Int_Cls, C);
	    Add_Const(N, V);
	    Add_Parameter(N, Name);
	 end if;
      end if;
   end;

   procedure Parse_Net_Parameters
     (E: in Element) is
   begin
      Check_Type(E, HYT.List);
      for I in 1..Length(E.List_Elements) loop
         Parse_Net_Parameter(Ith(E.List_Elements, I));
      end loop;
   end;



   --==========================================================================
   --  others
   --==========================================================================

   procedure Parse_Number
     (E  : in     Element;
      Num:    out Big_Int;
      Ok :    out Boolean) is
   begin
      Check_Type(E, HYT.Number);
      Num := Big_Int'Value(To_String(E.Number_Number));
      Ok := True;
   exception
      when Constraint_Error =>
         Add_Error(E, "Numerical constant " &
                   E.Number_Number & " is too large");
         Ok := False;
   end;

   procedure Parse_Name
     (E   : in     Element;
      Name:    out Ustring) is
   begin
      Check_Type(E, HYT.Name);
      Name := E.Name_Name;
   end;

   procedure Parse_Color_Ref
     (E : in     Element;
      C :    out Cls;
      Ok:    out Boolean) is
      Cls_Name: Ustring;
   begin
      Check_Type(E, HYT.Name);
      Parse_Name(E, Cls_Name);
      if Is_Cls(N, Cls_Name) then
         C := Get_Cls(N, Cls_Name);
         Ok := True;
      else
         Undefined(E, To_Ustring("Type"), Cls_Name);
         Ok := False;
      end if;
   end;

   procedure Parse_Place_Ref
     (E : in     Element;
      P :    out Pn.Nodes.Places.Place;
      Ok:    out Boolean) is
      P_Name: Ustring;
   begin
      Check_Type(E, HYT.Name);
      Parse_Name(E, P_Name);
      Ok := Is_Place(N, P_Name);
      if Ok then
         P := Get_Place(N, P_Name);
      else
         Undefined(E, To_Ustring("Place"), P_Name);
      end if;
   end;

   procedure Parse_Transition_Ref
     (E : in     Element;
      T :    out Pn.Nodes.Transitions.Trans;
      Ok:    out Boolean) is
      T_Name: Ustring;
   begin
      Check_Type(E, HYT.Name);
      Parse_Name(E, T_Name);
      Ok := Is_Trans(N, T_Name);
      if Ok then
         T := Get_Trans(N, T_Name);
      else
         Undefined(E, To_Ustring("Transition"), T_Name);
      end if;
   end;

   procedure Color_Expr
     (E : in     Element;
      Ex: in     Expr;
      C : in     Cls;
      Ok:    out Boolean) is
      Possible: Cls_Set;
      State   : Coloring_State;
   begin
      Color_Expr(Ex, C, Get_Cls(N), State);
      if Is_Success(State) then
         Ok := True;
      else
         Ok := False;
         case State is
            when Coloring_Ambiguous_Expression =>
               Add_Error(E, "Expression has ambiguous type");
            when Coloring_Failure =>
               Possible := Possible_Colors(Ex, Get_Cls(N));
               Add_Error(E, Get_Name(C) & " expression expected.");
               Add_Error(E, "Expression has type in " &
                         To_String(Possible));
            when Coloring_Success =>
               null;
         end case;
         Free(Possible);
      end if;
   end;

   procedure Parse_Num_Expr
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean) is
      Possible: Cls_Set;
      C       : Cls;
      Msg     : Ustring;
      State   : Coloring_State;
   begin
      Parse_Expr(E, Vars, Ex, Ok);
      if Ok then
         Possible := Possible_Colors(Ex, Get_Cls(N));
         Filter_On_Type(Possible, (A_Num_Cls => True,
                                   others    => False));
         if Card(Possible) > 0 then
            Choose(Possible, C, State);
            Free(Possible);
            case State is
               when Coloring_Ambiguous_Expression =>
                  Add_Error(E, "Expression has ambiguous type");
                  Free(Ex);
                  Ok := False;
               when Coloring_Failure =>
                  Add_Error(E, "Expression has undefined type");
                  Free(Ex);
                  Ok := False;
               when Coloring_Success =>
                  Ok := True;
            end case;
            if Ok then
               Pn.Exprs.Color_Expr(Ex, C, Get_Cls(N), State);
               Ok := Is_Success(State);
            end if;
         else
            Possible := Possible_Colors(Ex, Get_Cls(N));
            Add_Error(E, "Numerical expression expected");
            Add_Error(E, "Expression has type in " &
                      To_String(Possible));
            Free(Ex);
            Free(Possible);
            Ok := False;
         end if;
      end if;
   end;

   procedure Parse_Static_Num_Expr
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Val :    out Num_Type;
      Ok  :    out Boolean) is
      Tmp  : Expr;
      State: Evaluation_State;
   begin
      Parse_Num_Expr(E, Vars, Ex, Ok);
      if Ok and then not Is_Static(Ex) then
         Add_Error(E, "Static expression expected");
         Free(Ex);
         Ok := False;
      end if;
      if Ok then
         Evaluate_Static(E      => Ex,
                         Check  => False,
                         Result => Tmp,
                         State  => State);
         if Is_Success(State) then
            Val := Get_Const(Num_Consts.Num_Const(Tmp));
            Ok := True;
            Free(Tmp);
         else
            Ok := False;
            Add_Error(E, "Error in expression");
            Free(Ex);
         end if;
      end if;
   end;

   procedure Parse_Iter_Var
     (E     : in     Element;
      Static: in     Boolean;
      Types : in     Var_Type_Set;
      Vll   : in out Var_List_List;
      V     :    out Var;
      Ok    :    out Boolean) is
      C        : Cls;
      R        : Range_Spec;
      P        : Pn.Nodes.Places.Place;
      D        : Dom;
      Is_Place : Boolean := False;
      Is_Cls   : Boolean := False;
      Domain   : Ustring;
      Var_Name : Ustring;
      Cls_Name : Ustring;
      Container: Expr;
      Possible : Cls_Set;
      Cont_Cls : Cls;
      Dom      : Iter_Var_Dom;
   begin
      Check_Type(E, HYT.Iter_Variable);

      --===
      --  parse the name of the iteration variable
      --===
      Parse_Name(E.Iter_Variable_Name, Var_Name);

      --===
      --  check if the domain of the iteration variable is a place, a class, or
      --  an expression
      --===
      if E.Iter_Variable_Domain.T = Symbol then
         Parse_Name(E.Iter_Variable_Domain.Sym, Domain);
         Is_Cls := Pn.Nets.Is_Cls(N, Domain);
         Is_Place := Pn.Nets.Is_Place(N, Domain);
      end if;

      if Is_Cls and then Types(A_Discrete_Cls_Iter_Var) then

         --===
         --  a class iteration variable
         --===
         C := Get_Cls(N, Domain);
         Ensure_Discrete(E.Iter_Variable_Domain, C, Ok);
         if Ok then
            if E.Iter_Variable_Range /= null then
               Parse_Range
                 (E.Iter_Variable_Range, C, Static, False, Vll, R, Ok);
            else
               Ok := True;
               R := null;
            end if;
            if Ok then
               Dom := New_Iter_Var_Discrete_Cls_Dom(R);
            end if;
         end if;

      elsif Is_Place and then Types(A_Place_Iter_Var) then

         --===
         --  a place iteration variable
         --===
         P := Get_Place(N, Domain);
         D := Get_Dom(P);
         if E.Iter_Variable_Range /= null then
            Ok := False;
            Add_Error(E.Iter_Variable_Range, "No range allowed here");
            return;
         end if;

         --===
         --  check if the corresponding product type has already been
         --  generated and create it otherwise
         --===
         Cls_Name := Get_Product_Cls_Name(D);
         if not Pn.Nets.Is_Cls(N, Cls_Name) then
            C := New_Product_Cls(Copy(D));
            Add_Cls(N, C);
         else
            C := Get_Cls(N, Cls_Name);
         end if;
         Dom := New_Iter_Var_Place_Dom(P);
         Ok := True;

      elsif Types(A_Container_Iter_Var) then

         --===
         --  a container iteration variable
         --===
         if E.Iter_Variable_Range /= null then
            Ok := False;
            Add_Error(E.Iter_Variable_Range, "No range allowed here");
            return;
         end if;
         Parse_Expr(E.Iter_Variable_Domain, Vll, Container, Ok);
         if not Ok then
            return;
         end if;
         Possible := Possible_Colors(Container, Get_Cls(N));
         Filter_On_Type(Possible, (A_List_Cls => True,
                                   A_Set_Cls  => True,
                                   others     => False));
         if Card(Possible) /= 1 then
            Add_Error
              (E.Iter_Variable_Domain,
               "Invalid domain for iteration variable " & Var_Name);
            Free(Possible);
            Ok := False;
            return;
         end if;
         Cont_Cls := Ith(Possible, 1);
         Color_Expr(E.Iter_Variable_Domain, Container, Cont_Cls, Ok);
         if Ok then
            C := Get_Elements_Cls(Container_Cls(Cont_Cls));
            Dom := New_Iter_Var_Container_Dom(Container);
         end if;

      else
         Add_Error
           (E.Iter_Variable_Domain,
            "Invalid domain for iteration variable " & Var_Name);
         Ok := False;
      end if;
      if Ok then
         V := New_Iter_Var(Var_Name, C, Dom);
      end if;
   end;

   procedure Parse_Iter_Var_List
     (E     : in     Element;
      Static: in     Boolean;
      Types : in     Var_Type_Set;
      Vll   : in out Var_List_List;
      Vars  : in out Var_List;
      Ok    :    out Boolean) is
      Ith: Element;
      V  : Var;
   begin
      Check_Type(E, HYT.List);
      Ok := True;
      for I in 1..Length(E.List_Elements) loop
         Ith := Element_List_Pkg.Ith(E.List_Elements, I);
         VLLP.Append(Vll, Vars);
         Parse_Iter_Var(Ith, Static, Types, Vll, V, Ok);
         VLLP.Delete_Last(Vll);
         if Ok then
            Ok := not Contains(Vars, Get_Name(V));
            Append(Vars, V);
            if not Ok then
               Redefinition(Ith, To_Ustring("Variable"), Get_Name(V));
               return;
            end if;
         else
            return;
         end if;
      end loop;
   end;

   procedure Parse_Iter_Var_List_Names
     (E    : in     Element;
      Names:    out String_Set) is
      Var : Element;
      Name: Ustring;
   begin
      Check_Type(E, HYT.List);
      Names := String_Set_Pkg.Empty_Set;
      for I in 1..Length(E.List_Elements) loop
         Var := Ith(E.List_Elements, I);
         Check_Type(Var, HYT.Iter_Variable);
         Parse_Name(Var.Iter_Variable_Name, Name);
         String_Set_Pkg.Insert(Names, Name);
      end loop;
   end;

   procedure Parse_Range
     (E        : in     Element;
      C        : in     Cls;
      Static   : in     Boolean;
      Num_Range: in     Boolean;
      Vars     : in out Var_List_List;
      R        :    out Range_Spec;
      Ok       :    out Boolean) is
   begin
      case E.T is
         when HYT.Low_High_Range =>
            Parse_Low_High_Range(E, C, Static, Num_Range, Vars, R, Ok);
         when others =>
            pragma Assert(False); null;
      end case;
   end;

   procedure Parse_Low_High_Range
     (E        : in     Element;
      C        : in     Cls;
      Static   : in     Boolean;
      Num_Range: in     Boolean;
      Vars     : in out Var_List_List;
      R        :    out Range_Spec;
      Ok       :    out Boolean) is
      Low : Expr := null;
      High: Expr := null;
      procedure Parse_Expr
        (E : in     Element;
         Ex:    out Expr;
         Ok:    out Boolean) is
         Val  : Expr;
         State: Evaluation_State;
      begin
         if Num_Range then
            Parse_Num_Expr(E, Vars, Ex, Ok);
         else
            Parse_Expr(E, Vars, Ex, Ok);
         end if;
         if Ok and then C /= null then
            Color_Expr(E, Ex, C, Ok);
         end if;
         if Ok and then Static then
            if not Is_Static(Ex) then
               Add_Error(E, "Range cannot be evaluated statically");
               Free(Ex);
               Ok := False;
            elsif C /= null then
               Evaluate_Static(E      => Ex,
                               Check  => False,
                               Result => Val,
                               State  => State);
               if Is_Success(State) then
                  if not Is_Const_Of_Cls(C, Val) then
                     Add_Error
                       (E, "Constant expression does not belong to type " &
                        Get_Name(C));
                     Free(Ex);
                     Ok := False;
                  end if;
               else
                  Add_Error(E, "Error in expression");
                  Free(Ex);
                  Ok := False;
               end if;
               Free(Val);
            end if;
         end if;
      end;
   begin
      --===
      --  get bounds of the range and try to color them in C
      --===
      Parse_Expr(E.Low_High_Range_Low, Low, Ok);
      if Ok then
         Parse_Expr(E.Low_High_Range_High, High, Ok);
         if Ok then
            R := New_Low_High_Range(Low, High);
         end if;
      end if;
      if not Ok then
         if Low  /= null then Free(Low);  end if;
         if High /= null then Free(High); end if;
      end if;
   end;

   procedure Parse_Var_Items
     (E    : in     Element;
      Vars : in out Var_List_List;
      Const:    out Boolean;
      Name :    out Ustring;
      C    :    out Cls;
      Init :    out Expr;
      Ok   :    out Boolean) is
      Val  : Expr;
      State: Evaluation_State;
   begin
      Check_Type(E, HYT.Var_Decl);
      Const := E.Var_Decl_Const;
      Parse_Name(E.Var_Decl_Name, Name);
      Parse_Color_Ref(E.Var_Decl_Color, C, Ok);
      if Ok then
         if E.Var_Decl_Init /= null then
            Parse_Basic_Expr(E.Var_Decl_Init, C, Vars, Init, Ok);
            if Ok then
               if Is_Static(Init) then
                  Evaluate_Static(E      => Init,
                                  Check  => True,
                                  Result => Val,
                                  State  => State);
                  if Is_Success(State) then
                     if not Is_Const_Of_Cls(C, Val) then
                        Add_Error(E, "Invalid initialization for " & Name);
                        Ok := False;
                        Free(Val);
                        Free(Init);
                        return;
                     end if;
                     Free(Val);
                  else
                     Add_Error(E, "Invalid initialization for " & Name);
                     Ok := False;
                     Free(Init);
                     return;
                  end if;
               end if;
            end if;
         else
            Ok := not E.Var_Decl_Const;
            if E.Var_Decl_Const then
               Add_Error(E, "Missing initialization for constant " &
                           Name);
               Ok := False;
            end if;
         end if;
      end if;
   end;

   procedure Undefined
     (E: in Element;
      T: in Ustring;
      N: in Ustring) is
      Msg: Ustring := Null_String;
   begin
      if T /= Null_String then
         Msg := Msg & T & " ";
      end if;
      if N /= Null_String then
         Msg := Msg & N & " ";
      end if;
      Add_Error(E, Msg & "is undefined");
   end;

   procedure Redefinition
     (E   : in Element;
      T   : in Ustring;
      N   : in Ustring;
      Prev: in Element := null) is
      Msg: Ustring := Null_String;
   begin
      if T /= Null_String then
         Msg := Msg & T & " ";
      end if;
      if N /= Null_String then
         Msg := Msg & N & " ";
      end if;
      Msg := Msg & "redefinition";
      if Prev /= null then
	 Msg := Msg & " (previous definition was here: " &
	   Pos_To_String(Prev) & ")";
      end if;
      Add_Error(E, Msg);
   end;

   procedure Ensure_Bool
     (E : in     Element;
      Ex: in     Expr;
      Ok:    out Boolean) is
      Possible: Cls_Set := Possible_Colors(Ex, Get_Cls(N));
   begin
      Ok := Contains(Possible, Bool_Cls);
      if not Ok then
         Add_Error(E, Get_Name(Bool_Cls) & " expression expected");
         Add_Error(E, "Expression has type in " & To_String(Possible));
      end if;
      Free(Possible);
   end;

   procedure Ensure_Num
     (E: in     Element;
      Ex: in     Expr;
      Ok:    out Boolean) is
      Possible: Cls_Set := Possible_Colors(Ex, Get_Cls(N));
   begin
      Filter_On_Type(Possible, (A_Num_Cls => True,
                                others    => False));
      Ok := not Is_Empty(Possible);
      if not Ok then
         Free(Possible);
         Possible := Possible_Colors(Ex, Get_Cls(N));
         Add_Error(E, "Numerical expression expected");
         Add_Error(E, "Expression has type in " & To_String(Possible));
      end if;
      Free(Possible);
   end;

   procedure Ensure_Num
     (E: in     Element;
      C: in     Cls;
      Ok:    out Boolean) is
   begin
      Ok := Get_Type(C) = A_Num_Cls;
      if not Ok then
         Add_Error(E, "Numerical type expected");
      end if;
   end;

   procedure Ensure_Discrete
     (E: in     Element;
      Ex: in     Expr;
      Ok:    out Boolean) is
      function Pred
        (C: in Cls) return Boolean is
      begin
         return Is_Discrete(C);
      end;
      function Filter is new Generic_Filter_On_Type(Pred);
      Possible: Cls_Set := Filter(Possible_Colors(Ex, Get_Cls(N)),
                                   (others => True));
   begin
      Ok := not Is_Empty(Possible);
      if not Ok then
         Free(Possible);
         Possible := Possible_Colors(Ex, Get_Cls(N));
         Add_Error(E, "Discrete expression expected");
         Add_Error(E, "Expression has type in " & To_String(Possible));
      end if;
      Free(Possible);
   end;

   procedure Ensure_Discrete
     (E: in     Element;
      C: in     Cls;
      Ok:    out Boolean) is
   begin
      Ok := Is_Discrete(C);
      if not Ok then
         Add_Error(E, "Discrete type expected");
      end if;
   end;



   --==========================================================================
   --  net
   --==========================================================================

   procedure Parse_Defs
     (E: in Element) is
      Def: Element;
   begin
      Check_Type(E, HYT.List);
      for I in 1..Length(E.List_Elements) loop
         Def := Ith(E.List_Elements, I);
         case Def.T is
            when HYT.Color       => Parse_Color(Def);
            when HYT.Sub_Color   => Parse_Color(Def);
            when HYT.Func        => Parse_Func(Def);
            when HYT.Func_Prot   => Parse_Func_Prot(Def);
            when HYT.Var_Decl    => Parse_Const(Def);
            when HYT.Place       => Parse_Place(Def);
            when HYT.Transition  => Parse_Transition(Def);
            when HYT.Proposition => Parse_Proposition(Def);
	    when others          => pragma Assert(False); null;
         end case;
      end loop;

      --===
      --  check that all functions have a body
      --===
      for I in 1..Funcs_Card(N) loop
         if Is_Incomplete(Ith_Func(N, I)) then
            Add_Error(E, "Missing body for function " &
                      Get_Name(Ith_Func(N, I)));
         end if;
      end loop;
   end;

   procedure Parse_Net
     (E : in     Element;
      Ok:    out Boolean) is
      Net_Name  : Ustring;
      Predefined: constant Cls_Array := Get_Predefined_Cls;
   begin
      Check_Type(E, HYT.Net);
      Parse_Name(E.Net_Name, Net_Name);
      N := New_Net(Name => Net_Name);
      for I in Predefined'Range loop
         Add_Cls(N, Predefined(I));
      end loop;
      Parse_Net_Parameters(E.Net_Params);
      Parse_Defs(E.Net_Defs);
      Ok := True;
   end;

end Helena_Parser.Main;
