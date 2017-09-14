--=============================================================================
--
--  Package: Helena_Parser.Main
--
--  This is the main file of the Helena parser.
--
--=============================================================================


with
  Utils,
  Utils.Generics;

use
  Utils,
  Utils.Generics;

private package Helena_Parser.Main is

   type Arc_Type is
     (Input_Arc,
      Output_Arc,
      Inhibit_Arc,
      Reset_Arc);

   procedure Parse_Net
     (E : in     Element;
      Ok:    out Boolean);

   procedure Parse_Name
     (E   : in     Element;
      Name:    out Ustring);

   procedure Parse_Number
     (E  : in     Element;
      Num:    out Big_Int;
      Ok :    out Boolean);

   procedure Parse_Color_Ref
     (E : in     Element;
      C :    out Cls;
      Ok:    out Boolean);

   procedure Parse_Place_Ref
     (E : in     Element;
      P :    out Pn.Nodes.Places.Place;
      Ok:    out Boolean);

   procedure Parse_Transition_Ref
     (E : in     Element;
      T :    out Pn.Nodes.Transitions.Trans;
      Ok:    out Boolean);

   procedure Parse_Dom
     (E : in     Element;
      D :    out Dom;
      Ok:    out Boolean);

   procedure Parse_Var_Items
     (E    : in     Element;
      Vars : in out Var_List_List;
      Const:    out Boolean;
      Name :    out Ustring;
      C    :    out Cls;
      Init :    out Expr;
      Ok   :    out Boolean);

   procedure Color_Expr
     (E : in     Element;
      Ex: in     Expr;
      C : in     Cls;
      Ok:    out Boolean);

   procedure Parse_Static_Num_Expr
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Val :    out Num_Type;
      Ok  :    out Boolean);

   procedure Parse_Iter_Var
     (E     : in     Element;
      Static: in     Boolean;
      Types : in     Var_Type_Set;
      Vll   : in out Var_List_List;
      V     :    out Var;
      Ok    :    out Boolean);

   procedure Parse_Iter_Var_List
     (E     : in     Element;
      Static: in     Boolean;
      Types : in     Var_Type_Set;
      Vll   : in out Var_List_List;
      Vars  : in out Var_List;
      Ok    :    out Boolean);

   procedure Parse_Iter_Var_List_Names
     (E    : in     Element;
      Names:    out String_Set);

   procedure Parse_Range
     (E        : in     Element;
      C        : in     Cls;
      Static   : in     Boolean;
      Num_Range: in     Boolean;
      Vars     : in out Var_List_List;
      R        :    out Range_Spec;
      Ok       :    out Boolean);

   procedure Parse_Low_High_Range
     (E        : in     Element;
      C        : in     Cls;
      Static   : in     Boolean;
      Num_Range: in     Boolean;
      Vars     : in out Var_List_List;
      R        :    out Range_Spec;
      Ok       :    out Boolean);

   procedure Undefined
     (E: in Element;
      T: in Ustring;
      N: in Ustring);

   procedure Redefinition
     (E   : in Element;
      T   : in Ustring;
      N   : in Ustring;
      Prev: in Element := null);

   procedure Ensure_Bool
     (E : in     Element;
      Ex: in     Expr;
      Ok:    out Boolean);

   procedure Ensure_Num
     (E : in     Element;
      Ex: in     Expr;
      Ok:    out Boolean);

   procedure Ensure_Num
     (E : in     Element;
      C : in     Cls;
      Ok:    out Boolean);

   procedure Ensure_Discrete
     (E : in     Element;
      Ex: in     Expr;
      Ok:    out Boolean);

   procedure Ensure_Discrete
     (E : in     Element;
      C : in     Cls;
      Ok:    out Boolean);

end Helena_Parser.Main;
