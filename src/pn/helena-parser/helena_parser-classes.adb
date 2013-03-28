with
  Pn.Classes,
  Pn.Classes.Discretes.Enums.Roots,
  Pn.Classes.Discretes.Enums.Subs,
  Pn.Classes.Discretes.Nums,
  Pn.Classes.Discretes.Nums.Mods,
  Pn.Classes.Discretes.Nums.Ranges,
  Pn.Classes.Discretes.Nums.Subs,
  Pn.Classes.Containers.Lists,
  Pn.Classes.Containers.Sets,
  Pn.Classes.Vectors,
  Pn.Exprs.Num_Consts,
  Helena_Parser.Errors,
  Helena_Parser.Main;

use
  Pn.Classes,
  Pn.Classes.Discretes.Enums.Roots,
  Pn.Classes.Discretes.Enums.Subs,
  Pn.Classes.Discretes.Nums,
  Pn.Classes.Discretes.Nums.Mods,
  Pn.Classes.Discretes.Nums.Ranges,
  Pn.Classes.Discretes.Nums.Subs,
  Pn.Classes.Containers.Lists,
  Pn.Classes.Containers.Sets,
  Pn.Classes.Vectors,
  Pn.Exprs.Num_Consts,
  Helena_Parser.Errors,
  Helena_Parser.Main;

package body Helena_Parser.Classes is

   use Element_List_Pkg;
   package VLLP renames Var_List_List_Pkg;

   procedure Parse_Range_Color
     (E   : in     Element;
      Name: in     Ustring;
      C   :    out Cls;
      Ok  :    out Boolean) is
      Vll: Var_List_List := VLLP.Empty_Array;
      R  : Range_Spec;
   begin
      Check_Type(E, Range_Color);

      --===
      --  parse the range which must be strictly positive
      --===
      Parse_Range(E.Range_Color_Range, null, True, True, Vll, R, Ok);
      if not Ok then
         return;
      end if;
      if not Is_Positive(R) then
         Add_Error(E.Range_Color_Range,
                      "Invalid definition for type " & Name);
         Add_Error(E.Range_Color_Range,
                      "positive range expected");
         Ok := False;
      end if;

      C := New_Range_Cls(Name, R);
      Ok := True;
   end;

   procedure Parse_Mod_Color
     (E   : in     Element;
      Name: in     Ustring;
      C   :    out Cls;
      Ok  :    out Boolean) is
      Mod_Val: Expr;
      Vll    : Var_List_List := VLLP.Empty_Array;
      Const  : Expr;
      State  : Evaluation_State;
      N      : Num_Type;
   begin
      Check_Type(E, Mod_Color);

      --===
      --  parse the modulo value which must be numerical, statically evaluable
      --  and strictly positive
      --===
      Parse_Static_Num_Expr(E.Mod_Val, Vll, Mod_Val, N, Ok);
      if not Ok then
         return;
      end if;
      Evaluate_Static(E      => Mod_Val,
                      Check  => False,
                      Result => Const,
                      State  => State);
      if not Is_Success(State) then
         Ok := False;
         Add_Error(E, "Error in expression");
         Free(Mod_Val);
         return;
      end if;
      if not (Get_Const(Num_Consts.Num_Const(Const)) > 0) then
         Ok := False;
         Add_Error(E, "Positive value expected");
         Free(Const);
         Free(Mod_Val);
         return;
      end if;
      Free(Const);

      C := New_Mod_Cls(Name, Mod_Val);
      Ok := True;
   end;

   procedure Parse_Enum_Color
     (E: in     Element;
      Name: in     Ustring;
      C:    out Cls;
      Ok:    out Boolean) is
      Const  : Element;
      Enum_Const: Ustring;
   begin
      Ok := True;
      Check_Type(E, Enum_Color);
      Check_Type(E.Enum_Values, Helena_Yacc_Tokens.List);
      declare
         Values: String_Array(1..Length(E.Enum_Values.List_Elements));
      begin
         for I in 1..Length(E.Enum_Values.List_Elements) loop
            Const := Ith(E.Enum_Values.List_Elements, I);
            Parse_Name(Const, Enum_Const);
            for J in 1..I-1 loop
               if Enum_Const = Values(J) then
                  Redefinition(Const, Null_String, Enum_Const);
                  Ok := False;
                  return;
               end if;
            end loop;
            Values(I) := Enum_Const;
         end loop;
         C := New_Enum_Cls(Name, Values);
      end;
   end;

   procedure Parse_Index
     (E   : in     Element;
      Name: in     Ustring;
      D   :    out Dom;
      Ok  :    out Boolean) is
      C         : Cls;
      Cc        : Card_Type;
      Ith_Index : Element;
      Index_Size: Natural := 1;
      State     : Count_State;
      procedure Index_Too_Large is
      begin
         Add_Error(E,
                      "Index size of type " & Name & " is too large.");
         Add_Error(E,
                      "Maximum allowed size is " & Max_Vector_Index_Card);
         Ok := False;
         Free(D);
      end;
   begin
      D := New_Dom;
      Check_Type(E, Helena_Yacc_Tokens.List);
      for I in 1..Length(E.List_Elements) loop
         Ith_Index := Ith(E.List_Elements, I);
         Parse_Color_Ref(Ith_Index, C, Ok);
         if Ok then
            Ensure_Discrete(Ith_Index, C, Ok);
            if not Ok then
               Free(D);
               return;
            end if;
            Card(C, Cc, State);
            if not Is_Success(State) then
               Index_Too_Large;
               return;
            elsif Cc <= Card_Type(Max_Vector_Index_Card) then
               Index_Size := Index_Size * Natural(Cc);
               if Index_Size <= Max_Vector_Index_Card then
                  Append(D, C);
               else
                  Index_Too_Large;
                  return;
               end if;
            else
               Index_Too_Large;
               return;
            end if;
         else
            Free(D);
            return;
         end if;
      end loop;
      Ok := True;
   end;

   procedure Parse_Vector_Color
     (E   : in     Element;
      Name: in     Ustring;
      C   :    out Cls;
      Ok  :    out Boolean) is
      Elements: Cls;
      Index   : Dom;
   begin
      Parse_Color_Ref(E.Vector_Elements, Elements, Ok);
      if Ok then
         Parse_Index(E.Vector_Indexes, Name, Index, Ok);
         if Ok then
            C := New_Vector_Cls(Name     => Name,
                                Index    => Index,
                                Elements => Elements);
         end if;
      end if;
   end;

   procedure Parse_Struct_Color
     (E   : in     Element;
      Name: in     Ustring;
      C   :    out Cls;
      Ok  :    out Boolean) is
      procedure Parse_Component
        (E   : in     Element;
         Comp:    out Struct_Comp;
         Ok  :    out Boolean) is
         Comp_Color: Cls;
         Comp_Name : Ustring;
         Ok_Cls    : Boolean;
      begin
         Check_Type(E, Helena_Yacc_Tokens.Component);
         Parse_Color_Ref(E.Component_Color, Comp_Color, Ok_Cls);
         if Ok_Cls then
            Parse_Name(E.Component_Name, Comp_Name);
            Comp := New_Struct_Comp(Comp_Name, Comp_Color);
            Ok := True;
         else
            Ok := False;
         end if;
      end;
      procedure Parse_Components
        (E    : in     Element;
         Comps:    out Struct_Comp_List;
         Ok   :    out Boolean) is
         Comp: Struct_Comp;
      begin
         Check_Type(E, Helena_Yacc_Tokens.List);
         Comps := New_Struct_Comp_List;
         for I in 1..Length(E.List_Elements) loop
            Parse_Component(Ith(E.List_Elements, I), Comp, Ok);
            if Ok then
               if not Contains(Comps, Get_Name(Comp)) then
                  Append(Comps, Comp);
               else
                  Redefinition(E, To_Ustring("Component"), Get_Name(Comp));
                  Ok := False;
               end if;
            end if;
            if not Ok then
               Free(Comps);
               return;
            end if;
         end loop;
         Ok := True;
      end;
      Ok_Components: Boolean;
      Components: Struct_Comp_List;
   begin
      Parse_Components(E.Struct_Components, Components, Ok_Components);
      if Ok_Components then
         C := New_Struct_Cls(Name       => Name,
                             Components => Components);
         Ok := True;
      else
         Ok := False;
      end if;
   end;

   procedure Parse_List_Color
     (E   : in     Element;
      Name: in     Ustring;
      C   :    out Cls;
      Ok  :    out Boolean) is
      Elements_Cls: Cls;
      Index_Cls   : Cls;
      Vll         : Var_List_List := VLLP.Empty_Array;
      Capacity    : Expr;
      N           : Num_Type;
   begin
      Check_Type(E, List_Color);

      --===
      --  parse the index which must be a discrete color
      --===
      Parse_Color_Ref(E.List_Color_Index, Index_Cls, Ok);
      if not Ok then
         return;
      end if;
      Ensure_Discrete(E.List_Color_Index, Index_Cls, Ok);
      if not Ok then
         return;
      end if;

      --===
      --  parse the class of the elements of the list color
      --===
      Parse_Color_Ref(E.List_Color_Elements, Elements_Cls, Ok);
      if not Ok then
         return;
      end if;

      --===
      --  parse the capacity which must be a numerical expression, statically
      --  evaluable, positive and less than the maximal capacity of a list type
      --===
      Parse_Static_Num_Expr(E.List_Color_Capacity, Vll, Capacity, N, Ok);
      if not Ok then
         return;
      end if;
      if N <= 0 then
         Add_Error(E, "Invalid capacity for type " & Name & ".");
         Add_Error(E, "Positive value expected");
         Ok := False;
         Free(Capacity);
         return;
      end if;
      if N > Pn.Max_Container_Capacity then
         Add_Error(E, "Capacity of type " & Name & " is too large.");
         Add_Error(E, "Maximum allowed capacity is " &
                      Max_Container_Capacity);
         Ok := False;
         Free(Capacity);
         return;
      end if;

      C := New_List_Cls(Name     => Name,
                         Index    => Index_Cls,
                         Elements => Elements_Cls,
                         Capacity => Capacity);
      Ok := True;
   end;

   procedure Parse_Set_Color
     (E   : in     Element;
      Name: in     Ustring;
      C   :    out Cls;
      Ok  :    out Boolean) is
      Elements_Cls: Cls;
      Vll         : Var_List_List := VLLP.Empty_Array;
      Capacity    : Expr;
      N           : Num_Type;
   begin
      Check_Type(E, Set_Color);

      --===
      --  parse the class of the elements of the set color
      --===
      Parse_Color_Ref(E.Set_Color_Elements, Elements_Cls, Ok);
      if not Ok then
         return;
      end if;

      --===
      --  parse the capacity which must be a numerical expression, statically
      --  evaluable, positive and less than the maximal capacity of a list type
      --===
      Parse_Static_Num_Expr(E.Set_Color_Capacity, Vll, Capacity, N, Ok);
      if not Ok then
         return;
      end if;
      if N <= 0 then
         Add_Error(E, "Invalid capacity for type " & Name & ".");
         Add_Error(E, "Positive value expected");
         Ok := False;
         Free(Capacity);
         return;
      end if;
      if N > Pn.Max_Container_Capacity then
         Add_Error(E, "Capacity of type " & Name & " is too large.");
         Add_Error(E, "Maximum allowed capacity is " &
                      Max_Container_Capacity);
         Ok := False;
         Free(Capacity);
         return;
      end if;

      C := New_Set_Cls(Name     => Name,
                        Elements => Elements_Cls,
                        Capacity => Capacity);
      Ok := True;
   end;

   procedure Parse_Sub_Color
     (E : in     Element;
      C :    out Cls;
      Ok:    out Boolean) is
      Name      : Ustring;
      Parent    : Cls;
      Constraint: Range_Spec := null;
      Vll       : Var_List_List := VLLP.Empty_Array;
   begin
      Check_Type(E, Sub_Color);
      Parse_Name(E.Sub_Cls_Name, Name);
      Parse_Color_Ref(E.Sub_Cls_Parent, Parent, Ok);
      if not Ok then
         return;
      end if;
      if not Is_Discrete(Parent) then
         Add_Error
           (E.Sub_Cls_Constraint,
            "Invalid parent for subtype " & Name);
         Add_Error
           (E.Sub_Cls_Constraint,
            "discrete type expected");
         Ok := False;
         return;
      end if;
      if E.Sub_Cls_Constraint = null then
         Ok      := True;
         Constraint := null;
      else
         Parse_Range(E.Sub_Cls_Constraint, Parent, True, False, Vll,
                     Constraint, Ok);
         if Ok and then not Is_Positive(Constraint) then
            Add_Error
              (E.Sub_Cls_Constraint,
               "Invalid definition for subtype " & Name);
            Add_Error
              (E.Sub_Cls_Constraint,
               "positive range expected");
            Ok := False;
            Free(Constraint);
         end if;
         if not Ok then
            return;
         end if;
      end if;
      case Discrete_Cls_Type(Get_Type(Parent)) is
         when A_Num_Cls  => C := New_Num_Sub_Cls (Name, Parent, Constraint);
         when A_Enum_Cls => C := New_Enum_Sub_Cls(Name, Parent, Constraint);
      end case;
   end;

   procedure Parse_Color
     (E: in Element) is
      Name: Ustring;
      C   : Cls;
      Ok  : Boolean;
   begin
      if E.T = Color then
         Parse_Name(E.Cls_Name, Name);
         case E.Cls_Def.T is
            when Range_Color    => Parse_Range_Color(E.Cls_Def, Name, C, Ok);
            when Mod_Color      => Parse_Mod_Color(E.Cls_Def, Name, C, Ok);
            when Enum_Color     => Parse_Enum_Color(E.Cls_Def, Name, C, Ok);
            when Vector_Color   => Parse_Vector_Color(E.Cls_Def, Name, C, Ok);
            when Struct_Color   => Parse_Struct_Color(E.Cls_Def, Name, C, Ok);
            when List_Color     => Parse_List_Color(E.Cls_Def, Name, C, Ok);
            when Set_Color      => Parse_Set_Color(E.Cls_Def, Name, C, Ok);
            when others         => pragma Assert(False); null;
         end case;
      elsif E.T = Sub_Color then
         Parse_Sub_Color(E, C, Ok);
         if Ok then
            Name := Get_Name(C);
         end if;
      else
         pragma Assert(False); null;
      end if;
      if Ok then
         if not Is_Cls(N, Name) then
            if not (Basic_Elements_Size(C) > Max_Cls_Basic_Elements) then
               Add_Cls(N, C);
            else
               Add_Error(E, "Too many elements in type " & Name);
               Free(C);
            end if;
         else
            Redefinition(E, To_Ustring("Type"), Name);
         end if;
      end if;
   end;

end Helena_Parser.Classes;
