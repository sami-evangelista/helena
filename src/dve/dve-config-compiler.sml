(*
 *  File:
 *     dve-config-compiler.sml
 *)


structure DveConfigCompiler: sig
    
    val gen: System.system * TextIO.outstream * TextIO.outstream
	     -> unit

end = struct

open DveCompilerUtils

fun gen (s, hFile, cFile) = let
in
    TextIO.output
    (hFile,
     concatLines [
	 "char * model_name ();",
	 "bool_t model_is_state_proposition (char * prop_name);"
    ]);
    TextIO.output
    (cFile,
     concatLines [
	 "char * model_name",
	 " () {",
	 "   return CFG_MODEL_NAME;",
	 "}",
	 "bool_t model_is_state_proposition",
	 " (char * prop_name) {",
	 "   return FALSE;",
	 "}",
	 "bool_t model_check_state_proposition ",
	 " (char * prop_name, mstate_t s) {",
	 "   return FALSE;",
	 "}"
    ])
end

end
