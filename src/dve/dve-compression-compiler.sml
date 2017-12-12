(*
 *  File:
 *     dve-compression-compiler.sml
 *)


structure
DveCompressionCompiler:
sig
    
    val gen:
        System.system * TextIO.outstream * TextIO.outstream
	-> unit
                    
end = struct

open DveCompilerUtils

fun compileCompressProc (hFile, cFile) (p: Process.process)  = let
    val name = Process.getName p
    val prot = "uint32_t mstate_compress_" ^ name ^
               "(mstate_t s, bit_vector_t v)"
    val body =
	concatLines [
	    prot ^ " {",
	    "}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun compileCompress (s: System.system, hFile, cFile) = let
    val prot = "void mstate_compress(mstate_t s, bit_vector_t v)"
    val body =
	concatLines [
	    prot ^ " {",
	    "}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun gen (s, hFile, cFile) = (
    List.app (compileCompressProc (hFile, cFile)) (System.getProcs s);
    compileCompress (s, hFile, cFile))

end
