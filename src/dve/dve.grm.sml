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
(*#line 1.2 "dve.grm"*)(*****************************************************************************)
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
	 A_SYSTEM_TYPE of System.system_type * string option
			  
			  
fun extractComponents [] = (NONE, NONE, [], [], []) |
    extractComponents (comp :: comps) = let
	val (t, prop, vars, channels, procs) = extractComponents comps
    in
	case comp
	 of A_PROCESS p             => (t, prop, vars, channels, p :: procs) |
	    A_VAR_LIST v            => (t, prop, v @ vars,  channels, procs) |
	    A_CHANNEL_LIST c        => (t, prop, vars,  c @ channels, procs) |
	    A_SYSTEM_TYPE (t, prop) => (SOME t, prop, vars, channels, procs)
    end

val tid = ref 0


(*#line 62.1 "dve.grm.sml"*)
end
structure LrTable = Token.LrTable
structure Token = Token
local open LrTable in 
val table=let val actionRows =
"\
\\001\000\001\000\018\000\000\000\
\\001\000\001\000\022\000\000\000\
\\001\000\001\000\026\000\000\000\
\\001\000\001\000\050\000\002\000\049\000\012\000\048\000\018\000\047\000\
\\025\000\046\000\027\000\045\000\038\000\044\000\045\000\043\000\000\000\
\\001\000\001\000\052\000\000\000\
\\001\000\001\000\113\000\000\000\
\\001\000\001\000\115\000\000\000\
\\001\000\001\000\121\000\000\000\
\\001\000\001\000\126\000\000\000\
\\001\000\001\000\141\000\000\000\
\\001\000\001\000\148\000\000\000\
\\001\000\001\000\153\000\000\000\
\\001\000\001\000\164\000\000\000\
\\001\000\001\000\175\000\000\000\
\\001\000\002\000\040\000\000\000\
\\001\000\002\000\059\000\000\000\
\\001\000\004\000\079\000\014\000\078\000\017\000\077\000\027\000\076\000\
\\028\000\075\000\029\000\074\000\030\000\073\000\031\000\072\000\
\\032\000\071\000\033\000\070\000\034\000\069\000\035\000\068\000\
\\036\000\067\000\037\000\066\000\039\000\065\000\040\000\064\000\
\\041\000\063\000\042\000\062\000\043\000\061\000\046\000\112\000\000\000\
\\001\000\004\000\079\000\014\000\078\000\017\000\077\000\027\000\076\000\
\\028\000\075\000\029\000\074\000\030\000\073\000\031\000\072\000\
\\032\000\071\000\033\000\070\000\034\000\069\000\035\000\068\000\
\\036\000\067\000\037\000\066\000\039\000\065\000\040\000\064\000\
\\041\000\063\000\042\000\062\000\043\000\061\000\050\000\123\000\000\000\
\\001\000\004\000\079\000\014\000\078\000\017\000\077\000\027\000\076\000\
\\028\000\075\000\029\000\074\000\030\000\073\000\031\000\072\000\
\\032\000\071\000\033\000\070\000\034\000\069\000\035\000\068\000\
\\036\000\067\000\037\000\066\000\039\000\065\000\040\000\064\000\
\\041\000\063\000\042\000\062\000\043\000\061\000\054\000\178\000\000\000\
\\001\000\006\000\021\000\022\000\020\000\000\000\
\\001\000\007\000\015\000\016\000\012\000\000\000\
\\001\000\015\000\118\000\000\000\
\\001\000\021\000\088\000\000\000\
\\001\000\024\000\145\000\000\000\
\\001\000\044\000\190\000\000\000\
\\001\000\047\000\034\000\000\000\
\\001\000\047\000\122\000\000\000\
\\001\000\047\000\165\000\000\000\
\\001\000\048\000\090\000\000\000\
\\001\000\048\000\136\000\000\000\
\\001\000\048\000\173\000\000\000\
\\001\000\050\000\060\000\000\000\
\\001\000\050\000\091\000\000\000\
\\001\000\051\000\160\000\000\000\
\\001\000\053\000\156\000\000\000\
\\001\000\054\000\027\000\000\000\
\\001\000\054\000\037\000\000\000\
\\001\000\054\000\051\000\000\000\
\\001\000\054\000\053\000\000\000\
\\001\000\054\000\057\000\000\000\
\\001\000\054\000\128\000\000\000\
\\001\000\054\000\134\000\000\000\
\\001\000\054\000\142\000\000\000\
\\001\000\054\000\149\000\000\000\
\\001\000\054\000\155\000\000\000\
\\001\000\054\000\159\000\000\000\
\\001\000\054\000\189\000\000\000\
\\001\000\054\000\191\000\000\000\
\\001\000\056\000\181\000\057\000\180\000\000\000\
\\001\000\058\000\000\000\000\000\
\\195\000\000\000\
\\196\000\007\000\015\000\008\000\014\000\010\000\013\000\016\000\012\000\
\\019\000\011\000\023\000\010\000\000\000\
\\197\000\000\000\
\\198\000\000\000\
\\199\000\000\000\
\\200\000\000\000\
\\201\000\000\000\
\\202\000\000\000\
\\203\000\000\000\
\\204\000\055\000\028\000\000\000\
\\205\000\000\000\
\\206\000\044\000\092\000\000\000\
\\207\000\000\000\
\\208\000\044\000\030\000\049\000\029\000\000\000\
\\209\000\004\000\079\000\014\000\078\000\017\000\077\000\027\000\076\000\
\\028\000\075\000\029\000\074\000\030\000\073\000\031\000\072\000\
\\032\000\071\000\033\000\070\000\034\000\069\000\035\000\068\000\
\\036\000\067\000\037\000\066\000\039\000\065\000\040\000\064\000\
\\041\000\063\000\042\000\062\000\043\000\061\000\000\000\
\\210\000\000\000\
\\211\000\055\000\036\000\000\000\
\\212\000\000\000\
\\213\000\049\000\038\000\000\000\
\\214\000\000\000\
\\215\000\000\000\
\\216\000\000\000\
\\217\000\007\000\015\000\010\000\013\000\016\000\012\000\000\000\
\\218\000\000\000\
\\219\000\000\000\
\\220\000\055\000\127\000\000\000\
\\221\000\000\000\
\\222\000\000\000\
\\223\000\000\000\
\\224\000\003\000\125\000\000\000\
\\225\000\000\000\
\\226\000\009\000\132\000\000\000\
\\227\000\000\000\
\\228\000\005\000\139\000\000\000\
\\229\000\000\000\
\\230\000\055\000\154\000\000\000\
\\231\000\000\000\
\\232\000\004\000\079\000\014\000\078\000\017\000\077\000\027\000\076\000\
\\028\000\075\000\029\000\074\000\030\000\073\000\031\000\072\000\
\\032\000\071\000\033\000\070\000\034\000\069\000\035\000\068\000\
\\036\000\067\000\037\000\066\000\039\000\065\000\040\000\064\000\
\\041\000\063\000\042\000\062\000\043\000\061\000\000\000\
\\233\000\000\000\
\\234\000\055\000\158\000\000\000\
\\235\000\000\000\
\\236\000\000\000\
\\237\000\000\000\
\\238\000\013\000\168\000\000\000\
\\239\000\000\000\
\\240\000\011\000\177\000\000\000\
\\241\000\000\000\
\\242\000\055\000\188\000\000\000\
\\243\000\000\000\
\\244\000\000\000\
\\245\000\004\000\079\000\014\000\078\000\017\000\077\000\027\000\076\000\
\\028\000\075\000\029\000\074\000\030\000\073\000\031\000\072\000\
\\032\000\071\000\033\000\070\000\034\000\069\000\035\000\068\000\
\\036\000\067\000\037\000\066\000\039\000\065\000\040\000\064\000\
\\041\000\063\000\042\000\062\000\043\000\061\000\000\000\
\\246\000\006\000\172\000\022\000\171\000\000\000\
\\247\000\000\000\
\\248\000\000\000\
\\249\000\000\000\
\\250\000\000\000\
\\251\000\000\000\
\\252\000\001\000\050\000\002\000\049\000\012\000\048\000\018\000\047\000\
\\025\000\046\000\027\000\045\000\038\000\044\000\045\000\043\000\000\000\
\\253\000\004\000\079\000\014\000\078\000\017\000\077\000\027\000\076\000\
\\028\000\075\000\029\000\074\000\030\000\073\000\031\000\072\000\
\\032\000\071\000\033\000\070\000\034\000\069\000\035\000\068\000\
\\036\000\067\000\037\000\066\000\039\000\065\000\040\000\064\000\
\\041\000\063\000\042\000\062\000\043\000\061\000\000\000\
\\254\000\000\000\
\\255\000\000\000\
\\000\001\000\000\
\\001\001\000\000\
\\002\001\000\000\
\\003\001\000\000\
\\004\001\000\000\
\\005\001\027\000\076\000\028\000\075\000\029\000\074\000\030\000\073\000\
\\031\000\072\000\034\000\069\000\035\000\068\000\036\000\067\000\
\\037\000\066\000\039\000\065\000\040\000\064\000\000\000\
\\006\001\029\000\074\000\030\000\073\000\031\000\072\000\000\000\
\\007\001\000\000\
\\008\001\029\000\074\000\030\000\073\000\031\000\072\000\000\000\
\\009\001\029\000\074\000\030\000\073\000\031\000\072\000\000\000\
\\010\001\000\000\
\\011\001\000\000\
\\012\001\000\000\
\\013\001\004\000\079\000\017\000\077\000\027\000\076\000\028\000\075\000\
\\029\000\074\000\030\000\073\000\031\000\072\000\032\000\071\000\
\\033\000\070\000\034\000\069\000\035\000\068\000\036\000\067\000\
\\037\000\066\000\039\000\065\000\040\000\064\000\041\000\063\000\
\\042\000\062\000\043\000\061\000\000\000\
\\014\001\027\000\076\000\028\000\075\000\029\000\074\000\030\000\073\000\
\\031\000\072\000\032\000\071\000\033\000\070\000\034\000\069\000\
\\035\000\068\000\036\000\067\000\037\000\066\000\039\000\065\000\
\\040\000\064\000\041\000\063\000\042\000\062\000\043\000\061\000\000\000\
\\015\001\004\000\079\000\027\000\076\000\028\000\075\000\029\000\074\000\
\\030\000\073\000\031\000\072\000\032\000\071\000\033\000\070\000\
\\034\000\069\000\035\000\068\000\036\000\067\000\037\000\066\000\
\\039\000\065\000\040\000\064\000\041\000\063\000\042\000\062\000\
\\043\000\061\000\000\000\
\\016\001\027\000\076\000\028\000\075\000\029\000\074\000\030\000\073\000\
\\031\000\072\000\034\000\069\000\035\000\068\000\036\000\067\000\
\\037\000\066\000\039\000\065\000\040\000\064\000\000\000\
\\017\001\027\000\076\000\028\000\075\000\029\000\074\000\030\000\073\000\
\\031\000\072\000\034\000\069\000\035\000\068\000\036\000\067\000\
\\037\000\066\000\039\000\065\000\040\000\064\000\000\000\
\\018\001\027\000\076\000\028\000\075\000\029\000\074\000\030\000\073\000\
\\031\000\072\000\039\000\065\000\040\000\064\000\000\000\
\\019\001\027\000\076\000\028\000\075\000\029\000\074\000\030\000\073\000\
\\031\000\072\000\039\000\065\000\040\000\064\000\000\000\
\\020\001\027\000\076\000\028\000\075\000\029\000\074\000\030\000\073\000\
\\031\000\072\000\039\000\065\000\040\000\064\000\000\000\
\\021\001\027\000\076\000\028\000\075\000\029\000\074\000\030\000\073\000\
\\031\000\072\000\039\000\065\000\040\000\064\000\000\000\
\\022\001\027\000\076\000\028\000\075\000\029\000\074\000\030\000\073\000\
\\031\000\072\000\000\000\
\\023\001\027\000\076\000\028\000\075\000\029\000\074\000\030\000\073\000\
\\031\000\072\000\000\000\
\\024\001\027\000\076\000\028\000\075\000\029\000\074\000\030\000\073\000\
\\031\000\072\000\032\000\071\000\033\000\070\000\034\000\069\000\
\\035\000\068\000\036\000\067\000\037\000\066\000\039\000\065\000\
\\040\000\064\000\000\000\
\\025\001\027\000\076\000\028\000\075\000\029\000\074\000\030\000\073\000\
\\031\000\072\000\032\000\071\000\033\000\070\000\034\000\069\000\
\\035\000\068\000\036\000\067\000\037\000\066\000\039\000\065\000\
\\040\000\064\000\041\000\063\000\043\000\061\000\000\000\
\\026\001\027\000\076\000\028\000\075\000\029\000\074\000\030\000\073\000\
\\031\000\072\000\032\000\071\000\033\000\070\000\034\000\069\000\
\\035\000\068\000\036\000\067\000\037\000\066\000\039\000\065\000\
\\040\000\064\000\041\000\063\000\000\000\
\\027\001\049\000\086\000\000\000\
\\027\001\049\000\086\000\051\000\085\000\052\000\084\000\000\000\
\\028\001\000\000\
\\029\001\000\000\
\\030\001\000\000\
\\031\001\055\000\150\000\000\000\
\\032\001\000\000\
\\033\001\004\000\079\000\014\000\078\000\017\000\077\000\027\000\076\000\
\\028\000\075\000\029\000\074\000\030\000\073\000\031\000\072\000\
\\032\000\071\000\033\000\070\000\034\000\069\000\035\000\068\000\
\\036\000\067\000\037\000\066\000\039\000\065\000\040\000\064\000\
\\041\000\063\000\042\000\062\000\043\000\061\000\055\000\137\000\000\000\
\\034\001\000\000\
\\035\001\000\000\
\\036\001\000\000\
\\037\001\020\000\032\000\000\000\
\\038\001\000\000\
\"
val actionRowNumbers =
"\051\000\000\000\056\000\055\000\
\\054\000\051\000\050\000\053\000\
\\019\000\001\000\142\000\020\000\
\\002\000\141\000\035\000\059\000\
\\063\000\052\000\149\000\149\000\
\\025\000\000\000\066\000\036\000\
\\068\000\057\000\000\000\014\000\
\\003\000\037\000\004\000\038\000\
\\072\000\039\000\002\000\065\000\
\\015\000\060\000\031\000\113\000\
\\064\000\003\000\003\000\003\000\
\\111\000\003\000\112\000\110\000\
\\139\000\147\000\150\000\148\000\
\\022\000\072\000\028\000\058\000\
\\067\000\032\000\061\000\003\000\
\\003\000\003\000\003\000\003\000\
\\003\000\003\000\003\000\003\000\
\\003\000\003\000\003\000\003\000\
\\003\000\003\000\003\000\003\000\
\\003\000\003\000\016\000\118\000\
\\117\000\116\000\005\000\006\000\
\\003\000\021\000\007\000\073\000\
\\070\000\069\000\026\000\137\000\
\\136\000\135\000\134\000\133\000\
\\132\000\131\000\130\000\129\000\
\\128\000\127\000\123\000\122\000\
\\121\000\119\000\120\000\126\000\
\\124\000\125\000\109\000\114\000\
\\115\000\138\000\017\000\079\000\
\\008\000\075\000\040\000\077\000\
\\003\000\140\000\081\000\007\000\
\\041\000\007\000\074\000\029\000\
\\145\000\083\000\009\000\042\000\
\\078\000\076\000\062\000\003\000\
\\023\000\010\000\043\000\143\000\
\\080\000\146\000\071\000\011\000\
\\085\000\044\000\034\000\082\000\
\\009\000\089\000\045\000\033\000\
\\010\000\084\000\003\000\144\000\
\\011\000\088\000\012\000\086\000\
\\087\000\090\000\027\000\093\000\
\\101\000\030\000\003\000\013\000\
\\095\000\103\000\104\000\091\000\
\\018\000\048\000\092\000\006\000\
\\094\000\107\000\105\000\106\000\
\\099\000\097\000\046\000\024\000\
\\047\000\108\000\006\000\096\000\
\\003\000\102\000\098\000\100\000\
\\049\000"
val gotoT =
"\
\\001\000\192\000\002\000\007\000\008\000\006\000\009\000\005\000\
\\010\000\004\000\018\000\003\000\041\000\002\000\042\000\001\000\000\000\
\\016\000\015\000\017\000\014\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\002\000\007\000\008\000\017\000\009\000\005\000\010\000\004\000\
\\018\000\003\000\041\000\002\000\042\000\001\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\042\000\021\000\000\000\
\\011\000\023\000\012\000\022\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\026\000\029\000\000\000\
\\026\000\031\000\000\000\
\\000\000\
\\016\000\015\000\017\000\033\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\016\000\015\000\017\000\037\000\000\000\
\\000\000\
\\013\000\040\000\015\000\039\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\003\000\054\000\018\000\053\000\025\000\052\000\042\000\001\000\000\000\
\\000\000\
\\011\000\056\000\012\000\022\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\013\000\078\000\015\000\039\000\000\000\
\\013\000\079\000\015\000\039\000\000\000\
\\013\000\080\000\015\000\039\000\000\000\
\\000\000\
\\013\000\081\000\015\000\039\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\004\000\085\000\000\000\
\\018\000\053\000\025\000\087\000\042\000\001\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\013\000\091\000\015\000\039\000\000\000\
\\013\000\092\000\015\000\039\000\000\000\
\\013\000\093\000\015\000\039\000\000\000\
\\013\000\094\000\015\000\039\000\000\000\
\\013\000\095\000\015\000\039\000\000\000\
\\013\000\096\000\015\000\039\000\000\000\
\\013\000\097\000\015\000\039\000\000\000\
\\013\000\098\000\015\000\039\000\000\000\
\\013\000\099\000\015\000\039\000\000\000\
\\013\000\100\000\015\000\039\000\000\000\
\\013\000\101\000\015\000\039\000\000\000\
\\013\000\102\000\015\000\039\000\000\000\
\\013\000\103\000\015\000\039\000\000\000\
\\013\000\104\000\015\000\039\000\000\000\
\\013\000\105\000\015\000\039\000\000\000\
\\013\000\106\000\015\000\039\000\000\000\
\\013\000\107\000\015\000\039\000\000\000\
\\013\000\108\000\015\000\039\000\000\000\
\\013\000\109\000\015\000\039\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\015\000\112\000\000\000\
\\013\000\114\000\015\000\039\000\000\000\
\\007\000\115\000\000\000\
\\005\000\118\000\006\000\117\000\000\000\
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
\\020\000\122\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\013\000\128\000\014\000\127\000\015\000\039\000\000\000\
\\000\000\
\\021\000\129\000\000\000\
\\005\000\131\000\006\000\117\000\000\000\
\\000\000\
\\005\000\133\000\006\000\117\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\022\000\136\000\000\000\
\\019\000\138\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\013\000\128\000\014\000\141\000\015\000\039\000\000\000\
\\027\000\142\000\000\000\
\\023\000\145\000\024\000\144\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\028\000\150\000\029\000\149\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\019\000\155\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\023\000\159\000\024\000\144\000\000\000\
\\000\000\
\\013\000\160\000\015\000\039\000\000\000\
\\000\000\
\\028\000\161\000\029\000\149\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\030\000\165\000\031\000\164\000\000\000\
\\032\000\168\000\034\000\167\000\000\000\
\\000\000\
\\013\000\172\000\015\000\039\000\000\000\
\\000\000\
\\037\000\174\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\033\000\177\000\000\000\
\\000\000\
\\015\000\183\000\038\000\182\000\039\000\181\000\040\000\180\000\000\000\
\\000\000\
\\013\000\185\000\015\000\039\000\035\000\184\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\\015\000\183\000\038\000\190\000\039\000\181\000\040\000\180\000\000\000\
\\000\000\
\\013\000\191\000\015\000\039\000\000\000\
\\000\000\
\\000\000\
\\000\000\
\\000\000\
\"
val numstates = 193
val numrules = 100
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
datatype svalue = VOID | ntVOID of unit ->  unit | NUM of unit ->  (LargeInt.int) | IDENT of unit ->  (string) | type_ref of unit ->  (Typ.basic_typ) | system_type of unit ->  (System.system_type*string option) | assign_stat of unit ->  (Stat.stat) | stat of unit ->  (Stat.stat) | stat_list of unit ->  (Stat.stat list) | trans_effect of unit ->  (Stat.stat list) | data_exchanged of unit ->  (Expr.expr option) | sync_data of unit ->  (Expr.expr option) | sync_mode of unit ->  (Sync.sync_mode) | sync_type of unit ->  (Sync.sync_type) | trans_sync of unit ->  (Sync.sync option) | trans_guard of unit ->  (Expr.expr option) | trans_detail of unit ->  (Expr.expr option*Sync.sync option*Stat.stat list) | trans_def of unit ->  (Trans.trans) | trans_list of unit ->  (Trans.trans list) | transitions of unit ->  (Trans.trans list) | property_def of unit ->  (string option) | process_var_list of unit ->  (Var.var list) | accept_states of unit ->  (State.state list) | ident_list of unit ->  (string list) | var_list of unit ->  (Var.var list) | var_defs of unit ->  ( ( Pos.pos * string * int option * Expr.expr option )  list) | var_def of unit ->  (Pos.pos*string*int option*Expr.expr option) | var_ref of unit ->  (Expr.var_ref) | expr_list of unit ->  (Expr.expr list) | expr of unit ->  (Expr.expr) | channel_def of unit ->  (Channel.channel) | channel_defs of unit ->  (Channel.channel list) | channel_list of unit ->  (Channel.channel list) | system_comp of unit ->  (system_comp) | system_comp_list of unit ->  (system_comp list) | init_state of unit ->  (State.state) | state_ident of unit ->  (State.state) | state_ident_list of unit ->  (State.state list) | state_list of unit ->  (State.state list) | process_body of unit ->  (Var.var list*State.state list*State.state*State.state list*Trans.trans list) | process_def of unit ->  (Process.process) | spec of unit ->  (System.system)
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
  | (T 19) => "PROPERTY"
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
 $$ (T 57) $$ (T 56) $$ (T 55) $$ (T 54) $$ (T 53) $$ (T 52) $$ (T 51) $$ (T 50) $$ (T 49) $$ (T 48) $$ (T 47) $$ (T 46) $$ (T 45) $$ (T 44) $$ (T 43) $$ (T 42) $$ (T 41) $$ (T 40) $$ (T 39) $$ (T 38) $$ (T 37) $$ (T 36) $$ (T 35) $$ (T 34) $$ (T 33) $$ (T 32) $$ (T 31) $$ (T 30) $$ (T 29) $$ (T 28) $$ (T 27) $$ (T 26) $$ (T 25) $$ (T 24) $$ (T 23) $$ (T 22) $$ (T 21) $$ (T 20) $$ (T 19) $$ (T 18) $$ (T 17) $$ (T 16) $$ (T 15) $$ (T 14) $$ (T 13) $$ (T 12) $$ (T 11) $$ (T 10) $$ (T 9) $$ (T 8) $$ (T 7) $$ (T 6) $$ (T 5) $$ (T 4) $$ (T 3) $$ (T 2)end
structure Actions =
struct 
exception mlyAction of int
local open Header in
val actions = 
fn (i392,defaultPos,stack,
    (()):arg) =>
case (i392,stack)
of  ( 0, ( ( _, ( MlyValue.system_comp_list system_comp_list1, system_comp_list1left, system_comp_list1right)) :: rest671)) => let val  result = MlyValue.spec (fn _ => let val  (system_comp_list as system_comp_list1) = system_comp_list1 ()
 in ((*#line 194.2 "dve.grm"*)let val _ = tid := 0
     val comps = system_comp_list
     val (sys_type, prop, vars, channels, processes) =
	 extractComponents comps
 in
     case sys_type
      of NONE => raise Errors.ParseError
			   (1, "system type expected (sync / async)")
       | SOME t => { t     = t,
                     prop  = prop,
		     glob  = vars,
		     chans = channels,
		     procs = processes }
 end(*#line 689.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 0, ( result, system_comp_list1left, system_comp_list1right), rest671)
end
|  ( 1, ( rest671)) => let val  result = MlyValue.system_comp_list (fn _ => ((*#line 211.2 "dve.grm"*)[](*#line 708.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 7, ( result, defaultPos, defaultPos), rest671)
end
|  ( 2, ( ( _, ( MlyValue.system_comp_list system_comp_list1, _, system_comp_list1right)) :: ( _, ( MlyValue.system_comp system_comp1, system_comp1left, _)) :: rest671)) => let val  result = MlyValue.system_comp_list (fn _ => let val  (system_comp as system_comp1) = system_comp1 ()
 val  (system_comp_list as system_comp_list1) = system_comp_list1 ()
 in ((*#line 214.2 "dve.grm"*)system_comp :: system_comp_list(*#line 712.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 7, ( result, system_comp1left, system_comp_list1right), rest671)
end
|  ( 3, ( ( _, ( MlyValue.process_def process_def1, process_def1left, process_def1right)) :: rest671)) => let val  result = MlyValue.system_comp (fn _ => let val  (process_def as process_def1) = process_def1 ()
 in ((*#line 219.2 "dve.grm"*)A_PROCESS process_def(*#line 719.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 8, ( result, process_def1left, process_def1right), rest671)
end
|  ( 4, ( ( _, ( MlyValue.channel_list channel_list1, channel_list1left, channel_list1right)) :: rest671)) => let val  result = MlyValue.system_comp (fn _ => let val  (channel_list as channel_list1) = channel_list1 ()
 in ((*#line 222.2 "dve.grm"*)A_CHANNEL_LIST channel_list(*#line 725.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 8, ( result, channel_list1left, channel_list1right), rest671)
end
|  ( 5, ( ( _, ( MlyValue.var_list var_list1, var_list1left, var_list1right)) :: rest671)) => let val  result = MlyValue.system_comp (fn _ => let val  (var_list as var_list1) = var_list1 ()
 in ((*#line 225.2 "dve.grm"*)A_VAR_LIST var_list(*#line 731.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 8, ( result, var_list1left, var_list1right), rest671)
end
|  ( 6, ( ( _, ( MlyValue.system_type system_type1, system_type1left, system_type1right)) :: rest671)) => let val  result = MlyValue.system_comp (fn _ => let val  (system_type as system_type1) = system_type1 ()
 in ((*#line 228.2 "dve.grm"*)A_SYSTEM_TYPE system_type(*#line 737.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 8, ( result, system_type1left, system_type1right), rest671)
end
|  ( 7, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.var_defs var_defs1, _, _)) :: ( _, ( MlyValue.type_ref type_ref1, type_ref1left, _)) :: rest671)) => let val  result = MlyValue.var_list (fn _ => let val  (type_ref as type_ref1) = type_ref1 ()
 val  (var_defs as var_defs1) = var_defs1 ()
 in ((*#line 236.2 "dve.grm"*)buildVarList (var_defs, type_ref, false)(*#line 743.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 17, ( result, type_ref1left, SEMICOLON1right), rest671)
end
|  ( 8, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.var_defs var_defs1, _, _)) :: ( _, ( MlyValue.type_ref type_ref1, _, _)) :: ( _, ( _, CONST1left, _)) :: rest671)) => let val  result = MlyValue.var_list (fn _ => let val  (type_ref as type_ref1) = type_ref1 ()
 val  (var_defs as var_defs1) = var_defs1 ()
 in ((*#line 239.2 "dve.grm"*)buildVarList (var_defs, type_ref, true)(*#line 750.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 17, ( result, CONST1left, SEMICOLON1right), rest671)
end
|  ( 9, ( ( _, ( MlyValue.var_def var_def1, var_def1left, var_def1right)) :: rest671)) => let val  result = MlyValue.var_defs (fn _ => let val  (var_def as var_def1) = var_def1 ()
 in ((*#line 244.2 "dve.grm"*)[var_def](*#line 757.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 16, ( result, var_def1left, var_def1right), rest671)
end
|  ( 10, ( ( _, ( MlyValue.var_defs var_defs1, _, var_defs1right)) :: _ :: ( _, ( MlyValue.var_def var_def1, var_def1left, _)) :: rest671)) => let val  result = MlyValue.var_defs (fn _ => let val  (var_def as var_def1) = var_def1 ()
 val  (var_defs as var_defs1) = var_defs1 ()
 in ((*#line 247.2 "dve.grm"*)var_def :: var_defs(*#line 763.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 16, ( result, var_def1left, var_defs1right), rest671)
end
|  ( 11, ( ( _, ( _, _, RARRAY1right)) :: ( _, ( MlyValue.NUM NUM1, _, _)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, (IDENTleft as IDENT1left), _)) :: rest671)) => let val  result = MlyValue.var_def (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 val  (NUM as NUM1) = NUM1 ()
 in ((*#line 252.2 "dve.grm"*)(IDENTleft, IDENT, SOME (LargeInt.toInt NUM), NONE)(*#line 770.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 15, ( result, IDENT1left, RARRAY1right), rest671)
end
|  ( 12, ( ( _, ( _, _, RBRACE1right)) :: ( _, ( MlyValue.expr_list expr_list1, _, _)) :: _ :: _ :: ( _, ( _, RARRAYleft, _)) :: ( _, ( MlyValue.NUM NUM1, _, _)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, (IDENTleft as IDENT1left), _)) :: rest671)) => let val  result = MlyValue.var_def (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 val  (NUM as NUM1) = NUM1 ()
 val  (expr_list as expr_list1) = expr_list1 ()
 in ((*#line 255.2 "dve.grm"*)(IDENTleft, IDENT, SOME (LargeInt.toInt NUM),
  SOME (Expr.ARRAY_INIT (RARRAYleft, expr_list)))(*#line 777.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 15, ( result, IDENT1left, RBRACE1right), rest671)
end
|  ( 13, ( ( _, ( MlyValue.IDENT IDENT1, (IDENTleft as IDENT1left), IDENT1right)) :: rest671)) => let val  result = MlyValue.var_def (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 in ((*#line 259.2 "dve.grm"*)(IDENTleft, IDENT, NONE, NONE)(*#line 786.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 15, ( result, IDENT1left, IDENT1right), rest671)
end
|  ( 14, ( ( _, ( MlyValue.expr expr1, _, expr1right)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, (IDENTleft as IDENT1left), _)) :: rest671)) => let val  result = MlyValue.var_def (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 val  (expr as expr1) = expr1 ()
 in ((*#line 262.2 "dve.grm"*)(IDENTleft, IDENT, NONE, SOME expr)(*#line 792.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 15, ( result, IDENT1left, expr1right), rest671)
end
|  ( 15, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.channel_defs channel_defs1, _, _)) :: ( _, ( _, CHANNEL1left, _)) :: rest671)) => let val  result = MlyValue.channel_list (fn _ => let val  (channel_defs as channel_defs1) = channel_defs1 ()
 in ((*#line 270.2 "dve.grm"*)channel_defs(*#line 799.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 9, ( result, CHANNEL1left, SEMICOLON1right), rest671)
end
|  ( 16, ( ( _, ( MlyValue.channel_def channel_def1, channel_def1left, channel_def1right)) :: rest671)) => let val  result = MlyValue.channel_defs (fn _ => let val  (channel_def as channel_def1) = channel_def1 ()
 in ((*#line 275.2 "dve.grm"*)[channel_def](*#line 805.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 10, ( result, channel_def1left, channel_def1right), rest671)
end
|  ( 17, ( ( _, ( MlyValue.channel_defs channel_defs1, _, channel_defs1right)) :: _ :: ( _, ( MlyValue.channel_def channel_def1, channel_def1left, _)) :: rest671)) => let val  result = MlyValue.channel_defs (fn _ => let val  (channel_def as channel_def1) = channel_def1 ()
 val  (channel_defs as channel_defs1) = channel_defs1 ()
 in ((*#line 278.2 "dve.grm"*)channel_def :: channel_defs(*#line 811.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 10, ( result, channel_def1left, channel_defs1right), rest671)
end
|  ( 18, ( ( _, ( MlyValue.IDENT IDENT1, (IDENTleft as IDENT1left), IDENT1right)) :: rest671)) => let val  result = MlyValue.channel_def (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 in ((*#line 283.2 "dve.grm"*){ pos = IDENTleft, name = IDENT, size = 0 }(*#line 818.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 11, ( result, IDENT1left, IDENT1right), rest671)
end
|  ( 19, ( ( _, ( _, _, RARRAY1right)) :: ( _, ( MlyValue.NUM NUM1, _, _)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, (IDENTleft as IDENT1left), _)) :: rest671)) => let val  result = MlyValue.channel_def (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 val  (NUM as NUM1) = NUM1 ()
 in ((*#line 286.2 "dve.grm"*)if NUM = 0
 then { pos = IDENTleft, name = IDENT, size = 0 }
 else raise Errors.ParseError (IDENTleft,
			       "unimplemented feature: buffered channels")(*#line 824.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 11, ( result, IDENT1left, RARRAY1right), rest671)
end
|  ( 20, ( ( _, ( _, _, RBRACE1right)) :: ( _, ( MlyValue.process_body process_body1, _, _)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, _, _)) :: ( _, ( _, (PROCESSleft as PROCESS1left), _)) :: rest671)) => let val  result = MlyValue.process_def (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 val  (process_body as process_body1) = process_body1 ()
 in ((*#line 297.2 "dve.grm"*)let val (vars, states, init, accept, trans) = process_body in
     {
      pos    = PROCESSleft,
      name   = IDENT,
      vars   = vars,
      states = states,
      init   = init,
      trans  = trans,
      accept = accept
     }
 end(*#line 834.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 1, ( result, PROCESS1left, RBRACE1right), rest671)
end
|  ( 21, ( ( _, ( MlyValue.transitions transitions1, _, transitions1right)) :: ( _, ( MlyValue.ntVOID assert_clause1, _, _)) :: ( _, ( MlyValue.ntVOID commit_states1, _, _)) :: ( _, ( MlyValue.accept_states accept_states1, _, _)) :: ( _, ( MlyValue.init_state init_state1, _, _)) :: ( _, ( MlyValue.state_list state_list1, _, _)) :: ( _, ( MlyValue.process_var_list process_var_list1, process_var_list1left, _)) :: rest671)) => let val  result = MlyValue.process_body (fn _ => let val  (process_var_list as process_var_list1) = process_var_list1 ()
 val  (state_list as state_list1) = state_list1 ()
 val  (init_state as init_state1) = init_state1 ()
 val  (accept_states as accept_states1) = accept_states1 ()
 val  commit_states1 = commit_states1 ()
 val  assert_clause1 = assert_clause1 ()
 val  (transitions as transitions1) = transitions1 ()
 in ((*#line 313.2 "dve.grm"*)(process_var_list, state_list, init_state, accept_states, transitions)(*#line 851.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 2, ( result, process_var_list1left, transitions1right), rest671)
end
|  ( 22, ( rest671)) => let val  result = MlyValue.process_var_list (fn _ => ((*#line 317.2 "dve.grm"*)[](*#line 863.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 24, ( result, defaultPos, defaultPos), rest671)
end
|  ( 23, ( ( _, ( MlyValue.process_var_list process_var_list1, _, process_var_list1right)) :: ( _, ( MlyValue.var_list var_list1, var_list1left, _)) :: rest671)) => let val  result = MlyValue.process_var_list (fn _ => let val  (var_list as var_list1) = var_list1 ()
 val  (process_var_list as process_var_list1) = process_var_list1 ()
 in ((*#line 320.2 "dve.grm"*)var_list @ process_var_list(*#line 867.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 24, ( result, var_list1left, process_var_list1right), rest671)
end
|  ( 24, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.state_ident_list state_ident_list1, _, _)) :: ( _, ( _, STATE1left, _)) :: rest671)) => let val  result = MlyValue.state_list (fn _ => let val  (state_ident_list as state_ident_list1) = state_ident_list1 ()
 in ((*#line 325.2 "dve.grm"*)state_ident_list(*#line 874.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 3, ( result, STATE1left, SEMICOLON1right), rest671)
end
|  ( 25, ( ( _, ( MlyValue.state_ident state_ident1, state_ident1left, state_ident1right)) :: rest671)) => let val  result = MlyValue.state_ident_list (fn _ => let val  (state_ident as state_ident1) = state_ident1 ()
 in ((*#line 330.2 "dve.grm"*)[state_ident](*#line 880.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 4, ( result, state_ident1left, state_ident1right), rest671)
end
|  ( 26, ( ( _, ( MlyValue.state_ident_list state_ident_list1, _, state_ident_list1right)) :: _ :: ( _, ( MlyValue.state_ident state_ident1, state_ident1left, _)) :: rest671)) => let val  result = MlyValue.state_ident_list (fn _ => let val  (state_ident as state_ident1) = state_ident1 ()
 val  (state_ident_list as state_ident_list1) = state_ident_list1 ()
 in ((*#line 333.2 "dve.grm"*)state_ident :: state_ident_list(*#line 886.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 4, ( result, state_ident1left, state_ident_list1right), rest671)
end
|  ( 27, ( ( _, ( MlyValue.IDENT IDENT1, (IDENTleft as IDENT1left), IDENT1right)) :: rest671)) => let val  result = MlyValue.state_ident (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 in ((*#line 338.2 "dve.grm"*){ pos = IDENTleft, name = IDENT }(*#line 893.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 5, ( result, IDENT1left, IDENT1right), rest671)
end
|  ( 28, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.IDENT IDENT1, IDENTleft, _)) :: ( _, ( _, INIT1left, _)) :: rest671)) => let val  result = MlyValue.init_state (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 in ((*#line 343.2 "dve.grm"*){ pos = IDENTleft, name = IDENT }(*#line 899.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 6, ( result, INIT1left, SEMICOLON1right), rest671)
end
|  ( 29, ( rest671)) => let val  result = MlyValue.accept_states (fn _ => ((*#line 347.2 "dve.grm"*)[](*#line 905.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 19, ( result, defaultPos, defaultPos), rest671)
end
|  ( 30, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.state_ident_list state_ident_list1, _, _)) :: ( _, ( _, ACCEPT1left, _)) :: rest671)) => let val  result = MlyValue.accept_states (fn _ => let val  (state_ident_list as state_ident_list1) = state_ident_list1 ()
 in ((*#line 350.2 "dve.grm"*)state_ident_list(*#line 909.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 19, ( result, ACCEPT1left, SEMICOLON1right), rest671)
end
|  ( 31, ( rest671)) => let val  result = MlyValue.ntVOID (fn _ => ((*#line 354.2 "dve.grm"*)(*#line 915.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 20, ( result, defaultPos, defaultPos), rest671)
end
|  ( 32, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.ident_list ident_list1, _, _)) :: ( _, ( _, (COMMITleft as COMMIT1left), _)) :: rest671)) => let val  result = MlyValue.ntVOID (fn _ => ( let val  ident_list1 = ident_list1 ()
 in ((*#line 357.2 "dve.grm"*)raise Errors.ParseError (COMMITleft,
			  "unimplemented feature: commited states")(*#line 919.1 "dve.grm.sml"*)
)
end; ()))
 in ( LrTable.NT 20, ( result, COMMIT1left, SEMICOLON1right), rest671)
end
|  ( 33, ( rest671)) => let val  result = MlyValue.ntVOID (fn _ => ((*#line 362.2 "dve.grm"*)(*#line 926.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 21, ( result, defaultPos, defaultPos), rest671)
end
|  ( 34, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.ntVOID assert_list1, _, _)) :: ( _, ( _, (ASSERTleft as ASSERT1left), _)) :: rest671)) => let val  result = MlyValue.ntVOID (fn _ => ( let val  assert_list1 = assert_list1 ()
 in ((*#line 365.2 "dve.grm"*)raise Errors.ParseError (ASSERTleft,
			  "unimplemented feature: assertions")(*#line 930.1 "dve.grm.sml"*)
)
end; ()))
 in ( LrTable.NT 21, ( result, ASSERT1left, SEMICOLON1right), rest671)
end
|  ( 35, ( ( _, ( MlyValue.ntVOID assert_cond1, assert_cond1left, assert_cond1right)) :: rest671)) => let val  result = MlyValue.ntVOID (fn _ => ( let val  assert_cond1 = assert_cond1 ()
 in ((*#line 371.2 "dve.grm"*)(*#line 937.1 "dve.grm.sml"*)
)
end; ()))
 in ( LrTable.NT 22, ( result, assert_cond1left, assert_cond1right), rest671)
end
|  ( 36, ( ( _, ( MlyValue.ntVOID assert_list1, _, assert_list1right)) :: _ :: ( _, ( MlyValue.ntVOID assert_cond1, assert_cond1left, _)) :: rest671)) => let val  result = MlyValue.ntVOID (fn _ => ( let val  assert_cond1 = assert_cond1 ()
 val  assert_list1 = assert_list1 ()
 in ((*#line 374.2 "dve.grm"*)(*#line 943.1 "dve.grm.sml"*)
)
end; ()))
 in ( LrTable.NT 22, ( result, assert_cond1left, assert_list1right), rest671)
end
|  ( 37, ( ( _, ( MlyValue.expr expr1, _, expr1right)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, IDENT1left, _)) :: rest671)) => let val  result = MlyValue.ntVOID (fn _ => ( let val  IDENT1 = IDENT1 ()
 val  expr1 = expr1 ()
 in ((*#line 379.2 "dve.grm"*)(*#line 950.1 "dve.grm.sml"*)
)
end; ()))
 in ( LrTable.NT 23, ( result, IDENT1left, expr1right), rest671)
end
|  ( 38, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.trans_list trans_list1, _, _)) :: ( _, ( _, TRANS1left, _)) :: rest671)) => let val  result = MlyValue.transitions (fn _ => let val  (trans_list as trans_list1) = trans_list1 ()
 in ((*#line 387.2 "dve.grm"*)trans_list(*#line 957.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 26, ( result, TRANS1left, SEMICOLON1right), rest671)
end
|  ( 39, ( ( _, ( MlyValue.trans_def trans_def1, trans_def1left, trans_def1right)) :: rest671)) => let val  result = MlyValue.trans_list (fn _ => let val  (trans_def as trans_def1) = trans_def1 ()
 in ((*#line 392.2 "dve.grm"*)[trans_def](*#line 963.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 27, ( result, trans_def1left, trans_def1right), rest671)
end
|  ( 40, ( ( _, ( MlyValue.trans_list trans_list1, _, trans_list1right)) :: _ :: ( _, ( MlyValue.trans_def trans_def1, trans_def1left, _)) :: rest671)) => let val  result = MlyValue.trans_list (fn _ => let val  (trans_def as trans_def1) = trans_def1 ()
 val  (trans_list as trans_list1) = trans_list1 ()
 in ((*#line 395.2 "dve.grm"*)trans_def :: trans_list(*#line 969.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 27, ( result, trans_def1left, trans_list1right), rest671)
end
|  ( 41, ( ( _, ( _, _, RBRACE1right)) :: ( _, ( MlyValue.trans_detail trans_detail1, _, _)) :: _ :: ( _, ( MlyValue.IDENT IDENT2, _, _)) :: ( _, ( _, ARROWleft, _)) :: ( _, ( MlyValue.IDENT IDENT1, IDENT1left, _)) :: rest671)) => let val  result = MlyValue.trans_def (fn _ => let val  IDENT1 = IDENT1 ()
 val  IDENT2 = IDENT2 ()
 val  (trans_detail as trans_detail1) = trans_detail1 ()
 in ((*#line 400.2 "dve.grm"*)let val (guard, sync, effect) = trans_detail
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
 end(*#line 976.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 28, ( result, IDENT1left, RBRACE1right), rest671)
end
|  ( 42, ( ( _, ( MlyValue.trans_effect trans_effect1, _, trans_effect1right)) :: ( _, ( MlyValue.trans_sync trans_sync1, _, _)) :: ( _, ( MlyValue.trans_guard trans_guard1, trans_guard1left, _)) :: rest671)) => let val  result = MlyValue.trans_detail (fn _ => let val  (trans_guard as trans_guard1) = trans_guard1 ()
 val  (trans_sync as trans_sync1) = trans_sync1 ()
 val  (trans_effect as trans_effect1) = trans_effect1 ()
 in ((*#line 418.2 "dve.grm"*)(trans_guard, trans_sync, trans_effect)(*#line 997.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 29, ( result, trans_guard1left, trans_effect1right), rest671)
end
|  ( 43, ( rest671)) => let val  result = MlyValue.trans_guard (fn _ => ((*#line 422.2 "dve.grm"*)NONE(*#line 1005.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 30, ( result, defaultPos, defaultPos), rest671)
end
|  ( 44, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.expr expr1, _, _)) :: ( _, ( _, GUARD1left, _)) :: rest671)) => let val  result = MlyValue.trans_guard (fn _ => let val  (expr as expr1) = expr1 ()
 in ((*#line 425.2 "dve.grm"*)SOME expr(*#line 1009.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 30, ( result, GUARD1left, SEMICOLON1right), rest671)
end
|  ( 45, ( rest671)) => let val  result = MlyValue.trans_effect (fn _ => ((*#line 429.2 "dve.grm"*)[](*#line 1015.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 36, ( result, defaultPos, defaultPos), rest671)
end
|  ( 46, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.stat_list stat_list1, _, _)) :: ( _, ( _, EFFECT1left, _)) :: rest671)) => let val  result = MlyValue.trans_effect (fn _ => let val  (stat_list as stat_list1) = stat_list1 ()
 in ((*#line 432.2 "dve.grm"*)stat_list(*#line 1019.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 36, ( result, EFFECT1left, SEMICOLON1right), rest671)
end
|  ( 47, ( ( _, ( MlyValue.stat stat1, stat1left, stat1right)) :: rest671)) => let val  result = MlyValue.stat_list (fn _ => let val  (stat as stat1) = stat1 ()
 in ((*#line 437.2 "dve.grm"*)[stat](*#line 1025.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 37, ( result, stat1left, stat1right), rest671)
end
|  ( 48, ( ( _, ( MlyValue.stat_list stat_list1, _, stat_list1right)) :: _ :: ( _, ( MlyValue.stat stat1, stat1left, _)) :: rest671)) => let val  result = MlyValue.stat_list (fn _ => let val  (stat as stat1) = stat1 ()
 val  (stat_list as stat_list1) = stat_list1 ()
 in ((*#line 440.2 "dve.grm"*)stat :: stat_list(*#line 1031.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 37, ( result, stat1left, stat_list1right), rest671)
end
|  ( 49, ( ( _, ( MlyValue.assign_stat assign_stat1, assign_stat1left, assign_stat1right)) :: rest671)) => let val  result = MlyValue.stat (fn _ => let val  (assign_stat as assign_stat1) = assign_stat1 ()
 in ((*#line 445.2 "dve.grm"*)assign_stat(*#line 1038.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 38, ( result, assign_stat1left, assign_stat1right), rest671)
end
|  ( 50, ( ( _, ( MlyValue.expr expr1, _, expr1right)) :: ( _, ( _, ASSIGNleft, _)) :: ( _, ( MlyValue.var_ref var_ref1, var_ref1left, _)) :: rest671)) => let val  result = MlyValue.assign_stat (fn _ => let val  (var_ref as var_ref1) = var_ref1 ()
 val  (expr as expr1) = expr1 ()
 in ((*#line 450.2 "dve.grm"*)Stat.ASSIGN (ASSIGNleft, var_ref, expr)(*#line 1044.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 39, ( result, var_ref1left, expr1right), rest671)
end
|  ( 51, ( rest671)) => let val  result = MlyValue.trans_sync (fn _ => ((*#line 454.2 "dve.grm"*)NONE(*#line 1051.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 31, ( result, defaultPos, defaultPos), rest671)
end
|  ( 52, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.sync_data sync_data1, _, _)) :: ( _, ( MlyValue.sync_type sync_type1, _, _)) :: ( _, ( MlyValue.IDENT IDENT1, _, _)) :: ( _, ( MlyValue.sync_mode sync_mode1, (sync_modeleft as sync_mode1left), _)) :: rest671)) => let val  result = MlyValue.trans_sync (fn _ => let val  (sync_mode as sync_mode1) = sync_mode1 ()
 val  (IDENT as IDENT1) = IDENT1 ()
 val  (sync_type as sync_type1) = sync_type1 ()
 val  (sync_data as sync_data1) = sync_data1 ()
 in ((*#line 457.2 "dve.grm"*)SOME { pos  = sync_modeleft,
	mode = sync_mode,
	chan = IDENT,
	typ  = sync_type,
	data = sync_data }(*#line 1055.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 31, ( result, sync_mode1left, SEMICOLON1right), rest671)
end
|  ( 53, ( ( _, ( _, SYNC1left, SYNC1right)) :: rest671)) => let val  result = MlyValue.sync_mode (fn _ => ((*#line 466.2 "dve.grm"*)Sync.SYNC(*#line 1068.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 33, ( result, SYNC1left, SYNC1right), rest671)
end
|  ( 54, ( ( _, ( _, (ASYNCleft as ASYNC1left), ASYNC1right)) :: rest671)) => let val  result = MlyValue.sync_mode (fn _ => ((*#line 469.2 "dve.grm"*)raise Errors.ParseError
	   (ASYNCleft, "unimplemented feature: asynchronous communications")(*#line 1072.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 33, ( result, ASYNC1left, ASYNC1right), rest671)
end
|  ( 55, ( ( _, ( _, QUESTION1left, QUESTION1right)) :: rest671)) => let val  result = MlyValue.sync_type (fn _ => ((*#line 475.2 "dve.grm"*)Sync.RECV(*#line 1077.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 32, ( result, QUESTION1left, QUESTION1right), rest671)
end
|  ( 56, ( ( _, ( _, EXCLAMATION1left, EXCLAMATION1right)) :: rest671)) => let val  result = MlyValue.sync_type (fn _ => ((*#line 478.2 "dve.grm"*)Sync.SEND(*#line 1081.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 32, ( result, EXCLAMATION1left, EXCLAMATION1right), rest671)
end
|  ( 57, ( rest671)) => let val  result = MlyValue.sync_data (fn _ => ((*#line 482.2 "dve.grm"*)NONE(*#line 1085.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 34, ( result, defaultPos, defaultPos), rest671)
end
|  ( 58, ( ( _, ( MlyValue.expr expr1, expr1left, expr1right)) :: rest671)) => let val  result = MlyValue.sync_data (fn _ => let val  (expr as expr1) = expr1 ()
 in ((*#line 485.2 "dve.grm"*)SOME expr(*#line 1089.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 34, ( result, expr1left, expr1right), rest671)
end
|  ( 59, ( ( _, ( _, _, RPAREN1right)) :: ( _, ( MlyValue.expr expr1, _, _)) :: ( _, ( _, LPAREN1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  (expr as expr1) = expr1 ()
 in ((*#line 491.2 "dve.grm"*)expr(*#line 1095.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, LPAREN1left, RPAREN1right), rest671)
end
|  ( 60, ( ( _, ( MlyValue.NUM NUM1, (NUMleft as NUM1left), NUM1right)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  (NUM as NUM1) = NUM1 ()
 in ((*#line 494.2 "dve.grm"*)Expr.INT (NUMleft, NUM)(*#line 1101.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, NUM1left, NUM1right), rest671)
end
|  ( 61, ( ( _, ( _, (TRUEleft as TRUE1left), TRUE1right)) :: rest671)) => let val  result = MlyValue.expr (fn _ => ((*#line 497.2 "dve.grm"*)Expr.BOOL_CONST (TRUEleft, true)(*#line 1107.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 12, ( result, TRUE1left, TRUE1right), rest671)
end
|  ( 62, ( ( _, ( _, (FALSEleft as FALSE1left), FALSE1right)) :: rest671)) => let val  result = MlyValue.expr (fn _ => ((*#line 500.2 "dve.grm"*)Expr.BOOL_CONST (FALSEleft, false)(*#line 1111.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 12, ( result, FALSE1left, FALSE1right), rest671)
end
|  ( 63, ( ( _, ( MlyValue.var_ref var_ref1, (var_refleft as var_ref1left), var_ref1right)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  (var_ref as var_ref1) = var_ref1 ()
 in ((*#line 503.2 "dve.grm"*)Expr.VAR_REF (var_refleft, var_ref)(*#line 1115.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, var_ref1left, var_ref1right), rest671)
end
|  ( 64, ( ( _, ( MlyValue.IDENT IDENT2, _, IDENT2right)) :: ( _, ( _, DOTleft, _)) :: ( _, ( MlyValue.IDENT IDENT1, IDENT1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  IDENT1 = IDENT1 ()
 val  IDENT2 = IDENT2 ()
 in ((*#line 506.2 "dve.grm"*)Expr.PROCESS_STATE (DOTleft, IDENT1, IDENT2)(*#line 1121.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, IDENT1left, IDENT2right), rest671)
end
|  ( 65, ( ( _, ( MlyValue.var_ref var_ref1, _, var_ref1right)) :: ( _, ( _, ARROWleft, _)) :: ( _, ( MlyValue.IDENT IDENT1, IDENT1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 val  (var_ref as var_ref1) = var_ref1 ()
 in ((*#line 509.2 "dve.grm"*)Expr.PROCESS_VAR_REF (ARROWleft, IDENT, var_ref)(*#line 1128.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, IDENT1left, var_ref1right), rest671)
end
|  ( 66, ( ( _, ( MlyValue.expr expr1, _, expr1right)) :: ( _, ( _, (NOTleft as NOT1left), _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 in ((*#line 512.2 "dve.grm"*)Expr.UN_OP (NOTleft, Expr.NOT, expr1)(*#line 1135.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, NOT1left, expr1right), rest671)
end
|  ( 67, ( ( _, ( MlyValue.expr expr1, _, expr1right)) :: ( _, ( _, (MINUSleft as MINUS1left), _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 in ((*#line 515.2 "dve.grm"*)Expr.UN_OP (MINUSleft, Expr.UMINUS, expr1)(*#line 1141.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, MINUS1left, expr1right), rest671)
end
|  ( 68, ( ( _, ( MlyValue.expr expr1, _, expr1right)) :: ( _, ( _, (NEGleft as NEG1left), _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 in ((*#line 518.2 "dve.grm"*)Expr.UN_OP (NEGleft, Expr.NEG, expr1)(*#line 1147.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, NEG1left, expr1right), rest671)
end
|  ( 69, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, PLUSleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 521.2 "dve.grm"*)Expr.BIN_OP (PLUSleft, expr1, Expr.PLUS, expr2)(*#line 1153.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 70, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, MINUSleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 524.2 "dve.grm"*)Expr.BIN_OP (MINUSleft, expr1, Expr.MINUS, expr2)(*#line 1160.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 71, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, DIVleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 527.2 "dve.grm"*)Expr.BIN_OP (DIVleft, expr1, Expr.DIV, expr2)(*#line 1167.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 72, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, TIMESleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 530.2 "dve.grm"*)Expr.BIN_OP (TIMESleft, expr1, Expr.TIMES, expr2)(*#line 1174.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 73, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, MODleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 533.2 "dve.grm"*)Expr.BIN_OP (MODleft, expr1, Expr.MOD, expr2)(*#line 1181.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 74, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, IMPLYleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 536.2 "dve.grm"*)Expr.BIN_OP (IMPLYleft, expr1, Expr.IMPLY, expr2)(*#line 1188.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 75, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, ANDleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 539.2 "dve.grm"*)Expr.BIN_OP (ANDleft, expr1, Expr.AND, expr2)(*#line 1195.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 76, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, ORleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 542.2 "dve.grm"*)Expr.BIN_OP (ORleft, expr1, Expr.OR, expr2)(*#line 1202.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 77, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, EQleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 545.2 "dve.grm"*)Expr.BIN_OP (EQleft, expr1, Expr.EQ, expr2)(*#line 1209.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 78, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, NEQleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 548.2 "dve.grm"*)Expr.BIN_OP (NEQleft, expr1, Expr.NEQ, expr2)(*#line 1216.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 79, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, INFleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 551.2 "dve.grm"*)Expr.BIN_OP (INFleft, expr1, Expr.INF, expr2)(*#line 1223.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 80, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, SUPleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 554.2 "dve.grm"*)Expr.BIN_OP (SUPleft, expr1, Expr.SUP, expr2)(*#line 1230.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 81, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, INF_EQleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 557.2 "dve.grm"*)Expr.BIN_OP (INF_EQleft, expr1, Expr.INF_EQ, expr2)(*#line 1237.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 82, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, SUP_EQleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 560.2 "dve.grm"*)Expr.BIN_OP (SUP_EQleft, expr1, Expr.SUP_EQ, expr2)(*#line 1244.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 83, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, LSHIFTleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 563.2 "dve.grm"*)Expr.BIN_OP (LSHIFTleft, expr1, Expr.LSHIFT, expr2)(*#line 1251.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 84, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, RSHIFTleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 566.2 "dve.grm"*)Expr.BIN_OP (RSHIFTleft, expr1, Expr.RSHIFT, expr2)(*#line 1258.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 85, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, AND_BITleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 569.2 "dve.grm"*)Expr.BIN_OP (AND_BITleft, expr1, Expr.AND_BIT, expr2)(*#line 1265.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 86, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, OR_BITleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 572.2 "dve.grm"*)Expr.BIN_OP (OR_BITleft, expr1, Expr.OR_BIT, expr2)(*#line 1272.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 87, ( ( _, ( MlyValue.expr expr2, _, expr2right)) :: ( _, ( _, XORleft, _)) :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr (fn _ => let val  expr1 = expr1 ()
 val  expr2 = expr2 ()
 in ((*#line 575.2 "dve.grm"*)Expr.BIN_OP (XORleft, expr1, Expr.XOR, expr2)(*#line 1279.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 12, ( result, expr1left, expr2right), rest671)
end
|  ( 88, ( ( _, ( MlyValue.IDENT IDENT1, IDENT1left, IDENT1right)) :: rest671)) => let val  result = MlyValue.var_ref (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 in ((*#line 580.2 "dve.grm"*)Expr.SIMPLE_VAR IDENT(*#line 1286.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 14, ( result, IDENT1left, IDENT1right), rest671)
end
|  ( 89, ( ( _, ( _, _, RARRAY1right)) :: ( _, ( MlyValue.expr expr1, _, _)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, IDENT1left, _)) :: rest671)) => let val  result = MlyValue.var_ref (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 val  (expr as expr1) = expr1 ()
 in ((*#line 583.2 "dve.grm"*)Expr.ARRAY_ITEM (IDENT, expr)(*#line 1292.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 14, ( result, IDENT1left, RARRAY1right), rest671)
end
|  ( 90, ( ( _, ( _, BYTE1left, BYTE1right)) :: rest671)) => let val  result = MlyValue.type_ref (fn _ => ((*#line 591.2 "dve.grm"*)Typ.BYTE(*#line 1299.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 41, ( result, BYTE1left, BYTE1right), rest671)
end
|  ( 91, ( ( _, ( _, INT1left, INT1right)) :: rest671)) => let val  result = MlyValue.type_ref (fn _ => ((*#line 594.2 "dve.grm"*)Typ.INT(*#line 1303.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 41, ( result, INT1left, INT1right), rest671)
end
|  ( 92, ( ( _, ( MlyValue.IDENT IDENT1, IDENT1left, IDENT1right)) :: rest671)) => let val  result = MlyValue.ident_list (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 in ((*#line 599.2 "dve.grm"*)[IDENT](*#line 1307.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 18, ( result, IDENT1left, IDENT1right), rest671)
end
|  ( 93, ( ( _, ( MlyValue.ident_list ident_list1, _, ident_list1right)) :: _ :: ( _, ( MlyValue.IDENT IDENT1, IDENT1left, _)) :: rest671)) => let val  result = MlyValue.ident_list (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 val  (ident_list as ident_list1) = ident_list1 ()
 in ((*#line 602.2 "dve.grm"*)IDENT :: ident_list(*#line 1313.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 18, ( result, IDENT1left, ident_list1right), rest671)
end
|  ( 94, ( ( _, ( MlyValue.expr expr1, expr1left, expr1right)) :: rest671)) => let val  result = MlyValue.expr_list (fn _ => let val  (expr as expr1) = expr1 ()
 in ((*#line 607.2 "dve.grm"*)[expr](*#line 1320.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 13, ( result, expr1left, expr1right), rest671)
end
|  ( 95, ( ( _, ( MlyValue.expr_list expr_list1, _, expr_list1right)) :: _ :: ( _, ( MlyValue.expr expr1, expr1left, _)) :: rest671)) => let val  result = MlyValue.expr_list (fn _ => let val  (expr as expr1) = expr1 ()
 val  (expr_list as expr_list1) = expr_list1 ()
 in ((*#line 610.2 "dve.grm"*)expr :: expr_list(*#line 1326.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 13, ( result, expr1left, expr_list1right), rest671)
end
|  ( 96, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.property_def property_def1, _, _)) :: _ :: ( _, ( _, (SYSTEMleft as SYSTEM1left), _)) :: rest671)) => let val  result = MlyValue.system_type (fn _ => let val  property_def1 = property_def1 ()
 in ((*#line 617.2 "dve.grm"*)raise Errors.ParseError (SYSTEMleft,
			  "unimplemented feature: synchronous systems")(*#line 1333.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 40, ( result, SYSTEM1left, SEMICOLON1right), rest671)
end
|  ( 97, ( ( _, ( _, _, SEMICOLON1right)) :: ( _, ( MlyValue.property_def property_def1, _, _)) :: _ :: ( _, ( _, SYSTEM1left, _)) :: rest671)) => let val  result = MlyValue.system_type (fn _ => let val  (property_def as property_def1) = property_def1 ()
 in ((*#line 621.2 "dve.grm"*)System.ASYNCHRONOUS, property_def(*#line 1340.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 40, ( result, SYSTEM1left, SEMICOLON1right), rest671)
end
|  ( 98, ( rest671)) => let val  result = MlyValue.property_def (fn _ => ((*#line 624.2 "dve.grm"*)NONE(*#line 1346.1 "dve.grm.sml"*)
))
 in ( LrTable.NT 25, ( result, defaultPos, defaultPos), rest671)
end
|  ( 99, ( ( _, ( MlyValue.IDENT IDENT1, _, IDENT1right)) :: ( _, ( _, PROPERTY1left, _)) :: rest671)) => let val  result = MlyValue.property_def (fn _ => let val  (IDENT as IDENT1) = IDENT1 ()
 in ((*#line 627.2 "dve.grm"*)SOME IDENT(*#line 1350.1 "dve.grm.sml"*)
)
end)
 in ( LrTable.NT 25, ( result, PROPERTY1left, IDENT1right), rest671)
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
fun IDENT (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 0,(ParserData.MlyValue.IDENT (fn () => i),p1,p2))
fun NUM (i,p1,p2) = Token.TOKEN (ParserData.LrTable.T 1,(ParserData.MlyValue.NUM (fn () => i),p1,p2))
fun ACCEPT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 2,(ParserData.MlyValue.VOID,p1,p2))
fun AND (p1,p2) = Token.TOKEN (ParserData.LrTable.T 3,(ParserData.MlyValue.VOID,p1,p2))
fun ASSERT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 4,(ParserData.MlyValue.VOID,p1,p2))
fun ASYNC (p1,p2) = Token.TOKEN (ParserData.LrTable.T 5,(ParserData.MlyValue.VOID,p1,p2))
fun BYTE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 6,(ParserData.MlyValue.VOID,p1,p2))
fun CHANNEL (p1,p2) = Token.TOKEN (ParserData.LrTable.T 7,(ParserData.MlyValue.VOID,p1,p2))
fun COMMIT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 8,(ParserData.MlyValue.VOID,p1,p2))
fun CONST (p1,p2) = Token.TOKEN (ParserData.LrTable.T 9,(ParserData.MlyValue.VOID,p1,p2))
fun EFFECT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 10,(ParserData.MlyValue.VOID,p1,p2))
fun FALSE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 11,(ParserData.MlyValue.VOID,p1,p2))
fun GUARD (p1,p2) = Token.TOKEN (ParserData.LrTable.T 12,(ParserData.MlyValue.VOID,p1,p2))
fun IMPLY (p1,p2) = Token.TOKEN (ParserData.LrTable.T 13,(ParserData.MlyValue.VOID,p1,p2))
fun INIT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 14,(ParserData.MlyValue.VOID,p1,p2))
fun INT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 15,(ParserData.MlyValue.VOID,p1,p2))
fun OR (p1,p2) = Token.TOKEN (ParserData.LrTable.T 16,(ParserData.MlyValue.VOID,p1,p2))
fun NOT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 17,(ParserData.MlyValue.VOID,p1,p2))
fun PROCESS (p1,p2) = Token.TOKEN (ParserData.LrTable.T 18,(ParserData.MlyValue.VOID,p1,p2))
fun PROPERTY (p1,p2) = Token.TOKEN (ParserData.LrTable.T 19,(ParserData.MlyValue.VOID,p1,p2))
fun STATE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 20,(ParserData.MlyValue.VOID,p1,p2))
fun SYNC (p1,p2) = Token.TOKEN (ParserData.LrTable.T 21,(ParserData.MlyValue.VOID,p1,p2))
fun SYSTEM (p1,p2) = Token.TOKEN (ParserData.LrTable.T 22,(ParserData.MlyValue.VOID,p1,p2))
fun TRANS (p1,p2) = Token.TOKEN (ParserData.LrTable.T 23,(ParserData.MlyValue.VOID,p1,p2))
fun TRUE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 24,(ParserData.MlyValue.VOID,p1,p2))
fun USE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 25,(ParserData.MlyValue.VOID,p1,p2))
fun MINUS (p1,p2) = Token.TOKEN (ParserData.LrTable.T 26,(ParserData.MlyValue.VOID,p1,p2))
fun PLUS (p1,p2) = Token.TOKEN (ParserData.LrTable.T 27,(ParserData.MlyValue.VOID,p1,p2))
fun DIV (p1,p2) = Token.TOKEN (ParserData.LrTable.T 28,(ParserData.MlyValue.VOID,p1,p2))
fun TIMES (p1,p2) = Token.TOKEN (ParserData.LrTable.T 29,(ParserData.MlyValue.VOID,p1,p2))
fun MOD (p1,p2) = Token.TOKEN (ParserData.LrTable.T 30,(ParserData.MlyValue.VOID,p1,p2))
fun EQ (p1,p2) = Token.TOKEN (ParserData.LrTable.T 31,(ParserData.MlyValue.VOID,p1,p2))
fun NEQ (p1,p2) = Token.TOKEN (ParserData.LrTable.T 32,(ParserData.MlyValue.VOID,p1,p2))
fun INF (p1,p2) = Token.TOKEN (ParserData.LrTable.T 33,(ParserData.MlyValue.VOID,p1,p2))
fun SUP (p1,p2) = Token.TOKEN (ParserData.LrTable.T 34,(ParserData.MlyValue.VOID,p1,p2))
fun INF_EQ (p1,p2) = Token.TOKEN (ParserData.LrTable.T 35,(ParserData.MlyValue.VOID,p1,p2))
fun SUP_EQ (p1,p2) = Token.TOKEN (ParserData.LrTable.T 36,(ParserData.MlyValue.VOID,p1,p2))
fun NEG (p1,p2) = Token.TOKEN (ParserData.LrTable.T 37,(ParserData.MlyValue.VOID,p1,p2))
fun LSHIFT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 38,(ParserData.MlyValue.VOID,p1,p2))
fun RSHIFT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 39,(ParserData.MlyValue.VOID,p1,p2))
fun AND_BIT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 40,(ParserData.MlyValue.VOID,p1,p2))
fun OR_BIT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 41,(ParserData.MlyValue.VOID,p1,p2))
fun XOR (p1,p2) = Token.TOKEN (ParserData.LrTable.T 42,(ParserData.MlyValue.VOID,p1,p2))
fun ASSIGN (p1,p2) = Token.TOKEN (ParserData.LrTable.T 43,(ParserData.MlyValue.VOID,p1,p2))
fun LPAREN (p1,p2) = Token.TOKEN (ParserData.LrTable.T 44,(ParserData.MlyValue.VOID,p1,p2))
fun RPAREN (p1,p2) = Token.TOKEN (ParserData.LrTable.T 45,(ParserData.MlyValue.VOID,p1,p2))
fun LBRACE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 46,(ParserData.MlyValue.VOID,p1,p2))
fun RBRACE (p1,p2) = Token.TOKEN (ParserData.LrTable.T 47,(ParserData.MlyValue.VOID,p1,p2))
fun LARRAY (p1,p2) = Token.TOKEN (ParserData.LrTable.T 48,(ParserData.MlyValue.VOID,p1,p2))
fun RARRAY (p1,p2) = Token.TOKEN (ParserData.LrTable.T 49,(ParserData.MlyValue.VOID,p1,p2))
fun ARROW (p1,p2) = Token.TOKEN (ParserData.LrTable.T 50,(ParserData.MlyValue.VOID,p1,p2))
fun DOT (p1,p2) = Token.TOKEN (ParserData.LrTable.T 51,(ParserData.MlyValue.VOID,p1,p2))
fun COLON (p1,p2) = Token.TOKEN (ParserData.LrTable.T 52,(ParserData.MlyValue.VOID,p1,p2))
fun SEMICOLON (p1,p2) = Token.TOKEN (ParserData.LrTable.T 53,(ParserData.MlyValue.VOID,p1,p2))
fun COMMA (p1,p2) = Token.TOKEN (ParserData.LrTable.T 54,(ParserData.MlyValue.VOID,p1,p2))
fun EXCLAMATION (p1,p2) = Token.TOKEN (ParserData.LrTable.T 55,(ParserData.MlyValue.VOID,p1,p2))
fun QUESTION (p1,p2) = Token.TOKEN (ParserData.LrTable.T 56,(ParserData.MlyValue.VOID,p1,p2))
fun EOF (p1,p2) = Token.TOKEN (ParserData.LrTable.T 57,(ParserData.MlyValue.VOID,p1,p2))
end
end
