(*
 *  File:
 *     dve-progress-compiler.sml
 *
 *  Created:
 *     Nov. 13, 2007
 *
 *  Generate:
 *     structure DveProgress1: PROGRESS_MEASURE = struct ... end
 *     ...
 *     structure DveProgressN: PROGRESS_MEASURE = struct ... end
 *  one structure is generated for each progress measure of the DVE file.
 *)


structure DveProgressCompiler: sig

val gen: System.system * bool -> string list

end = struct

open DveCompilerUtils

fun gen (s as { prog = progUsed, progs, ... }: System.system, checks) = let
    val num = ref 1
    fun progToStruct prog = let
	val name = Progress.getName prog
	val comps = buildStateComps s
	val map = buildMapping comps
	val structName = "DveProgress" ^ (Int.toString (!num))
    in
	num := !num + 1;
	[ "structure ", structName,
	  ": PROGRESS_MEASURE = struct\n",
	  "structure Progress: ORD_KEY = struct\n",
	  "type ord_key = int\n",
	  "val compare = Int.compare\n",
	  "end\n",
	  "open DveDefinitions\n",
	  "type state = state * event list\n",
	  "fun getProgress (", genComps comps, ", _) =\n",
	  "   ", compileExpr "s" (Progress.getMap prog)
			     (NONE, map, comps, checks),
	  "\nend",
	  case progUsed of NONE => ""
			 | SOME (_, name') =>
			   if name = name'
			   then "\n\nstructure DveProgress = " ^ structName
			   else "",
	  "\n\n\n"
	]
    end
in
    List.concat (List.map progToStruct progs)
end

end
