with
  Pn.Classes,
  Pn.Compiler.Names;

use
  Pn.Classes,
  Pn.Compiler.Names;

package body Pn.Compiler.Classes is

   --==========================================================================
   --  Main generation procedure
   --==========================================================================

   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      Lib    : Library;
      Comment: constant Ustring :=
        To_Ustring
        ("This library contains the definition of the colors of the net.");

      procedure Gen_Lib_Init_Func is
         Set      : constant Cls_Set := Get_Cls(N);
         Prototype: constant Ustring :=
           "void " & Lib_Init_Func(Colors_Lib) & Nl &
           "()";
         procedure Action
           (C: in Cls) is
         begin
            Plc(Lib, Tab & Cls_Init_Func(C) & " ();");
         end;
         procedure Apply is new Generic_Apply_In_Right_Order(Action);
      begin
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype & " {");
         Apply(Set, True);
         Plc(Lib, "}");
      end;

      procedure Gen_Lib_Free_Func is
         Prototype: constant Ustring :=
           "void " & Lib_Free_Func(Colors_Lib) & Nl &
           "()";
      begin
         Plh(Lib, Prototype & ";");
         Plc(Lib, Prototype & " {");
         Plc(Lib, "}");
      end;

   begin
      Init_Library(Colors_Lib, Comment, Path, Lib);
      Compile(Get_Cls(N), Lib);
      Gen_Lib_Init_Func;
      Gen_Lib_Free_Func;
      End_Library(Lib);
   end;

end Pn.Compiler.Classes;
