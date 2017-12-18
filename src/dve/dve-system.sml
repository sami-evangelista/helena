(*
 *  File:
 *     dve-system.sml
 *
 *  Created:
 *     Nov. 13, 2007
 *
 *  Description:
 *     Description of dve systems.
 *)


structure Pos = struct

type pos = int

fun posToString pos = "line " ^ (Int.toString pos)

end



structure Typ = struct

datatype basic_typ =
	 BYTE
         | INT
	       
datatype typ =
	 BASIC_TYPE of basic_typ
         | ARRAY_TYPE of basic_typ * int

fun getBaseType t =
  case t
   of BASIC_TYPE bt      => bt
     |	ARRAY_TYPE (bt, _) => bt

end



structure Expr = struct

datatype bin_op =
	 PLUS
         | MINUS
         | TIMES
         | DIV
         | MOD
         | IMPLY
         | AND
         | OR
         | EQ
         | NEQ
         | INF
         | SUP
         | INF_EQ
         | SUP_EQ
         | LSHIFT
         | RSHIFT
         | AND_BIT
         | OR_BIT
         | XOR

datatype un_op =
	 NOT
         | NEG
         | UMINUS

datatype expr =
	 INT of Pos.pos * LargeInt.int
         | BIN_OP of Pos.pos * expr * bin_op * expr
         | UN_OP of Pos.pos * un_op * expr
         | VAR_REF of Pos.pos * var_ref
         | BOOL_CONST of Pos.pos * bool
         | ARRAY_INIT of Pos.pos * expr list
         | PROCESS_STATE of Pos.pos * string * string
         | PROCESS_VAR_REF of Pos.pos * string * var_ref
     and var_ref =
	 SIMPLE_VAR of string
         | ARRAY_ITEM of string * expr

fun getPos (INT (p, _)) = p
  | getPos (BOOL_CONST (p, _)) = p
  | getPos (UN_OP (p, _, _)) = p
  | getPos (BIN_OP (p, _, _, _)) = p
  | getPos (VAR_REF (p, _)) = p
  | getPos (PROCESS_STATE (p, _, _)) = p
  | getPos (ARRAY_INIT (p, _)) = p
  | getPos (PROCESS_VAR_REF (p, _, _)) = p

fun binOpToString PLUS    = "+"
  | binOpToString MINUS   = "-"
  | binOpToString TIMES   = "*"
  | binOpToString DIV     = "/"
  | binOpToString MOD     = "%"
  | binOpToString EQ      = "=="
  | binOpToString NEQ     = "!="
  | binOpToString SUP     = ">"
  | binOpToString SUP_EQ  = ">="
  | binOpToString INF     = "<"
  | binOpToString INF_EQ  = "<="
  | binOpToString AND     = "and"
  | binOpToString OR      = "or"
  | binOpToString IMPLY   = "imply"
  | binOpToString LSHIFT  = "<<"
  | binOpToString RSHIFT  = ">>"
  | binOpToString AND_BIT = "&"
  | binOpToString OR_BIT  = "|"
  | binOpToString XOR     = "^"

fun unOpToString NOT    = "not"
  | unOpToString NEG    = "~"
  | unOpToString UMINUS = "-"

fun getVarName (SIMPLE_VAR v) = v
  | getVarName (ARRAY_ITEM (v, _)) = v

fun isBoolExpr (BIN_OP (_, _, AND, _)) = true
  | isBoolExpr (BIN_OP (_, _, OR, _)) = true
  | isBoolExpr (BIN_OP (_, _, EQ, _)) = true
  | isBoolExpr (BIN_OP (_, _, NEQ, _)) = true
  | isBoolExpr (BIN_OP (_, _, INF, _)) = true
  | isBoolExpr (BIN_OP (_, _, SUP, _)) = true
  | isBoolExpr (BIN_OP (_, _, INF_EQ, _)) = true
  | isBoolExpr (BIN_OP (_, _, SUP_EQ, _)) = true
  | isBoolExpr (UN_OP (_, NOT, _)) = true
  | isBoolExpr (BOOL_CONST _) = true
  | isBoolExpr (PROCESS_STATE _) = true
  | isBoolExpr _ = false

fun app p (e as (INT _)) = p e
  | app p (e as (BOOL_CONST _)) = p e
  | app p (e as (PROCESS_STATE _)) = p e
  | app p (e as (BIN_OP (_, left, _, right))) = (app p left; p e; app p right)
  | app p (e as (UN_OP (_, _, right))) = (app p right; p e)
  | app p (e as (ARRAY_INIT (_, l))) = List.app p l
  | app p (e as (VAR_REF (_, v))) = (p e; appVar p v)
  | app p (e as (PROCESS_VAR_REF (_, _, v))) = (p e; appVar p v)
and appVar p (SIMPLE_VAR _) = ()
  | appVar p (ARRAY_ITEM (_, index)) = app p index

fun fold f value e = let
    fun foldVar f value (SIMPLE_VAR _) = value
      | foldVar f value (ARRAY_ITEM (_, index)) = fold f value index
in
    f (e, case e
	   of INT _  => value
	    | BOOL_CONST _ => value
	    | PROCESS_STATE _ => value
	    | BIN_OP (_, left, _, right) => fold f (fold f value left) right
	    | UN_OP (_, _, right) => fold f value right
	    | VAR_REF (_, v) => foldVar f value v
	    | PROCESS_VAR_REF (_, _, v) => foldVar f value v
	    | ARRAY_INIT (_, l) => List.foldl (fn (e, value) => fold f value e)
					      value l)
end

fun accessedVars e =
  fold (fn (e, l) => case e
		      of VAR_REF (_, v) => (accessedVarsInVarRef v) @ l
		       | _ => l) [] e
and accessedVarsInVarRef (SIMPLE_VAR v) =  [ v ]
  | accessedVarsInVarRef (ARRAY_ITEM (v, index)) = v :: (accessedVars (index))


fun dnf e = let
    fun removeImply (BIN_OP (p, l, IMPLY, r)) =
      BIN_OP (p, UN_OP (p, NOT, removeImply l), OR, removeImply r)
      | removeImply (BIN_OP (p, l, binOp as _, r)) =
	BIN_OP (p, removeImply l, binOp, removeImply r)
      | removeImply (UN_OP (p, unOp as _, r)) =
	UN_OP (p, unOp, removeImply r)
      | removeImply (e as _) = e
    fun neg (UN_OP (p, NOT, e)) b = neg e (not b)
      | neg (BIN_OP (p, l, OR, r)) b =
	BIN_OP (p, neg l b, if b then AND else OR, neg r b)
      | neg (BIN_OP (p, l, AND, r)) b =
	BIN_OP (p, neg l b, if b then OR else AND, neg r b)
      | neg (BIN_OP (p, l, EQ, r)) true = BIN_OP (p, l, NEQ, r)
      | neg (BIN_OP (p, l, NEQ, r)) true = BIN_OP (p, l, EQ, r)
      | neg (BIN_OP (p, l, INF, r)) true = BIN_OP (p, l, SUP_EQ, r)
      | neg (BIN_OP (p, l, SUP, r)) true = BIN_OP (p, l, INF_EQ, r)
      | neg (BIN_OP (p, l, INF_EQ, r)) true = BIN_OP (p, l, SUP, r)
      | neg (BIN_OP (p, l, SUP_EQ, r)) true = BIN_OP (p, l, INF, r)
      | neg (e as _) true = UN_OP (0, NOT, e)
      | neg (e as _) false = e
    fun dnf' (e as BIN_OP (pe, BIN_OP (p', a, OR, b), AND, c)) =
      dnf' (BIN_OP (0, BIN_OP (0, a, AND, c), OR, BIN_OP(0, b, AND, c)))
      | dnf' (e as BIN_OP (pe, a, AND, BIN_OP (p', b, OR, c))) =
	dnf' (BIN_OP (0, BIN_OP (0, a, AND, b), OR, BIN_OP(0, a, AND, c)))
      | dnf' (e as _) = e
in
    dnf' (neg (removeImply e) false)
end

fun same (INT (_, i)) (INT (_, i')) = i = i'
  | same (BIN_OP (_, l, binOp, r)) (BIN_OP (_, l', binOp', r')) =
    (binOp = binOp') andalso (same l l') andalso (same r r')
  | same (UN_OP (_, unOp, r)) (UN_OP (_, unOp', r')) =
    (unOp = unOp') andalso (same r r')
  | same (VAR_REF (_, SIMPLE_VAR v)) (VAR_REF (_, SIMPLE_VAR v')) =
    v = v'
  | same (VAR_REF (_, ARRAY_ITEM (v, i)))
	 (VAR_REF (_, ARRAY_ITEM (v', i'))) =
    (v = v') andalso (same i i')
  | same (BOOL_CONST (_, b)) (BOOL_CONST (_, b')) =
    b = b'
  | same (PROCESS_STATE (_, p, s)) (PROCESS_STATE (_, p', s')) =
    (p = p') andalso (s = s')
  | same _ _ = false

fun diff (INT (_, i)) (INT (_, i')) = i <> i'
  | diff (BOOL_CONST (_, b)) (BOOL_CONST (_, b')) = b <> b'
  | diff _ _ = false

fun dual EQ NEQ     = true
  | dual NEQ EQ     = true
  | dual EQ SUP     = true
  | dual SUP EQ     = true
  | dual EQ INF     = true
  | dual INF EQ     = true
  | dual INF SUP_EQ = true
  | dual SUP_EQ INF = true
  | dual SUP INF_EQ = true
  | dual INF_EQ SUP = true
  | dual _ _ = false

fun isContradiction e = let
    fun getList (BIN_OP (p, l, OR, r)) =
      (getList l) @ (getList r)
      | getList (BIN_OP (p, l, AND, r)) =
	[ (List.hd (getList l)) @ (List.hd (getList r)) ]
      | getList e = [[e]]
    fun checkConjunction [] = false
      | checkConjunction (e :: l) = let
	  fun findOpposite [] = false
	    | findOpposite (e' :: l) =
	      (case (e, e') of
		   (BIN_OP (_, l, binOp, r), BIN_OP (_, l', binOp', r')) =>
		   ((dual binOp binOp')
		    andalso
		    (((same l l') andalso (same r r'))
		     orelse
		     ((same l r') andalso (same r l'))))
		   orelse
		   ((binOp, binOp') = (EQ, EQ) andalso
		    (((same l l') andalso (diff r r')) orelse
		     ((same l r') andalso (diff r l')))
		   )
		 | _ => false)
	      orelse (findOpposite l)
      in
	  (findOpposite l) orelse (checkConjunction l)
      end
in
    List.all checkConjunction (getList (dnf e))
end

end



structure State = struct

type state = {
    pos : Pos.pos,
    name: string
}

fun getPos ({ pos, ... }: state)  = pos
fun getName ({ name, ... }: state)  = name


fun getState (l, name) = let
    fun isState s = (getName s = name)
in
    List.find isState l
end

end



structure Sync = struct

datatype sync_mode =
	 SYNC
         | ASYNC

datatype sync_type =
	 RECV
       | SEND

type sync = {
    pos : Pos.pos,
    mode: sync_mode,
    chan: string,
    typ : sync_type,
    data: Expr.expr option
}

fun getPos ({ pos, ... }: sync) = pos
fun getMode ({ mode, ... }: sync) = mode
fun getChan ({ chan, ... }: sync) = chan
fun getTyp ({ typ, ... }: sync) = typ
fun getData ({ data, ... }: sync) = data

fun accessedVars ({ data, ... }: sync) =
  case data of SOME data => Expr.accessedVars data | _ => []

fun modifiedVars ({ typ = RECV, data = SOME data, ... }: sync) =
  Expr.accessedVars data
  | modifiedVars _ = []

end



structure Var = struct

type var = {
    pos  : Pos.pos,
    const: bool,
    typ  : Typ.typ,
    name : string,
    init : Expr.expr option 
}

fun getPos ({ pos, ... }: var) = pos
fun getConst ({ const, ... }: var) = const
fun getTyp ({ typ, ... }: var) = typ
fun getName ({ name, ... }: var) = name
fun getInit ({ init, ... }: var) = init

				       
fun getVar (l, name) = let
    fun isVar v = (getName v = name)
in
    List.find isVar l
end

end



structure Channel = struct

type channel = {
    pos : Pos.pos,
    name: string,
    size: int
}

fun getChannel (l, name) = let
    fun isChannel ({ name = n, ... }: channel) = n = name
in
    List.find isChannel l
end

end



structure Stat = struct

datatype stat =
	 ASSIGN of Pos.pos *       (*  position of the statement  *)
		   Expr.var_ref *  (*  variable updated  *)
		   Expr.expr       (*  value assigned  *)

fun accessedVars s =
  case s of ASSIGN (_, var, value) =>
	    (Expr.accessedVarsInVarRef var) @ (Expr.accessedVars value)

fun modifiedVars s =
  case s of ASSIGN (_, var, _) => SOME (Expr.getVarName var)

fun foldExpr f v s =
  case s of ASSIGN (_, var, value) =>
	    Expr.fold f (Expr.fold f v (Expr.VAR_REF (0, var))) value

end



structure Trans = struct

type trans = {
    pos   : Pos.pos,
    id    : int,
    src   : string,
    dest  : string,
    guard : Expr.expr option,
    sync  : Sync.sync option,
    effect: Stat.stat list
}

fun getPos ({ pos, ... }: trans) = pos
fun getId ({ id, ... }: trans) = id
fun getSrc ({ src, ... }: trans) = src
fun getDest ({ dest, ... }: trans) = dest
fun getGuard ({ guard, ... }: trans) = guard
fun getSync ({ sync, ... }: trans) = sync
fun getEffect ({ effect, ... }: trans) = effect

fun accessedVars ({ src, dest, guard, sync, effect, ... }: trans) = let
    val inGuard  = if isSome guard then Expr.accessedVars (valOf guard) else []
    val inEffect = List.concat (List.map Stat.accessedVars effect)
    val inSync   = if isSome sync then Sync.accessedVars (valOf sync) else []
in
    Utils.mergeStringList (List.concat [ inGuard, inEffect, inSync ])
end

fun modifiedVars ({ src, dest, guard, sync, effect, ... }: trans) = let
    val inEffect = List.mapPartial (fn s => Stat.modifiedVars s) effect
    val inSync = case sync of NONE => [] | SOME sync => Sync.modifiedVars sync
in
    Utils.mergeStringList (List.concat [ inEffect, inSync ])
end

fun foldExprs f value ({ guard, sync, effect, ... }: trans) = let
    val value = case guard
		 of SOME guard => Expr.fold f value guard
		  | NONE => value
    val value = case sync
		 of NONE => value
		  | SOME sync => (case Sync.getData sync
				   of SOME expr => Expr.fold f value expr
				    | NONE => value)
    val value = List.foldl (fn (s, e) => Stat.foldExpr f e s) value effect
in
    value
end

fun channelUsed ({ sync, ... }: trans) =
  case sync
   of NONE => NONE
    | SOME sync => SOME (Sync.getChan sync)

end



structure Process = struct

type process = {
    pos   : Pos.pos,
    name  : string,
    vars  : Var.var list,
    states: State.state list,
    init  : State.state,
    accept: State.state list,
    trans : Trans.trans list
}

fun getPos ({ pos, ... }: process) = pos
fun getName ({ name, ... }: process) = name
fun getVars ({ vars, ... }: process) = vars
fun getStates ({ states, ... }: process) = states
fun getInit ({ init, ... }: process) = init
fun getTrans ({ trans, ... }: process) = trans
fun getAccept ({ accept, ... }: process) = accept

fun getProcess (l, name) = valOf (List.find (fn p => getName p = name) l)

fun isProcess (l, name) = List.find (fn p => getName p = name) l

fun outgoingTrans proc state =
  List.filter (fn t => Trans.getSrc t = State.getName state) (getTrans proc)


fun splitOutgoingTransitions proc state = let
    val t      = outgoingTrans proc state
    val prod   = ListXProd.mapX (fn x => x) (t, t)
    val prod   = List.filter (fn (x, y) => Trans.getId x < Trans.getId y) prod
    val result = ref [t]
    fun split t t' [] = []
      | split t t' (l :: tail) = let
	  val tail = split t t' tail
      in
	  (if List.exists (fn u => Trans.getId u = Trans.getId t) l
	      andalso List.exists (fn u => Trans.getId u = Trans.getId t') l
	   then
	       [
		 List.filter (fn u => Trans.getId u <> Trans.getId t) l,
		 List.filter (fn u => Trans.getId u <> Trans.getId t') l
	       ]
	   else [ l ])
	  @ tail
      end
    fun filter [] = []
      | filter (t :: tail) =
	if List.exists (fn t' => t = t') tail
	then filter tail
	else t :: (filter tail)
in
    filter (List.foldl (fn ((t, u), l) =>
			   case (Trans.getGuard t, Trans.getGuard u) of
			       (NONE, _) => l
			     | (_, NONE) => l
			     | (SOME tg, SOME ug) =>
			       if Expr.isContradiction
				      (Expr.BIN_OP (0, tg, Expr.AND, ug))
			       then split t u l
			       else l) [t] prod)
end


fun accessedVars proc tr = let
    val procVars = List.map Var.getName (getVars proc)
    val accessed = Trans.accessedVars tr
    val (loc, glob) =
	List.foldl (fn (v, (loc, glob)) =>
		       if List.exists (fn v' => v = v') procVars
		       then (v :: loc, glob)
		       else (loc, v :: glob)) ([], []) accessed
in
    (Utils.mergeStringList loc, Utils.mergeStringList glob)
end


fun onlyAccessLocalVars proc tr =
  List.all (fn t => #2 (accessedVars proc t) = []) tr


fun noProcessStateTest proc trans =
  List.all (fn t => Trans.foldExprs
			(fn (e, b) => b andalso
				      case e of Expr.PROCESS_STATE _ => false
					      | _ => true) true t) trans


fun channelAccessed (proc: process) trans = let
    val chans = List.foldl (fn (t, l) => (case Trans.channelUsed t of
					      NONE      => l
					    | SOME chan => chan :: l))
			   []
			   trans
in
    Utils.mergeStringList chans
end


fun usesChannel (proc: process) chan =
  List.exists (fn t => case Trans.channelUsed t of
			   NONE       => false
			 | SOME chan' => chan = chan')
	      (#trans proc)

fun hasLocalVariable ({vars, ...}: process) name =
  List.exists (fn v => Var.getName v = name) vars

end



structure System = struct

datatype system_type =
	 SYNCHRONOUS
       | ASYNCHRONOUS

type system = {
    t    : system_type,
    prop : string option,
    glob : Var.var list,
    chans: Channel.channel list,
    procs: Process.process list
}

fun getVars ({ glob, ... }: system) = glob
fun getChans ({ chans, ... }: system) = chans
fun getProcs ({ procs, prop, ... }: system) =
  case prop
   of NONE => procs
   |  SOME proc => List.filter (fn p => (Process.getName p) <> proc) procs
fun getProc ({ procs, ... }: system, p) = Process.getProcess (procs, p)
fun getProp ({ prop, ... }: system) = prop
fun getProcNamesWithGlobalHidden (s as { procs, ... }: system) =
  "_GLOBAL" :: (List.map (Process.getName) (getProcs s))

fun channelUsers ({ chans, procs, ... }: system) chan =
  List.filter (fn p => Process.usesChannel p chan) procs

fun getCoIndependentStates ({ chans, procs, ... }: system) = let
    fun areCoIndependantStates states =
      List.all (fn (p, s, t) => Process.onlyAccessLocalVars p t) states
      andalso
      List.all (fn (p, s, t) => Process.noProcessStateTest p t) states
      andalso let
	  val names = List.map (fn (p, _, _) => Process.getName p) states
	  val chans = List.concat (List.map (fn (p, s, t) =>
						Process.channelAccessed p t)
					    states)
	  val chans = Utils.mergeStringList chans
      in
	  List.all
	      (fn c => List.all
			   (fn p => (List.exists (fn n =>
						     n = Process.getName p)
						 names)
				    orelse
				    (not (Process.usesChannel p c)))
			   procs)
	      chans
      end
    fun case1 s = areCoIndependantStates [ s ]
    fun case2 (sp, sq) = areCoIndependantStates [ sp, sq ]
    fun case3 (sp, sq, sr) = areCoIndependantStates [ sp, sq, sr ]
    (*  get all the couples (process p, state of process p)  *)
    val states =
	List.concat
	    (List.map (fn p => List.map (fn s => (p, s))
					(Process.getStates p))
		      procs)
    (*  get all the triples (process p,                                    *)
    (*                       state of process p,                           *)
    (*                       dependent transitions outgoing of the state)  *)
    val states = 
	List.concat
	    (List.map (fn (p, s) => let
			      val trans = Process.splitOutgoingTransitions p s
			  in List.map (fn l => (p, s, l)) trans end)
		      states)
    val states' = List.filter (fn ((p, _, _), (q, _, _)) =>
				  (Process.getName p) < (Process.getName q))
			      (ListXProd.mapX (fn c => c) (states, states))
    val states'' = List.filter (fn ((p, _, _), (q, _, _), (r, _, _)) =>
				   (Process.getName p) < (Process.getName q)
				   andalso
				   (Process.getName q) < (Process.getName r))
			       (ListXProd.mapX
				    (fn (s1, (s2, s3)) => (s1, s2, s3))
				    (states, states'))
    val res = 
	List.map (fn s => [ s ]) (List.filter case1 states)
	@
	List.map (fn (sp, sq) => [sp, sq]) (List.filter case2 states')
	@
	List.map (fn (sp, sq, sr) => [sp, sq, sr]) (List.filter case3 states'')
    fun included sub super =
      (List.length sub < List.length super) andalso
      (List.all (fn (p, s, _) => List.exists (fn (p', s', _) =>
						 (Process.getName p, s) =
						 (Process.getName p', s'))
					     super)
		sub)
in
    List.filter
	(fn states => not (List.exists
			       (fn states' => included states' states) res))
	res
end

fun areIndependent ((p1, t1), (p2, t2)) =
  (Process.getName p1) <> (Process.getName p2) andalso let
      fun intersectEmpty ([], _) = true
	| intersectEmpty (_, []) = true
	| intersectEmpty (v1 :: l1, v2 :: l2) =
	  if v1 = v2
	  then false
	  else if v1 > v2
	  then intersectEmpty (v1 :: l1, l2)
	  else intersectEmpty (l1, v2 :: l2)
      val (_, glob1) = Process.accessedVars p1 t1
      val (_, glob2) = Process.accessedVars p2 t2
  in
      intersectEmpty (glob1, glob2)
      andalso Process.noProcessStateTest p1 [ t1 ]
      andalso Process.noProcessStateTest p2 [ t2 ]
  end

end
