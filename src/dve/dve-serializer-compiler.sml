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
    val prot = "unsigned int mstate_char_width (mstate_t s)"
    val body =
	concatLines [
	prot ^ " {",
	"   return STATE_VECTOR_SIZE;",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun compileStateSerialise (s: System.system, hFile, cFile) = let
    val prot = "void mstate_serialise (mstate_t s, bit_vector_t v)"
    val body =
	concatLines [
	prot ^ " {",
	"   memcpy (v, s, STATE_VECTOR_SIZE);",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun compileStateUnserialise (s: System.system, hFile, cFile) = let
    val protMem =
	"mstate_t mstate_unserialise_mem (bit_vector_t v, heap_t heap)"
    val bodyMem =
	concatLines [
	protMem ^ " {",
	"   mstate_t result = mem_alloc (heap, sizeof (struct_mstate_t));",
	"   memcpy (result, v, STATE_VECTOR_SIZE);",
	"   result->heap = heap;",
	"   return result;",
	"}"
	]
    val prot = "mstate_t mstate_unserialise (bit_vector_t v)"
    val body =
	concatLines [
	prot ^ " {",
	"   return mstate_unserialise_mem (v, SYSTEM_HEAP);",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (hFile, protMem ^ ";\n");
    TextIO.output (cFile, body ^ "\n");
    TextIO.output (cFile, bodyMem ^ "\n")
end

fun compileStateCmpVector (s: System.system, hFile, cFile) = let
    val prot = "bool_t mstate_cmp_vector (mstate_t s, bit_vector_t v)"
    val body =
	concatLines [
	prot ^ " {",
	"   unsigned int i = 0;",
	"   for (i = 0; i < STATE_VECTOR_SIZE; i ++) {",
	"      if (((char *) s)[i] != v[i]) {",
	"         return FALSE;",
	"      }",
	"   }",
	"   return TRUE;",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun compileEventSetCharWidth (s: System.system, hFile, cFile) = let
    val prot = "unsigned int mevent_set_char_width (mevent_set_t s)"
    val body =
	concatLines [
	prot ^ " {",
	"   fatal_error (\"mevent_set_char_width: unimplemented feature\");",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun compileEventSetSerialise (s: System.system, hFile, cFile) = let
    val prot = "void mevent_set_serialise (mevent_set_t s, bit_vector_t v)"
    val body =
	concatLines [
	prot ^ " {",
	"   fatal_error (\"mevent_set_serialise: unimplemented feature\");",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun compileEventSetUnserialise (s: System.system, hFile, cFile) = let
    val protMem =
	"mevent_set_t mevent_set_unserialise_mem (bit_vector_t v, heap_t heap)"
    val bodyMem =
	concatLines [
	protMem ^ " {",
	"   fatal_error (\"mevent_set_unserialise_mem: " ^
	"unimplemented feature\");",
	"}"
	]
    val prot = "mevent_set_t mevent_set_unserialise (bit_vector_t v)"
    val body =
	concatLines [
	prot ^ " {",
	"   return mevent_set_unserialise_mem (v, SYSTEM_HEAP);",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (hFile, protMem ^ ";\n");
    TextIO.output (cFile, body ^ "\n");
    TextIO.output (cFile, bodyMem ^ "\n")
end

fun gen params = (
    compileStateCharWidth params;
    compileStateSerialise params;
    compileStateUnserialise params;
    compileStateCmpVector params;
    compileEventSetCharWidth params;
    compileEventSetSerialise params;
    compileEventSetUnserialise params)

end
