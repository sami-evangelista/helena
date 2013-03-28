with Pn.Exprs;
use Pn.Exprs;

package body Pn is

   --==========================================================================
   --  operators on fuzzy booleans
   --==========================================================================

   function "or"
     (B: in Fuzzy_Boolean;
      C: in Fuzzy_Boolean) return Fuzzy_Boolean is
      Result: Fuzzy_Boolean;
   begin
      if B = FTrue or C = FTrue then
         Result := FTrue;
      elsif B = FFalse and C = FFalse then
         Result := FFalse;
      else
         Result := Dont_Know;
      end if;
      return Result;
   end;

   function "and"
     (B: in Fuzzy_Boolean;
      C: in Fuzzy_Boolean) return Fuzzy_Boolean is
      Result: Fuzzy_Boolean;
   begin
      if B = FFalse or C = FFalse then
         Result := FFalse;
      elsif B = FTrue and C = FTrue then
         Result := FTrue;
      else
         Result := Dont_Know;
      end if;
      return Result;
   end;



   --==========================================================================
   --  type of color class
   --==========================================================================

   function Card
     (C: in Cls_Type_Set) return Natural is
      Result: Natural := 0;
   begin
      for I in Cls_Type loop
         if C(I) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end;



   --==========================================================================
   --  result of an expression evaluation
   --==========================================================================

   function Is_Success
     (R: in Evaluation_State) return Boolean is
   begin
      return R = Evaluation_Success;
   end;



   --==========================================================================
   --  result of a coloring (typing of an expression)
   --==========================================================================

   function Is_Success
     (C: in Coloring_State) return Boolean is
   begin
      return C = Coloring_Success;
   end;



   --==========================================================================
   --  result of a count, e.g., counting the cardinal of a color class
   --==========================================================================

   function Is_Success
     (C: in Count_State) return Boolean is
   begin
      return C = Count_Success;
   end;



   --==========================================================================
   --  color classes
   --==========================================================================

   function Get_Root_Cls
     (C: in Cls_Record) return Cls is
   begin
      --===
      --  if function is not overloaded then I am the root class
      --===
      return C.Me;
   end;

   function Is_Sub_Cls
     (C     : in     Cls_Record;
      Parent: access Cls_Record'Class) return Boolean is
   begin
      return C.Me = Parent;
   end;

   function To_Pnml
     (C: in Cls_Record) return Ustring is
   begin
      raise Export_Exception;
      return Null_String;
   end;



   --==========================================================================
   --  expressions
   --==========================================================================

   function Is_Assignable
     (E: in Expr_Record) return Boolean is
   begin
      --  by default the expression is not assignable
      return False;
   end;

   procedure Assign
     (E  : in Expr_Record;
      B  : in Binding;
      Val: in Expr) is
   begin
      --  by default the expression is not assignable
      pragma Assert(False);
      null;
   end;

   function Get_Assign_Expr
     (E  : in Expr_Record;
      Val: in Expr) return Expr is
   begin
      --  by default the expression is not assignable
      pragma Assert(False);
      return null;
   end;

   procedure Compile_Definition
     (E  : in Expr_Record;
      R  : in Var_Mapping;
      Lib: in Library) is
   begin
      --  by default an expression does not generate any definition in the
      --  generated code
      null;
   end;

   function To_Pnml
     (E: in Expr_Record) return Ustring is
   begin
      raise Export_Exception;
      return Null_String;
   end;



   --==========================================================================
   --  variables
   --==========================================================================

   procedure Set_Init
     (V: in out Var_Record;
      E: in     Expr) is
   begin
      --  by default the expression is not assignable
      pragma Assert(False);
      null;
   end;

   function Change_Map
     (Map: in Var_Mapping;
      V  : in Var;
      Val: in Ustring) return Var_Mapping is
      Result: Var_Mapping := Map;
   begin
      for I in Result'Range loop
	 if Result(I).V = V then
	    Result(I).Expr := Val;
	 end if;
      end loop;
      return Result;
   end;

end Pn;
