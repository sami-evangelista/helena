(*
 *  File:
 *     dve-independence-relation-compiler.sml
 *)


structure
DveIndependenceRelationCompiler:
sig

    val gen:
        System.system * TextIO.outstream * TextIO.outstream
	-> unit

end = struct

open DveCompilerUtils

fun compileAreIndependent (s: System.system, hFile, cFile) = let

    (*
    val procs = System.getProcs s
    val events = buildEvents s

    fun areIndependent
	(e1 as (LOCAL (_, p1, t1)),
	 e2 as (LOCAL (_, p2, t2))) =
	 System.areIndependent ((Process.getProcess (procs, p1), t1),
				(Process.getProcess (procs, p2), t2))
      | areIndependent
	(e1 as (LOCAL (_, p1, t1)),
	 e2 as (SYNC (_, _, p2, t2, p3, t3))) =
	 System.areIndependent ((Process.getProcess (procs, p1), t1),
				(Process.getProcess (procs, p2), t2)) andalso
	 System.areIndependent ((Process.getProcess (procs, p1), t1),
				(Process.getProcess (procs, p3), t3))
      | areIndependent
	(e1 as (SYNC (_, _, p1, t1, p2, t2)),
	 e2 as (SYNC (_, _, p3, t3, p4, t4))) =
	 System.areIndependent ((Process.getProcess (procs, p1), t1),
				(Process.getProcess (procs, p3), t3)) andalso
	 System.areIndependent ((Process.getProcess (procs, p1), t1),
				(Process.getProcess (procs, p4), t4)) andalso
	 System.areIndependent ((Process.getProcess (procs, p2), t2),
				(Process.getProcess (procs, p3), t3)) andalso
	 System.areIndependent ((Process.getProcess (procs, p2), t2),
				(Process.getProcess (procs, p4), t4))
      | areIndependent (e1, e2) = areIndependent (e2, e1)
                 
    val switch =
        List.map (fn e => let
                      val test = List.foldl
                                     (fn (f, test) =>
                                         test ^
                                         (if areIndependent (e, f)
                                          then " || f == " ^ (getEventName f)
                                          else ""))
                                     "FALSE" events
                  in
                      if test = "FALSE"
                      then ""
                      else "      case " ^ getEventName e ^
                           ": return (" ^ test ^ ") ? TRUE : FALSE;"
                  end) events
    val switch = concatLines (List.filter (fn t => t <> "") switch)
      *)           
    val prot = concatLines
                   [ "bool_t mevent_are_independent",
                     "(mevent_t e,",
                     " mevent_t f)" ]
    val body = prot ^
               (concatLines [
                     " {",
                     "   switch(e) {",
                     (*switch,*)
                     "      default: return FALSE;",
                     "   }",
                     "}" ])
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun compilePersistentSet (s: System.system, hFile, cFile) = let
    val ls = System.getCoIndependentStates s
    val events = buildEvents s
    fun oneCase l = let
	val t = List.concat (List.map (fn (_, _, t) => t) l)
	val test = 
	    listFormat {
	    init  = "(fn e => false",
	    sep   = "",
	    final = ") ",
	    fmt   = (fn t => (" orelse " ^ (case getEventName' (events, t)
					     of	NONE   => "false"
					      | SOME e => e ^ " = e")))
	    } t
    in
	String.concat [
	"if ",
	listFormat {
	init  = "",
	sep   = " andalso ",
	final = " ",
	fmt   = (fn (p, s, _) =>
		    (getComp (PROCESS_STATE (Process.getName p), "s") ^ " = " ^
		     getLocalStateName (Process.getName p, State.getName s)))
	} l,
	"andalso (List.exists ", test, " e) then\n",
	"      List.filter ", test, "e"
	]
    end
    val prot = [
            "bool_t mevent_is_safe",
            "(mevent_t e)" ]
    val body = prot @ [
            " {",
            "}" ]
in                  
    TextIO.output (cFile, "/*fun persistentSet (s, e) = " ^
                          (if ls = []
                           then "e*/\n"
                           else "\n" ^ (listFormat {
		                             init  = "   ",
		                             sep   = "\n   else ",
		                             final = "\n   else e\n",
		                             fmt   = oneCase } ls) ^ "*/"))
end

fun gen (s, hFile, cFile) = (
    compileAreIndependent (s, hFile, cFile))
  
end
