--=============================================================================
--
--  Package: Helena_Parser
--
--  This is the parser of Helena.
--
--=============================================================================


with
  Ada.Strings.Unbounded,
  Ada.Text_Io,
  Generic_Array,
  Helena_Yacc_Tokens,
  Pn,
  Pn.Compiler,
  Pn.Exprs,
  Pn.Classes.Structs,
  Pn.Funcs,
  Pn.Guards,
  Pn.Vars.Iter,
  Pn.Vars.Net_Consts,
  Pn.Vars.Func_Params,
  Pn.Vars.Func_Vars,
  Pn.Vars.Trans_Vars,
  Pn.Mappings,
  Pn.Nodes.Places,
  Pn.Propositions,
  Pn.Nets,
  Pn.Ranges,
  Pn.Stats,
  Pn.Stats.Cases,
  Pn.Nodes.Transitions,
  Utils.Strings;

use
  Ada.Strings.Unbounded,
  Ada.Text_Io,
  Helena_Yacc_Tokens,
  Pn,
  Pn.Compiler,
  Pn.Exprs,
  Pn.Classes.Structs,
  Pn.Funcs,
  Pn.Guards,
  Pn.Vars.Iter,
  Pn.Vars.Net_Consts,
  Pn.Vars.Func_Params,
  Pn.Vars.Func_Vars,
  Pn.Vars.Trans_Vars,
  Pn.Mappings,
  Pn.Nodes.Places,
  Pn.Propositions,
  Pn.Nets,
  Pn.Ranges,
  Pn.Stats,
  Pn.Stats.Cases,
  Pn.Nodes.Transitions,
  Utils.Strings;

package Helena_Parser is

   procedure Parse_Net
     (File_Name: in     Ustring;
      N        :    out Pn.Nets.Net);

   function Get_Error_Msg return Ustring;

   Io_Exception,
   Parse_Exception: exception;


private


   N: Pn.Nets.Net := null;

   subtype Line_Number is Helena_Yacc_Tokens.Line_Number;
   subtype Element     is Helena_Yacc_Tokens.Element;

   --  attributes of a place
   subtype Place_Attribute is
     Element_Type range Place_Init .. Helena_Yacc_Tokens.Place_Type;

   --  attributes of a transition
   subtype Transition_Attribute is
     Element_Type range Transition_Description .. Transition_Safe;

   procedure Check_Type
     (E: in Element;
      T: in Element_Type);

   package Var_List_List_Pkg is new Generic_Array(Var_List, null, "=");
   subtype Var_List_List is Var_List_List_Pkg.Array_Type;

   function Pos_To_String
     (E: in Element) return Ustring;

end Helena_Parser;
