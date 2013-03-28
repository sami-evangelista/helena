--=============================================================================
--
--  Package: Helena_Parser.Stats
--
--  Part of the Helena parser which deals with statements.
--
--=============================================================================


private package Helena_Parser.Stats is

   procedure Parse_Stat
     (E   : in     Element;
      F   : in     Pn.Funcs.Func;
      Vars: in out Var_List_List;
      S   :    out Stat;
      Ok  :    out Boolean);

   procedure Parse_Func_Vars
     (E    : in     Element;
      Vars : in out Var_List_List;
      Nvars: in out Var_List;
      Ok   :    out Boolean);

end Helena_Parser.Stats;
