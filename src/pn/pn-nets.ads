--=============================================================================
--
--  Package: Pn.Nets
--
--  This library contains the definition of colored Petri nets.
--
--=============================================================================


with
  Pn.Exprs,
  Pn.Funcs,
  Pn.Mappings,
  Pn.Nodes.Places,
  Pn.Nodes.Transitions,
  Pn.Propositions;

use
  Pn.Exprs,
  Pn.Funcs,
  Pn.Mappings,
  Pn.Nodes.Places,
  Pn.Nodes.Transitions,
  Pn.Propositions;

package Pn.Nets is

   --==========================================================================
   --  Group: Types
   --==========================================================================

   type Net_Record is tagged private;

   type Net is access all Net_Record;

   type Export_Result is
     (Export_Error_In_Initial_Marking,
      Export_Net_Too_Large,
      Export_Infinite_Net,
      Export_Io_Error,
      Export_Success);



   --==========================================================================
   --  Group: General sub-programs
   --==========================================================================

   function New_Net
     (Name: in Ustring) return Net;

   procedure Free_All
     (N: in out Net);

   procedure Free
     (N: in out Net);

   function Get_Name
     (N: in Net) return Ustring;

   procedure Set_Name
     (N   : in Net;
      Name: in Ustring);



   --==========================================================================
   --  Group: Export operations
   --==========================================================================

   procedure To_Pnml
     (N     : in     Net;
      File  : in     String;
      Result:    out Export_Result);



   --==========================================================================
   --  Group: Places
   --==========================================================================

   function P_Size
     (N: in Net) return Count_Type;

   function Get_Places
     (N: in Net) return Place_Vector;

   procedure Set_Places
     (N: in Net;
      P: in Place_Vector);

   function Is_Place
     (N: in Net;
      P: in Ustring) return Boolean;

   function Ith_Place
     (N: in Net;
      I: in Index_Type) return Place;

   function Get_Index
     (N: in Net;
      P: in Place) return Extended_Index_Type;

   procedure Add_Place
     (N: in Net;
      P: in Place);

   procedure Delete_Place
     (N: in Net;
      P: in Place);

   function Get_Place
     (N: in Net;
      P: in Ustring) return Place;

   function Pre_Post_Set
     (N: in Net;
      P: in Place;
      A: in Arc_Type) return Trans_Vector;

   function Pre_Set
     (N: in Net;
      P: in Place) return Trans_Vector;

   function Post_Set
     (N: in Net;
      P: in Place) return Trans_Vector;

   function Pre_Set
     (N: in Net;
      P: in Place_Vector) return Trans_Vector;

   function Post_Set
     (N: in Net;
      P: in Place_Vector) return Trans_Vector;

   function Bit_To_Encode_Pid
     (N: in Net) return Natural;



   --==========================================================================
   --  Group: Transitions
   --==========================================================================

   function T_Size
     (N: in Net) return Count_Type;

   function Get_Trans
     (N: in Net) return Trans_Vector;

   procedure Set_Trans
     (N: in Net;
      T: in Trans_Vector);

   function Is_Trans
     (N: in Net;
      T: in Ustring) return Boolean;

   function Ith_Trans
     (N: in Net;
      I: in Index_Type) return Trans;

   function Get_Index
     (N: in Net;
      T: in Trans) return Index_Type;

   procedure Add_Trans
     (N: in Net;
      T: in Trans);

   procedure Delete_Trans
     (N: in Net;
      T: in Trans);

   function Get_Trans
     (N: in Net;
      T: in Ustring) return Trans;

   function Pre_Post_Set
     (N: in Net;
      T: in Trans;
      A: in Arc_Type) return Place_Vector;

   function Pre_Set
     (N: in Net;
      T: in Trans) return Place_Vector;

   function Post_Set
     (N: in Net;
      T: in Trans) return Place_Vector;

   function Pre_Post_Set
     (N: in Net;
      T: in Trans_Vector;
      A: in Arc_Type) return Place_Vector;

   function Pre_Set
     (N: in Net;
      T: in Trans_Vector) return Place_Vector;

   function Post_Set
     (N: in Net;
      T: in Trans_Vector) return Place_Vector;

   function Inhib_Set
     (N: in Net;
      T: in Trans) return Place_Vector;

   function Inhib_Set
     (N: in Net;
      T: in Trans_Vector) return Place_Vector;

   function Is_Unifiable
     (N: in Net;
      T: in Trans) return Boolean;

   procedure Replace_Var
     (N: in Net;
      T: in Trans;
      V: in Var;
      E: in Expr);

   procedure Map_Vars
     (N    : in Net;
      T    : in Trans;
      V_Old: in Var_List;
      V_New: in Var_List);

   function Bit_To_Encode_Tid
     (N: in Net) return Natural;



   --==========================================================================
   --  Group: Color classes
   --==========================================================================

   function Cls_Size
     (N: in Net) return Count_Type;

   function Ith_Cls
     (N: in Net;
      I: in Index_Type) return Cls;

   function Get_Cls
     (N: in Net) return Cls_Set;

   procedure Set_Cls
     (N: in Net;
      C: in Cls_Set);

   procedure Add_Cls
     (N: in Net;
      C: in Cls);

   function Is_Cls
     (N: in Net;
      C: in Ustring) return Boolean;

   function Get_Cls
     (N: in Net;
      C: in Ustring) return Cls;



   --==========================================================================
   --  Group: Arcs
   --==========================================================================

   procedure Add_Arc_Label
     (N: in Net;
      A: in Arc_Type;
      P: in Place;
      T: in Trans;
      M: in Mapping);

   procedure Add_Arc_Label
     (N  : in Net;
      A  : in Arc_Type;
      P  : in Place;
      T  : in Trans;
      Tup: in Tuple);

   function Get_Arc_Label
     (N: in Net;
      A: in Arc_Type;
      P: in Place;
      T: in Trans) return Mapping;

   procedure Set_Arc_Label
     (N: in Net;
      A: in Arc_Type;
      P: in Place;
      T: in Trans;
      M: in Mapping);



   --==========================================================================
   --  Group: Constants
   --==========================================================================

   function Get_Consts
     (N: in Net) return Var_List;

   procedure Add_Const
     (N: in Net;
      C: in Var);

   function Is_Const
     (N: in Net;
      C: in Ustring) return Boolean;

   function Get_Const
     (N: in Net;
      C: in Ustring) return Var;



   --==========================================================================
   --  Group: Parameters
   --==========================================================================

   function Get_Parameters
     (N: in Net) return Ustring_List;

   procedure Add_Parameter
     (N: in Net;
      P: in Ustring);

   function Is_Parameter
     (N: in Net;
      P: in Ustring) return Boolean;

   function Get_Parameter_Value
     (N: in Net;
      P: in Ustring) return Expr;

   procedure Set_Parameter_Value
     (N: in Net;
      P: in Ustring;
      V: in Num_Type);



   --==========================================================================
   --  Group: Functions
   --==========================================================================

   function Get_Funcs
     (N: in Net) return Func_List;

   procedure Set_Funcs
     (N: in Net;
      F: in Func_List);

   procedure Add_Func
     (N: in Net;
      F: in Func);

   procedure Delete_Func
     (N: in Net;
      F: in Ustring);

   function Is_Func
     (N: in Net;
      F: in Ustring) return Boolean;

   function Get_Func
     (N: in Net;
      F: in Ustring) return Func;

   function Funcs_Card
     (N: in Net) return Count_Type;

   function Ith_Func
     (N: in Net;
      I: in Index_Type) return Func;



   --==========================================================================
   --  Group: Priorities
   --==========================================================================

   function With_Priority
     (N: in Net) return Boolean;



   --==========================================================================
   --  Group: State propositions
   --==========================================================================

   function Is_Proposition
     (N   : in Net;
      Prop: in Ustring) return Boolean;

   function Get_Propositions
     (N: in Net) return State_Proposition_List;

   function Get_Proposition
     (N   : in Net;
      Prop: in Ustring) return State_Proposition;

   procedure Add_Proposition
     (N   : in Net;
      Prop: in State_Proposition);

   function Get_Observed_Places
     (N: in Net) return Place_Vector;

   function Is_Observed
     (N: in Net;
      P: in Place) return Boolean;



   --==========================================================================
   --  Group: Modules
   --==========================================================================

   function Get_Modules
     (N: in Net) return Natural_Set_Pkg.Set_Type;



   --==========================================================================
   --  Group: Others
   --==========================================================================

   procedure Get_Statistics
     (N         : in     Net;
      Places    :    out Natural;
      Trans     :    out Natural;
      Arcs      :    out Natural;
      In_Arcs   :    out Natural;
      Out_Arcs  :    out Natural;
      Inhib_Arcs:    out Natural);


private


   type Net_Record is tagged
      record
         Name   : Ustring;
         P      : Place_Vector;
         T      : Trans_Vector;
         C      : Cls_Set;
         Consts : Var_List;
         F      : Func_List;
	 Params : Ustring_List;
	 Props  : State_Proposition_List;
      end record;

end Pn.Nets;
