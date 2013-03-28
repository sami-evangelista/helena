with
  Pn.Nodes,
  Pn.Nodes.Places,
  Pn.Nodes.Transitions,
  Pn.Compiler.Config,
  Pn.Compiler.Names,
  Pn.Compiler.Vectors;

use
  Pn.Nodes,
  Pn.Nodes.Places,
  Pn.Nodes.Transitions,
  Pn.Compiler.Config,
  Pn.Compiler.Names,
  Pn.Compiler.Vectors;

package body Pn.Compiler.Util is

   --===
   --
   --  some constants and global variables name
   --
   --===

   function Capacity_Const_Name
     (P: in Place) return Ustring is
   begin
      return Const_Name(To_String("cap_" & Place_Name(P)));
   end;



   --===
   --
   --  places and transitions id
   --
   --===

   function Pid
     (P: in Place) return Ustring is
   begin
      return Const_Name(To_String("PLACE_ID_" & Place_Name(P)));
   end;

   function Tid
     (T: in Trans) return Ustring is
   begin
      return Const_Name(To_String("TRANS_ID_" & Trans_Name(T)));
   end;

   --  encodes a place identifier
   procedure Gen_Pid_Encode_Func
     (N  : in Net;
      Lib: in Library) is
      B: constant Natural := Bit_To_Encode_Pid(N);
   begin
      Plh(Lib, "#define PLACE_ID_encode(pid, bits) { \");
      Plh(Lib, 1, Vector_Set_Func(B) & "(bits, pid); \");
      Plh(Lib, "}");
   end;

   --  encodes a transition identifier
   procedure Gen_Tid_Encode_Func
     (N  : in Net;
      Lib: in Library) is
      B: constant Natural := Bit_To_Encode_Tid(N);
   begin
      Plh(Lib, "#define TRANS_ID_encode(tid, bits) { \");
      Plh(Lib, 1, Vector_Set_Func(B) & "(bits, tid); \");
      Plh(Lib, "}");
   end;

   --  decodes a place identifier
   procedure Gen_Pid_Decode_Func
     (N  : in Net;
      Lib: in Library) is
      B: constant Natural := Bit_To_Encode_Pid(N);
   begin
      Plh(Lib, "#define PLACE_ID_decode(bits, pid) \");
      Plh(Lib, "{ " & Vector_Get_Func(B) & "(bits, pid); }");
   end;

   --  decodes a transition identifier
   procedure Gen_Tid_Decode_Func
     (N  : in Net;
      Lib: in Library) is
      B: constant Natural := Bit_To_Encode_Tid(N);
   begin
      Plh(Lib, "#define TRANS_ID_decode(bits, tid) \");
      Plh(Lib, "{ " & Vector_Get_Func(B) & "(bits, tid); }");
   end;

   --  decodes back a place identifier
   procedure Gen_Pid_Decode_Back_Func
     (N  : in Net;
      Lib: in Library) is
      B: constant Natural := Bit_To_Encode_Tid(N);
   begin
      Plh(Lib, "#define PLACE_ID_decode_back(bits, pid) \");
      Plh(Lib, "{ " & Vector_Get_Back_Func(B) & "(bits, pid); }");
   end;

   --  decodes back a transition identifier
   procedure Gen_Tid_Decode_Back_Func
     (N  : in Net;
      Lib: in Library) is
      B: constant Natural := Bit_To_Encode_Tid(N);
   begin
      Plh(Lib, "#define TRANS_ID_decode_back(bits, tid) \");
      Plh(Lib, "{ " & Vector_Get_Back_Func(B) & "(bits, tid); }");
   end;

   --  generic test function on a transition id
   generic
      with function Test(T: in Trans) return Boolean;
   procedure Generic_Gen_Tid_Test_Func
     (N   : in Net;
      Func: in String;
      Lib: in Library);

   procedure Generic_Gen_Tid_Test_Func
     (N   : in Net;
      Func: in String;
      Lib: in Library) is
      T   : Trans;
      Cond: Ustring := Null_String;
   begin
      for I in 1..T_Size(N) loop
         T := Ith_Trans(N, I);
         if Test(T) then
            if Cond /= Null_String then
               Cond := Cond & " || \" & Nl;
            end if;
            Cond := Cond & "   (" & Tid(T) & " == tid)";
         end if;
      end loop;
      if Cond = Null_String then
         Plh(Lib, "#define " & Func & "(tid) FALSE");
      else
         Plh(Lib, "#define " & Func & "(tid) (\");
         Plh(Lib, Cond & ")");
      end if;
   end;

   --  check if a transition id is safe
   procedure Gen_Tid_Is_Safe_Func
     (N  : in Net;
      Lib: in Library) is
      procedure Gen is new Generic_Gen_Tid_Test_Func(Is_Safe);
   begin
      Gen(N, "TRANS_ID_is_safe", Lib);
   end;

   --  check if a transition id is visible
   procedure Gen_Tid_Is_Visible_Func
     (N  : in Net;
      Lib: in Library) is
      procedure Gen is new Generic_Gen_Tid_Test_Func(Is_Visible);
   begin
      Gen(N, "TRANS_ID_is_visible", Lib);
   end;

   procedure Gen_Id_Types
     (N  : in Net;
      Lib: in Library) is
      Prototype: Ustring;
      T        : Trans;
      P        : Place;
   begin
      Plh(Lib, "typedef unsigned short tr_id_t;");
      Plh(Lib, "typedef unsigned short pl_id_t;");
      Plh(Lib, "#define PLACE_ID_null " & P_Size(N));
      for I in 1..P_Size(N) loop
         P := Ith_Place(N, I);
         Plh(Lib, "#define " & Pid(P) & " " & (I - 1));
      end loop;
      Plh(Lib, "#define TRANS_ID_null " & T_Size(N));
      for I in 1..T_Size(N) loop
         T := Ith_Trans(N, I);
         Plh(Lib, "#define " & Tid(T) & " " & (I - 1));
      end loop;
      Gen_Pid_Encode_Func(N, Lib);
      Gen_Pid_Decode_Func(N, Lib);
      Gen_Tid_Encode_Func(N, Lib);
      Gen_Tid_Decode_Func(N, Lib);
      Gen_Tid_Decode_Back_Func(N, Lib);
      Gen_Tid_Is_Safe_Func(N, Lib);
      Gen_Tid_Is_Visible_Func(N, Lib);
      Prototype := To_Ustring
	("unsigned int TRANS_ID_safe_set (" & Nl &
	   "   tr_id_t id)");
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {");
      Plc(Lib, 1, "switch (id) {");
      for I in 1..T_Size(N) loop
         T := Ith_Trans(N, I);
	 Plc(Lib, 1, "case " & Tid(T) & ": return " &
	       Get_Safe_Set(T) & ";");
      end loop;
      Plc(Lib, 1, "default: fatal_error (""TRANS_ID_safe_set: invalid id"");");
      Plc(Lib, 1, "}");
      Plc(Lib, "}");
   end;



   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      Lib      : Library;
      Comment  : constant Ustring :=
        To_Ustring
        ("This library contains various functions and macros");
      Prototype: Ustring;
      T       : constant Trans_Vector := Get_Trans(N);
      P       : constant Place_Vector := Get_Places(N);
      Tid_Size: constant Natural := Bit_To_Encode_Tid(N);
      Pid_Size: constant Natural := Bit_To_Encode_Pid(N);
      Pl      : Place;
   begin
      Init_Library(Util_Lib, Comment, Path, Lib);
      for I in 1..Size(P) loop
         Pl := Ith(P, I);
         Plh(Lib,
             "#define " & Capacity_Const_Name(Pl) & " " & Get_Capacity(Pl));
      end loop;
      Nlh(Lib);
      Plh(Lib, "#define TID_SIZE " & Tid_Size);
      Plh(Lib, "#define PID_SIZE " & Pid_Size);
      Nlh(Lib);
      Prototype :=
	"void " & Lib_Init_Func(Util_Lib) & Nl &
	"()";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {}");
      Prototype :=
	"void " & Lib_Free_Func(Util_Lib) & Nl &
	"()";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {}");
      Gen_Id_Types(N, Lib);
      End_Library(Lib);
   end;

end Pn.Compiler.Util;
