--=============================================================================
--
--  Package: Pn.Compiler.State
--
--  This is the base package for the generation of the state library
--  which define the state type.  It also defines functions and macros
--  to manipulate states.  Local markings of places are represented by
--  lists.
--
--  Serialisation of states:
--  States stored in the state space are encoded in bit vectors before
--  their insertion in the state space in order to save space.  A
--  state is encoded - as follows (empty places are not encoded).
--
--  > | Number of non empty and non redundant places |
--  > | Marked place 1 id | Marked place 1 content |
--  > | ... |
--  > | Marked place N id | Marked place N content |
--
--  The number of marked places is encoded on log_2(|P| + 1) bits, and the id
--  of each marked place is encoded on log_2(|P|) bits.
--
--  The content of each marked place is encoded as follows.
--
--  > | Token 1 multiplicity | Token 1 value | 0 |
--  > | Token 2 multiplicity | Token 2 value | 0 |
--  > | ... |
--  > | Token N multiplicity | Token N value | 1 |
--
--  The multiplicity of a token is encoded on
--  log_2(Get_Capacity(p)). The number of bits used to encode a token
--  of place p is log_2(|C(p)|).  An additional bit is placed after
--  each token to indicate whether it is the last of the list or not.
--
--  The state type:
--  The state type is defined as:
--  > typedef struct {
--  >    ...
--  > } state_struct_t;
--  > typedef state_struct_t * state_t;
--
--=============================================================================


package Pn.Compiler.State is

   --==========================================================================
   --  Group: Main generation procedure
   --==========================================================================

   procedure Gen
     (N   : in Net;
      Path: in Ustring);



   --==========================================================================
   --  Group: Global state
   --==========================================================================

   function State_Component_Name
     (P: in Place) return Ustring;



   --==========================================================================
   --  Group: Local state of a place
   --==========================================================================

   function Local_State_Type
     (P: in Place) return Ustring;

   function Local_State_Init_Func
     (P: in Place) return Ustring;

   function Local_State_List_Type
     (P: in Place) return Ustring;

   function Local_State_Is_Empty_Func
     (P: in Place) return Ustring;

   function Local_State_Add_Tokens_Func
     (P: in Place) return Ustring;

   function Local_State_To_Xml_Func
     (P: in Place) return Ustring;


private


   function Local_State_Set_Heap_Func
     (P: in Place) return Ustring;
   function Local_State_Card_Func
     (P: in Place) return Ustring;
   function Local_State_Cmp_Local_State_Func
     (P: in Place) return Ustring;
   function Local_State_Free_Func
     (P: in Place) return Ustring;
   function Local_State_Copy_Func
     (P: in Place) return Ustring;
   function Local_State_Print_Func
     (P: in Place) return Ustring;
   function Local_State_Encode_Func
     (P: in Place) return Ustring;
   function Local_State_Decode_Func
     (P: in Place) return Ustring;
   function Local_State_Cmp_Vector_Func
     (P: in Place) return Ustring;
   function Local_State_Hash_Func
     (P: in Place) return Ustring;

end Pn.Compiler.State;
