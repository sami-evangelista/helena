--=============================================================================
--
--  Package: Pn.Classes.Discretes.Nums.Mods
--
--  This package implements modulo classes, e.g.,
--  > type mod8: mod 8;
--
--=============================================================================


package Pn.Classes.Discretes.Nums.Mods is

   --=====
   --  Type: Mod_Cls_Record
   --
   --  See also:
   --  o <Pn>, <Pn.Classes.Discretes> and <Pn.Classes.Discretes.Nums> to see
   --    all the primitive operations overridden by this type
   --=====
   type Mod_Cls_Record is new Num_Cls_Record with private;

   --=====
   --  Type: Mod_Cls
   --=====
   type Mod_Cls is access all Mod_Cls_Record;


   --=====
   --  Function: New_Mod_Cls
   --  Constructor.
   --
   --  Parameters:
   --  Name    - name of the class
   --  Mod_Val - value of the modulo which must be a numerical expression
   --            statically evaluable
   --=====
   function New_Mod_Cls
     (Name   : in Ustring;
      Mod_Val: in Expr) return Cls;


private


   type Mod_Cls_Record is new Num_Cls_Record with
      record
         Mod_Val: Expr;  --  value of the modulo
      end record;

   procedure Free
     (C: in out Mod_Cls_Record);

   function Colors_Used
     (C: in Mod_Cls_Record) return Cls_Set;

   function Get_Low
     (C: in Mod_Cls_Record) return Num_Type;

   function Get_High
     (C: in Mod_Cls_Record) return Num_Type;

   function Is_Circular
     (C: in Mod_Cls_Record) return Boolean;

   function Normalize_Value
     (C: in Mod_Cls_Record;
      I: in Num_Type) return Num_Type;

end Pn.Classes.Discretes.Nums.Mods;
