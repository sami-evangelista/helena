with
  Gnat.Directory_Operations,
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Funcs,
  Pn.Vars;

use
  Gnat.Directory_Operations,
  Pn.Classes,
  Pn.Compiler.Names,
  Pn.Funcs,
  Pn.Vars;

package body Pn.Compiler.Interfaces is

   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      Comment : constant String :=
        "Interface file that contain all type definitions, net constant" & Nl &
        " * declarations and function prototypes.";
      Consts  : constant Var_List := Get_Consts(N);
      Funcs   : constant Func_List := Get_Funcs(N);
      Const   : Var;
      F       : Func;
      Lib     : Library;
      Included: constant Libraries.String_Array := (1..0 => Null_String);
   begin
      Init_Library(Interfaces_File, To_Ustring(Comment), Path, Included, Lib);
      Compile_Type_Definitions(Get_Cls(N), Lib);
      for I in 1..Length(Consts) loop
         Const := Ith(Consts, I);
         Plh(Lib, "/*****");
         Plh(Lib, " * net constant " & Get_Name(Const));
         Plh(Lib, " *****/");
         Plh(Lib, Cls_Name(Get_Cls(Const)) & " " & Var_Name(Const) & ";");
         Nlh(Lib);
      end loop;
      for I in 1..Length(Funcs) loop
         F := Ith(Funcs, I);
         Plh(Lib, "/*****");
         Plh(Lib, " * function " & Get_Name(F));
         Plh(Lib, " *****/");
         Compile_Prototype(F, Lib);
         Nlh(Lib);
      end loop;
      End_Library(Lib);
   end;

end;
