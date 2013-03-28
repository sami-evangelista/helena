--=============================================================================
--
--  Package: Pn.Nets.Exporter
--
--  This library contains various procedures to export high level nets
--  into different formalisms.
--
--=============================================================================


private package Pn.Nets.Exporter is

   procedure To_Pnml
     (N     : in     Net;
      File  : in     String;
      Unfold: in     Boolean;
      Result:    out Export_Result);

end Pn.Nets.Exporter;
