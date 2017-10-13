(*
 *  File:
 *     dve-xml-compiler.sml
 *)


structure DveXmlCompiler: sig

    val gen: System.system * TextIO.outstream * TextIO.outstream
	     -> unit

end = struct

open DveCompilerUtils

fun compileStateToXml (s: System.system, hFile, cFile) = let
    val prot = "void mstate_to_xml (mstate_t s, FILE * out)"
    val body =
	concatLines [
	prot ^ " { assert(0); }"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun compileEventToXml (s: System.system, hFile, cFile) = let
    val prot = "void mevent_to_xml (mevent_t e, FILE * out)"
    val body =
	concatLines [
	prot ^ " { assert(0); }"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun compileModelXmlStatistics (s: System.system, hFile, cFile) = let
    val prot = "void model_xml_statistics (FILE * out)"
    val body =
	concatLines [
	prot ^ " {",
	"   fprintf (out, \"<modelStatistics>\");",
	"   fprintf (out, \"<stateVectorSize>\");",
	"   fprintf (out, \"%d\", STATE_VECTOR_SIZE);",
	"   fprintf (out, \"</stateVectorSize>\");",
	"   fprintf (out, \"</modelStatistics>\");",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun compileModelXmlParameters (s: System.system, hFile, cFile) = let
    val prot = "void model_xml_parameters (FILE * out)"
    val body =
	concatLines [
	prot ^ " {",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun gen params = (
    compileStateToXml params;
    compileEventToXml params;
    compileModelXmlStatistics params;
    compileModelXmlParameters params)

end
