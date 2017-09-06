(*
 *  File:
 *     dve-enabling-test-compiler.sml
 *)


structure DveEnablingTestCompiler: sig

    val gen: System.system * bool * TextIO.outstream * TextIO.outstream
	     -> unit
end = struct

open DveCompilerUtils

fun compileGetEnabledEvents getEvents funcName
			    (s: System.system, checks, hFile, cFile) = let

    val events = getEvents s
    val comps  = buildStateComps s

    fun compileIsEventEnabled (e, checks) = let
	val mapping = buildMapping comps
	fun compileStateTest (procName, trans) =
	    "(s->" ^
	    getCompName (PROCESS_STATE procName) ^ " == " ^
	    getLocalStateName (procName, Trans.getSrc trans) ^ ")"
	fun compileStateTest2 (procName1, trans1, procName2, trans2) =
	    String.concat [
	    "(s->", getCompName (PROCESS_STATE procName1), " == ",
	    getLocalStateName (procName1, Trans.getSrc trans1), ") && ",
	    "(s->", getCompName (PROCESS_STATE procName2), " == ",
	    getLocalStateName (procName2, Trans.getSrc trans2), ")" ]
	fun compileGuardTest (procName, trans) =
	    case Trans.getGuard trans
	     of NONE => ""
 	      | SOME e =>
		" && " ^
		compileExpr "s" e (SOME procName, mapping, comps, checks)
    in
	case e of
	    LOCAL (_, p, t) =>
	    compileStateTest (p, t) ^ compileGuardTest (p, t)
	  | SYNC  (_, _, p1, t1, p2, t2) =>
	    compileStateTest2 (p1, t1, p2, t2) ^
	    compileGuardTest (p1, t1) ^ compileGuardTest (p2, t2)
    end

    fun testName e = "is_enabled_" ^ (getEventName e)

    fun compileIsEnabledTest e =
	String.concat [ "\n#define ", testName e, "(s) (",
			compileIsEventEnabled (e, checks), ")" ]

    fun compileTest (enVar, noVar) e =
	String.concat [
	"   if (", enVar, "[i ++] = (is_enabled_" ^ (getEventName e),
	" (s))) ", noVar, " ++;" ]

    val protMem = String.concat [ "mevent_set_t " ^ funcName ^ "_mem" ^
			       " (mstate_t s, heap_t heap)" ]
    val bodyMem = [
	protMem ^ " {",
	"   unsigned short i = 0, no_evts = 0, j = 0;",
	"   bool_t en [NO_EVENTS];",
	"   mevent_set_t result = mem_alloc " ^
	"(heap, sizeof (struct_mevent_set_t));",
	"   result->no_evts = 0;",
	"   result->heap = heap;",
	"   i = 0;",
	concatLines (List.map (compileTest ("en", "no_evts")) events),
 	"   result->no_evts = no_evts;",
	"   result->evts = mem_alloc " ^
	"(heap, result->no_evts * sizeof (mevent_t));",
	"   no_evts = 0;",
	"   for (i = 0; i < NO_EVENTS; i ++)",
	"      if (en[i])",
	"         result->evts[no_evts ++] = i;",
	"   return result;",
	"}" ]
    val bodyMem = concatLines bodyMem

    val prot = String.concat [ "mevent_set_t " ^ funcName ^ " (mstate_t s)" ]
    val body = [
	prot ^ " {",
	"   return " ^ funcName ^ "_mem (s, SYSTEM_HEAP);",
	"}" ]
    val body = concatLines body

    fun compileFuncs events =
	List.app (fn f => TextIO.output (hFile, f))
		 (List.map compileIsEnabledTest events)
in
    compileFuncs events;
    TextIO.output (hFile, "\n" ^ prot ^ ";\n");
    TextIO.output (hFile, "\n" ^ protMem ^ ";\n");
    TextIO.output (cFile, "\n" ^ body ^ "\n");
    TextIO.output (cFile, "\n" ^ bodyMem ^ "\n")
end

fun compileGetEnabledEvent getEvents funcName
			   (s: System.system, checks, hFile, cFile) = let
    val prot    = String.concat [
		  "mevent_t ", funcName,
		  " (mstate_t s, mevent_id_t id)" ]
    val protMem = String.concat [
		  "mevent_t ", funcName, "_mem",
		  " (mstate_t s, mevent_id_t id, heap_t heap)" ]
    val body    = concatLines [ prot, " { return id; }" ]
    val bodyMem = concatLines [ protMem, " { return id; }" ]
in
    TextIO.output (hFile, "\n" ^ prot ^ ";\n");
    TextIO.output (hFile, "\n" ^ protMem ^ ";\n");
    TextIO.output (cFile, "\n" ^ body ^ "\n");
    TextIO.output (cFile, "\n" ^ bodyMem ^ "\n")
end

fun gen (s, checks, hFile, cFile) = (
    TextIO.output (hFile, "/*  enabling test functions  */");
    TextIO.output (cFile, "/*  enabling test functions  */");
    compileGetEnabledEvent
	buildEvents "mstate_enabled_event" (s, checks, hFile, cFile);
    compileGetEnabledEvents
	buildEvents "mstate_enabled_events" (s, checks, hFile, cFile);
    TextIO.output
        (hFile,
         concatLines [
	     "void mstate_stubborn_set (mstate_t s, mevent_set_t en);" ]);
    TextIO.output
        (cFile,
         concatLines [
	     "void mstate_stubborn_set (mstate_t s, mevent_set_t en) {",
             "/*  not implemented  */",
	     "}" ]))
end
