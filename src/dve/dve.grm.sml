functor DveLrValsFun(structure Token : TOKEN)
 : sig structure ParserData : PARSER_DATA
       structure Tokens : Dve_TOKENS
   end
 = 
struct
structure ParserData=
struct
structure Header = 
struct
(*****************************************************************************)
(*                                                                           *)
(*  File:                                                                    *)
(*     dve.grm                                                               *)
(*                                                                           *)
(*  Created:                                                                 *)
(*     Nov. 13, 2007                                                         *)
(*                                                                           *)
(*  Description: Parser for dve specification language.  A description can   *)
(*  be found at http://anna.fi.muni.cz/divine/current_doc/doc/divine/=       *)
(*                     tutorials/dve_language/dve_language.pdf               *)
(*                                                                           *)
(*****************************************************************************)


(*  construct a (Var.var list) from list l.  t is the type of these variables
 *  and c is a bool indicating if these are constants  *)
fun buildVarList (l, t, c) = let
    fun apply (pos, varName, dim, initVal) =
	{ pos   = pos,
	  const = c,
	  typ   = case dim of NONE   => Typ.BASIC_TYPE t |
			      SOME d => Typ.ARRAY_TYPE (t, d),
	  name  = varName,
	  init  = initVal }
in
    List.map apply l
end


datatype system_comp =
	 A_PROCESS of Process.process |
	 A_CHANNEL_LIST of Channel.channel list |
	 A_VAR_LIST of Var.var list |
	 A_PROGRESS of Progress.progress |
	 A_PROGRESS_USE of Pos.pos * string |
	 A_SYSTEM_TYPE of System.system_type
			  
			  
fun extractComponents [] = (NONE, [], [], [], [], NONE) |
    extractComponents (comp :: comps) = let
	val (t, vars, channels, procs, progs, prog) = extractComponents comps
    in
	case comp
	 of A_PROCESS p      => (t, vars, channels, p :: procs, progs, prog) |
	    A_VAR_LIST v     => (t, v @ vars,  channels, procs, progs, prog) |
	    A_CHANNEL_LIST c => (t, vars,  c @ channels, procs, progs, prog) |
	    A_SYSTEM_TYPE t  => (SOME t, vars, channels, procs, progs, prog) |
	    A_PROGRESS p     => (t, vars, channels, procs, p :: progs, prog) |
	    A_PROGRESS_USE p => (t, vars, channels, procs, progs, SOME p)
    end

val tid = ref 0


end
structure LrTable = Token.LrTable
structure Token = Token
local open LrTable in 
val table=let val actionRows =
"\
\\001\000\001\000\022\000\000\000\
\\001\000\001\000\027\000\000\000\
\\001\000\001\000\028\000\000\000\
\\001\000\001\000\032\000\000\000\
\\001\000\001\000\037\000\000\000\
\\001\000\001\000\057\000\002\000\056\000\012\000\055\000\018\000\054\000\
\\025\000\053\000\027\000\052\000\038\000\051\000\045\000\050\000\000\000\
\\001\000\001\000\120\000\000\000\
\\001\000\001\000\122\000\000\000\
\\001\000\001\000\128\000\000\000\
\\001\000\001\000\133\000\000\000\
\\001\000\001\000\148\000\000\000\
\\001\000\001\000\155\000\000\000\
\\001\000\001\000\160\000\000\000\
\\001\000\001\000\171\000\000\000\
\\001\000\001\000\182\000\000\000\
\\001\000\002\000\047\000\000\000\
\\001\000\002\000\065\000\000\000\
\\001\000\004\000\085\000\014\000\084\000\017\000\083\000\027\000\082\000\
\\028\000\081\000\029\000\080\000\030\000\079\000\031\000\078\000\
\\032\000\077\000\033\000\076\000\034\000\075\000\035\000\074\000\
\\036\000\073\000\037\000\072\000\039\000\071\000\040\000\070\000\
\\041\000\069\000\042\000\068\000\043\000\067\000\046\000\119\000\000\000\
\\001\000\004\000\085\000\014\000\084\000\017\000\083\000\027\000\082\000\
\\028\000\081\000\029\000\080\000\030\000\079\000\031\000\078\000\
\\032\000\077\000\033\000\076\000\034\000\075\000\035\000\074\000\
\\036\000\073\000\037\000\072\000\039\000\071\000\040\000\070\000\
\\041\000\069\000\042\000\068\000\043\000\067\000\050\000\130\000\000\000\
\\001\000\004\000\085\000\014\000\084\000\017\000\083\000\027\000\082\000\
\\028\000\081\000\029\000\080\000\030\000\079\000\031\000\078\000\
\\032\000\077\000\033\000\076\000\034\000\075\000\035\000\074\000\
\\036\000\073\000\037\000\072\000\039\000\071\000\040\000\070\000\
\\041\000\069\000\042\000\068\000\043\000\067\000\054\000\093\000\000\000\
\\001\000\004\000\085\000\014\000\084\000\017\000\083\000\027\000\082\000\
\\028\000\081\000\029\000\080\000\030\000\079\000\031\000\078\000\
\\032\000\077\000\033\000\076\000\034\000\075\000\035\000\074\000\
\\036\000\073\000\037\000\072\000\039\000\071\000\040\000\070\000\
\\041\000\069\000\042\000\068\000\043\000\067\000\054\000\185\000\000\000\
\\001\000\006\000\026\000\022\000\025\000\000\000\
\\001\000\007\000\019\000\016\000\016\000\000\000\
\\001\000\015\000\125\000\000\000\
\\001\000\020\000\024\000\000\000\
\\001\000\021\000\095\000\000\000\
\\001\000\024\000\152\000\000\000\
\\001\000\044\000\197\000\000\000\
\\001\000\047\000\041\000\000\000\
\\001\000\047\000\129\000\000\000\
\\001\000\047\000\172\000\000\000\
\\001\000\048\000\097\000\000\000\
\\001\000\048\000\143\000\000\000\
\\001\000\048\000\180\000\000\000\
\\001\000\050\000\066\000\000\000\
\\001\000\050\000\098\000\000\000\
\\001\000\051\000\167\000\000\000\
\\001\000\053\000\040\000\000\000\
\\001\000\053\000\163\000\000\000\
\\001\000\054\000\033\000\000\000\
\\001\000\054\000\038\000\000\000\
\\001\000\054\000\039\000\000\000\
\\001\000\054\000\044\000\000\000\
\\001\000\054\000\058\000\000\000\
\\001\000\054\000\063\000\000\000\
\\001\000\054\000\135\000\000\000\
\\001\000\054\000\141\000\000\000\
\\001\000\054\000\149\000\000\000\
\\001\000\054\000\156\000\000\000\
\\001\000\054\000\162\000\000\000\
\\001\000\054\000\166\000\000\000\
\\001\000\054\000\196\000\000\000\
\\001\000\054\000\198\000\000\000\
\\001\000\056\000\188\000\057\000\187\000\000\000\
\\001\000\058\000\000\000\000\000\
\\202\000\000\000\
\\203\000\007\000\019\000\008\000\018\000\010\000\017\000\016\000\016\000\
\\019\000\015\000\020\000\014\000\023\000\013\000\026\000\012\000\000\000\
\\204\000\000\000\
\\205\000\000\000\
\\206\000\000\000\
\\207\000\000\000\
\\208\000\000\000\
\\209\000\000\000\
\\210\000\000\000\
\\211\000\000\000\
\\212\000\000\000\
\\213\000\055\000\034\000\000\000\
\\214\000\000\000\
\\215\000\044\000\099\000\000\000\
\\216\000\000\000\
\\217\000\044\000\036\000\049\000\035\000\000\000\
\\218\000\004\000\085\000\014\000\084\000\017\000\083\000\027\000\082\000\
\\028\000\081\000\029\000\080\000\030\000\079\000\031\000\078\000\
\\032\000\077\000\033\000\076\000\034\000\075\000\035\000\074\000\
\\036\000\073\000\037\000\072\000\039\000\071\000\040\000\070\000\
\\041\000\069\000\042\000\068\000\043\000\067\000\000\000\
\\219\000\000\000\
\\220\000\055\000\043\000\000\000\
\\221\000\000\000\
\\222\000\049\000\045\000\000\000\
\\223\000\000\000\
\\224\000\000\000\
\\225\000\000\000\
\\226\000\007\000\019\000\010\000\017\000\016\000\016\000\000\000\
\\227\000\000\000\
\\228\000\000\000\
\\229\000\055\000\134\000\000\000\
\\230\000\000\000\
\\231\000\000\000\
\\232\000\000\000\
\\233\000\003\000\132\000\000\000\
\\234\000\000\000\
\\235\000\009\000\139\000\000\000\
\\236\000\000\000\
\\237\000\005\000\146\000\000\000\
\\238\000\000\000\
\\239\000\055\000\161\000\000\000\
\\240\000\000\000\
\\241\000\004\000\085\000\014\000\084\000\017\000\083\000\027\000\082\000\
\\028\000\081\000\029\000\080\000\030\000\079\000\031\000\078\000\
\\032\000\077\000\033\000\076\000\034\000\075\000\035\000\074\000\
\\036\000\073\000\037\000\072\000\039\000\071\000\040\000\070\000\
\\041\000\069\000\042\000\068\000\043\000\067\000\000\000\
\\242\000\000\000\
\\243\000\055\000\165\000\000\000\
\\244\000\000\000\
\\245\000\000\000\
\\246\000\000\000\
\\247\000\013\000\175\000\000\000\
\\248\000\000\000\
\\249\000\011\000\184\000\000\000\
\\250\000\000\000\
\\251\000\055\000\195\000\000\000\
\\252\000\000\000\
\\253\000\000\000\
\\254\000\004\000\085\000\014\000\084\000\017\000\083\000\027\000\082\000\
\\028\000\081\000\029\000\080\000\030\000\079\000\031\000\078\000\
\\032\000\077\000\033\000\076\000\034\000\075\000\035\000\074\000\
\\036\000\073\000\037\000\072\000\039\000\071\000\040\000\070\000\
\\041\000\069\000\042\000\068\000\043\000\067\000\000\000\
\\255\000\006\000\179\000\022\000\178\000\000\000\
\\000\001\000\000\
\\001\001\000\000\
\\002\001\000\000\
\\003\001\000\000\
\\004\001\000\000\
\\005\001\001\000\057\000\002\000\056\000\012\000\055\000\018\000\054\000\
\\025\000\053\000\027\000\052\000\038\000\051\000\045\000\050\000\000\000\
\\006\001\004\000\085\000\014\000\084\000\017\000\083\000\027\000\082\000\
\\028\000\081\000\029\000\080\000\030\000\079\000\031\000\078\000\
\\032\000\077\000\033\000\076\000\034\000\075\000\035\000\074\000\
\\036\000\073\000\037\000\072\000\039\000\071\000\040\000\070\000\
\\041\000\069\000\042\000\068\000\043\000\067\000\000\000\
\\007\001\000\000\
\\008\001\000\000\
\\009\001\000\000\
\\010\001\000\000\
\\011\001\000\000\
\\012\001\000\000\
\\013\001\000\000\
\\014\001\027\000\082\000\028\000\081\000\029\000\080\000\030\000\079\000\
\\031\000\078\000\034\000\075\000\035\000\074\000\036\000\073\000\
\\037\000\072\000\039\000\071\000\040\000\070\000\000\000\
\\015\001\029\000\080\000\030\000\079\000\031\000\078\000\000\000\
\\016\001\000\000\
\\017\001\029\000\080\000\030\000\079\000\031\000\078\000\000\000\
\\018\001\029\000\080\000\030\000\079\000\031\000\078\000\000\000\
\\019\001\000\000\
\\020\001\000\000\
\\021\001\000\000\
\\022\001\004\000\085\000\017\000\083\000\027\000\082\000\028\000\081\000\
\\029\000\080\000\030\000\079\000\031\000\078\000\032\000\077\000\
\\033\000\076\000\034\000\075\000\035\000\074\000\036\000\073\000\
\\037\000\072\000\039\000\071\000\040\000\070\000\041\000\069\000\
\\042\000\068\000\043\000\067\000\000\000\
\\023\001\027\000\082\000\028\000\081\000\029\000\080\000\030\000\079\000\
\\031\000\078\000\032\000\077\000\033\000\076\000\034\000\075\000\
\\035\000\074\000\036\000\073\000\037\000\072\000\039\000\071\000\
\\040\000\070\000\041\000\069\000\042\000\068\000\043\000\067\000\000\000\
\\024\001\004\000\085\000\027\000\082\000\028\000\081\000\029\000\080\000\
\\030\000\079\000\031\000\078\000\032\000\077\000\033\000\076\000\
\\034\000\075\000\035\000\074\000\036\000\073\000\037\000\072\000\
\\039\000\071\000\040\000\070\000\041\000\069\000\042\000\068\000\
\\043\000\067\000\000\000\
\\025\001\027\000\082\000\028\000\081\000\029\000\080\000\030\000\079\000\
\\031\000\078\000\034\000\075\000\035\000\074\000\036\000\073\000\
\\037\000\072\000\039\000\071\000\040\000\070\000\000\000\
\\026\001\027\000\082\000\028\000\081\000\029\000\080\000\030\000\079\000\
\\031\000\078\000\034\000\075\000\035\000\074\000\036\000\073\000\
\\037\000\072\000\039\000\071\000\040\000\070\000\000\000\
\\027\001\027\000\082\000\028\000\081\000\029\000\080\000\030\000\079\000\
\\031\000\078\000\039\000\071\000\040\000\070\000\000\000\
\\028\001\027\000\082\000\028\000\081\000\029\000\080\000\030\000\079\000\
\\031\000\078\000\039\000\071\000\040\000\070\000\000\000\
\\029\001\027\000\082\000\028\000\081\000\029\000\080\000\030\000\079\000\
\\031\000\078\000\039\000\071\000\040\000\070\000\000\000\
\\030\001\027\000\082\000\028\000\081\000\029\000\080\000\030\000\079\000\
\\031\000\078\000\039\000\071\000\040\000\070\000\000\000\
\\031\001\027\000\082\000\028\000\081\000\029\000\080\000\030\000\079\000\
\\031\000\078\000\000\000\
\\032\001\027\000\082\000\028\000\081\000\029\000\080\000\030\000\079\000\
\\031\000\078\000\000\000\
\\033\001\027\000\082\000\028\000\081\000\029\000\080\000\030\000\079\000\
\\031\000\078\000\032\000\077\000\033\000\076\000\034\000\075\000\
\\035\000\074\000\036\000\073\000\037\000\072\000\039\000\071\000\
\\040\000\070\000\000\000\
\\034\001\027\000\082\000\028\000\081\000\029\000\080\000\030\000\079\000\
\\031\000\078\000\032\000\077\000\033\000\076\000\034\000\075\000\
\\035\000\074\000\036\000\073\000\037\000\072\000\039\000\071\000\
\\040\000\070\000\041\000\069\000\043\000\067\000\000\000\
\\035\001\027\000\082\000\028\000\081\000\029\000\080\000\030\000\079\000\
\\031\000\078\000\032\000\077\000\033\000\076\000\034\000\075\000\
\\035\000\074\000\036\000\073\000\037\000\072\000\039\000\071\000\
\\040\000\070\000\041\000\069\000\000\000\
\\036\001\049\000\092\000\000\000\
\\036\001\049\000\092\000\051\000\091\000\052\000\090\000\000\000\
\\037\001\000\000\
\\038\001\000\000\
\\039\001\000\000\
\\040\001\000\000\
\\041\001\000\000\
\\042\001\055\000\157\000\000\000\
\\043\001\000\000\
\\044\001\004\000\085\000\014\000\084\000\017\000\083\000\027\000\082\000\
\\028\000\081\000\029\000\080\000\030\000\079\000\031\000\078\000\
\\032\000\077\000\033\000\076\000\034\000\075\000\035\000\074\000\
\\036\000\073\000\037\000\072\000\039\000\071\000\040\000\070\000\
\\041\000\069\000\042\000\068\000\043\000\067\000\055\000\144\000\000\000\
\\045\001\000\000\
\\046\001\000\000\
\\047\001\000\000\
\"
val actionRowNumbers =
"\056\000\000\000\061\000\063\000\
\\062\000\060\000\059\000\056\000\
\\055\000\058\000\024\000\021\000\
\\001\000\002\000\151\000\022\000\
\\003\000\150\000\039\000\066\000\
\\070\000\057\000\004\000\040\000\
\\041\000\037\000\028\000\000\000\
\\073\000\042\000\075\000\064\000\
\\000\000\015\000\005\000\043\000\
\\156\000\157\000\005\000\079\000\
\\044\000\003\000\072\000\016\000\
\\067\000\034\000\120\000\071\000\
\\005\000\005\000\005\000\118\000\
\\005\000\119\000\117\000\146\000\
\\149\000\019\000\025\000\079\000\
\\031\000\065\000\074\000\035\000\
\\068\000\005\000\005\000\005\000\
\\005\000\005\000\005\000\005\000\
\\005\000\005\000\005\000\005\000\
\\005\000\005\000\005\000\005\000\
\\005\000\005\000\005\000\005\000\
\\017\000\125\000\124\000\123\000\
\\006\000\007\000\005\000\148\000\
\\023\000\008\000\080\000\077\000\
\\076\000\029\000\144\000\143\000\
\\142\000\141\000\140\000\139\000\
\\138\000\137\000\136\000\135\000\
\\134\000\130\000\129\000\128\000\
\\126\000\127\000\133\000\131\000\
\\132\000\116\000\121\000\122\000\
\\145\000\018\000\086\000\009\000\
\\082\000\045\000\084\000\005\000\
\\147\000\088\000\008\000\046\000\
\\008\000\081\000\032\000\154\000\
\\090\000\010\000\047\000\085\000\
\\083\000\069\000\005\000\026\000\
\\011\000\048\000\152\000\087\000\
\\155\000\078\000\012\000\092\000\
\\049\000\038\000\089\000\010\000\
\\096\000\050\000\036\000\011\000\
\\091\000\005\000\153\000\012\000\
\\095\000\013\000\093\000\094\000\
\\097\000\030\000\100\000\108\000\
\\033\000\005\000\014\000\102\000\
\\110\000\111\000\098\000\020\000\
\\053\000\099\000\007\000\101\000\
\\114\000\112\000\113\000\106\000\
\\104\000\051\000\027\000\052\000\
\\115\000\007\000\103\000\005\000\
\\109\000\105\000\107\000\054\000"
val gotoT =
"\
\\001\000\199\000\002\000\009\000\008\000\008\000\009\000\007\000\
\\010\000\006\000\018\000\005\000\025\000\004\000\026\000\003\000\
\\042\000\002\000\043\000\001\000\000\000\
\\016\000\019\000\017\000\018\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\002\000\009\000\008\000\021\000\009\000\007\000\010\000\006\000\
\\018\000\005\000\025\000\004\000\026\000\003\000\042\000\002\000\
\\043\000\001\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\043\000\027\000\000\000\
\\011\000\029\000\012\000\028\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\016\000\019\000\017\000\040\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\016\000\019\000\017\000\044\000\000\000\
\\000\000\
\\013\000\047\000\015\000\046\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\013\000\057\000\015\000\046\000\000\000\
\\003\000\060\000\018\000\059\000\027\000\058\000\043\000\001\000\000\000\
\\000\000\
\\011\000\062\000\012\000\028\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\013\000\084\000\015\000\046\000\000\000\
\\013\000\085\000\015\000\046\000\000\000\
\\013\000\086\000\015\000\046\000\000\000\
\\000\000\
\\013\000\087\000\015\000\046\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\004\000\092\000\000\000\
\\018\000\059\000\027\000\094\000\043\000\001\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\013\000\098\000\015\000\046\000\000\000\
\\013\000\099\000\015\000\046\000\000\000\
\\013\000\100\000\015\000\046\000\000\000\
\\013\000\101\000\015\000\046\000\000\000\
\\013\000\102\000\015\000\046\000\000\000\
\\013\000\103\000\015\000\046\000\000\000\
\\013\000\104\000\015\000\046\000\000\000\
\\013\000\105\000\015\000\046\000\000\000\
\\013\000\106\000\015\000\046\000\000\000\
\\013\000\107\000\015\000\046\000\000\000\
\\013\000\108\000\015\000\046\000\000\000\
\\013\000\109\000\015\000\046\000\000\000\
\\013\000\110\000\015\000\046\000\000\000\
\\013\000\111\000\015\000\046\000\000\000\
\\013\000\112\000\015\000\046\000\000\000\
\\013\000\113\000\015\000\046\000\000\000\
\\013\000\114\000\015\000\046\000\000\000\
\\013\000\115\000\015\000\046\000\000\000\
\\013\000\116\000\015\000\046\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\015\000\119\000\000\000\
\\013\000\121\000\015\000\046\000\000\000\
\\000\000\
\\007\000\122\000\000\000\
\\005\000\125\000\006\000\124\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\020\000\129\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\013\000\135\000\014\000\134\000\015\000\046\000\000\000\
\\000\000\
\\021\000\136\000\000\000\
\\005\000\138\000\006\000\124\000\000\000\
\\000\000\
\\005\000\140\000\006\000\124\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\022\000\143\000\000\000\
\\019\000\145\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\013\000\135\000\014\000\148\000\015\000\046\000\000\000\
\\028\000\149\000\000\000\
\\023\000\152\000\024\000\151\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\029\000\157\000\030\000\156\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\019\000\162\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\023\000\166\000\024\000\151\000\000\000\
\\000\000\
\\013\000\167\000\015\000\046\000\000\000\
\\000\000\
\\029\000\168\000\030\000\156\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\031\000\172\000\032\000\171\000\000\000\
\\033\000\175\000\035\000\174\000\000\000\
\\000\000\
\\013\000\179\000\015\000\046\000\000\000\
\\000\000\
\\038\000\181\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\034\000\184\000\000\000\
\\000\000\
\\015\000\190\000\039\000\189\000\040\000\188\000\041\000\187\000\000\000\
\\000\000\
\\013\000\192\000\015\000\046\000\036\000\191\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\015\000\190\000\039\000\197\000\040\000\188\000\041\000\187\000\000\000\
\\000\000\
\\013\000\198\000\015\000\046\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\"
val numstates = 200
val numrules = 102
val s = ref "" and index = ref 0
val string_to_int = fn () => 
let val i = !index
in index := i+2; Char.ord(String.sub(!s,i)) + Char.ord(String.sub(!s,i+1)) * 256
end
val string_to_list = fn s' =>
    let val len = String.size s'
        fun f () =
           if !index < len then string_to_int() :: f()
           else nil
   in index := 0; s := s'; f ()
   end
val string_to_pairlist = fn (conv_key,conv_entry) =>
     let fun f () =
         case string_to_int()
         of 0 => EMPTY
          | n => PAIR(conv_key (n-1),conv_entry (string_to_int()),f())
     in f
     end
val string_to_pairlist_default = fn (conv_key,conv_entry) =>
    let val conv_row = string_to_pairlist(conv_key,conv_entry)
    in fn () =>
       let val default = conv_entry(string_to_int())
           val row = conv_row()
       in (row,default)
       end
   end
val string_to_table = fn (convert_row,s') =>
    let val len = String.size s'
        fun f ()=
           if !index < len then convert_row() :: f()
           else nil
     in (s := s'; index := 0; f ())
     end
local
  val memo = Array.array(numstates+numrules,ERROR)
  val _ =let fun g i=(Array.update(memo,i,REDUCE(i-numstates)); g(i+1))
       fun f i =
            if i=numstates then g i
            else (Array.update(memo,i,SHIFT (STATE i)); f (i+1))
          in f 0 handle Subscript => ()
          end
in
val entry_to_action = fn 0 => ACCEPT | 1 => ERROR | j => Array.sub(memo,(j-2))
end
val gotoT=Array.fromList(string_to_table(string_to_pairlist(NT,STATE),gotoT))
val actionRows=string_to_table(string_to_pairlist_default(T,entry_to_action),actionRows)
val actionRowNumbers = string_to_list actionRowNumbers
val actionT = let val actionRowLookUp=
let val a=Array.fromList(actionRows) in fn i=>Array.sub(a,i) end
in Array.fromList(map actionRowLookUp actionRowNumbers)
end
in LrTable.mkLrTable {actions=actionT,gotos=gotoT,numRules=numrules,
numStates=numstates,initialState=STATE 0}
end
end
local open Header in
type pos = int
type arg = unit
structure MlyValue = 
struct
datatype svalue = VOID | ntVOID of unit ->  unit
 | NUM of unit ->  (LargeInt.int) | IDENT of unit ->  (string)
 | type_ref of unit ->  (Typ.basic_typ)
 | system_type of unit ->  (System.system_type)
 | assign_stat of unit ->  (Stat.stat) | stat of unit ->  (Stat.stat)
 | stat_list of unit ->  (Stat.stat list)
 | trans_effect of unit ->  (Stat.stat list)
 | data_exchanged of unit ->  (Expr.expr option)
 | sync_data of unit ->  (Expr.expr option)
 | sync_mode of unit ->  (Sync.sync_mode)
 | sync_type of unit ->  (Sync.sync_type)
 | trans_sync of unit ->  (Sync.sync option)
 | trans_guard of unit ->  (Expr.expr option)
 | trans_detail of unit ->  (Expr.expr option*Sync.sync option*Stat.stat list)
 | trans_def of unit ->  (Trans.trans)
 | trans_list of unit ->  (Trans.trans list)
 | transitions of unit ->  (Trans.trans list)
 | process_var_list of unit ->  (Var.var list)
 | progress_use of unit ->  (Pos.pos*string)
 | progress of unit ->  (Progress.progress)
 | accept_states of unit ->  (State.state list)
 | ident_list of unit ->  (string list)
 | var_list of unit ->  (Var.var list)
 | var_defs of unit ->  ( ( Pos.pos * string * int option * Expr.expr option )  list)
 | var_def of unit ->  (Pos.pos*string*int option*Expr.expr option)
 | var_ref of unit ->  (Expr.var_ref)
 | expr_list of unit ->  (Expr.expr list)
 | expr of unit ->  (Expr.expr)
 | channel_def of unit ->  (Channel.channel)
 | channel_defs of unit ->  (Channel.channel list)
 | channel_list of unit ->  (Channel.channel list)
 | system_comp of unit ->  (system_comp)
 | system_comp_list of unit ->  (system_comp list)
 | init_state of unit ->  (State.state)
 | state_ident of unit ->  (State.state)
 | state_ident_list of unit ->  (State.state list)
 | state_list of unit ->  (State.state list)
 | process_body of unit ->  (Var.var list*State.state list*State.state*State.state list*Trans.trans list)
 | process_def of unit ->  (Process.process)
 | spec of unit ->  (System.system)
end
type svalue = MlyValue.svalue
type result = System.system
end
structure EC=
struct
open LrTable
infix 5 $$
fun x $$ y = y::x
val is_keyword =
fn _ => false
val preferred_change : (term list * term list) list = 
nil
val noShift = 
fn (T 57) => true | _ => false
val showTerminal =
fn (T 0) => "IDENT"
  | (T 1) => "NUM"
  | (T 2) => "ACCEPT"
  | (T 3) => "AND"
  | (T 4) => "ASSERT"
  | (T 5) => "ASYNC"
  | (T 6) => "BYTE"
  | (T 7) => "CHANNEL"
  | (T 8) => "COMMIT"
  | (T 9) => "CONST"
  | (T 10) => "EFFECT"
  | (T 11) => "FALSE"
  | (T 12) => "GUARD"
  | (T 13) => "IMPLY"
  | (T 14) => "INIT"
  | (T 15) => "INT"
  | (T 16) => "OR"
  | (T 17) => "NOT"
  | (T 18) => "PROCESS"
  | (T 19) => "PROGRESS"
  | (T 20) => "STATE"
  | (T 21) => "SYNC"
  | (T 22) => "SYSTEM"
  | (T 23) => "TRANS"
  | (T 24) => "TRUE"
  | (T 25) => "USE"
  | (T 26) => "MINUS"
  | (T 27) => "PLUS"
  | (T 28) => "DIV"
  | (T 29) => "TIMES"
  | (T 30) => "MOD"
  | (T 31) => "EQ"
  | (T 32) => "NEQ"
  | (T 33) => "INF"
  | (T 34) => "SUP"
  | (T 35) => "INF_EQ"
  | (T 36) => "SUP_EQ"
  | (T 37) => "NEG"
  | (T 38) => "LSHIFT"
  | (T 39) => "RSHIFT"
  | (T 40) => "AND_BIT"
  | (T 41) => "OR_BIT"
  | (T 42) => "XOR"
  | (T 43) => "ASSIGN"
  | (T 44) => "LPAREN"
  | (T 45) => "RPAREN"
  | (T 46) => "LBRACE"
  | (T 47) => "RBRACE"
  | (T 48) => "LARRAY"
  | (T 49) => "RARRAY"
  | (T 50) => "ARROW"
  | (T 51) => "DOT"
  | (T 52) => "COLON"
  | (T 53) => "SEMICOLON"
  | (T 54) => "COMMA"
  | (T 55) => "EXCLAMATION"
  | (T 56) => "QUESTION"
  | (T 57) => "EOF"
  | _ => "bogus-term"
local open Header in
val errtermvalue=
fn _ => MlyValue.VOID
end
val terms : term list = nil
 $$ (T 57) $$ (T 56) $$ (T 55) $$ (T 54) $$ (T 53) $$ (T 52) $$ (T 51)
 $$ (T 50) $$ (T 49) $$ (T 48) $$ (T 47) $$ (T 46) $$ (T 45) $$ (T 44)
 $$ (T 43) $$ (T 42) $$ (T 41) $$ (T 40) $$ (T 39) $$ (T 38) $$ (T 37)
 $$ (T 36) $$ (T 35) $$ (T 34) $$ (T 33) $$ (T 32) $$ (T 31) $$ (T 30)
 $$ (T 29) $$ (T 28) $$ (T 27) $$ (T 26) $$ (T 25) $$ (T 24) $$ (T 23)
 $$ (T 22) $$ (T 21) $$ (T 20) $$ (T 19) $$ (T 18) $$ (T 17) $$ (T 16)
 $$ (T 15) $$ (T 14) $$ (T 13) $$ (T 12) $$ (T 11) $$ (T 10) $$ (T 9)
 $$ (T 8) $$ (T 7) $$ (T 6) $$ (T 5) $$ (T 4) $$ (T 3) $$ (T 2)end
structure Actions =
struct 
type int = Int.int
exception mlyAction of int
local open Header in
val actions = 
fn (i392:int,defaultPos,stack,
    (()):arg) =>
case (i392,stack)
of  ( 0, ( ( _, ( MlyValue.system_comp_list system_comp_list1, 
system_comp_list1left, system_comp_list1right)) :: rest671)) => let
 val  result = MlyValue.spec (fn _ => let val  (system_comp_list as 
system_comp_list1) = system_comp_list1 ()
 in (
let val _ = tid := 0
     val comps = system_comp_list
     val (sys_type, vars, channels, processes, progs, prog) =
	 extractComponents comps
 in
     case sys_type
      of NONE => raise Errors.ParseError
			   (1, "system type expected (sync / async)")
       | SOME t => { t     = t,
		     glob  = vars,
		     chans = channels,
		     procs = processes,
		     progs = progs,
		     prog  = prog }
 end
)
end)
 in ( LrTable.NT 0, ( result, system_comp_list1left, 
system_comp_list1right), rest671)
end
|  ( 1, ( rest671)) => let val  result = MlyValue.system_comp_list (fn
 _ => ([]))
 in ( LrTable.NT 7, ( result, defaultPos, defaultPos), rest671)
end
|  ( 2, ( ( _, ( MlyValue.system_comp_list system_comp_list1, _, 
system_comp_list1right)) :: ( _, ( MlyValue.system_comp system_comp1, 
system_comp1left, _)) :: rest671)) => let val  result = 
MlyValue.system_comp_list (fn _ => let val  (system_comp as 
system_comp1) = system_comp1 ()
 val  (system_comp_list as system_comp_list1) = system_comp_list1 ()
 in (system_comp :: system_comp_list)
end)
 in ( LrTable.NT 7, ( result, system_comp1left, system_comp_list1right
), rest671)
end
|  ( 3, ( ( _, ( MlyValue.process_def process_def1, process_def1left, 
process_def1right)) :: rest671)) => let val  result = 
MlyValue.system_comp (fn _ => let val  (process_def as process_def1) =
 process_def1 ()
 in (A_PROCESS process_def)
end)
 in ( LrTable.NT 8, ( result, process_def1left, process_def1right), 
rest671)
end
|  ( 4, ( ( _, ( MlyValue.channel_list channel_list1, 
channel_list1left, channel_list1right)) :: rest671)) => let val  
result = MlyValue.system_comp (fn _ => let val  (channel_list as 
channel_list1) = channel_list1 ()
 in (A_CHANNEL_LIST channel_list)
end)
 in ( LrTable.NT 8, ( result, channel_list1left, channel_list1right), 
rest671)
end
|  ( 5, ( ( _, ( MlyValue.var_list var_list1, var_list1left, 
var_list1right)) :: rest671)) => let val  result = 
MlyValue.system_comp (fn _ => let val  (var_list as var_list1) = 
var_list1 ()
 in (A_VAR_LIST var_list)
end)
 in ( LrTable.NT 8, ( result, var_list1left, var_list1right), rest671)

end
|  ( 6, ( ( _, ( MlyValue.system_type system_type1, system_type1left, 
system_type1right)) :: rest671)) => let val  result = 
MlyValue.system_comp (fn _ => let val  (system_type as system_type1) =
 system_type1 ()
 in (A_SYSTEM_TYPE system_type)
end)
 in ( LrTable.NT 8, ( result, system_type1left, system_type1right), 
rest671)
end
|  ( 7, ( ( _, ( MlyValue.progress progress1, progress1left, 
progress1right)) :: rest671)) => let val  result = 
MlyValue.system_comp (fn _ => let val  (progress as progress1) = 
progress1 ()
 in (A_PROGRESS progress)
end)
 in ( LrTable.NT 8, ( result, progress1left, progress1right), rest671)

end
|  ( 8, ( ( _, ( MlyValue.progress_use progress_use1, 
progress_use1left, progress_use1right)) :: rest671)) => let val  
result = MlyValue.system_comp (fn _ => let val  (progress_use as 
progress_use1) = progress_use1 ()
 in (A_PROGRESS_USE progress_use)
end)
 in ( LrTable.NT 8, ( result, progress_use1left, progress_use1right), 
rest671)
end
|  ( 9, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.var_defs 
var_defs1, _, _)) :: ( _, ( MlyValue.type_ref type_ref1, type_ref1left
, _)) :: rest671)) => let val  result = MlyValue.var_list (fn _ => let
 val  (type_ref as type_ref1) = type_ref1 ()
 val  (var_defs as var_defs1) = var_defs1 ()
 in (buildVarList (var_defs, type_ref, false))
end)
 in ( LrTable.NT 17, ( result, type_ref1left, SEMICOLON1right), 
rest671)
end
|  ( 10, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.var_defs 
var_defs1, _, _)) :: ( _, ( MlyValue.type_ref type_ref1, _, _)) :: ( _
, ( _, CONST1left, _)) :: rest671)) => let val  result = 
MlyValue.var_list (fn _ => let val  (type_ref as type_ref1) = 
type_ref1 ()
 val  (var_defs as var_defs1) = var_defs1 ()
 in (buildVarList (var_defs, type_ref, true))
end)
 in ( LrTable.NT 17, ( result, CONST1left, SEMICOLON1right), rest671)

end
|  ( 11, ( ( _, ( MlyValue.var_def var_def1, var_def1left, 
var_def1right)) :: rest671)) => let val  result = MlyValue.var_defs
 (fn _ => let val  (var_def as var_def1) = var_def1 ()
 in ([var_def])
end)
 in ( LrTable.NT 16, ( result, var_def1left, var_def1right), rest671)

end
|  ( 12, ( ( _, ( MlyValue.var_defs var_defs1, _, var_defs1right)) ::
 _ :: ( _, ( MlyValue.var_def var_def1, var_def1left, _)) :: rest671))
 => let val  result = MlyValue.var_defs (fn _ => let val  (var_def as 
var_def1) = var_def1 ()
 val  (var_defs as var_defs1) = var_defs1 ()
 in (var_def :: var_defs)
end)
 in ( LrTable.NT 16, ( result, var_def1left, var_defs1right), rest671)

end
|  ( 13, ( ( _, ( _, _, RARRAY1right)) :: ( _, ( MlyValue.NUM NUM1, _,
 _)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, (IDENTleft as IDENT1left),
 _)) :: rest671)) => let val  result = MlyValue.var_def (fn _ => let
 val  (IDENT as IDENT1) = IDENT1 ()
 val  (NUM as NUM1) = NUM1 ()
 in ((IDENTleft, IDENT, SOME (LargeInt.toInt NUM), NONE))
end)
 in ( LrTable.NT 15, ( result, IDENT1left, RARRAY1right), rest671)
end
|  ( 14, ( ( _, ( _, _, RBRACE1right)) :: ( _, ( MlyValue.expr_list 
expr_list1, _, _)) :: _ :: _ :: ( _, ( _, RARRAYleft, _)) :: ( _, ( 
MlyValue.NUM NUM1, _, _)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, (
IDENTleft as IDENT1left), _)) :: rest671)) => let val  result = 
MlyValue.var_def (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 val  (NUM as NUM1) = NUM1 ()
 val  (expr_list as expr_list1) = expr_list1 ()
 in (
(IDENTleft, IDENT, SOME (LargeInt.toInt NUM),
  SOME (Expr.ARRAY_INIT (RARRAYleft, expr_list)))
)
end)
 in ( LrTable.NT 15, ( result, IDENT1left, RBRACE1right), rest671)
end
|  ( 15, ( ( _, ( MlyValue.IDENT IDENT1, (IDENTleft as IDENT1left), 
IDENT1right)) :: rest671)) => let val  result = MlyValue.var_def (fn _
 => let val  (IDENT as IDENT1) = IDENT1 ()
 in ((IDENTleft, IDENT, NONE, NONE))
end)
 in ( LrTable.NT 15, ( result, IDENT1left, IDENT1right), rest671)
end
|  ( 16, ( ( _, ( MlyValue.expr expr1, _, expr1right)) :: _ :: ( _, ( 
MlyValue.IDENT IDENT1, (IDENTleft as IDENT1left), _)) :: rest671)) =>
 let val  result = MlyValue.var_def (fn _ => let val  (IDENT as IDENT1
) = IDENT1 ()
 val  (expr as expr1) = expr1 ()
 in ((IDENTleft, IDENT, NONE, SOME expr))
end)
 in ( LrTable.NT 15, ( result, IDENT1left, expr1right), rest671)
end
|  ( 17, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( 
MlyValue.channel_defs channel_defs1, _, _)) :: ( _, ( _, CHANNEL1left,
 _)) :: rest671)) => let val  result = MlyValue.channel_list (fn _ =>
 let val  (channel_defs as channel_defs1) = channel_defs1 ()
 in (channel_defs)
end)
 in ( LrTable.NT 9, ( result, CHANNEL1left, SEMICOLON1right), rest671)

end
|  ( 18, ( ( _, ( MlyValue.channel_def channel_def1, channel_def1left,
 channel_def1right)) :: rest671)) => let val  result = 
MlyValue.channel_defs (fn _ => let val  (channel_def as channel_def1)
 = channel_def1 ()
 in ([channel_def])
end)
 in ( LrTable.NT 10, ( result, channel_def1left, channel_def1right), 
rest671)
end
|  ( 19, ( ( _, ( MlyValue.channel_defs channel_defs1, _, 
channel_defs1right)) :: _ :: ( _, ( MlyValue.channel_def channel_def1,
 channel_def1left, _)) :: rest671)) => let val  result = 
MlyValue.channel_defs (fn _ => let val  (channel_def as channel_def1)
 = channel_def1 ()
 val  (channel_defs as channel_defs1) = channel_defs1 ()
 in (channel_def :: channel_defs)
end)
 in ( LrTable.NT 10, ( result, channel_def1left, channel_defs1right), 
rest671)
end
|  ( 20, ( ( _, ( MlyValue.IDENT IDENT1, (IDENTleft as IDENT1left), 
IDENT1right)) :: rest671)) => let val  result = MlyValue.channel_def
 (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 in ({ pos = IDENTleft, name = IDENT, size = 0 })
end)
 in ( LrTable.NT 11, ( result, IDENT1left, IDENT1right), rest671)
end
|  ( 21, ( ( _, ( _, _, RARRAY1right)) :: ( _, ( MlyValue.NUM NUM1, _,
 _)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, (IDENTleft as IDENT1left),
 _)) :: rest671)) => let val  result = MlyValue.channel_def (fn _ =>
 let val  (IDENT as IDENT1) = IDENT1 ()
 val  (NUM as NUM1) = NUM1 ()
 in (
if NUM = 0
 then { pos = IDENTleft, name = IDENT, size = 0 }
 else raise Errors.ParseError (IDENTleft,
			       "unimplemented feature: buffered channels")
)
end)
 in ( LrTable.NT 11, ( result, IDENT1left, RARRAY1right), rest671)
end
|  ( 22, ( ( _, ( _, _, RBRACE1right)) :: ( _, ( MlyValue.process_body
 process_body1, _, _)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, _, _)) ::
 ( _, ( _, (PROCESSleft as PROCESS1left), _)) :: rest671)) => let val 
 result = MlyValue.process_def (fn _ => let val  (IDENT as IDENT1) = 
IDENT1 ()
 val  (process_body as process_body1) = process_body1 ()
 in (
let val (vars, states, init, accept, trans) = process_body in
     {
      pos    = PROCESSleft,
      name   = IDENT,
      vars   = vars,
      states = states,
      init   = init,
      trans  = trans,
      accept = accept
     }
 end
)
end)
 in ( LrTable.NT 1, ( result, PROCESS1left, RBRACE1right), rest671)

end
|  ( 23, ( ( _, ( MlyValue.transitions transitions1, _, 
transitions1right)) :: ( _, ( MlyValue.ntVOID assert_clause1, _, _))
 :: ( _, ( MlyValue.ntVOID commit_states1, _, _)) :: ( _, ( 
MlyValue.accept_states accept_states1, _, _)) :: ( _, ( 
MlyValue.init_state init_state1, _, _)) :: ( _, ( MlyValue.state_list 
state_list1, _, _)) :: ( _, ( MlyValue.process_var_list 
process_var_list1, process_var_list1left, _)) :: rest671)) => let val 
 result = MlyValue.process_body (fn _ => let val  (process_var_list
 as process_var_list1) = process_var_list1 ()
 val  (state_list as state_list1) = state_list1 ()
 val  (init_state as init_state1) = init_state1 ()
 val  (accept_states as accept_states1) = accept_states1 ()
 val  commit_states1 = commit_states1 ()
 val  assert_clause1 = assert_clause1 ()
 val  (transitions as transitions1) = transitions1 ()
 in (
(process_var_list, state_list, init_state, accept_states, transitions)
)
end)
 in ( LrTable.NT 2, ( result, process_var_list1left, transitions1right
), rest671)
end
|  ( 24, ( rest671)) => let val  result = MlyValue.process_var_list
 (fn _ => ([]))
 in ( LrTable.NT 26, ( result, defaultPos, defaultPos), rest671)
end
|  ( 25, ( ( _, ( MlyValue.process_var_list process_var_list1, _, 
process_var_list1right)) :: ( _, ( MlyValue.var_list var_list1, 
var_list1left, _)) :: rest671)) => let val  result = 
MlyValue.process_var_list (fn _ => let val  (var_list as var_list1) = 
var_list1 ()
 val  (process_var_list as process_var_list1) = process_var_list1 ()
 in (var_list @ process_var_list)
end)
 in ( LrTable.NT 26, ( result, var_list1left, process_var_list1right),
 rest671)
end
|  ( 26, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( 
MlyValue.state_ident_list state_ident_list1, _, _)) :: ( _, ( _, 
STATE1left, _)) :: rest671)) => let val  result = MlyValue.state_list
 (fn _ => let val  (state_ident_list as state_ident_list1) = 
state_ident_list1 ()
 in (state_ident_list)
end)
 in ( LrTable.NT 3, ( result, STATE1left, SEMICOLON1right), rest671)

end
|  ( 27, ( ( _, ( MlyValue.state_ident state_ident1, state_ident1left,
 state_ident1right)) :: rest671)) => let val  result = 
MlyValue.state_ident_list (fn _ => let val  (state_ident as 
state_ident1) = state_ident1 ()
 in ([state_ident])
end)
 in ( LrTable.NT 4, ( result, state_ident1left, state_ident1right), 
rest671)
end
|  ( 28, ( ( _, ( MlyValue.state_ident_list state_ident_list1, _, 
state_ident_list1right)) :: _ :: ( _, ( MlyValue.state_ident 
state_ident1, state_ident1left, _)) :: rest671)) => let val  result = 
MlyValue.state_ident_list (fn _ => let val  (state_ident as 
state_ident1) = state_ident1 ()
 val  (state_ident_list as state_ident_list1) = state_ident_list1 ()
 in (state_ident :: state_ident_list)
end)
 in ( LrTable.NT 4, ( result, state_ident1left, state_ident_list1right
), rest671)
end
|  ( 29, ( ( _, ( MlyValue.IDENT IDENT1, (IDENTleft as IDENT1left), 
IDENT1right)) :: rest671)) => let val  result = MlyValue.state_ident
 (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 in ({ pos = IDENTleft, name = IDENT })
end)
 in ( LrTable.NT 5, ( result, IDENT1left, IDENT1right), rest671)
end
|  ( 30, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.IDENT 
IDENT1, IDENTleft, _)) :: ( _, ( _, INIT1left, _)) :: rest671)) => let
 val  result = MlyValue.init_state (fn _ => let val  (IDENT as IDENT1)
 = IDENT1 ()
 in ({ pos = IDENTleft, name = IDENT })
end)
 in ( LrTable.NT 6, ( result, INIT1left, SEMICOLON1right), rest671)

end
|  ( 31, ( rest671)) => let val  result = MlyValue.accept_states (fn _
 => ([]))
 in ( LrTable.NT 19, ( result, defaultPos, defaultPos), rest671)
end
|  ( 32, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( 
MlyValue.state_ident_list state_ident_list1, _, _)) :: ( _, ( _, 
ACCEPT1left, _)) :: rest671)) => let val  result = 
MlyValue.accept_states (fn _ => let val  (state_ident_list as 
state_ident_list1) = state_ident_list1 ()
 in (state_ident_list)
end)
 in ( LrTable.NT 19, ( result, ACCEPT1left, SEMICOLON1right), rest671)

end
|  ( 33, ( rest671)) => let val  result = MlyValue.ntVOID (fn _ => ())
 in ( LrTable.NT 20, ( result, defaultPos, defaultPos), rest671)
end
|  ( 34, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( 
MlyValue.ident_list ident_list1, _, _)) :: ( _, ( _, (COMMITleft as 
COMMIT1left), _)) :: rest671)) => let val  result = MlyValue.ntVOID
 (fn _ => ( let val  ident_list1 = ident_list1 ()
 in (
raise Errors.ParseError (COMMITleft,
			  "unimplemented feature: commited states")
)
end; ()))
 in ( LrTable.NT 20, ( result, COMMIT1left, SEMICOLON1right), rest671)

end
|  ( 35, ( rest671)) => let val  result = MlyValue.ntVOID (fn _ => ())
 in ( LrTable.NT 21, ( result, defaultPos, defaultPos), rest671)
end
|  ( 36, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.ntVOID 
assert_list1, _, _)) :: ( _, ( _, (ASSERTleft as ASSERT1left), _)) :: 
rest671)) => let val  result = MlyValue.ntVOID (fn _ => ( let val  
assert_list1 = assert_list1 ()
 in (
raise Errors.ParseError (ASSERTleft,
			  "unimplemented feature: assertions")
)
end; ()))
 in ( LrTable.NT 21, ( result, ASSERT1left, SEMICOLON1right), rest671)

end
|  ( 37, ( ( _, ( MlyValue.ntVOID assert_cond1, assert_cond1left, 
assert_cond1right)) :: rest671)) => let val  result = MlyValue.ntVOID
 (fn _ => ( let val  assert_cond1 = assert_cond1 ()
 in ()
end; ()))
 in ( LrTable.NT 22, ( result, assert_cond1left, assert_cond1right), 
rest671)
end
|  ( 38, ( ( _, ( MlyValue.ntVOID assert_list1, _, assert_list1right))
 :: _ :: ( _, ( MlyValue.ntVOID assert_cond1, assert_cond1left, _)) ::
 rest671)) => let val  result = MlyValue.ntVOID (fn _ => ( let val  
assert_cond1 = assert_cond1 ()
 val  assert_list1 = assert_list1 ()
 in ()
end; ()))
 in ( LrTable.NT 22, ( result, assert_cond1left, assert_list1right), 
rest671)
end
|  ( 39, ( ( _, ( MlyValue.expr expr1, _, expr1right)) :: _ :: ( _, ( 
MlyValue.IDENT IDENT1, IDENT1left, _)) :: rest671)) => let val  result
 = MlyValue.ntVOID (fn _ => ( let val  IDENT1 = IDENT1 ()
 val  expr1 = expr1 ()
 in ()
end; ()))
 in ( LrTable.NT 23, ( result, IDENT1left, expr1right), rest671)
end
|  ( 40, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( 
MlyValue.trans_list trans_list1, _, _)) :: ( _, ( _, TRANS1left, _))
 :: rest671)) => let val  result = MlyValue.transitions (fn _ => let
 val  (trans_list as trans_list1) = trans_list1 ()
 in (trans_list)
end)
 in ( LrTable.NT 27, ( result, TRANS1left, SEMICOLON1right), rest671)

end
|  ( 41, ( ( _, ( MlyValue.trans_def trans_def1, trans_def1left, 
trans_def1right)) :: rest671)) => let val  result = 
MlyValue.trans_list (fn _ => let val  (trans_def as trans_def1) = 
trans_def1 ()
 in ([trans_def])
end)
 in ( LrTable.NT 28, ( result, trans_def1left, trans_def1right), 
rest671)
end
|  ( 42, ( ( _, ( MlyValue.trans_list trans_list1, _, trans_list1right
)) :: _ :: ( _, ( MlyValue.trans_def trans_def1, trans_def1left, _))
 :: rest671)) => let val  result = MlyValue.trans_list (fn _ => let
 val  (trans_def as trans_def1) = trans_def1 ()
 val  (trans_list as trans_list1) = trans_list1 ()
 in (trans_def :: trans_list)
end)
 in ( LrTable.NT 28, ( result, trans_def1left, trans_list1right), 
rest671)
end
|  ( 43, ( ( _, ( _, _, RBRACE1right)) :: ( _, ( MlyValue.trans_detail
 trans_detail1, _, _)) :: _ :: ( _, ( MlyValue.IDENT IDENT2, _, _)) ::
 ( _, ( _, ARROWleft, _)) :: ( _, ( MlyValue.IDENT IDENT1, IDENT1left,
 _)) :: rest671)) => let val  result = MlyValue.trans_def (fn _ => let
 val  IDENT1 = IDENT1 ()
 val  IDENT2 = IDENT2 ()
 val  (trans_detail as trans_detail1) = trans_detail1 ()
 in (
let val (guard, sync, effect) = trans_detail
 in
     {
      pos    = ARROWleft,
      id     = !tid,
      src    = IDENT1,
      dest   = IDENT2,
      guard  = guard,
      sync   = sync,
      effect = effect
     }
     before
     tid := !tid + 1
 end
)
end)
 in ( LrTable.NT 29, ( result, IDENT1left, RBRACE1right), rest671)
end
|  ( 44, ( ( _, ( MlyValue.trans_effect trans_effect1, _, 
trans_effect1right)) :: ( _, ( MlyValue.trans_sync trans_sync1, _, _))
 :: ( _, ( MlyValue.trans_guard trans_guard1, trans_guard1left, _)) ::
 rest671)) => let val  result = MlyValue.trans_detail (fn _ => let
 val  (trans_guard as trans_guard1) = trans_guard1 ()
 val  (trans_sync as trans_sync1) = trans_sync1 ()
 val  (trans_effect as trans_effect1) = trans_effect1 ()
 in ((trans_guard, trans_sync, trans_effect))
end)
 in ( LrTable.NT 30, ( result, trans_guard1left, trans_effect1right), 
rest671)
end
|  ( 45, ( rest671)) => let val  result = MlyValue.trans_guard (fn _
 => (NONE))
 in ( LrTable.NT 31, ( result, defaultPos, defaultPos), rest671)
end
|  ( 46, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.expr 
expr1, _, _)) :: ( _, ( _, GUARD1left, _)) :: rest671)) => let val  
result = MlyValue.trans_guard (fn _ => let val  (expr as expr1) = 
expr1 ()
 in (SOME expr)
end)
 in ( LrTable.NT 31, ( result, GUARD1left, SEMICOLON1right), rest671)

end
|  ( 47, ( rest671)) => let val  result = MlyValue.trans_effect (fn _
 => ([]))
 in ( LrTable.NT 37, ( result, defaultPos, defaultPos), rest671)
end
|  ( 48, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.stat_list
 stat_list1, _, _)) :: ( _, ( _, EFFECT1left, _)) :: rest671)) => let
 val  result = MlyValue.trans_effect (fn _ => let val  (stat_list as 
stat_list1) = stat_list1 ()
 in (stat_list)
end)
 in ( LrTable.NT 37, ( result, EFFECT1left, SEMICOLON1right), rest671)

end
|  ( 49, ( ( _, ( MlyValue.stat stat1, stat1left, stat1right)) :: 
rest671)) => let val  result = MlyValue.stat_list (fn _ => let val  (
stat as stat1) = stat1 ()
 in ([stat])
end)
 in ( LrTable.NT 38, ( result, stat1left, stat1right), rest671)
end
|  ( 50, ( ( _, ( MlyValue.stat_list stat_list1, _, stat_list1right))
 :: _ :: ( _, ( MlyValue.stat stat1, stat1left, _)) :: rest671)) =>
 let val  result = MlyValue.stat_list (fn _ => let val  (stat as stat1
) = stat1 ()
 val  (stat_list as stat_list1) = stat_list1 ()
 in (stat :: stat_list)
end)
 in ( LrTable.NT 38, ( result, stat1left, stat_list1right), rest671)

end
|  ( 51, ( ( _, ( MlyValue.assign_stat assign_stat1, assign_stat1left,
 assign_stat1right)) :: rest671)) => let val  result = MlyValue.stat
 (fn _ => let val  (assign_stat as assign_stat1) = assign_stat1 ()
 in (assign_stat)
end)
 in ( LrTable.NT 39, ( result, assign_stat1left, assign_stat1right), 
rest671)
end
|  ( 52, ( ( _, ( MlyValue.expr expr1, _, expr1right)) :: ( _, ( _, 
ASSIGNleft, _)) :: ( _, ( MlyValue.var_ref var_ref1, var_ref1left, _))
 :: rest671)) => let val  result = MlyValue.assign_stat (fn _ => let
 val  (var_ref as var_ref1) = var_ref1 ()
 val  (expr as expr1) = expr1 ()
 in (Stat.ASSIGN (ASSIGNleft, var_ref, expr))
end)
 in ( LrTable.NT 40, ( result, var_ref1left, expr1right), rest671)
end
|  ( 53, ( rest671)) => let val  result = MlyValue.trans_sync (fn _ =>
 (NONE))
 in ( LrTable.NT 32, ( result, defaultPos, defaultPos), rest671)
end
|  ( 54, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.sync_data
 sync_data1, _, _)) :: ( _, ( MlyValue.sync_type sync_type1, _, _)) ::
 ( _, ( MlyValue.IDENT IDENT1, _, _)) :: ( _, ( MlyValue.sync_mode 
sync_mode1, (sync_modeleft as sync_mode1left), _)) :: rest671)) => let
 val  result = MlyValue.trans_sync (fn _ => let val  (sync_mode as 
sync_mode1) = sync_mode1 ()
 val  (IDENT as IDENT1) = IDENT1 ()
 val  (sync_type as sync_type1) = sync_type1 ()
 val  (sync_data as sync_data1) = sync_data1 ()
 in (
SOME { pos  = sync_modeleft,
	mode = sync_mode,
	chan = IDENT,
	typ  = sync_type,
	data = sync_data }
)
end)
 in ( LrTable.NT 32, ( result, sync_mode1left, SEMICOLON1right), 
rest671)
end
|  ( 55, ( ( _, ( _, SYNC1left, SYNC1right)) :: rest671)) => let val  
result = MlyValue.sync_mode (fn _ => (Sync.SYNC))
 in ( LrTable.NT 34, ( result, SYNC1left, SYNC1right), rest671)
end
|  ( 56, ( ( _, ( _, (ASYNCleft as ASYNC1left), ASYNC1right)) :: 
rest671)) => let val  result = MlyValue.sync_mode (fn _ => (
raise Errors.ParseError
	   (ASYNCleft, "unimplemented feature: asynchronous communications")
))
 in ( LrTable.NT 34, ( result, ASYNC1left, ASYNC1right), rest671)
end
|  ( 57, ( ( _, ( _, QUESTION1left, QUESTION1right)) :: rest671)) =>
 let val  result = MlyValue.sync_type (fn _ => (Sync.RECV))
 in ( LrTable.NT 33, ( result, QUESTION1left, QUESTION1right), rest671
)
end
|  ( 58, ( ( _, ( _, EXCLAMATION1left, EXCLAMATION1right)) :: rest671)
) => let val  result = MlyValue.sync_type (fn _ => (Sync.SEND))
 in ( LrTable.NT 33, ( result, EXCLAMATION1left, EXCLAMATION1right), 
rest671)
end
|  ( 59, ( rest671)) => let val  result = MlyValue.sync_data (fn _ =>
 (NONE))
 in ( LrTable.NT 35, ( result, defaultPos, defaultPos), rest671)
end
|  ( 60, ( ( _, ( MlyValue.expr expr1, expr1left, expr1right)) :: 
rest671)) => let val  result = MlyValue.sync_data (fn _ => let val  (
expr as expr1) = expr1 ()
 in (SOME expr)
end)
 in ( LrTable.NT 35, ( result, expr1left, expr1right), rest671)
end
|  ( 61, ( ( _, ( _, _, RPAREN1right)) :: ( _, ( MlyValue.expr expr1,
 _, _)) :: ( _, ( _, LPAREN1left, _)) :: rest671)) => let val  result
 = MlyValue.expr (fn _ => let val  (expr as expr1) = expr1 ()
 in (expr)
end)
 in ( LrTable.NT 12, ( result, LPAREN1left, RPAREN1right), rest671)

end
|  ( 62, ( ( _, ( MlyValue.NUM NUM1, (NUMleft as NUM1left), NUM1right)
) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  (
NUM as NUM1) = NUM1 ()
 in (Expr.INT (NUMleft, NUM))
end)
 in ( LrTable.NT 12, ( result, NUM1left, NUM1right), rest671)
end
|  ( 63, ( ( _, ( _, (TRUEleft as TRUE1left), TRUE1right)) :: rest671)
) => let val  result = MlyValue.expr (fn _ => (
Expr.BOOL_CONST (TRUEleft, true)))
 in ( LrTable.NT 12, ( result, TRUE1left, TRUE1right), rest671)
end
|  ( 64, ( ( _, ( _, (FALSEleft as FALSE1left), FALSE1right)) :: 
rest671)) => let val  result = MlyValue.expr (fn _ => (
Expr.BOOL_CONST (FALSEleft, false)))
 in ( LrTable.NT 12, ( result, FALSE1left, FALSE1right), rest671)
end
|  ( 65, ( ( _, ( MlyValue.var_ref var_ref1, (var_refleft as 
var_ref1left), var_ref1right)) :: rest671)) => let val  result = 
MlyValue.expr (fn _ => let val  (var_ref as var_ref1) = var_ref1 ()
 in (Expr.VAR_REF (var_refleft, var_ref))
end)
 in ( LrTable.NT 12, ( result, var_ref1left, var_ref1right), rest671)

end
|  ( 66, ( ( _, ( MlyValue.IDENT IDENT2, _, IDENT2right)) :: ( _, ( _,
 DOTleft, _)) :: ( _, ( MlyValue.IDENT IDENT1, IDENT1left, _)) :: 
rest671)) => let val  result = MlyValue.expr (fn _ => let val  IDENT1
 = IDENT1 ()
 val  IDENT2 = IDENT2 ()
 in (Expr.PROCESS_STATE (DOTleft, IDENT1, IDENT2))
end)
 in ( LrTable.NT 12, ( result, IDENT1left, IDENT2right), rest671)
end
|  ( 67, ( ( _, ( MlyValue.var_ref var_ref1, _, var_ref1right)) :: ( _
, ( _, ARROWleft, _)) :: ( _, ( MlyValue.IDENT IDENT1, IDENT1left, _))
 :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  (
IDENT as IDENT1) = IDENT1 ()
 val  (var_ref as var_ref1) = var_ref1 ()
 in (Expr.PROCESS_VAR_REF (ARROWleft, IDENT, var_ref))
end)
 in ( LrTable.NT 12, ( result, IDENT1left, var_ref1right), rest671)

end
|  ( 68, ( ( _, ( MlyValue.expr expr1, _, expr1right)) :: ( _, ( _, (
NOTleft as NOT1left), _)) :: rest671)) => let val  result = 
MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 in (Expr.UN_OP (NOTleft, Expr.NOT, expr1))
end)
 in ( LrTable.NT 12, ( result, NOT1left, expr1right), rest671)
end
|  ( 69, ( ( _, ( MlyValue.expr expr1, _, expr1right)) :: ( _, ( _, (
MINUSleft as MINUS1left), _)) :: rest671)) => let val  result = 
MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 in (Expr.UN_OP (MINUSleft, Expr.UMINUS, expr1))
end)
 in ( LrTable.NT 12, ( result, MINUS1left, expr1right), rest671)
end
|  ( 70, ( ( _, ( MlyValue.expr expr1, _, expr1right)) :: ( _, ( _, (
NEGleft as NEG1left), _)) :: rest671)) => let val  result = 
MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 in (Expr.UN_OP (NEGleft, Expr.NEG, expr1))
end)
 in ( LrTable.NT 12, ( result, NEG1left, expr1right), rest671)
end
|  ( 71, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
PLUSleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671
)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1
 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (PLUSleft, expr1, Expr.PLUS, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 72, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
MINUSleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: 
rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 =
 expr1 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (MINUSleft, expr1, Expr.MINUS, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 73, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
DIVleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)
) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1
 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (DIVleft, expr1, Expr.DIV, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 74, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
TIMESleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: 
rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 =
 expr1 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (TIMESleft, expr1, Expr.TIMES, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 75, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
MODleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)
) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1
 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (MODleft, expr1, Expr.MOD, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 76, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
IMPLYleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: 
rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 =
 expr1 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (IMPLYleft, expr1, Expr.IMPLY, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 77, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
ANDleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)
) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1
 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (ANDleft, expr1, Expr.AND, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 78, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
ORleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671))
 => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (ORleft, expr1, Expr.OR, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 79, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
EQleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671))
 => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (EQleft, expr1, Expr.EQ, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 80, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
NEQleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)
) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1
 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (NEQleft, expr1, Expr.NEQ, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 81, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
INFleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)
) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1
 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (INFleft, expr1, Expr.INF, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 82, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
SUPleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)
) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1
 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (SUPleft, expr1, Expr.SUP, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 83, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
INF_EQleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: 
rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 =
 expr1 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (INF_EQleft, expr1, Expr.INF_EQ, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 84, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
SUP_EQleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: 
rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 =
 expr1 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (SUP_EQleft, expr1, Expr.SUP_EQ, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 85, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
LSHIFTleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: 
rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 =
 expr1 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (LSHIFTleft, expr1, Expr.LSHIFT, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 86, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
RSHIFTleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: 
rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 =
 expr1 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (RSHIFTleft, expr1, Expr.RSHIFT, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 87, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
AND_BITleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: 
rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 =
 expr1 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (AND_BITleft, expr1, Expr.AND_BIT, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 88, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
OR_BITleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: 
rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 =
 expr1 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (OR_BITleft, expr1, Expr.OR_BIT, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 89, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, 
XORleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)
) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1
 ()
 val  expr2 = expr2 ()
 in (Expr.BIN_OP (XORleft, expr1, Expr.XOR, expr2))
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 90, ( ( _, ( MlyValue.IDENT IDENT1, IDENT1left, IDENT1right)) :: 
rest671)) => let val  result = MlyValue.var_ref (fn _ => let val  (
IDENT as IDENT1) = IDENT1 ()
 in (Expr.SIMPLE_VAR IDENT)
end)
 in ( LrTable.NT 14, ( result, IDENT1left, IDENT1right), rest671)
end
|  ( 91, ( ( _, ( _, _, RARRAY1right)) :: ( _, ( MlyValue.expr expr1,
 _, _)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, IDENT1left, _)) :: 
rest671)) => let val  result = MlyValue.var_ref (fn _ => let val  (
IDENT as IDENT1) = IDENT1 ()
 val  (expr as expr1) = expr1 ()
 in (Expr.ARRAY_ITEM (IDENT, expr))
end)
 in ( LrTable.NT 14, ( result, IDENT1left, RARRAY1right), rest671)
end
|  ( 92, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.expr 
expr1, _, _)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, IDENTleft, _)) :: 
( _, ( _, PROGRESS1left, _)) :: rest671)) => let val  result = 
MlyValue.progress (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 val  (expr as expr1) = expr1 ()
 in ({ pos  = IDENTleft,
   name = IDENT,
   map  = expr })
end)
 in ( LrTable.NT 24, ( result, PROGRESS1left, SEMICOLON1right), 
rest671)
end
|  ( 93, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.IDENT 
IDENT1, IDENTleft, _)) :: _ :: ( _, ( _, USE1left, _)) :: rest671)) =>
 let val  result = MlyValue.progress_use (fn _ => let val  (IDENT as 
IDENT1) = IDENT1 ()
 in (IDENTleft, IDENT)
end)
 in ( LrTable.NT 25, ( result, USE1left, SEMICOLON1right), rest671)

end
|  ( 94, ( ( _, ( _, BYTE1left, BYTE1right)) :: rest671)) => let val  
result = MlyValue.type_ref (fn _ => (Typ.BYTE))
 in ( LrTable.NT 42, ( result, BYTE1left, BYTE1right), rest671)
end
|  ( 95, ( ( _, ( _, INT1left, INT1right)) :: rest671)) => let val  
result = MlyValue.type_ref (fn _ => (Typ.INT))
 in ( LrTable.NT 42, ( result, INT1left, INT1right), rest671)
end
|  ( 96, ( ( _, ( MlyValue.IDENT IDENT1, IDENT1left, IDENT1right)) :: 
rest671)) => let val  result = MlyValue.ident_list (fn _ => let val  (
IDENT as IDENT1) = IDENT1 ()
 in ([IDENT])
end)
 in ( LrTable.NT 18, ( result, IDENT1left, IDENT1right), rest671)
end
|  ( 97, ( ( _, ( MlyValue.ident_list ident_list1, _, ident_list1right
)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, IDENT1left, _)) :: rest671))
 => let val  result = MlyValue.ident_list (fn _ => let val  (IDENT as 
IDENT1) = IDENT1 ()
 val  (ident_list as ident_list1) = ident_list1 ()
 in (IDENT :: ident_list)
end)
 in ( LrTable.NT 18, ( result, IDENT1left, ident_list1right), rest671)

end
|  ( 98, ( ( _, ( MlyValue.expr expr1, expr1left, expr1right)) :: 
rest671)) => let val  result = MlyValue.expr_list (fn _ => let val  (
expr as expr1) = expr1 ()
 in ([expr])
end)
 in ( LrTable.NT 13, ( result, expr1left, expr1right), rest671)
end
|  ( 99, ( ( _, ( MlyValue.expr_list expr_list1, _, expr_list1right))
 :: _ :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) =>
 let val  result = MlyValue.expr_list (fn _ => let val  (expr as expr1
) = expr1 ()
 val  (expr_list as expr_list1) = expr_list1 ()
 in (expr :: expr_list)
end)
 in ( LrTable.NT 13, ( result, expr1left, expr_list1right), rest671)

end
|  ( 100, ( ( _, ( _, _, SEMICOLON1right)) :: _ :: ( _, ( _, (
SYSTEMleft as SYSTEM1left), _)) :: rest671)) => let val  result = 
MlyValue.system_type (fn _ => (
raise Errors.ParseError (SYSTEMleft,
			  "unimplemented feature: synchronous systems")
))
 in ( LrTable.NT 41, ( result, SYSTEM1left, SEMICOLON1right), rest671)

end
|  ( 101, ( ( _, ( _, _, SEMICOLON1right)) :: _ :: ( _, ( _, 
SYSTEM1left, _)) :: rest671)) => let val  result = 
MlyValue.system_type (fn _ => (System.ASYNCHRONOUS))
 in ( LrTable.NT 41, ( result, SYSTEM1left, SEMICOLON1right), rest671)

end
| _ => raise (mlyAction i392)
end
val void = MlyValue.VOID
val extract = fn a => (fn MlyValue.spec x => x
| _ => let exception ParseInternal
	in raise ParseInternal end) a ()
end
end
structure Tokens : Dve_TOKENS =
struct
type svalue = ParserData.svalue
type ('a,'b) token = ('a,'b) Token.token
fun IDENT (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 0,(
ParserData.MlyValue.IDENT (fn () => i),p1,p2))
fun NUM (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 1,(
ParserData.MlyValue.NUM (fn () => i),p1,p2))
fun ACCEPT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 2,(
ParserData.MlyValue.VOID,p1,p2))
fun AND (p1,p2) = Token.TOKEN (ParserData.LrTable.T 3,(
ParserData.MlyValue.VOID,p1,p2))
fun ASSERT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 4,(
ParserData.MlyValue.VOID,p1,p2))
fun ASYNC (p1,p2) = Token.TOKEN (ParserData.LrTable.T 5,(
ParserData.MlyValue.VOID,p1,p2))
fun BYTE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 6,(
ParserData.MlyValue.VOID,p1,p2))
fun CHANNEL (p1,p2) = Token.TOKEN (ParserData.LrTable.T 7,(
ParserData.MlyValue.VOID,p1,p2))
fun COMMIT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 8,(
ParserData.MlyValue.VOID,p1,p2))
fun CONST (p1,p2) = Token.TOKEN (ParserData.LrTable.T 9,(
ParserData.MlyValue.VOID,p1,p2))
fun EFFECT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 10,(
ParserData.MlyValue.VOID,p1,p2))
fun FALSE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 11,(
ParserData.MlyValue.VOID,p1,p2))
fun GUARD (p1,p2) = Token.TOKEN (ParserData.LrTable.T 12,(
ParserData.MlyValue.VOID,p1,p2))
fun IMPLY (p1,p2) = Token.TOKEN (ParserData.LrTable.T 13,(
ParserData.MlyValue.VOID,p1,p2))
fun INIT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 14,(
ParserData.MlyValue.VOID,p1,p2))
fun INT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 15,(
ParserData.MlyValue.VOID,p1,p2))
fun OR (p1,p2) = Token.TOKEN (ParserData.LrTable.T 16,(
ParserData.MlyValue.VOID,p1,p2))
fun NOT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 17,(
ParserData.MlyValue.VOID,p1,p2))
fun PROCESS (p1,p2) = Token.TOKEN (ParserData.LrTable.T 18,(
ParserData.MlyValue.VOID,p1,p2))
fun PROGRESS (p1,p2) = Token.TOKEN (ParserData.LrTable.T 19,(
ParserData.MlyValue.VOID,p1,p2))
fun STATE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 20,(
ParserData.MlyValue.VOID,p1,p2))
fun SYNC (p1,p2) = Token.TOKEN (ParserData.LrTable.T 21,(
ParserData.MlyValue.VOID,p1,p2))
fun SYSTEM (p1,p2) = Token.TOKEN (ParserData.LrTable.T 22,(
ParserData.MlyValue.VOID,p1,p2))
fun TRANS (p1,p2) = Token.TOKEN (ParserData.LrTable.T 23,(
ParserData.MlyValue.VOID,p1,p2))
fun TRUE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 24,(
ParserData.MlyValue.VOID,p1,p2))
fun USE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 25,(
ParserData.MlyValue.VOID,p1,p2))
fun MINUS (p1,p2) = Token.TOKEN (ParserData.LrTable.T 26,(
ParserData.MlyValue.VOID,p1,p2))
fun PLUS (p1,p2) = Token.TOKEN (ParserData.LrTable.T 27,(
ParserData.MlyValue.VOID,p1,p2))
fun DIV (p1,p2) = Token.TOKEN (ParserData.LrTable.T 28,(
ParserData.MlyValue.VOID,p1,p2))
fun TIMES (p1,p2) = Token.TOKEN (ParserData.LrTable.T 29,(
ParserData.MlyValue.VOID,p1,p2))
fun MOD (p1,p2) = Token.TOKEN (ParserData.LrTable.T 30,(
ParserData.MlyValue.VOID,p1,p2))
fun EQ (p1,p2) = Token.TOKEN (ParserData.LrTable.T 31,(
ParserData.MlyValue.VOID,p1,p2))
fun NEQ (p1,p2) = Token.TOKEN (ParserData.LrTable.T 32,(
ParserData.MlyValue.VOID,p1,p2))
fun INF (p1,p2) = Token.TOKEN (ParserData.LrTable.T 33,(
ParserData.MlyValue.VOID,p1,p2))
fun SUP (p1,p2) = Token.TOKEN (ParserData.LrTable.T 34,(
ParserData.MlyValue.VOID,p1,p2))
fun INF_EQ (p1,p2) = Token.TOKEN (ParserData.LrTable.T 35,(
ParserData.MlyValue.VOID,p1,p2))
fun SUP_EQ (p1,p2) = Token.TOKEN (ParserData.LrTable.T 36,(
ParserData.MlyValue.VOID,p1,p2))
fun NEG (p1,p2) = Token.TOKEN (ParserData.LrTable.T 37,(
ParserData.MlyValue.VOID,p1,p2))
fun LSHIFT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 38,(
ParserData.MlyValue.VOID,p1,p2))
fun RSHIFT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 39,(
ParserData.MlyValue.VOID,p1,p2))
fun AND_BIT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 40,(
ParserData.MlyValue.VOID,p1,p2))
fun OR_BIT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 41,(
ParserData.MlyValue.VOID,p1,p2))
fun XOR (p1,p2) = Token.TOKEN (ParserData.LrTable.T 42,(
ParserData.MlyValue.VOID,p1,p2))
fun ASSIGN (p1,p2) = Token.TOKEN (ParserData.LrTable.T 43,(
ParserData.MlyValue.VOID,p1,p2))
fun LPAREN (p1,p2) = Token.TOKEN (ParserData.LrTable.T 44,(
ParserData.MlyValue.VOID,p1,p2))
fun RPAREN (p1,p2) = Token.TOKEN (ParserData.LrTable.T 45,(
ParserData.MlyValue.VOID,p1,p2))
fun LBRACE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 46,(
ParserData.MlyValue.VOID,p1,p2))
fun RBRACE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 47,(
ParserData.MlyValue.VOID,p1,p2))
fun LARRAY (p1,p2) = Token.TOKEN (ParserData.LrTable.T 48,(
ParserData.MlyValue.VOID,p1,p2))
fun RARRAY (p1,p2) = Token.TOKEN (ParserData.LrTable.T 49,(
ParserData.MlyValue.VOID,p1,p2))
fun ARROW (p1,p2) = Token.TOKEN (ParserData.LrTable.T 50,(
ParserData.MlyValue.VOID,p1,p2))
fun DOT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 51,(
ParserData.MlyValue.VOID,p1,p2))
fun COLON (p1,p2) = Token.TOKEN (ParserData.LrTable.T 52,(
ParserData.MlyValue.VOID,p1,p2))
fun SEMICOLON (p1,p2) = Token.TOKEN (ParserData.LrTable.T 53,(
ParserData.MlyValue.VOID,p1,p2))
fun COMMA (p1,p2) = Token.TOKEN (ParserData.LrTable.T 54,(
ParserData.MlyValue.VOID,p1,p2))
fun EXCLAMATION (p1,p2) = Token.TOKEN (ParserData.LrTable.T 55,(
ParserData.MlyValue.VOID,p1,p2))
fun QUESTION (p1,p2) = Token.TOKEN (ParserData.LrTable.T 56,(
ParserData.MlyValue.VOID,p1,p2))
fun EOF (p1,p2) = Token.TOKEN (ParserData.LrTable.T 57,(
ParserData.MlyValue.VOID,p1,p2))
end
end
