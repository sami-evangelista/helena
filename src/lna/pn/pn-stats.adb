package body Pn.Stats is

   procedure Deallocate is
      new Ada.Unchecked_Deallocation(Stat_Record'Class, Stat);

   procedure Initialize
     (S: access Stat_Record'Class) is
   begin
      null;
   end;

   procedure Free
     (S: in out Stat) is
   begin
      if S /= null then
         Free(S.all);
         Deallocate(S);
         S := null;
      end if;
   end;

   function Copy
     (S: access Stat_Record'Class) return Stat is
   begin
      return Copy(S.all);
   end;

   procedure Compile
     (S   : access Stat_Record'Class;
      Tabs: in     Natural;
      Lib : in     Library) is
   begin
      Compile(S.all, Tabs, Lib);
   end;



   package SAP renames Stat_Array_Pkg;

   function New_Stat_List return Stat_List is
      Result: constant Stat_List := new Stat_List_Record;
   begin
      Result.Stats := SAP.Empty_Array;
      return Result;
   end;

   function New_Stat_List
     (S: in Stat_Array) return Stat_List is
      Result: constant Stat_List := new Stat_List_Record;
   begin
      Result.Stats := SAP.New_Array(SAP.Element_Array(S));
      return Result;
   end;

   procedure Free
     (S: in out Stat_List) is
      procedure Free is new SAP.Generic_Apply(Free);
      procedure Deallocate is
         new Ada.Unchecked_Deallocation(Stat_List_Record, Stat_List);
   begin
      Free(S.Stats);
      Deallocate(S);
      S := null;
   end;

   function Copy
     (S: in Stat_List) return Stat_List is
      Result: constant Stat_List := new Stat_List_Record;
      function Copy_Stat
        (S: in Stat) return Stat is
      begin
         return Copy(S);
      end;
      function Copy is new SAP.Generic_Map(Copy_Stat);
   begin
      Result.Stats := Copy(S.Stats);
      return Result;
   end;

   function Ith
     (S: in Stat_List;
      I: in Index_Type) return Stat is
   begin
      return SAP.Ith(S.Stats, I);
   end;

   function Length
     (S: in Stat_List) return Natural is
   begin
      return SAP.Length(S.Stats);
   end;

   procedure Append
     (S: in Stat_List;
      St: in Stat) is
   begin
      SAP.Append(S.Stats, St);
   end;

   procedure Compile
     (S   : in Stat_List;
      Tabs: in Natural;
      Lib: in Library) is
   begin
      for I in 1..Length(S) loop
         Compile(Ith(S, I), Tabs, Lib);
      end loop;
   end;

end Pn.Stats;
