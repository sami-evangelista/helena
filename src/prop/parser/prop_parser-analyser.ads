package Prop_Parser.Analyser is

   procedure Parse_Properties
     (File_Name: in     Ustring;
      Props    :    out Property_List);

   function Get_Error_Msg return Ustring;

   Io_Exception,
   Parse_Exception: exception;

end Prop_Parser.Analyser;
