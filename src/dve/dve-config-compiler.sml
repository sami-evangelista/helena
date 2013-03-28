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
     concatLines [])
end

end
