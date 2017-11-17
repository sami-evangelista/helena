with
  Pn.Classes.Containers.Lists,
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Compiler.Config,
  Pn.Exprs.Enum_Consts;

use
  Pn.Classes.Containers.Lists,
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Compiler.Config,
  Pn.Exprs.Enum_Consts;

package body Pn.Exprs.Attributes.Lists is

   function New_List_Attribute
     (L        : in Expr;
      Attribute: in Attribute_Type;
      C        : in Cls) return Expr is
      Result: constant List_Attribute := new List_Attribute_Record;
   begin
      Initialize(Result,Attribute, C);
      Result.L := L;
      return Expr(Result);
   end;

   procedure Free
     (E: in out List_Attribute_Record) is
   begin
      Free(E.L);
   end;

   function Copy
     (E: in List_Attribute_Record) return Expr is
   begin
      return New_List_Attribute(Copy(E.L), E.Attribute, E.C);
   end;

   procedure Color_Expr
     (E    : in     List_Attribute_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Possible: Cls_Set := Possible_Colors(E.L, Cs);
   begin
      Filter_On_Type(Possible, (A_List_Cls => True,
                                others     => False));
      if Card(Possible) > 1 then
         State := Coloring_Ambiguous_Expression;
      elsif Card(Possible) = 0 then
         State := Coloring_Failure;
      else
         State := Coloring_Success;
         Color_Expr(E.L, Ith(Possible, 1), Cs, State);
      end if;
      Free(Possible);
   end;

   function Possible_Colors
     (E: in List_Attribute_Record;
      Cs: in Cls_Set) return Cls_Set is
      Result           : Cls_Set;
      List_Possible    : Cls_Set := Possible_Colors(E.L, Cs);
      Elements_Possible: Cls_Set := New_Cls_Set;
      C                : Cls;
   begin
      Filter_On_Type(List_Possible, (A_List_Cls => True,
                                     others     => False));
      for I in 1..Card(List_Possible) loop
         C := Ith(List_Possible, I);
         Insert(Elements_Possible, Get_Elements_Cls(List_Cls(C)));
      end loop;
      case E.Attribute is

            --===
            --  l'first or l'last =>
            --     accept all the possible element classes for the possible
            --     classes of l
            --===
         when A_First
           |  A_Last  =>
            Result := Copy(Elements_Possible);

            --===
            --  l'prefix or l'suffix =>
            --     accept all the possible classes of l
            --===
         when A_Prefix
           |  A_Suffix =>
            Result := Copy(List_Possible);

            --===
            --  l'first_index, l'last_index =>
            --     accept only the index class of the list class
            --===
         when A_First_Index
           |  A_Last_Index =>
            Result := New_Cls_Set((1 => Get_Index_Cls(List_Cls(C))));

            --===
            --  other attributes are not list attributes
            --===
         when others  => pragma Assert(False); null;
      end case;

      Free(Elements_Possible);
      Free(List_Possible);
      return Result;
   end;

   function Is_Static
     (E: in List_Attribute_Record) return Boolean is
   begin
      return False;
   end;

   function Is_Basic
     (E: in List_Attribute_Record) return Boolean is
   begin
      return Is_Basic(E.L);
   end;

   function Get_True_Cls
     (E: in List_Attribute_Record) return Cls is
      Result: Cls;
   begin
      case E.Attribute is
         when A_Prefix
           |  A_Suffix     => Result := E.L.C;
         when A_First
           |  A_Last       => Result := Get_Elements_Cls(List_Cls(E.L.C));
         when A_First_Index
           |  A_Last_Index => Result := Get_Index_Cls(List_Cls(E.L.C));
         when others  => pragma Assert(False); null;
      end case;
      return Result;
   end;

   function Can_Overflow
     (E: in List_Attribute_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     List_Attribute_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
   begin
      pragma Assert(False);
      Result := null;
      State := Evaluation_Failure;
   end;

   function Static_Equal
     (Left: in List_Attribute_Record;
      Right: in List_Attribute_Record) return Boolean is
   begin
      return Left.Attribute = Left.Attribute and Static_Equal(Left.L, Right.L);
   end;

   function Vars_In
     (E: in List_Attribute_Record) return Var_List is
   begin
      return Vars_In(E.L);
   end;

   procedure Get_Sub_Exprs
     (E: in List_Attribute_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.L, R);
   end;

   procedure Get_Observed_Places
     (E     : in     List_Attribute_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.L, Places);
   end;

   function To_Helena
     (E: in List_Attribute_Record) return Ustring is
   begin
      return To_Helena(E.L) & "'" & To_Helena(E.Attribute);
   end;

   function Compile_Evaluation
     (E: in List_Attribute_Record;
      M: in Var_Mapping) return Ustring is
      Result         : Ustring;
      L              : constant Ustring := Compile_Evaluation(E.L, M);
      C              : constant List_Cls := List_Cls(Get_Cls(E.L));
      Cap            : constant Num_Type := Get_Capacity_Value(C);
      First_Index    : Expr := Low_Value(Get_Index_Cls(C));
      First_Index_Str: constant Ustring := Compile_Evaluation(First_Index);
   begin
      Free(First_Index);
      case E.Attribute is
         when A_Prefix =>
            Result := Cls_Prefix_Func(Cls(C)) & "(" & L & ")";
         when A_Suffix =>
            Result := Cls_Suffix_Func(Cls(C)) & "(" & L & ")";
         when A_First =>
            if Get_Run_Time_Checks then
               Result := "(" & L & ".length > 0 || " &
                 "context_error(""getting first element of an empty list"")) ?"
                 & "(" & L & ".items[0]): (" & L & ".items[0])";
            else
               Result := L & ".items[0]";
            end if;
         when A_Last =>
            if Get_Run_Time_Checks then
               Result := "(" & L & ".length > 0 || " &
                 "context_error(""getting last element of an empty list"")) ?" &
                 "(" & L & ".items[" & L & ".length - 1]): " &
                 "(" & L & ".items[0])";
            else
               Result := L & ".items[" & L & ".length - 1]";
            end if;
         when A_First_Index =>
            Result := First_Index_Str;
         when A_Last_Index =>
            if Get_Run_Time_Checks then
               Result := "(" & L & ".length > 0 || " &
                 "context_error(""getting last index of an empty list"")) ?" &
                 "(" & L & ".length - 1 - " & First_Index_Str & "): " &
                 "(" & First_Index_Str & ")";
            else
               Result := L & ".length - 1 - " & First_Index_Str;
            end if;
         when others =>
            pragma Assert(False);
            null;
      end case;
      return Result;
   end;

   function Replace_Var
     (E: in List_Attribute_Record;
      V: in Var;
      Ne: in Expr) return Expr is
   begin
      return New_List_Attribute(Replace_Var(E.L, V, Ne), E.Attribute, E.C);
   end;

end Pn.Exprs.Attributes.Lists;
