(*
 *  File:
 *     dve-hash-function-compiler.sml
 *)


structure
DveHashFunctionCompiler:
sig

    val gen:
        System.system * TextIO.outstream * TextIO.outstream
	-> unit
               
end = struct

open DveCompilerUtils

fun compileStateHash (hFile, cFile) = let
    val prot = "hkey_t mstate_hash(mstate_t s)"
    val body = prot ^ " { return string_hash((char *) s, MODEL_STATE_SIZE); }"
in
    TextIO.output (hFile, prot ^ ";\n")
  ; TextIO.output (cFile, body ^ "\n")
end

fun gen (s, hFile, cFile) = 
    compileStateHash (hFile, cFile)

end
