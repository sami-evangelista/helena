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

fun compileStateHash (s: System.system, hFile, cFile) = let
    val prot = "hkey_t mstate_hash (mstate_t s)"
    val body =
	concatLines [
	    prot ^ " {",
	    "  return bit_vector_hash((bit_vector_t) s, STATE_VECTOR_SIZE);",
	    "}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun gen (s, hFile, cFile) = (
    compileStateHash (s, hFile, cFile))

end
