with
  Pn.Classes,
  Pn.Exprs,
  Pn.Exprs.Num_Consts;

use
  Pn.Classes,
  Pn.Exprs,
  Pn.Exprs.Num_Consts;

package body Pn.Classes.Discretes.Nums.Mods is

   function New_Mod_Cls
     (Name   : in Ustring;
      Mod_Val: in Expr) return Cls is
      Result: Mod_Cls;
      Tmp   : Expr;
      State: Evaluation_State;
   begin
      --===
      --  modulo expression must be statically evaluable
      --===
      pragma Assert(Is_Static(Mod_Val));

      --===
      --  modulo expression must be strictly positive
      --===
      Evaluate_Static(E      => Mod_Val,
                      Check  => False,
                      Result => Tmp,
                      State  => State);
      pragma Assert(Is_Success(State)           and then
                    Get_Type(Tmp) = A_Num_Const and then
                    Get_Const(Num_Const(Tmp)) > 0);
      Free(Tmp);

      Result := new Mod_Cls_Record;
      Initialize(Result, Name);
      Result.Mod_Val := Mod_Val;
      return Cls(Result);
   end;

   procedure Free
     (C: in out Mod_Cls_Record) is
   begin
      Free(C.Mod_Val);
   end;

   function Colors_Used
     (C: in Mod_Cls_Record) return Cls_Set is
   begin
      return New_Cls_Set;
   end;

   function Get_Low
     (C: in Mod_Cls_Record) return Num_Type is
   begin
      return 0;
   end;

   function Get_High
     (C: in Mod_Cls_Record) return Num_Type is
      State: Evaluation_State;
      Tmp   : Expr;
      Result: Num_Type;
   begin
      Evaluate_Static(E      => C.Mod_Val,
                      Check  => False,
                      Result => Tmp,
                      State  => State);
      pragma Assert(Is_Success(State) and then Get_Type(Tmp) = A_Num_Const);
      Result := Get_Const(Num_Const(Tmp)) - 1;
      Free(Tmp);
      return Result;
   end;

   function Is_Circular
     (C: in Mod_Cls_Record) return Boolean is
   begin
      return True;
   end;

   function Normalize_Value
     (C: in Mod_Cls_Record;
      I: in Num_Type) return Num_Type is
      High  : constant Num_Type := Get_High(C);
      Result: Num_Type := I;
   begin
      while Result < 0 loop
         Result := Result + High + 1;
      end loop;
      Result := Result mod (High + 1);
      return Result;
   end;

end Pn.Classes.Discretes.Nums.Mods;
