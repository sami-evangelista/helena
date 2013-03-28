(*
 *  File:
 *     dve-independence-relation-compiler.sml
 *
 *  Created:
 *     Nov. 17, 2008
 *
 *  Generate:
 *     structure DveIndependenceRelation: INDEPENDENCE_RELATION = struct
 *        structure Model = DveModel
 *        ...
 *     end
 *)


structure DveIndependenceRelationCompiler: sig

    val gen: System.system -> string list

end = struct

open DveCompilerUtils

fun compileAreIndependent (s: System.system) = let

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

    fun twoEvents (e1, e2) =
	if areIndependent (e1, e2)
	then String.concat [
	     " (", getEventName e1, ", ", getEventName e2, ") => true\n  |" ]
	else ""
in
    [ "val areIndependent = fn\n   " ] @
    ListXProd.mapX twoEvents (events, events) @
    [ " _ => false\n" ]
end

fun compilePersistentSet (s: System.system) = let
    val ls = System.getCoIndependentStates s
    fun oneCase l = let
	val t = List.concat (List.map (fn (_, _, t) => t) l)
	val test = 
	    listFormat {
	    init  = "(fn e => false",
	    sep   = "",
	    final = ") ",
	    fmt   = (fn t => (" orelse " ^ (case getEventName' t
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
in
    "fun persistentSet (s, e) = " ^
    (if ls = []
     then "e\n"
     else "\n" ^ (listFormat {
		  init  = "   ",
		  sep   = "\n   else ",
		  final = "\n   else e\n",
		  fmt   = oneCase } ls))
end

fun gen s =
    [ "structure DveIndependenceRelation: INDEPENDENCE_RELATION = ",
      "struct\n",
      "open DveDefinitions\n" ] @
    compileAreIndependent s @
    [ compilePersistentSet s,
      "end\n" ]
end
