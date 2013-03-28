with  Ada.strings.unbounded;
with  Utils.strings;
with  Generic_Array;
use   Ada.strings.unbounded;
use   Utils.strings;
package Prop_Parser_Tokens is


   subtype Line_Number is Natural;
   subtype Column_Number is Natural;

   type Element_Record;
   type Element is access all Element_Record;
   subtype Yystype is Element;

   package Element_list_Pkg is
      new Generic_Array(Element, null, "=");
   subtype Element_list is Element_list_Pkg.array_type;

   Empty_Element_list :
     constant Element_list := Element_list_Pkg.Empty_Array;

   type Element_Type is
     (Not_Op,
      Finally_Op,
      Generally_Op,
      And_Op,
      Or_Op,
      Implies_Op,
      Until_Op,
      Property,
      Deadlock,
      State_Property,
      Ltl_Property,
      Ltl_Un_Op,
      Ltl_Bin_Op,
      Ltl_Prop,
      Name,
      List,
      Ltl_Const);


   type Element_Record(T : Element_Type) is record
      Line : Line_Number;
      Col  : Column_Number;
      case T is
	 when Not_Op => null;
         when And_Op => null;
         when Or_Op => null;
         when Generally_Op => null;
         when Finally_Op => null;
         when Implies_Op => null;
         when Until_Op => null;
	 when property =>
            property_name     : element;
            property_property : element;
         when State_Property =>
            State_Property_Reject: Element;
            State_Property_Accept: Element;
         when Deadlock => null;
         when Ltl_Const =>
	    Ltl_Constant: Boolean;
         when Ltl_Property =>
	    Ltl_Property_Formula : Element;
         when Ltl_Un_Op =>
	    Ltl_Un_Op_Operator: Element;
            Ltl_Un_Op_Operand : Element;
         when Ltl_Bin_Op =>
	    Ltl_Bin_Op_Left_Operand : Element;
	    Ltl_Bin_Op_Operator     : Element;
	    Ltl_Bin_Op_Right_Operand: Element;
         when Ltl_Prop =>
	    Ltl_Prop_Proposition: Element;
         when Name =>
            Name_Name : Unbounded_String;
         when List =>
            List_Elements : Element_list;
      end case;
   end record;

    YYLVal, YYVal : YYSType; 
    type Token is
        (End_Of_Input, Error, Accept_Token, And_Token,
         Deadlock_Token, False_Token, Ltl_Token,
         Not_Token, Or_Token, Property_Token,
         Reject_Token, State_Token, True_Token,
         Until_Token, Identifier_Token, Implies_Token,
         Semicolon_Token, Colon_Token, Generally_Token,
         Finally_Token, Rbracket_Token, Lbracket_Token );

    Syntax_Error : exception;

end Prop_Parser_Tokens;
