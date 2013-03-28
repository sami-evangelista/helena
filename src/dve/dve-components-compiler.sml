(*
 *  File:
 *     dve-components-compiler.sml
 *
 *  Created:
 *     Jan. 13, 2009
 *
 *  Generate:
 *     structure DveComponents: MODEL_COMPONENTS = struct
 *        type event = ...
 *        ...
 *     end
 *)


structure DveComponentsCompiler: sig

    val gen: System.system -> string list

end = struct

open DveCompilerUtils

fun updated (sys, comps) e = let
    fun updates (LOCAL (_, proc, tr), GLOBAL_VAR var) =
	List.exists (fn v => v = Var.getName var) (Trans.modifiedVars tr)
	andalso
	not (Process.hasLocalVariable (System.getProc (sys, proc))
				      (Var.getName var))
      (*****)
      | updates (LOCAL (_, proc, tr), PROCESS_STATE proc') =
	(proc = proc') andalso
	(Trans.getSrc tr) <> (Trans.getDest tr)
      (*****)
      | updates (LOCAL (_, proc, tr), LOCAL_VAR (proc', var)) =
	(proc = proc') andalso
	List.exists (fn v => v = Var.getName var) (Trans.modifiedVars tr)
      (*****)
      | updates (SYNC (i1, i2, p1, t1, p2, t2), c) =
	updates (LOCAL (i1, p1, t1), c) orelse
	updates (LOCAL (i2, p2, t2), c)
in	
    #2 (List.foldl (fn (c, (n, l)) => (n + 1, if updates (e, c)
					      then (n, c) :: l
					      else l))
		   (0, []) comps)
end

fun compileComponents (s: System.system) = let
    val comps  = List.filter (fn c => not (isCompConst c)) (buildStateComps s)
    val events = buildEvents s
    fun componentsUpdated e =
	String.concat [
	"\n  | componentsUpdated ", getEventName e, " = ",
	listFormat { init  = "[ ",
		     sep   = ", ",
		     final = " ]",
		     fmt   = Int.toString }
		   (List.map #1 (updated (s, comps) e)) ]
    val i = ref 0
    fun componentDef c = 
	String.concat [
	"COMP", Int.toString (!i), " of ",
	getCompTypeName c ] before i := !i + 1
    val i = ref 0
    fun getComponent c =
	String.concat [
	"getComponent ({", getCompName c, ", ...}: state, ",
	Int.toString (!i), ") = COMP", Int.toString (!i),
	" ", getCompName c, "\n  | " ] before i := !i + 1
    val i = ref 0
    fun componentName c =
	String.concat [
	"componentName ", Int.toString (!i), " = \"",
	getCompDescription c, "\"\n  | " ] before i := !i + 1
    val i = ref 0
    fun componentToString c =
	String.concat [
	"componentToString (COMP", Int.toString (!i), " c) = ",
	getCompToStringFuncName c, " c" ] before i := !i + 1
    val i = ref 0
    fun componentToSML c =
	String.concat [
	"componentToSMLString (COMP", Int.toString (!i), " c) = ",
	getCompToSMLStringFuncName c, " c" ] before i := !i + 1
	
in
    [ "val numComponents = ", Int.toString (List.length comps), "\n\n",
      "datatype component = \n",
      listFormat { init  = "    ",
		   sep   = "\n  | ",
		   final = "\n",
		   fmt   = componentDef } comps, "\n",
      listFormat { init  = "fun ",
		   sep   = "",
		   final = ("getComponent _ = raise Impossible \"" ^
			    "invalid component_id\"\n"),
		   fmt   = getComponent } comps, "\n",
      listFormat { init  = "fun ",
		   sep   = "",
		   final = ("componentName _ = raise Impossible \"" ^
			    "invalid component_id\"\n"),
		   fmt   = componentName } comps, "\n",
      "fun componentsUpdated DUMMY_EVENT = []",
      listFormat { init  = "",
		   sep   = "",
		   final = "\n",
		   fmt   = componentsUpdated } events, "\n",
      listFormat { init  = "fun ",
		   sep   = "\n  | ",
		   final = "",
		   fmt   = componentToString } comps, "\n",
      listFormat { init  = "fun ",
		   sep   = "\n  | ",
		   final = "",
		   fmt   = componentToSML } comps, "\n" ]
end

fun compileLargeComponents (s: System.system) = let
    val comps = List.filter (fn c => not (isCompConst c)) (buildStateComps s)
    val largeComps = buildLargeStateComps s
    val events = buildEvents s
    fun updated' e = let
	val lc = List.map #2 (updated (s, comps) e)
	fun intersect lc' =
	    List.exists (fn c => List.exists (fn c' => c = c') lc) lc'
    in
	#2 (List.foldl (fn (c, (n, l)) => (n + 1,
					   if intersect (getSubComps c)
					   then (n, c) :: l
					   else l))
		       (0, []) largeComps)
    end
in
    [
      "val numComponents = ", Int.toString (List.length largeComps), "\n",
      "fun "
    ] @
    (List.foldr (fn (e, rest) =>
		    String.concat [
		    "componentsUpdated ", getEventName e, " = ",
		    listFormat { init  = "[ ",
				 sep   = ", ",
				 final = " ]",
				 fmt   = Int.toString }
			       (List.map #1 (updated' e))  ]
		    :: "\n  | " :: rest)
		["componentsUpdated DUMMY_EVENT = []" ] events)
end

fun gen s = let
    val componentsDef = compileComponents s
    val componentsLargeDef = compileLargeComponents s
in
    [ "structure DveComponents(*: MODEL_COMPONENTS*) = struct\n",
      "open DveDefinitions\n",
      "type event = event\n",
      "type state = state\n",
      "type component_id = int\n" ] @ componentsDef @
    [ "\n",
      "val hashComponents = DveComponentsHashFunction.hash\n",
      "\nend\n\n",
      
      "structure DveLargeComponents(*: MODEL_COMPONENTS*) = struct\n",
      "open DveDefinitions\n",
      "type event = event\n",
      "type state = state\n",
      "type component_id = int\n" ] @ componentsLargeDef @
    [ "\n",
      "val hashComponents = DveLargeComponentsHashFunction.hash\n",
      "\nend\n" ]
end

end
