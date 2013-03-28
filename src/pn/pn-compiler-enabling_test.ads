--=============================================================================
--
--  Package: Pn.Compiler.Enabling_Test
--
--  This package enables to generate the enabling test algorithm of
--  Helena.  The enabling test for a transition t consists of
--  determining under which assignments of its variables the
--  transition t is firable.
--
--=============================================================================


with
  Pn.Guards,
  Pn.Mappings;

use
  Pn.Guards,
  Pn.Mappings;

package Pn.Compiler.Enabling_Test is

   procedure Gen
     (N   : in Net;
      Path: in Ustring);

   function Is_Evaluable
     (T: in Trans;
      N: in Net) return Boolean;


private


   No_Valid_Evaluation_Order: exception;

   type Evaluation_Item_Kind is
     (A_Tuple,
      A_Inhib_Tuple,
      A_Pick_Var,
      A_Guard,
      A_Let_Var);

   type Evaluation_Item_Record(K: Evaluation_Item_Kind) is
      record
         case K is
            when A_Tuple
	      |  A_Inhib_Tuple =>
               P: Place;
               T: Tuple;
            when A_Pick_Var =>
               Pv: Var;
            when A_Let_Var =>
               Lv: Var;
            when A_Guard =>
               G: Guard;
         end case;
      end record;

   type Evaluation_Item is access all Evaluation_Item_Record;

   procedure Free
     (E: in out Evaluation_Item);



   package Evaluation_Item_Array_Pkg is
      new Generic_Array(Evaluation_Item, null, "=");

   subtype Evaluation_Order is Evaluation_Item_Array_Pkg.Array_Type;

end Pn.Compiler.Enabling_Test;
