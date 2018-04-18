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
    val mapping = buildMapping comps
    val procs = System.getProcs s
    val prot = String.concat [ "list_t " ^ funcName ^
			       " (mstate_t s, heap_t heap)" ]
    fun compileProc p = let
        val pName = Process.getName p
        val states = Process.getStates p
        fun isPEvent (LOCAL (_, pName', _)) = pName = pName'
          | isPEvent (SYNC (_, _, pName', _, qName, _)) = pName = pName'
        val pEvts = List.filter isPEvent events
        fun compileState s = let
	    fun compileGuardTest name t =
	      case Trans.getGuard t
	       of NONE => NONE
 	        | SOME e =>
                  SOME (compileExpr "s" e (SOME name, mapping, comps, checks))
            fun appendInstrs e =
              "e = " ^ (getEventName e) ^ "; list_append(result, &e);"
            fun compileEvent (e as (LOCAL (_, _, t))) = let
                val gt = compileGuardTest pName t
                val (pref, suff) =
                    case gt of NONE => ("", "")
                             | SOME pref => ("if(" ^ pref ^ ") {", "}")
                val instr =
                    "      " ^ pref ^ (appendInstrs e) ^ suff ^ "\n"
            in TextIO.output (cFile, instr) end
              | compileEvent (e as (SYNC (_, _, _, pt, qName, qt))) = let
                val pgt = compileGuardTest pName pt
                val qgt = compileGuardTest qName qt
                val s = Trans.getSrc qt
                val stateTest =
                    "s->" ^ (getCompName (PROCESS_STATE qName)) ^ " == "
                    ^ (getLocalStateName (qName, s))
                val instr = 
                    "      if("
                    ^ stateTest
                    ^ (case pgt of NONE => "" | SOME t => " && (" ^ t ^ ")")
                    ^ (case qgt of NONE => "" | SOME t => " && (" ^ t ^ ")")
                    ^ ") { " ^ (appendInstrs e) ^ "}\n"
            in TextIO.output (cFile, instr) end
            fun isSEvent (LOCAL (_, _, t)) = Trans.getSrc t = s
              | isSEvent (SYNC (_, _, _, t, _, _)) = Trans.getSrc t = s
            val sEvts = List.filter isSEvent pEvts
        in
            TextIO.output (cFile, "   case " ^ (getLocalStateName (pName, s))
                                  ^ ": {\n")
          ; List.app compileEvent sEvts
          ; TextIO.output (cFile, "   break;\n   }\n")
        end
    in
        TextIO.output (cFile, "   switch(s->" ^
	                      (getCompName (PROCESS_STATE pName)) ^ ") {\n")
      ; List.app compileState (List.map State.getName states)
      ; TextIO.output (cFile, "   default: assert(0);\n")
      ; TextIO.output (cFile, "}\n")
    end
in
    TextIO.output (hFile, "\n" ^ prot ^ ";\n")
  ; TextIO.output (cFile, concatLines [
                       prot ^ " {",
                       "   mevent_t e;",
                       "   list_t result = " ^
                       "list_new(heap, sizeof(mevent_t), NULL);\n\n" ])
  ; List.app compileProc procs
  ; TextIO.output (cFile, concatLines [
                       "   return result;",
                       "}\n" ])
end

fun compileGetEnabledEvent
        funcName (s: System.system, checks, hFile, cFile) = let
    val prot = String.concat [
	    "mevent_t ", funcName,
	    " (mstate_t s, mevent_id_t e, heap_t heap)" ]
    val body = concatLines [ prot, " { return e; }" ]
in
    TextIO.output (hFile, "\n" ^ prot ^ ";\n")
  ; TextIO.output (cFile, "\n" ^ body ^ "\n")
end
                                  
fun gen (s, checks, hFile, cFile) = (
    TextIO.output (hFile, "#include \"list.h\"")
  ; compileGetEnabledEvent "mstate_event" (s, checks, hFile, cFile)
  ; compileGetEnabledEvents "mstate_events" (s, checks, hFile, cFile))
end
