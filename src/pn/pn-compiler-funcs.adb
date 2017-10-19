with
  Pn.Funcs;

use
  Pn.Funcs;

package body Pn.Compiler.Funcs is

   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      Funcs    : constant Func_List := Get_Funcs(N);
      Comment  : constant Ustring :=
        To_Ustring
        ("This library contains the functions defined in the net.");
      L        : Library;
      F        : Func;
      Prototype: Ustring;

   begin
      Init_Library(Funcs_Lib, Comment, Path, L);
      Plh(L, "#include ""colors.h""");
      Nlh(L);
      for I in 1..Length(Funcs) loop
         F := Ith(Funcs, I);
	 Compile_Prototype(F, L);
         Nlh(L);
         Compile_Body(F, L);
         Nlc(L);
      end loop;
      Prototype := "void " & Lib_Init_Func(To_Ustring("funcs")) & Nl & "()";
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {}");
      End_Library(L);
   end;

end Pn.Compiler.Funcs;
