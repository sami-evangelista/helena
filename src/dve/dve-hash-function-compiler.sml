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

    val processHashFuncName:
	string
	-> string
                    
end = struct

open DveCompilerUtils

fun processHashFuncName procName =
  "mstate_hash_" ^ procName

fun compileProcessHash comps (hFile, cFile) procName = let
    val pos = positionOfProcInStateVector comps procName
    val size = sizeofComps (getProcessComps procName comps)
    val prot = "hkey_t " ^ (processHashFuncName procName) ^ "(mstate_t s)"
    val body =
	concatLines [
	    prot ^ " {",
	    "  return bit_vector_hash((bit_vector_t) s + " ^
	    (Int.toString pos) ^ ", " ^ (Int.toString size) ^ ");",
	    "}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun compileStateHash (hFile, cFile) = let
    val prot = "hkey_t mstate_hash(mstate_t s)"
    val body =
	concatLines [
	    prot ^ " {",
	    "  return bit_vector_hash((bit_vector_t) s, " ^
            "MODEL_STATE_VECTOR_SIZE);",
	    "}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun gen (s, hFile, cFile) = let
    val comps = buildStateCompsWithGlobalHidden s
in
    List.app (compileProcessHash comps (hFile, cFile))
	     (System.getProcNamesWithGlobalHidden s);
    compileStateHash (hFile, cFile)
end

end
