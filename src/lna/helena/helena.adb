package body Helena is

   function Unknown_Err_Msg return String is
   begin
      return
	"An uncatched exception occured" &
	Ascii.Lf &
	"Please send an e-mail with the file which caused this bug to: " &
	Ascii.Lf &
        "   sami.evangelista@lipn.univ-paris13.fr";
   end;

end Helena;
