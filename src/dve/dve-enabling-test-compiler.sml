(*
 *  File:
 *     dve-enabling-test-compiler.sml
 *)


structure
DveEnablingTestCompiler:
sig

    val gen: System.system * bool * TextIO.outstream * TextIO.outstream
	     -> unit
end = struct

open DveCompilerUtils

fun compileGetEnabledEvents
        funcName (s: System.system, checks, hFile, cFile) = let

    val events = buildEvents s
    val comps  = buildStateComps s

    fun compileIsEventEnabled e = let
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
		      compileIsEventEnabled e, ")" ]

    fun compileTest (enVar, noVar) e =
      String.concat [
	  "   if(", testName e, "(s)) { e = ", getEventName e,
          "; list_append(result, &e); }" ]

    val prot = String.concat [ "list_t " ^ funcName ^
			       " (mstate_t s, heap_t heap)" ]
    val body = concatLines [
	    prot ^ " {",
            "   mevent_t e;",
            "   list_t result = " ^
            "list_new(heap, sizeof(mevent_t), NULL);",
	    concatLines (List.map (compileTest ("en", "no_evts")) events),
	    "   return result;",
	    "}" ]

    fun compileFuncs events =
      List.app (fn f => TextIO.output (hFile, f))
	       (List.map compileIsEnabledTest events)
in
    compileFuncs events
  ; TextIO.output (hFile, "\n" ^ prot ^ ";\n")
  ; TextIO.output (cFile, "\n" ^ body ^ "\n")
end

fun compileGetEnabledEvent
        funcName (s: System.system, checks, hFile, cFile) = let
    val prot = String.concat [
	    "mevent_t ", funcName,
	    " (mstate_t s, mevent_t e, heap_t heap)" ]
    val body = concatLines [ prot, " { return e; }" ]
in
    TextIO.output (hFile, "\n" ^ prot ^ ";\n")
  ; TextIO.output (cFile, "\n" ^ body ^ "\n")
end

fun gen (s, checks, hFile, cFile) = (
    TextIO.output (hFile, "#include \"list.h\"")
  ; TextIO.output (hFile, "/*  enabling test functions  */")
  ; TextIO.output (cFile, "/*  enabling test functions  */")
  ; compileGetEnabledEvent "mstate_event" (s, checks, hFile, cFile)
  ; compileGetEnabledEvents "mstate_events" (s, checks, hFile, cFile))
end
