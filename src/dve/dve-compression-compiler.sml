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

fun procFunName name f = "mstate_" ^ name ^ "_" ^ f

fun compileCompressDefs (hFile, cFile) s comps procName = let
    val pos = Int.toString (positionOfProcInStateVector comps procName)
    val size = Int.toString (sizeofComps (getProcessComps procName comps))
    val prot = "void " ^ (procFunName procName "compress")
               ^ "(void * s, char * v, uint16_t * size)"
    val body = prot ^ " {*size = " ^ size ^ "; memcpy(v, s + "
               ^ pos ^ ", " ^ size ^ ");}"
in
    TextIO.output (hFile, prot ^ ";\n")
  ; TextIO.output (cFile, body ^ "\n")
end

fun compileGetSizeFunc (hFile, cFile) s comps procNames = let
    val prot = "htbl_data_size_t model_component_size"
               ^ "(unsigned int comp_id)"
    val ids = List.tabulate (List.length procNames, fn x => x)
    val funcs = ListPair.zip (ids, procNames)
    fun getCase (i, p) = let
        val size = Int.toString (sizeofComps (getProcessComps p comps))
    in
        "   case " ^ (Int.toString i) ^ ": return " ^ size ^ ";"
    end
    val cases = concatLines (List.map getCase funcs)
    val body = prot ^ concatLines [
                   "{",
                   "   switch(comp_id) {",
                   cases,
                   "   default: assert(0);",
                   "   }",
                   "}"
               ]
in
    TextIO.output (hFile, prot ^ ";\n")
  ; TextIO.output (cFile, body ^ "\n")
end

fun compileGetCompressFunc (hFile, cFile) s comps procNames = let
    val prot = "htbl_compress_func_t model_component_compress_func"
               ^ "(unsigned int comp_id)"
    val ids = List.tabulate (List.length procNames, fn x => x)
    val funcs = ListPair.zip (ids, procNames)
    fun getCase (i, p) =
      "   case " ^ (Int.toString i) ^ ": return "
      ^ (procFunName p "compress") ^ ";"
    val cases = concatLines (List.map getCase funcs)
    val body = prot ^ concatLines [
                   "{",
                   "   switch(comp_id) {",
                   cases,
                   "   default: assert(0);",
                   "   }",
                   "}"
               ]
in
    TextIO.output (hFile, prot ^ ";\n")
  ; TextIO.output (cFile, body ^ "\n")
end
fun compileReconstruct (hFile, cFile) s comps procNames = let
    val prot = "mstate_t mstate_reconstruct_from_components"
               ^ "(void ** comps, heap_t heap)"
    val ids = List.tabulate (List.length procNames, fn x => x)
    val funcs = ListPair.zip (ids, procNames)
    fun getCase (i, p) = let
        val pos = Int.toString (positionOfProcInStateVector comps p)
        val size = Int.toString (sizeofComps (getProcessComps p comps))
    in
        "   memcpy(result + " ^ pos ^ ", comps["
        ^ (Int.toString i) ^ "], " ^ size ^ ");"
    end
    val instrs = concatLines (List.map getCase funcs)
    val body = prot ^ concatLines [
                   "{",
                   "   void * result = mem_alloc(heap, " ^
                   "sizeof(struct_mstate_t));",
                   "   ((mstate_t) result)->heap = heap;",
                   instrs,
                   "   return (mstate_t) result;",
                   "}"
               ]
in
    TextIO.output (hFile, prot ^ ";\n")
  ; TextIO.output (cFile, body ^ "\n")
end

fun gen (s, hFile, cFile) = let
    val comps = buildStateCompsWithGlobalHidden s
    val (_, comps) = List.partition isCompConst comps
    val procNames = System.getProcNamesWithGlobalHidden s
in
    TextIO.output(hFile, "#define MODEL_HAS_STATE_COMPRESSION\n")
  ; TextIO.output(hFile, "#define MODEL_NO_COMPONENTS " ^
                         (Int.toString (List.length procNames)) ^ "\n")
  ; List.app (compileCompressDefs (hFile, cFile) s comps) procNames
  ; compileGetCompressFunc (hFile, cFile) s comps procNames
  ; compileGetSizeFunc (hFile, cFile) s comps procNames
  ; compileReconstruct (hFile, cFile) s comps procNames
end

end
