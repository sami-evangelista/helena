--=============================================================================
--
--  Package: Prop.Ltl
--
--  This package implements Ltl properties.
--
--=============================================================================


package Prop.Ltl is

   type Ltl_Property_Record is new Property_Record with private;

   type Ltl_Property is access all Ltl_Property_Record;

   type Ltl_Expr is private;

   type Ltl_Un_Op is (Ltl_Generally, Ltl_Finally, Ltl_Not);

   type Ltl_Bin_Op is (Ltl_And, Ltl_Or, Ltl_Until, Ltl_Implies,
		       Ltl_Equivalence);


   --==========================================================================
   --  Group: Ltl property
   --==========================================================================

   function New_Ltl_Property
     (Name  : in Ustring;
      Ltl_Ex: in Ltl_Expr) return Property;



   --==========================================================================
   --  Group: Ltl expression
   --==========================================================================

   function New_Ltl_Proposition
     (Prop: in Ustring) return Ltl_Expr;

   function New_Ltl_Constant
     (C: in Boolean) return Ltl_Expr;

   function New_Ltl_Bin_Op
     (Left : in Ltl_Expr;
      Op   : in Ltl_Bin_Op;
      Right: in Ltl_Expr) return Ltl_Expr;

   function New_Ltl_Un_Op
     (Op   : in Ltl_Un_Op;
      Right: in Ltl_Expr) return Ltl_Expr;

   function To_Helena
     (E: in Ltl_Expr) return Ustring;

   function To_Spin
     (E: in Ltl_Expr) return Ustring;

   function Get_Propositions
     (E: in Ltl_Expr) return Ustring_List;


private


   --==========================================================================
   --  Ltl property
   --==========================================================================

   type Ltl_Property_Record is new Property_Record with
      record
	 E: Ltl_Expr;
      end record;

   function Get_Type
     (P: in Ltl_Property_Record) return Property_Type;

   function To_Helena
     (P: in Ltl_Property_Record) return Ustring;

   procedure Compile_Definition
     (P  : in Ltl_Property_Record;
      Lib: in Library;
      Dir: in String);

   function Get_Propositions
     (P: in Ltl_Property_Record) return Ustring_List;



   --==========================================================================
   --  Ltl expression
   --==========================================================================

   type Ltl_Expr_Type is (Ltl_Expr_Constant,
			  Ltl_Expr_Bin_Op,
			  Ltl_Expr_Un_Op,
			  Ltl_Expr_Proposition);

   type Ltl_Expr_Record (T : Ltl_Expr_Type) is
      record
	 case T is
	    when Ltl_Expr_Constant =>
	       C: Boolean;
	    when Ltl_Expr_Proposition =>
	       Prop: Ustring;
	    when Ltl_Expr_Bin_Op =>
	       Left  : Ltl_Expr;
	       Bin_Op: Ltl_Bin_Op;
	       Right : Ltl_Expr;
	    when Ltl_Expr_Un_Op =>
	       Un_Op  : Ltl_Un_Op;
	       Operand: Ltl_Expr;
	 end case;
      end record;

   type Ltl_Expr is access all Ltl_Expr_Record;

end Prop.Ltl;
