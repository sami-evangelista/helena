(*
 *  File:
 *     dve-event-execution-compiler.sml
 *)


structure DveEventExecutionCompiler: sig

    val gen: System.system * bool * TextIO.outstream * TextIO.outstream
	     -> unit

end = struct

open DveCompilerUtils

fun genEventExec (s: System.system, checks, hFile, cFile) = let
    val events = buildEvents s
    val comps = buildStateComps s
    val map = buildMapping comps

    fun compileExecEvent e = let

	fun compileProcessStateChange (proc, newState) =
	    String.concat [
	    "      s->", getCompName (PROCESS_STATE proc), " = ",
	    getLocalStateName(proc, newState), ";\n" ]		

	fun compileStat proc (Stat.ASSIGN (pos, var, value)) = let
	    val comp = getVarComp (comps, SOME proc, Expr.getVarName var)
	    val varExpr = 
		compileVarRef "s" var (SOME proc, map, comps, checks)
	    val valueExpr =
		compileExpr "s" value (SOME proc, map, comps, checks)
	in
	    String.concat [
	    "      ", varExpr, " = ",
	    valueExpr, ";\n" ]
	end
							 
	fun compileStatList proc stats =
	    String.concat (List.map (compileStat proc) stats)
				    
	fun compileExecLocalEvent (proc, trans) =
	    String.concat [
	    compileStatList proc (Trans.getEffect trans),
	    compileProcessStateChange (proc, Trans.getDest trans) ]
    						  
	fun compileExecSyncEvent (proc1, trans1, proc2, trans2) = let
	    (*  NB: proc1 is the sender and proc2 the receiver  *)
	    val sl1  = Trans.getEffect trans1
	    val sl2  = Trans.getEffect trans2
	    val sent = Sync.getData (valOf (Trans.getSync trans1))
	    val recv = Sync.getData (valOf (Trans.getSync trans2))
	    val sync =
		(*
		 *  in case of a synchronization event, the state change is
		 *  done as follows:
		 *  1 - reception of the data sent if any
		 *  2 - sending process executes its effect
		 *  3 - receiving process executes its effect
		 *  4 - changement of states of both processes
		 *)
		String.concat [
		case (sent, recv) of
		    (SOME dataSent, SOME (Expr.VAR_REF (pos, var))) => let
			(*
			 *  we have to take care here that the data sent and
			 *  the receiving variable do not belong to the same
			 *  process
			 *)
		    in
			String.concat [
			"      int_t dataSent = ",
			compileExpr
			    "s"
			    dataSent (SOME proc1, map, comps, checks), ";\n",
			"      ",
			compileVarRef
			    "s"
			    var (SOME proc2, map, comps, checks),
			" = dataSent;\n" ]
		    end
		  | _ => ""  (*  no data sent throught channel  *)
		]
	in
	    String.concat [
	    sync,
	    compileStatList proc1 sl1,
	    compileStatList proc2 sl2,
	    compileProcessStateChange (proc1, Trans.getDest trans1),
	    compileProcessStateChange (proc2, Trans.getDest trans2) ]
	end
    in
	case e
	 of LOCAL (_, proc, trans) =>
	    compileExecLocalEvent (proc, trans)
	  | SYNC (_, _, proc1, trans1, proc2, trans2) =>
	    compileExecSyncEvent (proc1, trans1, proc2, trans2)
    end
    val prot = "void mevent_exec (mevent_t e, mstate_t s)"
    val body =
	concatLines [
	prot ^ " {",
	"   switch (e) {",
	concatLines (
	List.map (fn e => 
		     concatLines [
		     "   case " ^ (getEventName e) ^ ": {",
		     compileExecEvent e ^ "      break;",
		     "   }" ]) events
	),
	"   default: fatal_error (\"mevent_exec: undefined event\");",
	"   }",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun genEventUndo (s: System.system, checks, hFile, cFile) = let
    val prot = "void mevent_undo (mevent_t e, mstate_t s)"
    val body =
	concatLines [
	prot ^ " {",
	"   fatal_error (\"mevent_undo: unimplemented feature\");",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun genStateSucc (s: System.system, checks, hFile, cFile) = let
    val protMem =
	"mstate_t mstate_succ_mem (mstate_t s, mevent_t e, heap_t heap)"
    val bodyMem =
	concatLines [
	protMem ^ " {",
	"   mstate_t result = mem_alloc (heap, sizeof (struct_mstate_t));",
	"   memcpy (result, s, STATE_VECTOR_SIZE);",
	"   result->heap = heap;",
	"   mevent_exec (e, result);",
	"   return result;",
	"}"
	]
    val prot = "mstate_t mstate_succ (mstate_t s, mevent_t e)"
    val body =
	concatLines [
	prot ^ " {",
	"   return mstate_succ_mem (s, e, SYSTEM_HEAP);",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (hFile, protMem ^ ";\n");
    TextIO.output (cFile, body ^ "\n");
    TextIO.output (cFile, bodyMem ^ "\n")
end

fun genStatePred (s: System.system, checks, hFile, cFile) = let
    val prot = "mstate_t mstate_pred (mstate_t s, mevent_t e)"
    val body =
	concatLines [
	prot ^ " {",
	"   mstate_t result = NULL;",
	"   fatal_error (\"mstate_pred: unimplemented feature\");",
	"   return result;",
	"}",
	""
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (cFile, body ^ "\n")
end

fun gen params = (
    genEventExec params;
    genEventUndo params;
    genStateSucc params;
    genStatePred params)

end
