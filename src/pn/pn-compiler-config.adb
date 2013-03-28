with
  Ada.Directories,
  Ada.Calendar,
  Gnat.Calendar.Time_Io;

use
  Ada.Directories,
  Ada.Calendar,
  Gnat.Calendar.Time_Io;

package body Pn.Compiler.Config is

   Global_Config: Compiler_Config :=
     (Capacity        => 1,
      Run_Time_Checks => True,
      Params          => String_List_Pkg.Empty_Array,
      Param_Values    => String_List_Pkg.Empty_Array);

   function Get_Run_Time_Checks return Boolean is
   begin
      return Global_Config.Run_Time_Checks;
   end;

   procedure Set_Run_Time_Checks
     (Run_Time_Checks: in Boolean) is
   begin
      Global_Config.Run_Time_Checks := Run_Time_Checks;
   end;

   function Get_Capacity return Mult_Type is
   begin
      return Global_Config.Capacity;
   end;

   procedure Set_Capacity
     (Capacity: in Mult_Type) is
   begin
      Global_Config.Capacity := Capacity;
   end;

   procedure Set_Parameter
     (Param: in Ustring;
      Value: in Num_Type) is
      V : constant Ustring := To_Ustring(Num_Type'Image(Value));
   begin
      String_List_Pkg.Append(Global_Config.Params, Param);
      String_List_Pkg.Append(Global_Config.Param_Values, V);
   end;

   procedure Set_Net_Parameters
     (N: in Net) is
      P: Ustring;
      V: Ustring;
   begin
      for I in 1..String_List_Pkg.Length(Global_Config.Params) loop
	 P := String_List_Pkg.Ith(Global_Config.Params, I);
	 V := String_List_Pkg.Ith(Global_Config.Param_Values, I);
	 Set_Parameter_Value(N, P, Num_Type'Value(To_String(V)));
      end loop;
   end;

end Pn.Compiler.Config;
