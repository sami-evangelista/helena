with
  Pn.Nodes,
  Pn.Vars;

use
  Pn.Nodes,
  Pn.Vars;

package body Pn.Bindings is

   --==========================================================================
   --  Variable binding
   --==========================================================================

   function New_Var_Binding
     (V: in Var;
      E: in Expr) return Var_Binding is
      Result: constant Var_Binding := new Var_Binding_Record;
   begin
      Result.V     := V;
      Result.V_Name := Get_Name(V);
      Result.E     := E;
      return Result;
   end;

   function New_Var_Binding
     (V: in Ustring;
      E: in Expr) return Var_Binding is
      Result: constant Var_Binding := new Var_Binding_Record;
   begin
      Result.V     := null;
      Result.V_Name := V;
      Result.E     := E;
      return Result;
   end;

   procedure Free
     (V: in out Var_Binding) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Var_Binding_Record, Var_Binding);
   begin
      Free(V.E);
      Deallocate(V);
      V := null;
   end;

   function Equal
     (V1: in Var_Binding;
      V2: in Var_Binding) return Boolean is
   begin
      return (V1.V /= null and V1.V = V2.V) or (V1.V_Name = V2.V_Name);
   end;

   function Get_Expr
     (V: in Var_Binding) return Expr is
   begin
      return V.E;
   end;

   function Get_Var
     (V: in Var_Binding) return Var is
   begin
      return V.V;
   end;

   function Get_Va
     (V: in Var_Binding) return Ustring is
   begin
      return V.V_Name;
   end;

   function To_String
     (V: in Var_Binding) return Ustring is
      Result: Ustring;
   begin
      Result := V.V_Name & " = " & To_Helena(V.E);
      return Result;
   end;



   --==========================================================================
   --  Binding
   --==========================================================================

   package VBAP renames Var_Binding_Array_Pkg;

   function New_Binding return Binding is
      Result: constant Binding := new Binding_Record;
   begin
      Result.Bindings := VBAP.Empty_Array;
      return Result;
   end;

   procedure Free
     (B: in out Binding) is
      procedure Free is new VBAP.Generic_Apply(Free);
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Binding_Record, Binding);
   begin
      Free(B.Bindings);
      Deallocate(B);
      B := null;
   end;

   function Copy
     (B: in Binding) return Binding is
      Result: constant Binding := New_Binding;
      Vb    : Var_Binding;
   begin
      Result.Bindings := VBAP.Empty_Array;
      for I in 1..VBAP.Length(B.Bindings) loop
         Vb := VBAP.Ith(B.Bindings, I);
         VBAP.Append(Result.Bindings, New_Var_Binding(Vb.V, Copy(Vb.E)));
      end loop;
      return Result;
   end;

   function Is_Empty
     (B: in Binding) return Boolean is
   begin
      return VBAP."="(B.Bindings, VBAP.Empty_Array);
   end;

   function Is_Bound
     (B: in Binding;
      V: in Var) return Boolean is
      function Is_V
        (Vb: in Var_Binding) return Boolean is
      begin
         return Get_Var(Vb) = V;
      end;
      function Contains is new VBAP.Generic_Exists(Is_V);
   begin
      return Contains(B.Bindings);
   end;

   function Is_Bound
     (B: in Binding;
      V: in Ustring) return Boolean is
      function Is_V
        (Vb: in Var_Binding) return Boolean is
      begin
         return Get_Va(Vb) = V;
      end;
      function Contains is new VBAP.Generic_Exists(Is_V);
   begin
      return Contains(B.Bindings);
   end;

   procedure Bind_Var
     (B: in Binding;
      V: in Var;
      E: in Expr) is
      Found: Boolean := False;
      procedure Action
        (Vb: in out Var_Binding) is
      begin
         if Get_Var(Vb) = V then
            pragma Assert(not Found);
            Found := True;
            Free(Vb.E);
            Vb.E := E;
         end if;
      end;
      procedure Bind is new VBAP.Generic_Apply(Action);
   begin
      Bind(B.Bindings);
      if not Found then
         VBAP.Append(B.Bindings, New_Var_Binding(V, E));
      end if;
   end;

   procedure Bind_Var
     (B: in Binding;
      V: in Ustring;
      E: in Expr) is
      Found: Boolean := False;
      procedure Action
        (Vb: in out Var_Binding) is
      begin
         if Get_Va(Vb) = V then
            pragma Assert(not Found);
            Found := True;
            Free(Vb.E);
            Vb.E := E;
         end if;
      end;
      procedure Bind is new VBAP.Generic_Apply(Action);
   begin
      Bind(B.Bindings);
      if not Found then
         VBAP.Append(B.Bindings, New_Var_Binding(V, E));
      end if;
   end;

   procedure Unbind_Var
     (B: in Binding;
      V: in Var) is
      function Is_V
        (Vb: in Var_Binding) return Boolean is
      begin
         return Vb /= null and then Get_Var(Vb) = V;
      end;
      procedure Delete is new VBAP.Generic_Apply_Subset_And_Delete(Is_V, Free);
   begin
      Delete(B.Bindings);
   end;

   function Get_Var_Binding
     (B: in Binding;
      V: in Var) return Expr is
      function Is_V
        (Vb: in Var_Binding) return Boolean is
      begin
         return Vb /= null and then Get_Var(Vb) = V;
      end;
      function Get_Vb is new VBAP.Generic_Get_First_Satisfying_Element(Is_V);
      Vb: constant Var_Binding := Get_Vb(B.Bindings);
   begin
      pragma Assert(Vb /= null);
      return Vb.E;
   end;

   function Get_Var_Binding
     (B: in Binding;
      V: in Ustring) return Expr is
      function Is_V
        (Vb: in Var_Binding) return Boolean is
      begin
         return Vb /= null and then Get_Va(Vb) = V;
      end;
      function Get_Vb is new VBAP.Generic_Get_First_Satisfying_Element(Is_V);
      Vb: constant Var_Binding := Get_Vb(B.Bindings);
   begin
      pragma Assert(Vb /= null);
      return Vb.E;
   end;

   function To_String
     (B: in Binding) return Ustring is
      function To_String
        (Vb: in Var_Binding) return String is
      begin
         return To_String(To_String(Vb));
      end;
      function To_String is new VBAP.Generic_To_String(", ", "", To_String);
   begin
      return To_Ustring("[" & To_String(B.Bindings) & "]");
   end;

end Pn.Bindings;
