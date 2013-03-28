--=============================================================================
--
--  Package: Pn.Compiler.Config
--
--  This package provides procedures that enable to configure the
--  generation of the compiled net.
--
--=============================================================================


with
  Pn.Compiler.Vectors;

use
  Pn.Compiler.Vectors;

package Pn.Compiler.Config is

   --==========================================================================
   --  Group: Sub-Programs to activate / deactivate options
   --==========================================================================

   procedure Set_Run_Time_Checks
     (Run_Time_Checks: in Boolean);
   function Get_Run_Time_Checks return Boolean;

   procedure Set_Capacity
     (Capacity: in Mult_Type);
   function Get_Capacity return Mult_Type;

   procedure Set_Parameter
     (Param: in Ustring;
      Value: in Num_Type);

   procedure Set_Net_Parameters
     (N: in Net);


private


   --==========================================================================
   --  a record type that contains all the possible configuration options for
   --  the compilation
   --==========================================================================

   type Compiler_Config is
      record
	 Capacity       : Pn.Mult_Type;
         Run_Time_Checks: Boolean;
	 Params         : Ustring_List;
	 Param_Values   : Ustring_List;
      end record;

end Pn.Compiler.Config;
