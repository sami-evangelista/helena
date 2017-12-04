with
  Pn.Classes,
  Pn.Classes.Containers,
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts;

use
  Pn.Classes,
  Pn.Classes.Containers,
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts;

package body Pn.Exprs.Attributes.Containers is

   function New_Container_Attribute
     (Cont     : in Expr;
      Attribute: in Attribute_Type;
      C        : in Cls) return Expr is
      Result: constant Container_Attribute := new Container_Attribute_Record;
   begin
      Initialize(Result,Attribute, C);
      Result.Cont := Cont;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Container_Attribute_Record) is
   begin
      Free(E.Cont);
   end;

   function Copy
     (E: in Container_Attribute_Record) return Expr is
   begin
      return New_Container_Attribute(Copy(E.Cont), E.Attribute, E.C);
   end;

   procedure Color_Expr
     (E    : in     Container_Attribute_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
      Possible: Cls_Set := Possible_Colors(E.Cont, Cs);
   begin
      Filter_On_Type(Possible, (A_List_Cls => True,
                                A_Set_Cls  => True,
                                others     => False));
      if Card(Possible) > 1 then
         State := Coloring_Ambiguous_Expression;
      elsif Card(Possible) = 0 then
         State := Coloring_Failure;
      else
         State := Coloring_Success;
         Color_Expr(E.Cont, Ith(Possible, 1), Cs, State);
      end if;
      Free(Possible);
   end;

   function Possible_Colors
     (E: in Container_Attribute_Record;
      Cs: in Cls_Set) return Cls_Set is
      Result           : Cls_Set;
      Cont_Possible    : Cls_Set := Possible_Colors(E.Cont, Cs);
      Elements_Possible: Cls_Set := New_Cls_Set;
      C                : Cls;
   begin
      Filter_On_Type(Cont_Possible, (A_List_Cls => True,
                                     A_Set_Cls  => True,
                                     others     => False));
      for I in 1..Card(Cont_Possible) loop
         C := Ith(Cont_Possible, I);
         Insert(Elements_Possible, Get_Elements_Cls(Container_Cls(C)));
      end loop;
      case E.Attribute is

            --===
            --  c'full or c'empty=>
            --     accept only the boolean class
            --===
         when A_Full
           |  A_Empty =>
            Result := New_Cls_Set((1 => Bool_Cls));

            --===
            --  c'capacity, or c'space =>
            --     accept any numerical color class
            --===
         when A_Capacity
           |  A_Size
           |  A_Space =>
            Result := Filter_On_Type(Cs, (A_Num_Cls => True,
                                          others    => False));

            --===
            --  other attributes are not container attributes
            --===
         when others  => pragma Assert(False); null;
      end case;

      Free(Elements_Possible);
      Free(Cont_Possible);
      return Result;
   end;

   function Is_Static
     (E: in Container_Attribute_Record) return Boolean is
   begin
      return False;
   end;

   function Is_Basic
     (E: in Container_Attribute_Record) return Boolean is
   begin
      return Is_Basic(E.Cont);
   end;

   function Get_True_Cls
     (E: in Container_Attribute_Record) return Cls is
      Result: Cls;
   begin
      case E.Attribute is
         when A_Capacity
           |  A_Size
           |  A_Space => Result := Nat_Cls;
         when A_Full
           |  A_Empty => Result := Bool_Cls;
         when others  => pragma Assert(False); null;
      end case;
      return Result;
   end;

   function Can_Overflow
     (E: in Container_Attribute_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Container_Attribute_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
   begin
      pragma Assert(False);
      Result := null;
      State := Evaluation_Failure;
   end;

   function Static_Equal
     (Left: in Container_Attribute_Record;
      Right: in Container_Attribute_Record) return Boolean is
   begin
      return
        Left.Attribute = Left.Attribute and
        Static_Equal(Left.Cont, Right.Cont);
   end;

   function Vars_In
     (E: in Container_Attribute_Record) return Var_List is
   begin
      return Vars_In(E.Cont);
   end;

   procedure Get_Sub_Exprs
     (E: in Container_Attribute_Record;
      R: in Expr_List) is
   begin
      Get_Sub_Exprs(E.Cont, R);
   end;

   procedure Get_Observed_Places
     (E     : in     Container_Attribute_Record;
      Places: in out String_Set) is
   begin
      Get_Observed_Places(E.Cont, Places);
   end;

   function To_Helena
     (E: in Container_Attribute_Record) return Ustring is
   begin
      return To_Helena(E.Cont) & "'" & To_Helena(E.Attribute);
   end;

   function Compile_Evaluation
     (E: in Container_Attribute_Record;
      M: in Var_Mapping) return Ustring is
      Result: Ustring;
      Cont  : constant Ustring := Compile_Evaluation(E.Cont, M);
      C     : constant Container_Cls := Container_Cls(Get_Cls(E.Cont));
      Cap   : constant Num_Type := Get_Capacity_Value(C);
   begin
      case E.Attribute is
         when A_Capacity => Result := Cap & "";
         when A_Full     => Result := Cap & " == " & Cont & ".length";
         when A_Space    => Result := Cap & " - " & Cont & ".length";
         when A_Empty    => Result := "0 == " & Cont & ".length";
         when A_Size     => Result := Cont & ".length";
         when others     => pragma Assert(False); null;
      end case;
      return Result;
   end;

   function Replace_Var
     (E: in Container_Attribute_Record;
      V: in Var;
      Ne: in Expr) return Expr is
   begin
      return
        New_Container_Attribute(Replace_Var(E.Cont, V, Ne), E.Attribute, E.C);
   end;

end Pn.Exprs.Attributes.Containers;
