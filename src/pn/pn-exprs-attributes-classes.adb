with
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Num_Consts,
  Pn.Classes,
  Pn.Vars;

use
  Pn.Compiler.Names,
  Pn.Exprs.Enum_Consts,
  Pn.Exprs.Num_Consts,
  Pn.Classes,
  Pn.Vars;

package body Pn.Exprs.Attributes.Classes is

   function New_Cls_Attribute
     (Cl       : in Cls;
      Attribute: in Attribute_Type;
      C        : in Cls) return Expr is
      Result: Cls_Attribute;
      Cl_Card: Card_Type;
      State  : Count_State;
      Cond   : Boolean;
   begin
      --===
      --  - the attribute must be a class attribute
      --  - if the attribute is "first" or "last" the color must be a discrete
      --    one
      --  - if the attribute is "card" the color must be a discrete one and the
      --    color must be countable
      --===
      case Attribute is
         when A_First
           |  A_Last =>
            Cond := Is_Discrete(Cl);
         when A_Card =>
            Card(Cl, Cl_Card, State);
            Cond := Is_Discrete(Cl) and then Is_Success(State);
         when others =>
            Cond := False;
      end case;
      pragma Assert(Cond);

      Result := new Cls_Attribute_Record;
      Initialize(Result, Attribute, C);
      Result.Cl := Cl;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Cls_Attribute_Record) is
   begin
      null;
   end;

   function Copy
     (E: in Cls_Attribute_Record) return Expr is
      Result: Expr;
   begin
      Result := New_Cls_Attribute(E.Cl, E.Attribute, E.C);
      return Result;
   end;

   procedure Color_Expr
     (E    : in     Cls_Attribute_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
   begin
      State := Coloring_Success;
   end;

   function Possible_Colors
     (E: in Cls_Attribute_Record;
      Cs: in Cls_Set) return Cls_Set is
      Result: Cls_Set;
   begin
      case E.Attribute is
         when A_First
           |  A_Last =>
            Result := New_Cls_Set;
            Insert(Result, E.Cl);
         when A_Card =>
            Result := Filter_On_Type(Cs, (A_Num_Cls => True,
                                          others    => False));
         when others =>
            pragma Assert(False);
            null;
      end case;
      return Result;
   end;

   function Is_Static
     (E: in Cls_Attribute_Record) return Boolean is
   begin
      return True;
   end;

   function Is_Basic
     (E: in Cls_Attribute_Record) return Boolean is
   begin
      return True;
   end;

   function Get_True_Cls
     (E: in Cls_Attribute_Record) return Cls is
      Result: Cls;
   begin
      case E.Attribute is
         when A_First
           |  A_Last =>
            Result := E.Cl;
         when A_Card =>
            Result := E.C;
         when others =>
            pragma Assert(False);
            null;
      end case;
      return Result;
   end;

   function Can_Overflow
     (E: in Cls_Attribute_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Cls_Attribute_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
      Cl_Card: Card_Type;
      Count  : Count_State;
   begin
      case E.Attribute is
         when A_First =>
            Result := Low_Value(E.Cl);
         when A_Last  =>
            Result := High_Value(E.Cl);
         when A_Card  =>
            Card(E.Cl, Cl_Card, Count);
            pragma Assert(Is_Success(Count));
            Result := New_Num_Const(Num_Type(Cl_Card), E.Cl);
         when others =>
            pragma Assert(False);
            null;
      end case;
      State := Evaluation_Success;
   end;

   function Static_Equal
     (Left: in Cls_Attribute_Record;
      Right: in Cls_Attribute_Record) return Boolean is
      Result: Boolean;
   begin
      Result := (Left.Cl = Right.Cl) and (Left.Attribute = Right.Attribute);
      return Result;
   end;

   function Vars_In
     (E: in Cls_Attribute_Record) return Var_List is
      Result: constant Var_List := New_Var_List;
   begin
      return Result;
   end;

   procedure Get_Sub_Exprs
     (E: in Cls_Attribute_Record;
      R: in Expr_List) is
   begin
      null;
   end;

   procedure Get_Observed_Places
     (E     : in     Cls_Attribute_Record;
      Places: in out String_Set) is
   begin
      null;
   end;

   function To_Helena
     (E: in Cls_Attribute_Record) return Ustring is
   begin
      return Get_Name(E.Cl) & "'" & To_Helena(E.Attribute);
   end;

   function Compile_Evaluation
     (E: in Cls_Attribute_Record;
      M: in Var_Mapping) return Ustring is
      Result: Ustring := Null_String;
   begin
      case E.Attribute is
         when A_First => Result := Cls_First_Const_Name(E.Cl);
         when A_Last  => Result := Cls_Last_Const_Name(E.Cl);
         when A_Card  => Result := Cls_Card_Const_Name(E.Cl);
         when others  => pragma Assert(False); null;
      end case;
      return Result;
   end;

   function Replace_Var
     (E: in Cls_Attribute_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: constant Expr := Copy(E);
   begin
      return Result;
   end;

end Pn.Exprs.Attributes.Classes;
