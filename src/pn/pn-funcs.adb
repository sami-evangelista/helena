with
  Pn.Bindings,
  Pn.Classes,
  Pn.Compiler,
  Pn.Compiler.Config,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Vars;

use
  Pn.Bindings,
  Pn.Classes,
  Pn.Compiler,
  Pn.Compiler.Config,
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Vars;

package body Pn.Funcs is

   --==========================================================================
   --  Function
   --==========================================================================

   procedure Deallocate is
      new Ada.Unchecked_Deallocation(Func_Record, Func);

   function New_Func
     (Name     : in Ustring;
      Ret_Cls  : in Cls;
      Params   : in Var_List;
      Func_Stat: in Stat;
      Imported : in Boolean) return Func is
      Result: constant Func := new Func_Record;
   begin
      Result.Name      := Name;
      Result.Ret_Cls   := Ret_Cls;
      Result.Params    := Params;
      Result.Func_Stat := Func_Stat;
      Result.Domain    := New_Dom;
      Result.Imported  := Imported;
      for I in 1..Length(Params) loop
         Append(Result.Domain, Get_Cls(Ith(Params, I)));
      end loop;
      return Result;
   end;

   function New_Func
     (Name: in Ustring) return Func is
      Result: constant Func := new Func_Record;
   begin
      Result.Name      := Name;
      Result.Ret_Cls   := null;
      Result.Params    := New_Var_List;
      Result.Func_Stat := null;
      Result.Domain    := New_Dom;
      Result.Imported  := False;
      return Result;
   end;

   procedure Free
     (F: in out Func) is
   begin
      Free_All(F.Params);
      Free(F.Domain);
      if F.Func_Stat /= null then
         Free(F.Func_Stat);
      end if;
      Deallocate(F);
      F := null;
   end;

   function Get_Name
     (F: in Func) return Ustring is
   begin
      return F.Name;
   end;

   procedure Set_Name
     (F   : in Func;
      Name: in Ustring) is
   begin
      F.Name := Name;
   end;

   function Get_Ret_Cls
     (F: in Func) return Cls is
   begin
      return F.Ret_Cls;
   end;

   procedure Set_Ret_Cls
     (F       : in Func;
      Ret_Cls: in Cls) is
   begin
      F.Ret_Cls := Ret_Cls;
   end;

   function Get_Params
     (F: in Func) return Var_List is
   begin
      return F.Params;
   end;

   procedure Set_Params
     (F     : in Func;
      Params: in Var_List) is
   begin
      F.Params := Params;
      if F.Domain /= null then
         Free(F.Domain);
      end if;
      F.Domain := New_Dom;
      for I in 1..Length(Params) loop
         Append(F.Domain, Get_Cls(Ith(Params, I)));
      end loop;
   end;

   function Params_Size
     (F: in Func) return Natural is
   begin
      return Length(F.Params);
   end;

   function Is_Param
     (F: in Func;
      P: in Ustring) return Boolean is
   begin
      return Contains(F.Params, P);
   end;

   function Get_Param
     (F: in Func;
      P: in Ustring) return Var is
   begin
      return Get(F.Params, P);
   end;

   function Get_Func_Stat
     (F: in Func) return Stat is
   begin
      return F.Func_Stat;
   end;

   procedure Set_Func_Stat
     (F        : in Func;
      Func_Stat: in Stat) is
   begin
      F.Func_Stat := Func_Stat;
   end;

   function Get_Imported
     (F: in Func) return Boolean is
   begin
      return F.Imported;
   end;

   procedure Set_Imported
     (F       : in Func;
      Imported: in Boolean) is
   begin
      F.Imported := Imported;
   end;

   function Get_Dom
     (F: in Func) return Dom is
   begin
      return F.Domain;
   end;

   function Is_Incomplete
     (F: in Func) return Boolean is
   begin
      return (F.Func_Stat = null and not F.Imported) or F.Ret_Cls = null;
   end;

   function Get_C_Prototype
     (F   : in Func;
      Name: in Ustring) return Ustring is
      Param : Var;
      Result: Ustring := Cls_Name(F.Ret_Cls) & " " & Name & Nl & "(";
   begin
      for I in 1..Length(F.Params) loop
         Param := Ith(F.Params, I);
         if I > 1 then
            Result := Result & "," & Nl & " ";
         end if;
         Result := Result & Cls_Name(Get_Cls(Param)) & " " & Var_Name(Param);
      end loop;
      Result := Result & ")";
      return Result;
   end;

   function Get_C_Parameters
     (F : in Func) return Ustring is
      Result: Ustring := To_Ustring("");
   begin
      for I in 1..Length(F.Params) loop
         if I > 1 then
            Result := Result & ", ";
         end if;
         Result := Result & Var_Name(Ith(F.Params, I));
      end loop;
      return Result;
   end;

   procedure Compile_Prototype
     (F  : in Func;
      Lib: in Library) is
   begin
      Plh(Lib, Get_C_Prototype(F, Func_Name(F)) & ";");
      if F.Imported then
	 Plh(Lib, Get_C_Prototype(F, Imported_Func_Name(F)) & ";");
      end if;
   end;

   procedure Compile_Body
     (F  : in Func;
      Lib: in Library) is
      Prot: constant Ustring := Get_C_Prototype(F, Func_Name(F));
      Test: Ustring;
   begin

      Plc(Lib, Prot & " {");
      Plc(Lib, 1, Cls_Name(F.Ret_Cls) & " result;");
      if not F.Imported then
         Compile(F.Func_Stat, 1, Lib);
      else
         Plc(Lib, 1, "result = " & Imported_Func_Name(F) &
               "(" & Get_C_Parameters(F) & ");");
         Plc(Lib, 1, "goto function_end;");
      end if;

      --===
      --  if we are here then no value has been returned we raise an error
      --===
      if Get_Run_Time_Checks then
	 Plc(Lib, 1, "raise_error" &
	       "(""no value returned in function " & Get_Name(F) & """);");
	 Plc(Lib, 1, "return " & Cls_First_Const_Name(F.Ret_Cls) & ";");
      end if;

      --===
      --  end of the function
      --===
      Plc(Lib, "function_end:");
      Plc(Lib, 1, "return result;");
      Plc(Lib, "}");
   end;



   --==========================================================================
   --  Function list
   --==========================================================================

   package FAP renames Func_Array_Pkg;

   function New_Func_List return Func_List is
      Result: constant Func_List := new Func_List_Record;
   begin
      Result.Funcs := FAP.Empty_Array;
      return Result;
   end;

   function New_Func_List
     (F: in Func_Array) return Func_List is
      Result: constant Func_List := new Func_List_Record;
   begin
      Result.Funcs := FAP.New_Array(FAP.Element_Array(F));
      return Result;
   end;

   procedure Free_All
     (F: in out Func_List) is
      procedure Free is new FAP.Generic_Apply(Free);
   begin
      Free(F.Funcs);
      Free(F);
   end;

   procedure Free
     (F: in out Func_List) is
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Func_List_Record, Func_List);
   begin
      Deallocate(F);
      F := null;
   end;

   function Length
     (F: in Func_List) return Count_Type is
   begin
      return FAP.Length(F.Funcs);
   end;

   function Ith
     (F: in Func_List;
      I: in Index_Type) return Func is
   begin
      return FAP.Ith(F.Funcs, I);
   end;

   function Contains
     (F: in Func_List;
      G: in Ustring) return Boolean is
      function Is_G
        (F: in Func) return Boolean is
      begin
         return Get_Name(F) = G;
      end;
      function Contains is new FAP.Generic_Exists(Is_G);
   begin
      return Contains(F.Funcs);
   end;

   procedure Append
     (F: in Func_List;
      G: in Func) is
   begin
      FAP.Append(F.Funcs, G);
   end;

   procedure Delete
     (F: in Func_List;
      G: in Ustring) is
      function Is_G
        (F: in Func) return Boolean is
      begin
         return Get_Name(F) = G;
      end;
      procedure Delete is new FAP.Generic_Delete(Is_G);
   begin
      Delete(F.Funcs);
   end;

   function Get
     (F: in Func_List;
      G: in Ustring) return Func is
      function Is_G
        (F: in Func) return Boolean is
      begin
         return Get_Name(F) = G;
      end;
      function Get is new FAP.Generic_Get_First_Satisfying_Element(Is_G);
      Result: constant Func := Get(F.Funcs);
   begin
      pragma Assert(Result /= Null_Func);
      return Result;
   end;

end Pn.Funcs;
