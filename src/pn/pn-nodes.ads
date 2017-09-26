--=============================================================================
--
--  Package: Pn.Nodes
--
--=============================================================================


with
  Generic_Array,
  Pn.Mappings;

use
  Pn.Mappings;

package Pn.Nodes is

   type Node_Record is abstract tagged private;

   type Node is access all Node_Record'Class;

   type Arc is private;

   type Arc_List is private;



   --==========================================================================
   --  Group: Arc
   --==========================================================================

   function New_Arc
     (Target: access Node_Record'Class;
      T     : in     Arc_Type;
      Label : in     Mapping) return Arc;

   procedure Free
     (A: in out Arc);



   --==========================================================================
   --  Group: Arc list
   --==========================================================================

   function New_Arc_List return Arc_List;

   procedure Free
     (A: in out Arc_List);

   function Length
     (L: in Arc_List) return Count_Type;

   function Ith
     (L: in Arc_List;
      I: in Index_Type) return Arc;

   procedure Insert
     (L: in Arc_List;
      A: in Arc);



   --==========================================================================
   --  Group: Node
   --==========================================================================

   procedure Initialize
     (N   : access Node_Record'Class;
      Name: in     Ustring;
      D   : in     Dom);

   function Get_Name
     (N: access Node_Record'Class) return Ustring;

   procedure Set_Name
     (N   : access Node_Record'Class;
      Name: in     Ustring);

   function Get_Dom
     (N: access Node_Record'Class) return Dom;

   procedure Set_Dom
     (N: access Node_Record'Class;
      D: in     Dom);

   function Dom_Size
     (N: access Node_Record'Class) return Count_Type;

   function Ith_Dom
     (N: access Node_Record'Class;
      I: in     Index_Type) return Cls;

   procedure Add_Dom
     (N: access Node_Record'Class;
      C: in     Cls);

   procedure Add_Dom
     (N: access Node_Record'Class;
      C: in     Cls;
      I: in     Index_Type);

   procedure Remove_Dom
     (N: access Node_Record'Class);

   procedure Remove_Dom
     (N: access Node_Record'Class;
      I: in     Index_Type);

   procedure Add_Arc
     (N: access Node_Record'Class;
      A: in     Arc);

   procedure Delete_Arc
     (N     : access Node_Record'Class;
      Target: access Node_Record'Class;
      T     : in     Arc_Type);

   procedure Delete_Arcs
     (N: access Node_Record'Class);

   function Get_Arc_Label
     (N     : access Node_Record'Class;
      Target: access Node_Record'Class;
      T     : in     Arc_Type) return Mapping;

   procedure Set_Arc_Label
     (N     : access Node_Record'Class;
      Target: access Node_Record'Class;
      T     : in     Arc_Type;
      M     : in     Mapping);

   procedure Add_To_Arc_Label
     (N     : access Node_Record'Class;
      Target: access Node_Record'Class;
      T     : in     Arc_Type;
      M     : in     Mapping);

   procedure Add_To_Arc_Label
     (N     : access Node_Record'Class;
      Target: access Node_Record'Class;
      T     : in     Arc_Type;
      Tup   : in     Tuple);

   generic
      with procedure Action(M: in Mapping);
   procedure Generic_Apply_Arcs_Labels
     (N: access Node_Record'Class);


private


   type Arc_Record is
      record
         Target: access Node_Record'Class;  --  the end of the arc
         T     : Arc_Type;                  --  the type of the arc
         Label : Mapping;                   --  the mapping that label the arc
      end record;
   type Arc is access all Arc_Record;

   Null_Arc: constant Arc := null;

   package Arc_Array_Pkg is new Generic_Array(Element_Type => Arc,
                                              Null_Element => Null_Arc,
                                              "="          => "=");
   type Arc_List_Record is
      record
         Arcs: Arc_Array_Pkg.Array_Type;
      end record;
   type Arc_List is access Arc_List_Record;

   type Node_Record is abstract tagged
      record
         Name: Ustring;   --  name of the node
         D   : Dom;       --  its color domain
         Arcs: Arc_List;  --  arcs contiguous to the node
      end record;

   procedure Free
     (N: in out Node);

end Pn.Nodes;
