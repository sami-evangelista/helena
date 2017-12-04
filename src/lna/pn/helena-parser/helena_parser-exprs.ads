--=============================================================================
--
--  Package: Helena_Parser.Exprs
--
--  Part of the Helena parser which deals with expressions.
--
--=============================================================================


private package Helena_Parser.Exprs is

   procedure Parse_Expr
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean);

   procedure Parse_Expr
     (E   : in     Element;
      C   : in     Cls;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean);

   procedure Parse_Basic_Expr
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean);

   procedure Parse_Basic_Expr
     (E   : in     Element;
      C   : in     Cls;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean);

   procedure Parse_Static_Expr
     (E   : in     Element;
      Vars: in out Var_List_List;
      Ex  :    out Expr;
      Ok  :    out Boolean);

   procedure Parse_Expr_List
     (E     : in     Element;
      Vars  : in out Var_List_List;
      D     : in     Dom;
      Check : in     Boolean;
      El    :    out Expr_List;
      Ok    :    out Boolean);

   procedure Parse_Discrete_Expr_List
     (E    : in     Element;
      Vars : in out Var_List_List;
      El   :    out Expr_List;
      Ok   :    out Boolean);

   procedure Parse_Basic_Expr_List
     (E     : in     Element;
      Vars  : in out Var_List_List;
      D     : in     Dom;
      Check : in     Boolean;
      El    :    out Expr_List;
      Ok    :    out Boolean);

   procedure Parse_Symbol
     (E    : in     Element;
      Vars : in out Var_List_List;
      Error: in     Boolean;
      Ex   :    out Expr;
      Ok   :    out Boolean);

end Helena_Parser.Exprs;
