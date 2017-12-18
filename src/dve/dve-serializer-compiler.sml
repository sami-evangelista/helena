(*
 *  File:
 *     dve-serializer-compiler.sml
 *)


structure DveSerializerCompiler: sig

    val gen: System.system * TextIO.outstream * TextIO.outstream
	     -> unit

end = struct

open DveCompilerUtils

fun compileStateCharWidth (s: System.system, hFile, cFile) = let
    val prot = "unsigned int mstate_char_size (mstate_t s)"
    val body = prot ^ " { return MODEL_STATE_SIZE; }"
in
    TextIO.output (hFile, prot ^ ";\n")
  ; TextIO.output (cFile, body ^ "\n")
end

fun compileStateSerialise (s: System.system, hFile, cFile) = let
    val prot = "void mstate_serialise(mstate_t s, char * v, uint16_t * size)"
    val body = prot
               ^ " {*size = MODEL_STATE_SIZE; memcpy(v, s, MODEL_STATE_SIZE);}"
in
    TextIO.output (hFile, prot ^ ";\n")
  ; TextIO.output (cFile, body ^ "\n")
end

fun compileStateUnserialise (s: System.system, hFile, cFile) = let
    val prot =
        "mstate_t mstate_unserialise(char * v, heap_t heap)"
    val body =
	concatLines [
	prot ^ " {",
	"   mstate_t result = mem_alloc(heap, sizeof(struct_mstate_t));",
	"   memcpy(result, v, MODEL_STATE_SIZE);",
	"   result->heap = heap;",
	"   return result;",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n")
  ; TextIO.output (cFile, body ^ "\n")
end

fun compileStateCmpString (s: System.system, hFile, cFile) = let
    val prot = "bool_t mstate_cmp_string(mstate_t s, char * v)"
    val body = prot ^ " { return 0 == memcmp(s, v, MODEL_STATE_SIZE); }"
in
    TextIO.output (hFile, prot ^ ";\n")
  ; TextIO.output (cFile, body ^ "\n")
end

fun compileEventSerialise (s: System.system, hFile, cFile) = let
    val prot = "void mevent_serialise(mevent_t e, char * v)"
    val body = prot ^ " { memcpy(v, &e, sizeof(mevent_t)); }"
in
    TextIO.output (hFile, prot ^ ";\n")
  ; TextIO.output (cFile, body ^ "\n")
end

fun compileEventUnserialise (s: System.system, hFile, cFile) = let
    val prot =
	"mevent_t mevent_unserialise(char * v, heap_t heap)"
    val body =
	concatLines [
	prot ^ " {",
        "   mevent_t result;",    
        "   memcpy(&result, v, sizeof(mevent_t));",
	"   return result;",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n")
  ; TextIO.output (cFile, body ^ "\n")
end

fun gen params = (
    compileStateCharWidth params
  ; compileStateSerialise params
  ; compileStateCmpString params
  ; compileStateUnserialise params
  ; compileEventSerialise params
  ; compileEventUnserialise params)

end
