with
  Pn.Compiler,
  Pn.Compiler.State,
  Pn.Classes,
  Pn.Nodes,
  Pn.Vars;

use
  Pn.Compiler,
  Pn.Compiler.State,
  Pn.Classes,
  Pn.Nodes,
  Pn.Vars;

package body Pn.Exprs.Attributes.Places is

   function New_Place_Attribute
     (P        : in Place;
      Attribute: in Attribute_Type;
      C        : in Cls) return Expr is
      Result: Place_Attribute;
   begin
      --===
      --  the attribute must be a place attribute
      --===
      pragma Assert(Attribute = A_Card or Attribute = A_Mult);

      Result := new Place_Attribute_Record;
      Initialize(Result, Attribute, C);
      Result.P := P;
      return Expr(Result);
   end;

   procedure Free
     (E: in out Place_Attribute_Record) is
   begin
      null;
   end;

   function Copy
     (E: in Place_Attribute_Record) return Expr is
   begin
      return New_Place_Attribute(E.P, E.Attribute, E.C);
   end;

   procedure Color_Expr
     (E    : in     Place_Attribute_Record;
      C    : in     Cls;
      Cs   : in     Cls_Set;
      State:    out Coloring_State) is
   begin
      State := Coloring_Success;
   end;

   function Possible_Colors
     (E: in Place_Attribute_Record;
      Cs: in Cls_Set) return Cls_Set is
      Result: Cls_Set;
   begin
      Result := Copy(Cs);
      Filter_On_Type(Result, (A_Num_Cls  => True,
                              others     => False));
      return Result;
   end;

   function Is_Static
     (E: in Place_Attribute_Record) return Boolean is
   begin
      return False;
   end;

   function Is_Basic
     (E: in Place_Attribute_Record) return Boolean is
   begin
      return False;
   end;

   function Get_True_Cls
     (E: in Place_Attribute_Record) return Cls is
      Result: Cls;
   begin
      case E.Attribute is
         when A_Card => Result := Nat_Cls;
         when A_Mult => Result := Nat_Cls;
         when others => pragma Assert(False); null;
      end case;
      return Result;
   end;

   function Can_Overflow
     (E: in Place_Attribute_Record) return Boolean is
   begin
      return False;
   end;

   procedure Evaluate
     (E     : in     Place_Attribute_Record;
      B     : in     Binding;
      Result:    out Expr;
      State:    out Evaluation_State) is
   begin
      pragma Assert(False);
      Result := null;
      State := Evaluation_Failure;
   end;

   function Static_Equal
     (Left: in Place_Attribute_Record;
      Right: in Place_Attribute_Record) return Boolean is
   begin
      return Left.P = Right.P and Left.Attribute = Right.Attribute;
   end;

   function Vars_In
     (E: in Place_Attribute_Record) return Var_List is
   begin
      return New_Var_List;
   end;

   procedure Get_Sub_Exprs
     (E: in Place_Attribute_Record;
      R: in Expr_List) is
   begin
      null;
   end;

   procedure Get_Observed_Places
     (E     : in     Place_Attribute_Record;
      Places: in out String_Set) is
   begin
      String_Set_Pkg.Insert(Places, Get_Name(E.P));
   end;

   function To_Helena
     (E: in Place_Attribute_Record) return Ustring is
   begin
      return Get_Name(E.P) & "'" & To_Helena(E.Attribute);
   end;

   function Compile_Evaluation
     (E: in Place_Attribute_Record;
      M: in Var_Mapping) return Ustring is
      Comp  : constant Ustring := State_Component_Name(E.P);
      Result: Ustring;
   begin
      Result := "prop_state->" & Comp & ".";
      case E.Attribute is
         when A_Card => Result := Result & "card";
         when A_Mult => Result := Result & "mult";
         when others => pragma Assert(False); null;
      end case;
      return Result;
   end;

   function Replace_Var
     (E: in Place_Attribute_Record;
      V: in Var;
      Ne: in Expr) return Expr is
      Result: constant Expr := Copy(E);
   begin
      return Result;
   end;

end Pn.Exprs.Attributes.Places;
