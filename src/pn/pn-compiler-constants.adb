with
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Vars;

use
  Pn.Compiler.Names,
  Pn.Exprs,
  Pn.Vars;

package body Pn.Compiler.Constants is

   procedure Gen_Const
     (Const: in Var;
      Lib  : in Library) is
   begin
      Nlc(Lib);
      Plc(Lib, "/* constant " & Get_Name(Const) & " */");
      Plh(Lib, Cls_Name(Get_Cls(Const)) & " " & Var_Name(Const) & ";");
   end;

   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      Consts : constant Var_List := Get_Consts(N);
      Comment: constant Ustring :=
        To_Ustring("This library contains the constants defined in the net.");
      Lib    : Library;

      procedure Gen_Lib_Init_Func is
         Prototype: Ustring;
         Consts   : constant Var_List := Get_Consts(N);
         Const    : Var;
      begin
         Prototype :=
           "void " & Lib_Init_Func(Constants_Lib) & Nl &
           "()";
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype & " {");
         for I in 1..Length(Consts) loop
            Const := Ith(Consts, I);
            Plc(Lib, 1,
                Var_Name(Const) & " = " &
                Compile_Evaluation(Get_Init(Const)) & ";");
         end loop;
         Plc(Lib, "}");
      end;

      procedure Gen_Lib_Free_Func is
         Prototype: Ustring;
      begin
         Prototype :=
           "void " & Lib_Free_Func(Constants_Lib) & Nl &
           "()";
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype & " {}");
      end;

   begin
      Init_Library(Constants_Lib, Comment, Path, Lib);
      Plh(Lib, "#include ""colors.h""");
      Plh(Lib, "#include ""funcs.h""");
      for I in 1..Length(Consts) loop
         Gen_Const(Ith(Consts, I), Lib);
      end loop;
      Gen_Lib_Init_Func;
      Gen_Lib_Free_Func;
      End_Library(Lib);
   end;

end Pn.Compiler.Constants;
