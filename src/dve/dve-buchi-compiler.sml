(*
 *  File:
 *     dve-buchi-compiler.sml
 *)


structure
DveBuchiCompiler:
sig
    
    val gen: System.system * bool * TextIO.outstream
	     -> unit

end = struct

open DveCompilerUtils

fun gen (sys, checks, out) = let
    val comps  = buildStateComps sys
    val procName = valOf (System.getProp sys)
    val proc = System.getProc (sys, procName)
    val procInit = Process.getInit proc
    val s0 = getLocalStateName (procName, State.getName procInit)
    val a = List.map (fn s => getLocalStateName (procName, State.getName s))
                     (Process.getAccept proc)
    val accepting_test =
        concatLines(List.map (fn s => "      case " ^ s ^ ": return TRUE;") a)
    fun compileIsEventEnabled (e, checks) = let
	val mapping = buildMapping comps
	fun compileStateTest (procName, trans) =
	  "(" ^ (getLocalStateName (procName, Trans.getSrc trans)) ^ " == b)"
	fun compileGuardTest (procName, trans) =
	  case Trans.getGuard trans
	   of NONE => ""
 	    | SOME e =>
	      " && " ^
	      compileExpr "s" e (SOME procName, mapping, comps, checks)
    in
	case e
         of LOCAL (_, p, t) =>
            compileStateTest (p, t) ^ compileGuardTest (p, t)
	  | SYNC  (_, _, p1, t1, p2, t2) => raise Errors.InternalError
    end
    val events = buildProcEvents (sys, procName)
    val enabling_tests =
        List.map (fn e => let
	              val t = case e
                               of LOCAL (_, _, t) => t
                               |  _ => raise Errors.InternalError
                      val d = Trans.getDest t
                      val s = getLocalStateName (procName, d)
                  in "   if(" ^ (compileIsEventEnabled (e, checks)) ^
                     ") { succs[(*no_succs) ++] = " ^ s ^ "; }"
                  end) events
    val enabling_tests = concatLines enabling_tests
    val code = [
        "",
        DveDefinitionsCompiler.compileProcessState proc,
        "bstate_t bstate_initial",
        "() {",
        "   return " ^ s0 ^ ";",
        "}",
        "",
        "bool_t bstate_accepting",
        "(bstate_t b) {",
        "  switch(b) {",
        accepting_test,
        "      default: return FALSE;",
        "   }",
        "}",
        "",
        "void bstate_succs",
        "(bstate_t b,",
        " mstate_t s,",
        " bstate_t * succs,",
        " unsigned int * no_succs) {",
        "   *no_succs = 0;",
        enabling_tests,
        "}",
        "",
        "order_t bevent_cmp",
        "(bevent_t e,",
        " bevent_t f) {",
        "   if (e.from < f.from) return LESS;",
        "   else if (e.from > f.from) return GREATER;",
        "   else if (e.to < f.to) return LESS;",
        "   else if (e.to > f.to) return GREATER;",
        "   else return EQUAL;",
        "}" ]
in
    TextIO.output (out, concatLines code)
end
                    
end
