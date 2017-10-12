(*
 *  File:
 *     dve-initial-state-compiler.sml
 *)


structure DveInitialStateCompiler: sig

    val gen: System.system * bool * TextIO.outstream * TextIO.outstream
	     -> unit

end = struct

open DveCompilerUtils

fun gen (s: System.system, checks, hFile, cFile) = let
    val events = buildEvents s
    val comps = buildStateComps s
    val map = buildMapping comps
    val procs = System.getProcs s

    (*  We initialize the initial state as follows:
     *  1 - set the initial states of processes
     *  2 - compute the initial values of global variables
     *  3 - compute the initial values of local variables
     *)
    fun generateLocalStateInit proc = let
	val procName = Process.getName proc
	val procInit = Process.getInit proc
	val stmt     =
	    String.concat [
	    "   result->", getCompName (PROCESS_STATE procName), " = ",
	    getLocalStateName (procName, State.getName procInit), ";" ]
    in
	stmt
    end

    fun generateVarInit (var : Var.var,
			 proc: string option) = let
	val init = case Var.getInit var
		    of NONE => compileInitVal (Var.getTyp var)
		     | SOME init => init
	val typ = Var.getTyp var
	val comp = case proc
		    of NONE => GLOBAL_VAR var
		     | SOME proc => LOCAL_VAR (proc, var)
    in
	if Var.getConst var
	then ""
	else case init
	      of Expr.ARRAY_INIT (pos, l) => let
		     val nums = List.tabulate (List.length l, fn i => i)
		     val l = ListPair.zip (nums, l)
		     fun indexInit (i, init) =
			 String.concat [
			 "   result->", getCompName comp, "[",
			 Int.toString i, "] = ",
			 compileExpr "result" init (proc, map, comps, checks),
			 ";" ]
		 in
		     concatLines (List.map indexInit l) ^ "\n"
		 end
	       | _ => String.concat [
		      "   result->", getCompName comp, " = ",
		      compileExpr "result" init (proc, map, comps, checks),
		      ";\n" ]
    end

    fun generateGlobalVarInit var =
	generateVarInit (var, NONE)

    fun generateLocalVarsInit proc = let
	val procName = Process.getName proc
	fun generateLocalVarInit var = generateVarInit (var, SOME procName)
    in
	String.concat (List.map generateLocalVarInit (Process.getVars proc))
    end

    val protMem = "mstate_t mstate_initial_mem (heap_t heap)"
    val bodyMem =
	concatLines [
	protMem ^ " {",
	"   mstate_t result = mem_alloc(heap, sizeof(struct_mstate_t));",
	"   memset(result, 0, sizeof(struct_mstate_t));",
	"   result->heap = heap;",
	"",
	"   /*  process state  */",
	concatLines (List.map generateLocalStateInit procs),
	"",
	"   /*  global variables  */",
	String.concat (List.map generateGlobalVarInit (System.getVars s)),
	"",
	"   /*  local variables  */",
	String.concat (List.map generateLocalVarsInit procs),
	"   return result;",
	"}"
	]
    val prot = "mstate_t mstate_initial ()"
    val body =
	concatLines [
	prot ^ " {",
	"   return mstate_initial_mem (SYSTEM_HEAP);",
	"}"
	]
in
    TextIO.output (hFile, prot ^ ";\n");
    TextIO.output (hFile, protMem ^ ";\n");
    TextIO.output (cFile, body ^ ";\n");
    TextIO.output (cFile, bodyMem ^ ";\n")
end

end
