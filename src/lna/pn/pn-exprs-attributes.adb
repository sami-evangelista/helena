package body Pn.Exprs.Attributes is

   procedure Initialize
     (A        : access Attribute_Record'Class;
      Attribute: in     Attribute_Type;
      C        : in     Cls) is
   begin
      Initialize(A, C);
      A.Attribute := Attribute;
   end;

   function Get_Type
     (E: in Attribute_Record) return Expr_Type is
   begin
      return A_Attribute;
   end;

   function Compare
     (Left: in Attribute_Record;
      Right: in Attribute_Record) return Comparison_Result is
   begin
      return Cmp_Error;
   end;

   function To_Helena
     (A: in Attribute_Type) return String is
   begin
      case A is
         when A_Capacity    => return "capacity";
         when A_Card        => return "card";
         when A_Empty       => return "empty";
         when A_First       => return "first";
         when A_First_Index => return "first_index";
         when A_Full        => return "full";
         when A_Last        => return "last";
         when A_Last_Index  => return "last_index";
         when A_Prefix      => return "prefix";
         when A_Size        => return "size";
         when A_Suffix      => return "suffix";
         when A_Mult        => return "mult";
         when A_Space       => return "space";
      end case;
   end;

   procedure Get_Attribute
     (Att_Name: in     String;
      Attribute:    out Attribute_Type;
      Success  :    out Boolean) is
   begin
      Success := False;
      for Att in Attribute_Type loop
         if To_Helena(Att) = Att_Name then
            Success  := True;
            Attribute := Att;
            return;
         end if;
      end loop;
   end;

end Pn.Exprs.Attributes;
