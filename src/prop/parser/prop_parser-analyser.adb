with
  Ada.Directories,
  Ada.Io_Exceptions,
  Prop.Ltl,
  Prop.State,
  Prop_Lexer_Io;

use
  Ada.Directories,
  Ada.Io_Exceptions,
  Prop.Ltl,
  Prop.State,
  Prop_Lexer_Io;

package body Prop_Parser.Analyser is

   use Element_List_Pkg;
   package PPT renames Prop_Parser_Tokens;

   procedure Parse_Name
     (E   : in     PPT.Element;
      Name:    out Ustring) is
   begin
      pragma Assert(E.T = PPT.Name);
      Name := E.Name_Name;
   end;

   procedure Add_Error
     (E  : in PPT.Element;
      Msg: in Ustring) is
   begin
      if Error_Msg /= Null_String then
         Error_Msg := Error_Msg & Nl;
      end if;
      Error_Msg := Error_Msg &
        Simple_Name(To_String(File_Name)) & ":" & E.Line & ": " & Msg;
   exception
      when Ada.Directories.Name_Error =>
      Error_Msg := Error_Msg & File_Name & ":" & E.Line & ": " & Msg;
   end;

   procedure Undefined
     (E: in PPT.Element;
      T: in Ustring;
      N: in Ustring) is
      Msg: Ustring := Null_String;
   begin
      if T /= Null_String then
         Msg := Msg & T & " ";
      end if;
      if N /= Null_String then
         Msg := Msg & N & " ";
      end if;
      Add_Error(E, Msg & "is undefined");
   end;

   procedure Redefinition
     (E: in PPT.Element;
      T: in Ustring;
      N: in Ustring) is
      Msg: Ustring := Null_String;
   begin
      if T /= Null_String then
         Msg := Msg & T & " ";
      end if;
      if N /= Null_String then
         Msg := Msg & N & " ";
      end if;
      Add_Error(E, Msg & "redefinition");
   end;

   procedure Parse_State_Property_Comp
     (E   : in     PPT.Element;
      Comp:    out State_Property_Comp;
      Ok  :    out Boolean) is
      Name: Ustring;
   begin
      case E.T is
         when PPT.Deadlock =>
            Comp := New_Deadlock;
            Ok := True;
         when PPT.Name =>
            Parse_Name(E, Name);
	    Comp := New_Predicate(Name);
	 when others =>
            pragma Assert(False); null;
      end case;
   end;

   procedure Parse_State_Property
     (E : in     PPT.Element;
      P :    out Prop.Property;
      Ok:    out Boolean) is
      Comps  : constant State_Property_Comp_List :=
	New_State_Property_Comp_List;
      Reject : State_Property_Comp;
      Comp   : State_Property_Comp;
      Accepts: PPT.Element;
   begin
      pragma Assert(E.T = PPT.State_Property);
      Parse_State_Property_Comp(E.State_Property_Reject, Reject, Ok);
      if Ok then
         pragma Assert(E.State_Property_Accept.T = PPT.List);
         Accepts := E.State_Property_Accept;
         for I in 1..Length(Accepts.List_Elements) loop
            Parse_State_Property_Comp(Ith(Accepts.List_Elements, I), Comp, Ok);
            if not Ok then
	       return;
            else
               Append(Comps, Comp);
            end if;
         end loop;
      end if;
      P := New_State_Property(Null_String, Reject, Comps);
   end;

   procedure Parse_Ltl_Formula
     (E : in     PPT.Element;
      F :    out Prop.Ltl.Ltl_Expr;
      Ok:    out Boolean) is
      Left : Prop.Ltl.Ltl_Expr;
      Right: Prop.Ltl.Ltl_Expr;
      Uop  : Prop.Ltl.Ltl_Un_Op;
      Bop  : Prop.Ltl.Ltl_Bin_Op;
      Name : Ustring;
   begin
      Ok := True;
      case E.T is
	 when PPT.Ltl_Un_Op =>
	    Parse_Ltl_Formula(E.Ltl_Un_Op_Operand, Right, Ok);
	    if Ok then
	       case E.Ltl_Un_Op_Operator.T is
		  when PPT.Finally_Op => Uop := Ltl_Finally;
		  when PPT.Generally_Op => Uop := Ltl_Generally;
		  when PPT.Not_Op => Uop := Ltl_Not;
		  when others => pragma Assert(False); null;
	       end case;
	       F := New_Ltl_Un_Op(Uop, Right);
	    end if;
	 when PPT.Ltl_Bin_Op =>
	    Parse_Ltl_Formula(E.Ltl_Bin_Op_Left_Operand, Left, Ok);
	    if Ok then
	       Parse_Ltl_Formula(E.Ltl_Bin_Op_Right_Operand, Right, Ok);
	       if Ok then
		  case E.Ltl_Bin_Op_Operator.T is
		     when PPT.Until_Op => Bop := Ltl_Until;
		     when PPT.And_Op => Bop := Ltl_And;
		     when PPT.Or_Op => Bop := Ltl_Or;
		     when PPT.Implies_Op => Bop := Ltl_Implies;
		     when PPT.Equivalence_Op => Bop := Ltl_Equivalence;
		     when others => pragma Assert(False); null;
		  end case;
		  F := New_Ltl_Bin_Op(Left, Bop, Right);
	       end if;
	    end if;
	 when PPT.Ltl_Prop =>
	    Parse_Name(E.Ltl_Prop_Proposition, Name);
	    F := New_Ltl_Proposition(Name);
	 when PPT.Ltl_Const =>
	    F := New_Ltl_Constant(E.Ltl_Constant);
	 when others =>
            pragma Assert(False); null;
      end case;
   end;

   procedure Parse_Ltl_Property
     (E : in     PPT.Element;
      P :    out Prop.Property;
      Ok:    out Boolean) is
      F: Ltl_Expr;
   begin
      Parse_Ltl_Formula(E.Ltl_Property_Formula, F, Ok);
      if Ok then
	 P := New_Ltl_Property(Null_String, F);
      end if;
   end;

   procedure Parse_Property
     (E : in     PPT.Element;
      P :    out Prop.Property;
      Ok:    out Boolean) is
      Name: Ustring;
   begin
      pragma Assert(E.T = PPT.Property);
      case E.Property_Property.T is
	 when PPT.State_Property =>
	    Parse_State_Property(E.Property_Property, P, Ok);
	 when PPT.Ltl_Property =>
	    Parse_Ltl_Property(E.Property_Property, P, Ok);
	 when others =>
	    pragma Assert(False); null;
      end case;
      if Ok then
         Parse_Name(E.Property_Name, Name);
         Set_Name(P, Name);
      end if;
   end;

   procedure Parse_Properties
     (File_Name: in     Ustring;
      Props    :    out Property_List) is
      E      : PPT.Element;
      El_Prop: PPT.Element;
      P      : Prop.Property;
      Ok     : Boolean;
   begin
      Initialize_Parser(File_Name);
      Prop_Lexer_Io.Open_Input(To_String(File_Name));
      Yyparse;
      Prop_Lexer_Io.Close_Input;
      E := Get_Parsed_Element;
      pragma Assert(E.T = PPT.List);
      Props := New_Property_List;
      for I in 1..Length(E.List_Elements) loop
         El_Prop := Ith(E.List_Elements, I);
	 case El_Prop.T is
	    when PPT.Property =>
	       Parse_Property(El_Prop, P, Ok);
	       if Ok then
		  if not Contains(Props, Get_Name(P)) then
		     Append(Props, P);
		  else
		     Ok := False;
		     Redefinition(El_Prop, To_Ustring("Property"),
				  Get_Name(P));
		  end if;
	       end if;
	    when others =>
	       pragma Assert(False); null;
	 end case;
      end loop;
      if Get_Error_Msg /= Null_String then
	 raise Parse_Exception with To_String(Get_Error_Msg);
      end if;
   exception
      when Ada.Io_Exceptions.Name_Error
        |  Ada.Io_Exceptions.Use_Error
        |  Ada.Io_Exceptions.Device_Error
        |  Ada.Io_Exceptions.Status_Error =>
         raise Io_Exception with
           To_String("could not open file '" & File_Name & "'");
      when Prop_Lexer.Lexical_Exception =>
         raise Parse_Exception with To_String(Prop_Lexer.Get_Error_Msg);
      when Prop_Parser.Syntax_Exception =>
         raise Parse_Exception with To_String(Prop_Parser.Get_Error_Msg);
   end;

   function Get_Error_Msg return Ustring is
   begin
      return Error_Msg;
   end;

end Prop_Parser.Analyser;
