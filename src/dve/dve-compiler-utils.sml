(*
 *  File:
 *     dve-compiler-utils.sml
 *
 *  Created:
 *     Nov. 17, 2008
 *
 *  Description:
 *    Some useful functions used everywhere by the compiler.
 *)


structure DveCompilerUtils = struct

(*
 * SYNC  = event that corresponds to a synchronous exchange between 2 proc
 * LOCAL = event that corresponds to the execution of single process
 *)
datatype event =
	 LOCAL of
	 int *         (*  id of the transition  *)
	 string *      (*  process name  *)
	 Trans.trans   (*  transition  *)
         | SYNC of
	   int *          (*  id of the sending process transition  *)
	   int *          (*  id of the receiving process transition  *)
	   string *       (*  sending process name  *)
	   Trans.trans *  (*  sending process transition  *)
	   string *       (*  receiving process name  *)
	   Trans.trans    (*  receiving process transition  *)

(*  component of the state type  *)
datatype state_comp =
	 GLOBAL_VAR of Var.var
         | LOCAL_VAR of string * Var.var
         | PROCESS_STATE of string

datatype large_state_comp =
	 PROCESS of string * state_comp list
         | GLOBAL of state_comp list

type mapping = (state_comp * string) list

val baseType = "int"

val listFormat = ListFormat.fmt

fun baseToInt ex = ex

fun intToBase ex = ex

fun typeName (Typ.BASIC_TYPE Typ.INT) = "int_t"
  | typeName (Typ.BASIC_TYPE Typ.BYTE) = "byte_t"
  | typeName (Typ.ARRAY_TYPE (Typ.INT, n)) = "int" ^ (Int.toString n) ^ "_t"
  | typeName (Typ.ARRAY_TYPE (Typ.BYTE, n)) = "byte" ^ (Int.toString n) ^ "_t"

fun arrayToStringFunc t = typeName t ^ "_toString"

fun arrayToSMLStringFunc t = typeName t ^ "_toSMLString"

fun getLocalStateType (proc) =
  "P_" ^ (Utils.toLower proc) ^ "_STATE_TYPE"

fun getLocalStateToInt (proc) =
  getLocalStateType proc ^ "_ToInt"

fun getIntToLocalState (proc) =
  "intTo_" ^ getLocalStateType proc

fun getLocalStateName (proc, state) =
  "P_" ^ (Utils.toLower proc) ^ "_STATE_" ^ (Utils.toLower state)

fun getLocalStateToString (proc) = getLocalStateType proc ^ "_ToString"

fun getLocalStateToSMLString (proc) = getLocalStateType proc ^ "_ToSMLString"

fun getCompVar (GLOBAL_VAR v) = SOME v
  | getCompVar (LOCAL_VAR (_, v)) = SOME v	
  | getCompVar (PROCESS_STATE _) = NONE

fun getCompName (GLOBAL_VAR v) = "GV_" ^ (Utils.toLower (Var.getName v))
  | getCompName (LOCAL_VAR (p, v)) = "LV_" ^ (Utils.toLower (p)) ^ "_V_" ^
				     (Utils.toLower (Var.getName v))
  | getCompName (PROCESS_STATE p) = "P_" ^ (Utils.toLower p) ^ "_S"

fun getCompTypeName (GLOBAL_VAR def) = typeName (Var.getTyp def)
  | getCompTypeName (LOCAL_VAR (_, def)) = typeName (Var.getTyp def)
  | getCompTypeName (PROCESS_STATE proc) = "proc_state_t"

fun getCompDescription (GLOBAL_VAR v) = Var.getName v
  | getCompDescription (LOCAL_VAR (p, v)) = p ^ "->" ^ (Var.getName v)
  | getCompDescription (PROCESS_STATE p) = "process " ^ (Utils.toLower p)

fun getCompToStringFuncName (PROCESS_STATE p) = getLocalStateToString p
  | getCompToStringFuncName comp = let
      val var = valOf (getCompVar comp)
      val t = Var.getTyp var
  in
      case t of Typ.ARRAY_TYPE _ => arrayToStringFunc t
	      | Typ.BASIC_TYPE _ => "baseToString"
  end

fun getCompToSMLStringFuncName (PROCESS_STATE p) = getLocalStateToSMLString p
  | getCompToSMLStringFuncName comp = let
      val var = valOf (getCompVar comp)
      val t = Var.getTyp var
  in
      case t of Typ.ARRAY_TYPE _ => arrayToSMLStringFunc t
	      | Typ.BASIC_TYPE _ => "baseToString"
  end

fun sizeofType (Typ.BASIC_TYPE Typ.BYTE) = 1
  | sizeofType (Typ.BASIC_TYPE Typ.INT) = 4
  | sizeofType (Typ.ARRAY_TYPE (bt, n)) = n * sizeofType (Typ.BASIC_TYPE bt)

fun sizeofComps comps =
  List.foldl (fn (n, m) => n + m) 0
	     (List.map (fn (PROCESS_STATE _) => 1
		       | (LOCAL_VAR (_, {typ, ...})) => sizeofType typ
		       | (GLOBAL_VAR {typ, ...}) => sizeofType typ) comps)
	     
fun isCompConst comp =
  case getCompVar comp of NONE => false | SOME var => Var.getConst var

fun getComp (comp, st) =
  if isCompConst comp
  then "(!" ^ (getCompName comp) ^ ")"
  else "(#" ^ (getCompName comp) ^ " " ^ st ^ ")"

fun getEventName (LOCAL (id, proc, tr)) =
  String.concat [
      "LOC_", Int.toString id,
      "_P_", Utils.toLower proc,
      "_T_", Utils.toLower (Trans.getSrc tr),
      "_TO_", Utils.toLower (Trans.getDest tr) ]
  | getEventName (SYNC (id1, id2, proc1, tr1, proc2, tr2)) =
    String.concat [
        "SYN_", Int.toString id1, "_", Int.toString id2,
        "_P_", Utils.toLower proc1,
        "_T_", Utils.toLower (Trans.getSrc tr1),
        "_TO_", Utils.toLower (Trans.getDest tr1),
        "_P_", Utils.toLower proc2,
        "_T_", Utils.toLower (Trans.getSrc tr2),
        "_TO_", Utils.toLower (Trans.getDest tr2) ]

fun getEventName' (events, t) =
  case List.find (fn LOCAL (id', _, _) => Trans.getId t = id'
		 | SYNC  (id', id'', _, _, _, _) =>
		   Trans.getId t = id' orelse
		   Trans.getId t = id'')
		 events of
      NONE   => NONE
    | SOME e => SOME (getEventName e)

fun getInitStateName (proc) =
  "INIT_P_" ^ (Utils.toLower proc)

fun getImage (mapping: mapping,
	      comp   : state_comp) =
  case List.find (fn (c, _) => comp = c) mapping of
      NONE          => raise Errors.InternalError
    | SOME (_, img) => img

fun getVarImage (stateName: string)
		(mapping: mapping,
		 proc   : string option,
		 varName: string) = let
    fun isLocalVar (LOCAL_VAR (p, var), _) =
      (Var.getName var) = varName andalso SOME p = proc
      | isLocalVar _ = false
    fun isGlobalVar (GLOBAL_VAR var, _) = (Var.getName var) = varName
      | isGlobalVar _ = false
    val (v, img) =
	(*  first look in local variables that hide global ones  *)
	case List.find isLocalVar mapping
	 of NONE => (case List.find isGlobalVar mapping
		      of NONE => (
                          print (varName ^ " not found\n")
                        ; raise Errors.InternalError)
		       | SOME (v, img) => (getCompVar v, img))
	  | SOME (v, img) => (getCompVar v, img)
in
    case v
     of NONE => img
      | SOME v => if Var.getConst v
		  then img
		  else stateName ^ "->" ^ img
end

fun getProcessStateImage (mapping: mapping,
			  proc   : string) = let
    fun isProcessState (PROCESS_STATE p, _) = proc = p
      | isProcessState _                    = false
in
    case List.find isProcessState mapping of
	NONE          => raise Errors.InternalError
      | SOME (_, img) => img
end

fun buildStateComps (s: System.system) = let
    fun mapProcessState proc = PROCESS_STATE (Process.getName proc)
    fun mapGlobalVar v = GLOBAL_VAR v
    fun getProcessVarList proc = let
	fun mapVar var = LOCAL_VAR (Process.getName proc, var)
    in
	List.map mapVar (Process.getVars proc)
    end
in
    (List.map mapGlobalVar (System.getVars s))
    @
    (List.concat
	 (List.map (fn proc => PROCESS_STATE (Process.getName proc)
			       :: getProcessVarList proc)
		   (System.getProcs s)))
end

fun buildStateCompsWithGlobalHidden (s: System.system) =
  List.map (fn GLOBAL_VAR v => LOCAL_VAR("_GLOBAL", v)
	   | comp => comp)
	   (buildStateComps s)

fun getProcessComps procName comps =
  List.filter (fn PROCESS_STATE procName' => procName = procName'
	      | LOCAL_VAR (procName', _) => procName = procName'
	      | _ => false) comps

fun getGlobalComps comps =
  List.filter (fn GLOBAL_VAR _  => true
	      | _ => false) comps

fun positionOfProcInStateVector comps "_GLOBAL" = 0
  | positionOfProcInStateVector comps procName = let
    val (compsBefore, _) =
	List.foldl (fn (_, (l, true)) => (l, true)
		   |   (comp as PROCESS_STATE st, (l, false)) =>
		       if st = procName
		       then (l, true)
		       else (comp :: l, false)
		   |   (comp,  (l, false)) => (comp :: l, false))
		   ([], false) comps
in
    sizeofComps compsBefore
end

local
    fun build procs (s: System.system) = let
        fun getLocalEventsProcess proc = let
	    fun map tr =
	      if isSome (Trans.getSync tr)
	         andalso Sync.getMode (valOf (Trans.getSync tr)) = Sync.SYNC
	      then NONE
	      else SOME (LOCAL (Trans.getId tr, Process.getName proc, tr))
        in
	    List.mapPartial map (Process.getTrans proc)
        end
        val localEvents = List.concat (List.map getLocalEventsProcess procs)
        fun getSyncEventsProcess proc = let
	    fun map tr =
	      case Trans.getSync tr
	       of NONE => NONE
	        | SOME s =>
		  if (Sync.getMode s) <> Sync.SYNC
		  then NONE
		  else SOME (Sync.getTyp s, Sync.getChan s,
			     Process.getName proc, tr)
        in
	    List.mapPartial map (Process.getTrans proc)
        end
        fun match ((stype, schan, sproc, _), (rtype, rchan, rproc, _)) =
	  (stype, rtype) = (Sync.SEND, Sync.RECV)
	  andalso (schan = rchan)
	  andalso (sproc <> rproc)
        fun map ((_, _, sproc, str), (_, _, rproc, rtr)) =
	  SYNC (Trans.getId str, Trans.getId rtr, sproc, str, rproc, rtr)
        val syncTrans = List.concat (List.map getSyncEventsProcess procs)
        val syncEvents = List.map map (Utils.zipPartial match syncTrans)
    in
        localEvents @ syncEvents
    end
in
fun buildEvents (s: System.system) =
  build (System.getProcs s) s
fun buildProcEvents (s: System.system, proc) =
  build [ System.getProc (s, proc) ] s
end

fun getVarComp (comps: state_comp list,
		proc : string option,
		var  : string) = let
    fun isLocalVar (LOCAL_VAR (p, v)) = (Var.getName v, valOf proc) = (var, p)
      | isLocalVar _                  = false
    fun isGlobalVar (GLOBAL_VAR v)    = Var.getName v = var
      | isGlobalVar _                 = false
in
    if isSome proc
    then case List.find isLocalVar comps of
	     NONE   => (case List.find isGlobalVar comps
			 of NONE => raise Errors.InternalError |
			    SOME v => v)
	   | SOME v => v
    else case List.find isGlobalVar comps
	  of NONE => raise Errors.InternalError |
	     SOME v => v
end

fun buildMapping comps =
  List.map (fn comp => (comp, getCompName comp)) comps

fun genComps comps =
  Utils.fmt { init  = "{ ",
	      final = " }",
	      fmt   = (fn c => if isCompConst c
			       then NONE
			       else SOME (getCompName c)),
	      sep   = ", " } comps

fun genOneComp c = let
    fun oneVar c v =
      case Var.getTyp v of
	  Typ.ARRAY_TYPE (_, size) => let
	   fun getIth i = getCompName c ^ "_ITEM_" ^ (Int.toString i)
	   val indexes = List.tabulate (size, (fn i => i))
       in
	   (List.map getIth indexes,
	    Utils.fmt { init  = (getCompName c) ^ " = (",
			final = ")",
			fmt   = fn i => SOME (getIth i),
			sep   = ", " } indexes)
       end	    
	| _ => ([ getCompName c ], getCompName c)
in
    case c of GLOBAL_VAR v => oneVar c v
	    | LOCAL_VAR (_, v) => oneVar c v
	    | PROCESS_STATE p =>
	      ([ "(" ^ getLocalStateToInt p ^ " " ^ getCompName c ^ ")"],
	       getCompName c)
end

fun mappingToState mapping = let
    fun mapComp (comp, value) =
      if isCompConst comp
      then NONE
      else SOME ((getCompName comp) ^ " =\n" ^ value)
in
    Utils.fmt {init  = "{\n",
	       sep   = ",\n",
	       final = "\n}",
	       fmt   = mapComp} mapping
end

fun updateMapping (mapping, comp, newValue) = let
    fun sameComp (c1, c2) =
      case (c1, c2)
       of (GLOBAL_VAR var1, GLOBAL_VAR var2) =>
	  Var.getName var1 = Var.getName var2
	| (LOCAL_VAR (proc1, var1), LOCAL_VAR (proc2, var2)) =>
	  proc1 = proc2 andalso Var.getName var1 = Var.getName var2
	| (PROCESS_STATE (proc1), PROCESS_STATE (proc2)) =>
	  proc1 = proc2
	| _ =>
	  false
in
    case mapping of
	[] => [(comp, newValue)]
      | (map as (comp', _)) :: mapping' =>
	if sameComp (comp, comp')
	then (comp, newValue) :: mapping'
	else map :: updateMapping (mapping', comp, newValue)
end

fun checkIndex checks comps proc pos var index = let
    val p = Int.toString pos
    val checkStr =
	" handle indexError => raise ModelError(" ^ p ^ ", \"index overflow\")"
in
    if not checks
    then ""
    else case index of
	     Expr.INT (_, num) => let
	      val comp = getVarComp (comps, proc, Expr.getVarName var)
	      val varDef = valOf (getCompVar comp)
	      val noCheck = case Var.getTyp varDef of
				Typ.ARRAY_TYPE (_, size) =>
				num < LargeInt.fromInt size
			      | _ => false
	  in
	      if noCheck
	      then ""
	      else checkStr
	  end
	   | _ => checkStr
end

fun compileInitVal (Typ.BASIC_TYPE _) =
  Expr.INT (0, 0)
  | compileInitVal (Typ.ARRAY_TYPE (_, n)) =
    Expr.ARRAY_INIT (0, Utils.constructList (Expr.INT (0, 0), n))

fun compileVarRef (stateName: string)
		  (var: Expr.var_ref)
		  (context as (proc   : string option,
			       mapping: mapping,
			       comps  : state_comp list,
			       checks : bool)) = let
    val v = getVarImage stateName (mapping, proc, Expr.getVarName var)
in
    case var
     of Expr.ARRAY_ITEM (array, index) => let
	 val comp = getVarComp (comps, proc, array)
	 val t    = Var.getTyp (valOf (getCompVar comp))
     in
	 String.concat [
	     v, " [", baseToInt (compileExpr stateName) index context, "]" ]
     end
      | Expr.SIMPLE_VAR (var) => v
end
and compileExpr (stateName: string)
		(e: Expr.expr)
		(context as (proc   : string option,
			     mapping: mapping,
			     comps  : state_comp list,
			     checks : bool)) = let
    val compileExpr = compileExpr stateName
in
    case e
     of
        (*  int  *)
	Expr.INT (_, num) =>
	if num >= 0
	then LargeInt.toString num
	else "(- " ^ (LargeInt.toString (~ num)) ^ ")"
	                                               
      (*  true  *)
      | Expr.BOOL_CONST (_, true) => "TRUE"

      (*  false  *)
      | Expr.BOOL_CONST (_, false) => "FALSE"
	                                  
      (*  array initializer  *)
      | Expr.ARRAY_INIT (_, exprs) => let
	  fun comp e = compileExpr e context
      in
	  listFormat {init  = "{",
		      sep   = ", ",
		      final = "}",
		      fmt   = comp} exprs
      end

      (*  state of a process  *)
      | Expr.PROCESS_STATE (_, proc, state) =>
	"((s->" ^ getProcessStateImage (mapping, proc) ^ " " ^
	" == " ^ getLocalStateName (proc, state) ^ ") ? TRUE : FALSE)"
			                               
      (*  local variable of another process  *)
      | Expr.PROCESS_VAR_REF (pos, proc, var) =>
	compileVarRef stateName var (SOME proc, mapping, comps, checks)
	              
      (*  binary operations  *)
      | Expr.BIN_OP (pos, left, binOp, right) => let
	  val l = compileExpr left context
	  val r = compileExpr right context
	  val p = Int.toString pos

	  fun compileNumOp opStr =
	    l ^ " " ^ opStr ^ " " ^ r ^
	    (if checks
	     then " handle Overflow => raise ModelError (" ^ p ^
		  ", \"overflow\")"
	     else "")

	  fun compileDivOp opStr =
	    l ^ " " ^ opStr ^ " " ^ r
	  fun compileCompOp opStr =
	    "(" ^ l ^ " " ^ opStr ^ " " ^ r ^ ") ? TRUE : FALSE"

	  fun compileBoolOp opStr =
	    "(" ^ l ^ " " ^ opStr ^ " " ^ r ^ ") ? TRUE : FALSE"

	  fun compileBitOp opStr =
	    l ^ " " ^ opStr ^ " " ^ r
      in
	  "(" ^ (
	  case binOp
	   of	Expr.PLUS    => compileNumOp  "+"
	      | Expr.MINUS   => compileNumOp  "-"
	      | Expr.TIMES   => compileNumOp  "*"
	      | Expr.DIV     => compileDivOp  "/"
	      | Expr.MOD     => compileDivOp  "%"
	      | Expr.EQ      => compileCompOp "=="
	      | Expr.NEQ     => compileCompOp "!="
	      | Expr.SUP     => compileCompOp ">"
	      | Expr.SUP_EQ  => compileCompOp ">="
	      | Expr.INF     => compileCompOp "<"
	      | Expr.INF_EQ  => compileCompOp "<="
	      | Expr.AND     => compileBoolOp "&&"
	      | Expr.OR      => compileBoolOp "||"
	      | Expr.LSHIFT  => compileBitOp  "<<"
	      | Expr.RSHIFT  => compileBitOp  ">>"
	      | Expr.AND_BIT => compileBitOp  "&"
	      | Expr.OR_BIT  => compileBitOp  "|"
	      | Expr.XOR     => compileBitOp  "^"
	      | any          =>
		raise Errors.CompilerError
		      (pos,
		       "unimplemented feature in compiler: operator " ^
		       Expr.binOpToString any))
	  ^ ")"
      end
						     
      (*  unary operations  *)
      | Expr.UN_OP (pos, unOp, right) => let
	  val r = compileExpr right context
	  val p = Int.toString pos
      in
	  "(" ^ (
	  case unOp
	   of	Expr.NOT    =>
		r ^ " ? FALSE : TRUE"
	      | Expr.UMINUS =>
		"- " ^ r 
	      | Expr.NEG    =>
		raise Errors.CompilerError
		      (pos,
		       "unimplemented feature in compiler: operator " ^
		       Expr.unOpToString Expr.NEG))
	  ^ ")"
      end

      (*  variable reference  *)
      | Expr.VAR_REF (pos, var) => compileVarRef stateName var context
end

fun concatLines [] = ""
  | concatLines [ str ] = str
  | concatLines (str1 :: str2 :: tl) = str1 ^ "\n" ^ (concatLines (str2 :: tl))
                                                         
end
