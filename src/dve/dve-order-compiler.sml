(*
 *  File:
 *     dve-order-compiler.sml
 *
 *  Created:
 *     Nov. 17, 2008
 *
 *  Generate:
 *     structure DveStateOrder: ORD_KEY = struct
 *        type ord_key = DveModel.state
 *        ...
 *     end
 *     structure DveEventOrder: ORD_KEY = struct
 *        type ord_key = DveModel.event
 *        ...
 *     end
 *)


structure DveOrderCompiler: sig

    val genState: System.system -> string list

    val genEvent: System.system -> string list

end = struct

open DveCompilerUtils

fun compileStateOrder (s: System.system) = let
    val comps = buildStateComps s
    fun cmpBasicItem (comp1, comp2) =
	String.concat [
	"if ", comp1, " < ", comp2, "\n",
	"   then LESS\n",
	"   else if ", comp1, " > ", comp2, "\n",
	"   then GREATER\n"
	]
    val (l1, c1) = genAllComps (comps, SOME "s1")
    val (l2, c2) = genAllComps (comps, SOME "s2")
in
    String.concat [
    "fun compareState (", c1, ": state, ", c2, ": state) =\n   ",
    case comps
     of [] => "EQUAL\n"
      | _  => listFormat { init  = "",
			   final = "   else EQUAL\n",
			   sep   = "   else ",
			   fmt   = cmpBasicItem }
			 (ListPair.zip (l1, l2)) ]
end

fun compileEventOrder (s: System.system) =
    String.concat [
    "fun compareEvent (e1: event, e2: event) = let\n",
    "   val e1 = eventToInt e1\n",
    "   val e2 = eventToInt e2\n",
    "in if e1>e2 then GREATER else if e1=e2 then EQUAL else LESS end\n" ]

fun genState s =
    [
     "structure DveStateOrder: ORD_KEY = struct\n",
     "open DveDefinitions\n",
     "type ord_key = DveModel.state\n",
     compileStateOrder s,
     "val compare = compareState\n",
     "end\n"
    ]

fun genEvent s =
    [
     "structure DveEventOrder: ORD_KEY = struct\n",
     "open DveDefinitions\n",
     "type ord_key = DveModel.event\n",
     compileEventOrder s,
     "val compare = compareEvent\n",
     "end\n"
    ]

end
