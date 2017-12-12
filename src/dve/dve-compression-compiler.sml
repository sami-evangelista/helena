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
open DveHashFunctionCompiler

fun procFunName name f =
  "mstate_" ^ name ^ "_" ^ f 

fun compileCompressDefs (hFile, cFile) s comps procName = let
    val pos = Int.toString (positionOfProcInStateVector comps procName)
    val size = Int.toString (sizeofComps (getProcessComps procName comps))
    val serialiseBody =
	"void " ^ (procFunName procName "serialise") ^
	"(mstate_t s, char * v) { memcpy(v, s + " ^ pos ^ ", " ^ size ^ "); }"
    val unserialiseBody =
	"void * " ^ (procFunName procName "unserialise") ^
	"(char * v, heap_t h) { return (void *) v; }"
    val cmpBody = 
	"bool_t " ^ (procFunName procName "cmp") ^ "(mstate_t s, char * v) " ^
	"{ return (0 == memcmp(v, s + " ^ pos ^ ", " ^ size ^
	")) ? TRUE : FALSE; }"
in
    TextIO.output (cFile, "htbl_t model_ctbl_" ^ procName ^ ";\n");
    TextIO.output (cFile, serialiseBody ^ "\n");
    TextIO.output (cFile, unserialiseBody ^ "\n");
    TextIO.output (cFile, cmpBody ^ "\n\n")
end

fun compileCompressInit (hFile, cFile) s comps = let
    fun compileCompressInit procName = let
	val size = sizeofComps (getProcessComps procName comps)
    in
	concatLines [
	    "   model_ctbl_" ^ procName ^ " =",
	    "     htbl_new(FALSE, 65536, 2, HTBL_FULL_STATIC, "
	    ^ (Int.toString size) ^ ", 0,",
	    "      (htbl_hash_func_t) "
	    ^ (processHashFuncName procName) ^ ", ",
	    "      (htbl_serialise_func_t) "
	    ^ (procFunName procName "serialise") ^ ",",
	    "      (htbl_unserialise_func_t) "
	    ^ (procFunName procName "unserialise") ^ ",",
	    "      (htbl_char_size_func_t) NULL,",
	    "      (htbl_cmp_func_t) "
	    ^ (procFunName procName "cmp") ^ ");"
	]
    end
    val prot = "void model_compress_data_init()"
    val body =
	concatLines [
	    prot ^ " {",
	    concatLines (List.map compileCompressInit
				  (System.getProcNamesWithGlobalHidden s)),
	    "}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun compileCompress (hFile, cFile) s comps procNames = let
    val instr =
	List.map (fn procName =>
		     "   htbl_insert(model_ctbl_" ^ procName ^ ", " ^
		     "(void *) s, &is_new, &id, &h); " ^
		     "memcpy(v, &id, 2); " ^
		     "v += 2;")
		 procNames
    val prot = "void mstate_compress(mstate_t s, bit_vector_t v)"
    val body =
	concatLines [
	    prot ^ " {",
	    "   bool_t is_new;",
	    "   hkey_t h;",
	    "   htbl_id_t id;",
	    concatLines instr,
	    "}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun gen (s, hFile, cFile) = let
    val comps = buildStateCompsWithGlobalHidden s
    val procNames = System.getProcNamesWithGlobalHidden s
in
    List.app (compileCompressDefs (hFile, cFile) s comps) procNames;
    compileCompressInit (hFile, cFile) s comps;
    compileCompress (hFile, cFile) comps s procNames
end

end
