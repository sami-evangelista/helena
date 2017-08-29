with
  Ada.Text_Io,
  Gnat.Os_Lib;

use
  Ada.Text_Io,
  Gnat.Os_Lib;

package body Prop.Ltl is

   --==========================================================================
   --  Ltl property
   --==========================================================================

   function New_Ltl_Property
     (Name  : in Ustring;
      Ltl_Ex: in Ltl_Expr) return Property is
      Result: constant Ltl_Property := new Ltl_Property_Record;
   begin
      Initialize(Result, Name);
      Result.E := Ltl_Ex;
      return Property(Result);
   end;

   function Get_Type
     (P: in Ltl_Property_Record) return Property_Type is
   begin
      return A_Ltl_Property;
   end;

   function To_Helena
     (P: in Ltl_Property_Record) return Ustring is
      Result: Ustring;
   begin
      Result :=
	"ltl property " & P.Name & ": " & Nl &
	"   " & To_Helena(P.E) & ";";
      return Result;
   end;

   procedure Compile_Definition
     (P  : in Ltl_Property_Record;
      Lib: in Library;
      Dir: in String) is
      Exec   : constant Gnat.Os_Lib.String_Access :=
	Locate_Exec_On_Path ("helena-ltl2ba");
      Success: Boolean;
      Args   : constant Argument_List :=
	(1 => new String'("-f"),
	 2 => new String'(To_String("!(" & To_Spin(P.E) & ")")),
	 3 => new String'(Dir));
   begin
      if Exec = null then
	 raise Compilation_Exception with
	   "could not locate helena-ltl2ba in the PATH environment variable";
      else
	 Spawn(Exec.all, Args, Success);
      end if;
   end;

   function Get_Propositions
     (P: in Ltl_Property_Record) return Ustring_List is
      Result: Ustring_List := String_List_Pkg.Empty_Array;
   begin
      return Get_Propositions(P.E);
   end;



   --==========================================================================
   --  Ltl expression
   --==========================================================================

   function New_Ltl_Proposition
     (Prop: in Ustring) return Ltl_Expr is
      Result: constant Ltl_Expr := new Ltl_Expr_Record(Ltl_Expr_Proposition);
   begin
      Result.Prop := Prop;
      return Result;
   end;

   function New_Ltl_Constant
     (C: in Boolean) return Ltl_Expr is
      Result: constant Ltl_Expr := new Ltl_Expr_Record(Ltl_Expr_Constant);
   begin
      Result.C := C;
      return Result;
   end;

   function New_Ltl_Bin_Op
     (Left : in Ltl_Expr;
      Op   : in Ltl_Bin_Op;
      Right: in Ltl_Expr) return Ltl_Expr is
      Result: constant Ltl_Expr := new Ltl_Expr_Record(Ltl_Expr_Bin_Op);
   begin
      Result.Left := Left;
      Result.Bin_Op := Op;
      Result.Right := Right;
      return Result;
   end;

   function New_Ltl_Un_Op
     (Op   : in Ltl_Un_Op;
      Right: in Ltl_Expr) return Ltl_Expr is
      Result: constant Ltl_Expr := new Ltl_Expr_Record(Ltl_Expr_Un_Op);
   begin
      Result.Operand := Right;
      Result.Un_Op := Op;
      return Result;
   end;

   function Convert
     (E: in Ltl_Expr;
      H: in Boolean) return Ustring is
      Result: Ustring;
   begin
      case E.T is
	 when Ltl_Expr_Un_Op =>
	    case E.Un_Op is
	       when Ltl_Not =>
		  if H then
		     Result := To_Ustring("(not");
		  else
		     Result := To_Ustring("(!");
		  end if;
	       when Ltl_Generally =>
		  Result := To_Ustring("([]");
	       when Ltl_Finally =>
		  Result := To_Ustring("(<>");
	    end case;
	    Result := Result & " " & Convert(E.Operand, H) & ")";
	 when Ltl_Expr_Bin_Op =>
	    Result := "(" & Convert(E.Left, H);
	    case E.Bin_Op is
	       when Ltl_And =>
		  if H then
		     Result := Result & "and";
		  else
		     Result := Result & "&&";
		  end if;
	       when Ltl_Or =>
		  if H then
		     Result := Result & "or";
		  else
		     Result := Result & "||";
		  end if;
	       when Ltl_Until =>
		  if H then
		     Result := Result & "until";
		  else
		     Result := Result & "U";
		  end if;
	       when Ltl_Implies =>
		  if H then
		     Result := Result & "=>";
		  else
		     Result := Result & "->";
		  end if;
	       when Ltl_Equivalence =>
		  if H then
		     Result := Result & "<=>";
		  else
		     Result := Result & "<->";
		  end if;
	    end case;
	    Result := Result & Convert(E.Right, H) & ")";
	 when Ltl_Expr_Constant =>
	    if E.C then
	       Result := To_Ustring("true");
	    else
	       Result := To_Ustring("false");
	    end if;
	    return Result;
	 when Ltl_Expr_Proposition =>
	    Result := E.Prop;
      end case;
      return Result;
   end;

   function To_Helena
     (E: in Ltl_Expr) return Ustring is
   begin
      return Convert(E, True);
   end;

   function To_Spin
     (E: in Ltl_Expr) return Ustring is
   begin
      return Convert(E, False);
   end;

   function Get_Propositions
     (E: in Ltl_Expr) return Ustring_List is
      Result: Ustring_List;
   begin
      case E.T is
	 when Ltl_Expr_Un_Op =>
	    Result := Get_Propositions(E.Operand);
	 when Ltl_Expr_Bin_Op =>
	    Result := Get_Propositions(E.Left);
	    String_List_Pkg.Append(Result, Get_Propositions(E.Right));
	 when Ltl_Expr_Constant =>
	    Result := String_List_Pkg.Empty_Array;
	 when Ltl_Expr_Proposition =>
	    Result := String_List_Pkg.New_Array(E.Prop);
      end case;
      return Result;
   end;

end Prop.Ltl;
