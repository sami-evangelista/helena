with
  Ada.Calendar,
  Ada.Strings,
  Ada.Strings.Fixed,
  Ada.Strings.Unbounded.Text_Io,
  Ada.Unchecked_Deallocation,
  Gnat.Directory_Operations,
  Ada.Strings.Maps,
  Utils.Strings;

use
  Ada.Calendar,
  Ada.Strings,
  Ada.Strings.Fixed,
  Ada.Strings.Unbounded.Text_Io,
  Gnat.Directory_Operations,
  Ada.Strings.Maps,
  Utils.Strings;

package body Libraries is

   procedure Deallocate is new Ada.Unchecked_Deallocation(Library_Record,
                                                          Library);

   procedure Init_Library
     (Name    : in     String;
      Comment : in     String;
      Path    : in     String;
      Lib     :    out Library;
      Included: in     String_Array := Empty_String_Array) is

      procedure Put_Comment
        (File: in File_Type;
         Name: in String) is
         Now  : constant Time := Clock;
         Year : Year_Number;
         Month: Month_Number;
         Day  : Day_Number;
         Secs : Day_Duration;
         S    : Natural;
         H    : Natural;
         M    : Natural;
         function Complete
           (N: in Natural) return String is
            S: constant String := Trim(Natural'Image(N), Both);
         begin
            if N < 10 then
               return "0" & S;
            else
               return S;
            end if;
         end;
      begin
         Split(Now, Year, Month, Day, Secs);
         S := Natural(Secs);
         H := S / 3600;
         M := (S - (S / 3600) * 3600) / 60;
         Put_Line(File, "/*");
         Put_Line(File, " *");
         Put_Line(File, " * File: " & Name);
         Put(File,  " * Date: " &
               Complete(Month) & "/" &
               Complete(Day) & "/" &
               Complete(Year));
         Put_Line(File, " at " & Complete(H) & ":" & Complete(M));
         Put_Line(File, " *");
         Put_Line(File, " * " &
                  "This file has been created by Helena. " &
                  "It is useless to modify it.");
         Put_Line(File, " *");
         Put_Line(File, " * Description:");
         Put_Line(File, " *    " & Comment);
         Put_Line(File, " *");
         Put_Line(File, " */");
         New_Line(File, 2);
      end;

      File_Name: Unbounded_String;

   begin
      Lib       := new Library_Record;
      Lib.N     := To_Unbounded_String(Name);
      File_Name := Path & Dir_Separator & Lib.N;

      --===
      --  header file
      --    include the all_libs library
      --===
      Create(Lib.H, Out_File, To_String(File_Name & "." & Header_Extension));
      Put_Comment(Lib.H, To_String(Lib.N & "." & Header_Extension));
      Put_Line(Lib.H, "#ifndef " & To_Upper(Lib.N) & "_H");
      Put_Line(Lib.H, "#   define " & To_Upper(Lib.N) & "_H");
      for I in Included'Range loop
         Put_Line(Lib.H, "#include """ &
                  To_String(Included(I)) & "." & Header_Extension & """");
      end loop;
      New_Line(Lib.H, 2);

      --===
      --  code file
      --===
      Create(Lib.C, Out_File, To_String(File_Name & "." & Code_Extension));
      Put_Comment(Lib.C, To_String(Lib.N & "." & Code_Extension));
      Put_Line(Lib.C, "#include """ & Name & "." & Header_Extension & """");
   end;

   procedure End_Library
     (L: in out Library) is
   begin
      New_Line(L.H);
      Put_Line(L.H, "#endif /*  " & To_Upper(L.N) & "_H  */");
      Close(L.H);
      Close(L.C);
      Deallocate(L);
      L := null;
   end;

   function Get_Header_File
     (L: in Library) return access File_Type is
   begin
      return L.H'Access;
   end;

   function Get_Code_File
     (L: in Library) return access File_Type is
   begin
      return L.C'Access;
   end;

   procedure Nlh
     (L: in Library;
      N: in Natural := 1) is
   begin
      New_Line(L.H, Ada.Text_Io.Count(N));
   end;

   procedure Ph
     (L: in Library;
      S: in String;
      T: in Natural := 0) is
   begin
      Ada.Text_Io.Put(L.H, T*Tab & S);
   end;

   procedure Ph
     (L: in Library;
      S: in Unbounded_String;
      T: in Natural := 0) is
   begin
      Ph(L, T, To_String(S));
   end;

   procedure Ph
     (L: in Library;
      T: in Natural;
      S: in String) is
   begin
      Ph(L, S, T);
   end;

   procedure Ph
     (L: in Library;
      T: in Natural;
      S: in Unbounded_String) is
   begin
      Ph(L, S, T);
   end;

   procedure Plh
     (L: in Library;
      S: in String;
      T: in Natural := 0) is
   begin
      Ada.Text_Io.Put_Line(L.H, T*Tab & S);
   end;

   procedure Plh
     (L: in Library;
      S: in Unbounded_String;
      T: in Natural := 0) is
   begin
      Plh(L, T, To_String(S));
   end;

   procedure Plh
     (L: in Library;
      T: in Natural;
      S: in String) is
   begin
      Plh(L, S, T);
   end;

   procedure Plh
     (L: in Library;
      T: in Natural;
      S: in Unbounded_String) is
   begin
      Plh(L, S, T);
   end;

   procedure Nlc
     (L: in Library;
      N: in Natural := 1) is
   begin
      New_Line(L.C, Ada.Text_Io.Count(N));
   end;

   procedure Pc
     (L: in Library;
      S: in String;
      T: in Natural := 0) is
   begin
      Ada.Text_Io.Put(L.C, T*Tab & S);
   end;

   procedure Pc
     (L: in Library;
      S: in Unbounded_String;
      T: in Natural := 0) is
   begin
      Pc(L, To_String(S), T);
   end;

   procedure Pc
     (L: in Library;
      T: in Natural;
      S: in String) is
   begin
      Pc(L, S, T);
   end;

   procedure Pc
     (L: in Library;
      T: in Natural;
      S: in Unbounded_String) is
   begin
      Pc(L, S, T);
   end;

   procedure Plc
     (L: in Library;
      S: in String;
      T: in Natural := 0) is
   begin
      Ada.Text_Io.Put_Line(L.C, T*Tab & S);
   end;

   procedure Plc
     (L: in Library;
      S: in Unbounded_String;
      T: in Natural := 0) is
   begin
      Plc(L, To_String(S), T);
   end;

   procedure Plc
     (L: in Library;
      T: in Natural;
      S: in String) is
   begin
      Plc(L, S, T);
   end;

   procedure Plc
     (L: in Library;
      T: in Natural;
      S: in Unbounded_String) is
   begin
      Plc(L, To_String(S), T);
   end;

   procedure Section_Start_Comment
     (L      : in Library;
      Comment: in Unbounded_String) is
   begin
      L.S := Comment;
      Nlh(L, 2);
      Plh(L, "/****** begin " & Comment & " *****/");
      Nlc(L, 2);
      Plc(L, "/****** begin " & Comment & " *****/");
   end;

   procedure Section_Start_Comment
     (L      : in Library;
      Comment: in String) is
   begin
      Section_Start_Comment(L,To_Unbounded_String(Comment));
   end;

   procedure Section_End_Comment
     (L: in Library) is
   begin
      Plh(L, "/****** end   " & L.S & " *****/");
      Nlh(L, 2);
      Plc(L, "/****** end   " & L.S & " *****/");
      Nlc(L, 2);
      L.S := Null_Unbounded_String;
   end;

   procedure Pcl
     (L    : in Library;
      Lines: in String_Array) is
   begin
      for I in Lines'Range loop
	Plc (L, Lines (I));
      end loop;
   end;

   procedure Function_Header
     (L      : in Library;
      Comment: in Unbounded_String) is
      Buf         : Unbounded_String := Comment;
      Size        : constant Integer := 51;
      Current_Size: Integer := 0;
      Res         : Unbounded_String;
      Tmp         : Unbounded_String;
      Sep_Set     : constant Character_Set := To_Set(" ");
      First       : Positive;
      Last        : Natural;
   begin
      Plh(L, "");
      Plh(L, "");
      Plh(L, "/**********************************************************/");
      Res := To_Unbounded_String("/*** ");
      while Length(Buf) >= 1 loop
         Find_Token(Buf, Sep_Set, Inside, First,Last);
         if (Current_Size + First) > size then
            for I in 1..(Size-Current_Size) loop
               Res := Res & " ";
            end loop;
            Res := Res & "***/";
            Plh(L, To_String(Res));
            Current_Size := 0;
            Res := To_Unbounded_String("/*** ");
         else
            Tmp := Unbounded_Slice(Buf,1,First);
            Res := Res & Tmp;
            Current_Size := Current_Size + Length(Tmp);
            Buf := Unbounded_Slice(Buf,First+1,Length(Buf));
         end if;
      end loop;
      for I in 1..(Size-Current_Size) loop
         Res := Res & " ";
      end loop;
      Res := Res & "***/";
      Plh(L, To_String(Res));
      Plh(L, "/**********************************************************/");
   end;

end Libraries;
