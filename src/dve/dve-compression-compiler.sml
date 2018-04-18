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

fun createCompressionItemList s comps procNames = let
    val (minCompSize, maxCompSize) = DveCompilerOptions.getCompressionMinMax ()
    fun splitComponents (procName, (items, first, last)) = let
        val remaining = last - first
        val size = sizeofComps (getProcessComps procName comps)
    in
        if size >= maxCompSize
        then (if remaining > 0
              then  let val newRes = (items @ [ remaining ], last, last)
                    in splitComponents (procName, newRes) end
              else let val n = size div maxCompSize
                               + (if size mod maxCompSize = 0 then 0 else 1)
                       val compSize = size div n
                       val lastCompSize = compSize + size - (compSize * n)
                       val it = List.tabulate (n, fn i => if i < n - 1
                                                          then compSize
                                                          else lastCompSize)
                   in
                       (items @ it, first + size, last + size)
                   end)
        else if size + remaining >= maxCompSize
        then let val newRes = (items @ [ remaining ], last, last)
             in splitComponents (procName, newRes) end
        else if size + remaining >= minCompSize
        then let val next = last + remaining + size
             in (items @ [ remaining + size ], next, next) end
        else (items, first, last + size)
    end
    val (sizes , first, last) = List.foldl splitComponents ([], 0, 0) procNames
    val result = if first = last
                 then sizes
                 else sizes @ [ last - first ]
in
    result
end

fun compileCompressDefs (hFile, cFile) l = let
    val (h, c, _, _) =
        List.foldl (fn (size, (h, c, pos, comp)) =>
                       let val s = Int.toString size
                           val p = Int.toString pos
                           val prot =
                               "void mstate_compress_comp"
                               ^ (Int.toString comp)
                               ^ "(void * s, char * v, uint16_t * size)"
                           val code =
                               prot ^ " { *size = " ^ s
                               ^ "; memcpy(v, s + " ^ p ^ ", " ^ s ^ "); }"
                           val prot = prot ^ ";"
                           val h = h @ [ prot ]
                           val c = c @ [ code ]
                       in (h, c, pos + size, comp + 1) end)
                   ([], [], 0, 0) l
    val fmt = ListFormat.fmt { init = "", sep = "\n",
                               final = "\n", fmt = fn x => x }
in
    TextIO.output (hFile, fmt h)
  ; TextIO.output (cFile, fmt c)
end

fun compileGetSizeFunc (hFile, cFile) l = let
    val prot = "htbl_data_size_t model_component_size"
               ^ "(unsigned int comp_id)"
    val ids = List.tabulate (List.length l, fn x => x)
    fun getCase (i, s) =
      "   case " ^ (Int.toString i) ^ ": return " ^ (Int.toString s) ^ ";"
    val cases = concatLines (List.map getCase (ListPair.zip (ids, l)))
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

fun compileGetCompressFunc (hFile, cFile) l = let
    val prot = "htbl_compress_func_t model_component_compress_func"
               ^ "(unsigned int comp_id)"
    fun getCase c =
      "   case " ^ (Int.toString c)
      ^ ": return mstate_compress_comp" ^ (Int.toString c) ^ ";"
    val ids = List.tabulate (List.length l, fn x => x)
    val cases = concatLines (List.map getCase ids)
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

fun compileReconstruct (hFile, cFile) l = let
    val prot = "mstate_t mstate_reconstruct_from_components"
               ^ "(void ** comps, heap_t heap)"
    val ids = List.tabulate (List.length l, fn x => x)
    val pos = ref 0
    fun getCase (i, s) =
      ("   memcpy(result + " ^ (Int.toString (!pos)) ^ ", comps["
       ^ (Int.toString i) ^ "], " ^ (Int.toString s) ^ ");")
      before pos := !pos + s
    val instrs = concatLines (List.map getCase (ListPair.zip (ids, l)))
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
    val l = createCompressionItemList s comps procNames
in
    TextIO.output(hFile, "#define MODEL_HAS_STATE_COMPRESSION\n")
  ; TextIO.output(hFile, "#define MODEL_NO_COMPONENTS " ^
                         (Int.toString (List.length l)) ^ "\n")
  ; compileCompressDefs (hFile, cFile) l
  ; compileGetCompressFunc (hFile, cFile) l
  ; compileGetSizeFunc (hFile, cFile) l
  ; compileReconstruct (hFile, cFile) l
end

end
