(*
 *  File:
 *     dve-definitions-compiler.sml
 *)


structure DveDefinitionsCompiler: sig

    val gen: System.system * TextIO.outstream * TextIO.outstream
	     -> unit

end = struct

open DveCompilerUtils

fun compileStateType s = let
    fun compileProcessStateTypes () = let	
	fun compileProcessState p = let
	    val num     = ref 0
	    val pName   = Process.getName p
	    val pInit   = Process.getInit p
	    val pStates = Process.getStates p
	in
	    num := 0;
	    listFormat { init  = "",
			 sep   = "\n",
			 final = "\n",
			 fmt   = (fn s => 
				     String.concat [
				     "#define ",
				     getLocalStateName (pName, State.getName s),
				     " ", Int.toString (!num) ]
				     before num := !num + 1) }
		       pStates
	end
    in
	String.concat (List.map compileProcessState (System.getProcs s))
    end

    fun compileArrayTypes () = let
	fun compileArrayType (bt, n) =
	    SOME ("typedef " ^ (typeName (Typ.BASIC_TYPE bt)) ^ " " ^
		  (typeName (Typ.ARRAY_TYPE (bt, n)))  ^ "[" ^
		  (Int.toString n) ^ "];\n")
	val lv = List.concat (List.map Process.getVars (System.getProcs s))
	val gv = System.getVars s
	val t = List.map Var.getTyp (lv @ gv)
	val t = List.mapPartial
		    (fn (Typ.BASIC_TYPE _) => NONE
		      | (Typ.ARRAY_TYPE (bt, n)) => SOME (bt, n)) t
	val t = ListMergeSort.uniqueSort
		    (fn ((Typ.INT, n), (Typ.INT, m)) => Int.compare (n, m)
		      | ((Typ.BYTE, n), (Typ.BYTE, m)) => Int.compare (n, m)
		      | ((Typ.INT, n), _) => GREATER
		      | _ => LESS) t
    in
	String.concat (List.mapPartial compileArrayType t) 
    end

    fun sizeof (Typ.BASIC_TYPE Typ.BYTE) = 1
      | sizeof (Typ.BASIC_TYPE Typ.INT) = 4
      | sizeof (Typ.ARRAY_TYPE (bt, n)) = n * sizeof (Typ.BASIC_TYPE bt)

    fun compileComp comp =
	SOME (String.concat [ getCompTypeName comp, " ",
			      getCompName comp, ";" ])
    val processStateTypeDefs = compileProcessStateTypes ()
    val comps = buildStateComps s
    val (consts, comps) = List.partition isCompConst comps
    val arrayTypeDefs = compileArrayTypes ()

    fun compileConst comp = let
	val v = valOf (getCompVar comp)
	val t = Var.getTyp v
    in
	SOME (typeName t ^ " " ^ (getCompName comp) ^ ";")
    end

    fun compilePrintComp comp = let
	val compName = getCompName comp
	fun printVar (field, txt, Typ.BASIC_TYPE _) =
	    "fprintf (out, \"   " ^ txt ^ " = %d\\n\", s->" ^ field ^ ");"
	  | printVar (field, txt, Typ.ARRAY_TYPE (bt, n)) =
	    String.concat
	    (List.map (fn e => printVar (field ^ "[" ^ (Int.toString e) ^ "]",
					 txt ^ "[" ^ (Int.toString e) ^ "]",
					 Typ.BASIC_TYPE bt))
		      (List.tabulate (n, fn x => x)))
    in
	SOME (case comp
	       of GLOBAL_VAR { name, typ, ... } =>
		  printVar (compName, name, typ)
		| LOCAL_VAR (s, { name, typ, ... }) =>
		  printVar (compName, "   " ^ name, typ)
		| PROCESS_STATE s =>
		  "fprintf (out, \"   " ^ s ^ " @ %d:\\n\", s->" ^
		  compName ^ ");")
    end
    val printComps =
	ListMergeSort.sort
	    (fn (GLOBAL_VAR {name = n1, ...}, GLOBAL_VAR {name = n2, ...}) =>
		String.> (n1, n2)
	      | (GLOBAL_VAR _, _) => false
	      | (_, GLOBAL_VAR _) => true
	      | (LOCAL_VAR (p1, {name = n1, ...}),
		 LOCAL_VAR (p2, {name = n2, ...})) =>
		String.> (p1, p2) orelse (p1 = p2 andalso String.> (n1, n2))
	      | (PROCESS_STATE p1, PROCESS_STATE p2) => String.> (p1, p2)
	      | (LOCAL_VAR (p1, _), PROCESS_STATE p2) => String.> (p1, p2)
	      | (PROCESS_STATE p1, LOCAL_VAR (p2, _)) => String.> (p1, p2)
	    )
	    comps
    val stateVectorSize =
	List.map (fn (PROCESS_STATE _) => 1
		   | (LOCAL_VAR (_, {typ, ...})) => sizeof typ
		   | (GLOBAL_VAR {typ, ...}) => sizeof typ) comps
    val stateVectorSize = List.foldl (fn (n, m) => n + m) 0 stateVectorSize
in
    (concatLines [
     processStateTypeDefs,
     "/*  state type  */",
     arrayTypeDefs,
     "typedef struct {",
     Utils.fmt {init  = "   ",
		sep   = "\n   ",
		final = "\n   heap_t heap;\n} struct_mstate_t;",
		fmt   = compileComp} comps,
     "#define STATE_VECTOR_SIZE " ^ (Int.toString stateVectorSize),
     "typedef struct_mstate_t * mstate_t;",
     "void mstate_free (mstate_t s);",
     "mstate_t mstate_copy (mstate_t s);",
     "mstate_t mstate_copy_mem (mstate_t s, heap_t heap);",
     "void mstate_print (mstate_t s, FILE * out);",
     "",
     Utils.fmt {init  = if consts <> [] then "/*  constants  */\n" else "",
		sep   = "\n",
		final = "",
		fmt   = compileConst} consts
     ],
     concatLines [
     "void mstate_free (mstate_t s) {",
     "   mem_free (s->heap, s);",
     "}",
     "",
     "mstate_t mstate_copy_mem (mstate_t s, heap_t heap) {",
     "   mstate_t result = mem_alloc (heap, sizeof (struct_mstate_t));",
     "   *result = *s;",
     "   result->heap = heap;",
     "   return result;",
     "}",
     "",
     "mstate_t mstate_copy (mstate_t s) {",
     "   return mstate_copy_mem (s, SYSTEM_HEAP);",
     "}",
     "",
     "bool_t mstate_equal (mstate_t s1, mstate_t s2) {",
     "   int i;",
     "   bit_vector_t v1 = (bit_vector_t) s1;",
     "   bit_vector_t v2 = (bit_vector_t) s2;",
     "   for (i = 0; i < STATE_VECTOR_SIZE; i ++) {",
     "      if (v1[i] != v2[i]) {",
     "         return FALSE;",
     "      }",
     "   }",
     "   return TRUE;",
     "}",
     "",
     "void mstate_print (mstate_t s, FILE * out) {",
     "   fprintf (out, \"{\\n\");",
     Utils.fmt {init  = "   ",
		sep   = "\n   ",
		final = "\n",
		fmt   = compilePrintComp} printComps,
     "   fprintf (out, \"}\\n\");",
     "}",
     "",
     "void mevent_print (mevent_t e, FILE * out) {",
     "   fatal_error (\"mevent_print: unimplemented feature\");",
     "}",
     ""
    ])
end

fun compileEventType (s: System.system) = let
    fun isProcEvent (name, LOCAL (_, p, _)) = p = name
      | isProcEvent (name, SYNC (_, _, p, _, q, _)) = p = name orelse q = name
    fun getProcEvents (events, name) =
	List.filter (fn e => isProcEvent (name, e)) events
    val systemEvents = buildEvents s
    val num = ref 0
in
    (concatLines [
     "#define NO_EVENTS " ^ (Int.toString (List.length (systemEvents))),
     listFormat {init  = "",
		 sep   = "\n",
		 final = "\n",
		 fmt   = fn e => ("#define " ^ (getEventName e) ^ " " ^
				  (Int.toString (!num)
				   before (num := !num + 1))) }
		systemEvents,
     "typedef struct {",
     "   uint8_t no_evts;",
     "   mevent_t * evts;",
     "   heap_t * heap;",
     "} struct_mevent_set_t;",
     "typedef mevent_t mevent_id_t;",
     "typedef struct_mevent_set_t * mevent_set_t;",
     "void mevent_free (mevent_t e);",
     "mevent_t mevent_copy (mevent_t e);",
     "mevent_t mevent_copy_mem (mevent_t e, heap_t h);",
     "void mevent_set_free (mevent_set_t set);",
     "unsigned short mevent_set_size (mevent_set_t set);",
     "mevent_t mevent_set_nth (mevent_set_t set, unsigned int n);",
     "mevent_id_t mevent_set_nth_id (mevent_set_t set, unsigned int n);"
     ],
     concatLines [
     "void mevent_free (mevent_t e) {",
     "}",
     "",
     "mevent_t mevent_copy(mevent_t e) {",
     "   return e;",
     "}",
     "",
     "mevent_t mevent_copy_mem(mevent_t e, heap_t h) {",
     "   return e;",
     "}",
     "",
     "void mevent_set_free (mevent_set_t set) {",
     "   mem_free (set->heap, set->evts);",
     "   mem_free (set->heap, set);",
     "}",
     "",
     "unsigned short mevent_set_size (mevent_set_t set) {",
     "   return set->no_evts;",
     "}",
     "",
     "mevent_t mevent_set_nth (mevent_set_t set, unsigned int n) {",
     "   return set->evts[n];",
     "}",
     "",
     "mevent_id_t mevent_set_nth_id (mevent_set_t set, unsigned int n) {",
     "   return set->evts[n];",
     "}"
    ])
end

fun gen (s, hFile, cFile) = let
    val (eventDefH, eventDefC) = compileEventType s
    val (stateDefH, stateDefC) = compileStateType s
    val comps = buildStateComps s
    val map = buildMapping comps
    val (consts, comps) = List.partition isCompConst comps
    fun compileConst comp = let
	val v = valOf (getCompVar comp)
	val t = Var.getTyp v
	val i = Var.getInit v
    in
	SOME ("   " ^ (getCompName comp) ^ " = " ^ 
	      (compileExpr "" (valOf i) (NONE, map, comps, false)) ^ ";")
    end
in
    (*
     *  H file
     *)
    TextIO.output (
    hFile,
    concatLines [
    "/*  basic types  */",
    "typedef int32_t int_t;",
    "typedef uint8_t byte_t;",
    "typedef uint8_t proc_state_t;",
    "typedef uint16_t mevent_t;",
    "",
    "/*  event definition  */",
    eventDefH,
    "",
    "/*  state definition  */",
    stateDefH,
    "",
    "/*  model initialisation and termination  */",
    "void init_model ();",
    "void free_model ();" ]);

    (*
     *  C file
     *)
    TextIO.output (
    cFile,
    concatLines [
    eventDefC,
    "",
    stateDefC,
    "",
    "void init_model () {",
    Utils.fmt {init  = "",
	       sep   = "\n",
	       final = "",
	       fmt   = compileConst} consts,
    "}",
    "void free_model () {",
    "}" ])
end

end
