package body Pn.Stats.Cases is

   --==========================================================================
   --  case alternative
   --==========================================================================

   function New_Case_Stat_Alternative
     (E: in Expr;
      S: in Stat) return Case_Stat_Alternative is
      Result: Case_Stat_Alternative;
   begin
      Result.E := E;
      Result.S := S;
      return Result;
   end;

   procedure Free
     (C: in out Case_Stat_Alternative) is
   begin
      Free(C.E);
      Free(C.S);
   end;

   function Copy
     (A: in Case_Stat_Alternative) return Case_Stat_Alternative is
      Result: Case_Stat_Alternative;
   begin
      Result.S := Copy(A.S);
      Result.E := Copy(A.E);
      return Result;
   end;

   function Get_Expr
     (C: in Case_Stat_Alternative) return Expr is
   begin
      return C.E;
   end;

   procedure Set_Expr
     (C: in out Case_Stat_Alternative;
      E: in     Expr) is
   begin
      C.E := E;
   end;

   function Get_Stat
     (C: in Case_Stat_Alternative) return Stat is
   begin
      return C.S;
   end;

   procedure Set_Stat
     (C: in out Case_Stat_Alternative;
      S: in     Stat) is
   begin
      C.S := S;
   end;

   procedure Compile
     (C   : in Case_Stat_Alternative;
      Tabs: in Natural;
      Lib: in Library) is
   begin
      Plc(Lib, Tabs, "case " & Compile_Evaluation(C.E) & ":");
      Compile(C.S, Tabs+1, Lib);
      Plc(Lib, Tabs + 1, "break;");
   end;



   --==========================================================================
   --  case alternative list
   --==========================================================================

   package CAAP renames Case_Stat_Alternative_Array_Pkg;

   function New_Case_Stat_Alternative_List return Case_Stat_Alternative_List is
      Result: constant Case_Stat_Alternative_List :=
        new Case_Stat_Alternative_List_Record;
   begin
      Result.Alts := CAAP.Empty_Array;
      return Result;
   end;

   function New_Case_Stat_Alternative_List
     (C: in Case_Stat_Alternative_Array) return Case_Stat_Alternative_List is
      Result: constant Case_Stat_Alternative_List :=
        new Case_Stat_Alternative_List_Record;
   begin
      Result.Alts := CAAP.New_Array(CAAP.Element_Array(C));
      return Result;
   end;

   procedure Free
     (C: in out Case_Stat_Alternative_List) is
      procedure Free is new CAAP.Generic_Apply(Free);
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Case_Stat_Alternative_List_Record,
                                        Case_Stat_Alternative_List);
   begin
      Free(C.Alts);
      Deallocate(C);
      C := null;
   end;

   function Copy
     (C: in Case_Stat_Alternative_List) return Case_Stat_Alternative_List is
      Result: constant Case_Stat_Alternative_List :=
        new Case_Stat_Alternative_List_Record;
      function Copy is new CAAP.Generic_Map(Copy);
   begin
      Result.Alts := Copy(C.Alts);
      return Result;
   end;

   procedure Append
     (C: in Case_Stat_Alternative_List;
      Ca: in Case_Stat_Alternative) is
   begin
      CAAP.Append(C.Alts, Ca);
   end;

   function Length
     (C: in Case_Stat_Alternative_List) return Count_Type is
   begin
      return CAAP.Length(C.Alts);
   end;

   function Ith
     (C: in Case_Stat_Alternative_List;
      I: in Index_Type) return Case_Stat_Alternative is
   begin
      return CAAP.Ith(C.Alts, I);
   end;

   function Contains
     (C  : in Case_Stat_Alternative_List;
      Alt: in Expr) return Boolean is
      function Is_Alt
        (C: in Case_Stat_Alternative) return Boolean is
      begin
         return Static_Equal(Alt, Get_Expr(C));
      end;
      function Contains is new CAAP.Generic_Exists(Is_Alt);
   begin
      return Contains(C.Alts);
   end;

   procedure Compile
     (C   : in Case_Stat_Alternative_List;
      Tabs: in Natural;
      Lib: in Library) is
      procedure Compile
        (C: in out Case_Stat_Alternative) is
      begin
         Compile(C, Tabs, Lib);
      end;
      procedure Compile is new CAAP.Generic_Apply(Compile);
   begin
      Compile(C.Alts);
   end;



   --==========================================================================
   --  case statement
   --==========================================================================

   function New_Case_Stat
     (E      : in Expr;
      Alt    : in Case_Stat_Alternative_List;
      Default: in Stat) return Stat is
      Result: constant Case_Stat := new Case_Stat_Record;
   begin
      Initialize(Result);
      Result.E := E;
      Result.Alt := Alt;
      Result.Default := Default;
      return Stat(Result);
   end;

   function New_Case_Stat
     (E  : in Expr;
      Alt: in Case_Stat_Alternative_List) return Stat is
   begin
      return New_Case_Stat(E, Alt, null);
   end;

   procedure Free
     (S: in out Case_Stat_Record) is
   begin
      Free(S.E);
      Free(S.Alt);
      if S.Default /= null then
         Free(S.Default);
      end if;
   end;

   function Copy
     (S: in Case_Stat_Record) return Stat is
      Result: constant Case_Stat := new Case_Stat_Record;
      function Copy is new CAAP.Generic_Map(Copy);
   begin
      Initialize(Result);
      Result.Alt := Copy(S.Alt);
      if S.Default /= null then
         Result.Default := Copy(S.Default);
      end if;
      return Stat(Result);
   end;

   procedure Compile
     (S   : in Case_Stat_Record;
      Tabs: in Natural;
      Lib : in Library) is
   begin
      Plc(Lib, Tabs, "switch(" & Compile_Evaluation(S.E) & ")");
      Plc(Lib, Tabs, "{");
      Compile(S.Alt, Tabs+1, Lib);
      if S.Default /= null then
         Plc(Lib, Tabs + 1, "default:");
         Compile(S.Default, Tabs+2, Lib);
         Plc(Lib, Tabs + 2, "break;");
      end if;
      Plc(Lib, Tabs*Tab & "}");
   end;

end Pn.Stats.Cases;
