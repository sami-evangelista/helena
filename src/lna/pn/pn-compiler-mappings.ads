--=============================================================================
--
--  Package: Pn.Compiler.Mappings
--
--  This package enables to compile the mappings and initial state of
--  a net in a C library.
--
--=============================================================================


package Pn.Compiler.Mappings is

   --==========================================================================
   --  Group: Main generation procedure
   --==========================================================================

   --=====
   --  Procedure: Gen
   --  Main generation procedure.
   --  Compile all the mappings and initial markings of net N.  Path
   --  is the absolute path of the directory in which the generated
   --  library will be placed.
   --=====
   procedure Gen
     (N   : in Net;
      Path: in Ustring);



   --==========================================================================
   --  Group: Functions generated
   --==========================================================================

   --=====
   --  Type: Mapping_Mode
   --  mode of a mapping application:
   --  - *Add* tokens are added to the place
   --  - *Remove* tokens are removed from the place
   --=====
   type Mapping_Mode is
     (Add,
      Remove);

   --=====
   --  Function: M0_Func
   --  Name of the macro which adds or removes m0(p) to a
   --  state.
   --  Prototype:
   --  > #define add_m0(s, c, check_cap)
   --  where s is a state of type state_t c must be NULL and check_cap
   --  is a boolean which states if the capacity of the place must be
   --  checked.
   --=====
   function M0_Func
     (P: in Place;
      M: in Mapping_Mode) return Ustring;

   --=====
   --  Function: Arc_Mapping_Func
   --  Name of the function which adds or removes from a state the
   --  bag produced by the mapping which labels the arc of type A between P
   --  and T.
   --  Prototype:
   --  > #define add_mapping(m, c, check_cap)
   --  where s is a state of type state_t c is the instantiation color
   --  of T of type <Pn.Compiler.Domains.Trans_Dom_Type> (T) and
   --  check_cap is a boolean which states if the capacity of the
   --  place must be checked.
   --=====
   function Arc_Mapping_Func
     (P: in Place;
      T: in Trans;
      A: in Arc_Type;
      M: in Mapping_Mode) return Ustring;

end Pn.Compiler.Mappings;
