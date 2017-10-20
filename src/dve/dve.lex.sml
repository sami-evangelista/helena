(*#line 65.10 "dve.lex"*)functor DveLexFun(structure Tokens: Dve_TOKENS)(*#line 1.1 "dve.lex.sml"*)
=
   struct
    structure UserDeclarations =
      struct
(*#line 1.1 "dve.lex"*)exception NotAKeyword

type pos = int

structure Tokens = Tokens

type pos = int
val line = ref 1

val inSlc = ref false  (*  in a single line comment  *)
val inMlc = ref false  (*  in a multi line comment  *)

fun initLexer () =
(inSlc := false;
 inMlc := false;
 line  := 1)

fun inComment () = (!inSlc) orelse (!inMlc)

type svalue = Tokens.svalue
type ('a,'b) token = ('a,'b) Tokens.token
type lexresult= (svalue,pos) token

val eof = fn () =>
if !inMlc then raise Errors.LexError (!line,
				      "unterminated comment at end of output")
else Tokens.EOF(!line,!line)

val error = fn (e,l : int,_) => ()



fun getKeyword word =
  case word of
    "accept"   => Tokens.ACCEPT
  | "and"      => Tokens.AND
  | "assert"   => Tokens.ASSERT
  | "async"    => Tokens.ASYNC
  | "byte"     => Tokens.BYTE
  | "channel"  => Tokens.CHANNEL
  | "commit"   => Tokens.COMMIT
  | "const"    => Tokens.CONST
  | "effect"   => Tokens.EFFECT
  | "false"    => Tokens.FALSE
  | "guard"    => Tokens.GUARD
  | "imply"    => Tokens.IMPLY
  | "init"     => Tokens.INIT
  | "int"      => Tokens.INT
  | "not"      => Tokens.NOT
  | "or"       => Tokens.OR
  | "process"  => Tokens.PROCESS
  | "property" => Tokens.PROPERTY
  | "state"    => Tokens.STATE
  | "sync"     => Tokens.SYNC
  | "system"   => Tokens.SYSTEM
  | "trans"    => Tokens.TRANS
  | "true"     => Tokens.TRUE
  | "use"      => Tokens.USE
  | _          => raise NotAKeyword


(*#line 67.1 "dve.lex.sml"*)
end (* end of user routines *)
exception LexError (* raised if illegal leaf action tried *)
structure Internal =
	struct

datatype yyfinstate = N of int
type statedata = {fin : yyfinstate list, trans: string}
(* transition & final state table *)
val tab = let
val s = [ 
 (0, 
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
),
 (1, 
"\003\003\003\003\003\003\003\003\003\044\046\003\003\003\003\003\
\\003\003\003\003\003\003\003\003\003\003\003\003\003\003\003\003\
\\044\042\003\003\003\041\039\003\038\037\035\034\033\031\030\027\
\\025\025\025\025\025\025\025\025\025\025\024\023\020\018\015\014\
\\003\009\009\009\009\009\009\009\009\009\009\009\009\009\009\009\
\\009\009\009\009\009\009\009\009\009\009\009\013\003\012\011\003\
\\003\009\009\009\009\009\009\009\009\009\009\009\009\009\009\009\
\\009\009\009\009\009\009\009\009\009\009\009\008\006\005\004\003\
\\003"
),
 (6, 
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\007\000\000\000\
\\000"
),
 (9, 
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\010\010\010\010\010\010\010\010\010\010\000\000\000\000\000\000\
\\000\010\010\010\010\010\010\010\010\010\010\010\010\010\010\010\
\\010\010\010\010\010\010\010\010\010\010\010\000\000\000\000\010\
\\000\010\010\010\010\010\010\010\010\010\010\010\010\010\010\010\
\\010\010\010\010\010\010\010\010\010\010\010\000\000\000\000\000\
\\000"
),
 (15, 
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\017\016\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
),
 (18, 
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\019\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
),
 (20, 
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\022\021\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
),
 (25, 
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\026\026\026\026\026\026\026\026\026\026\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
),
 (27, 
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\029\000\000\000\000\028\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
),
 (31, 
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\032\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
),
 (35, 
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\036\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
),
 (39, 
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\040\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
),
 (42, 
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\043\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
),
 (44, 
"\000\000\000\000\000\000\000\000\000\045\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\045\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
),
(0, "")]
fun f x = x 
val s = map f (rev (tl (rev s))) 
exception LexHackingError 
fun look ((j,x)::r, i: int) = if i = j then x else look(r, i) 
  | look ([], i) = raise LexHackingError
fun g {fin=x, trans=i} = {fin=x, trans=look(s,i)} 
in Vector.fromList(map g 
[{fin = [], trans = 0},
{fin = [], trans = 1},
{fin = [], trans = 1},
{fin = [(N 96)], trans = 0},
{fin = [(N 63),(N 96)], trans = 0},
{fin = [(N 20),(N 96)], trans = 0},
{fin = [(N 83),(N 96)], trans = 6},
{fin = [(N 79)], trans = 0},
{fin = [(N 18),(N 96)], trans = 0},
{fin = [(N 7),(N 96)], trans = 9},
{fin = [(N 7)], trans = 9},
{fin = [(N 85),(N 96)], trans = 0},
{fin = [(N 24),(N 96)], trans = 0},
{fin = [(N 22),(N 96)], trans = 0},
{fin = [(N 71),(N 96)], trans = 0},
{fin = [(N 55),(N 96)], trans = 15},
{fin = [(N 69)], trans = 0},
{fin = [(N 61)], trans = 0},
{fin = [(N 12),(N 96)], trans = 18},
{fin = [(N 48)], trans = 0},
{fin = [(N 53),(N 96)], trans = 20},
{fin = [(N 58)], trans = 0},
{fin = [(N 66)], trans = 0},
{fin = [(N 33),(N 96)], trans = 0},
{fin = [(N 31),(N 96)], trans = 0},
{fin = [(N 10),(N 96)], trans = 25},
{fin = [(N 10)], trans = 25},
{fin = [(N 41),(N 96)], trans = 27},
{fin = [(N 94)], trans = 0},
{fin = [(N 88)], trans = 0},
{fin = [(N 29),(N 96)], trans = 0},
{fin = [(N 37),(N 96)], trans = 31},
{fin = [(N 27)], trans = 0},
{fin = [(N 35),(N 96)], trans = 0},
{fin = [(N 39),(N 96)], trans = 0},
{fin = [(N 43),(N 96)], trans = 35},
{fin = [(N 91)], trans = 0},
{fin = [(N 16),(N 96)], trans = 0},
{fin = [(N 14),(N 96)], trans = 0},
{fin = [(N 81),(N 96)], trans = 39},
{fin = [(N 76)], trans = 0},
{fin = [(N 45),(N 96)], trans = 0},
{fin = [(N 73),(N 96)], trans = 42},
{fin = [(N 51)], trans = 0},
{fin = [(N 4),(N 96)], trans = 44},
{fin = [(N 4)], trans = 44},
{fin = [(N 1)], trans = 0}])
end
structure StartStates =
	struct
	datatype yystartstate = STARTSTATE of int

(* start state definitions *)

val INITIAL = STARTSTATE 1;

end
type result = UserDeclarations.lexresult
	exception LexerError (* raised if illegal leaf action tried *)
end

structure YYPosInt : INTEGER = Int
fun makeLexer yyinput =
let	val yygone0= YYPosInt.fromInt ~1
	val yyb = ref "\n" 		(* buffer *)
	val yybl = ref 1		(*buffer length *)
	val yybufpos = ref 1		(* location of next character to use *)
	val yygone = ref yygone0	(* position in file of beginning of buffer *)
	val yydone = ref false		(* eof found yet? *)
	val yybegin = ref 1		(*Current 'start state' for lexer *)

	val YYBEGIN = fn (Internal.StartStates.STARTSTATE x) =>
		 yybegin := x

fun lex () : Internal.result =
let fun continue() = lex() in
  let fun scan (s,AcceptingLeaves : Internal.yyfinstate list list,l,i0) =
	let fun action (i,nil) = raise LexError
	| action (i,nil::l) = action (i-1,l)
	| action (i,(node::acts)::l) =
		case node of
		    Internal.N yyk => 
			(let fun yymktext() = substring(!yyb,i0,i-i0)
			     val yypos = YYPosInt.+(YYPosInt.fromInt i0, !yygone)
			open UserDeclarations Internal.StartStates
 in (yybufpos := i; case yyk of 

			(* Application actions *)

  1 => ((*#line 76.14 "dve.lex"*)line := !line + 1; inSlc := false; lex()(*#line 329.1 "dve.lex.sml"*)
)
| 10 => let val yytext=yymktext() in (*#line 80.14 "dve.lex"*)if inComment() then lex() else 
	     case LargeInt.fromString yytext of
  	     NONE     => raise Errors.LexError (!line, "int value too large")
	     | SOME i => Tokens.NUM (i, !line, !line)(*#line 334.1 "dve.lex.sml"*)
 end
| 12 => ((*#line 84.14 "dve.lex"*)if inComment() then lex() else Tokens.ASSIGN     (!line, !line)(*#line 336.1 "dve.lex.sml"*)
)
| 14 => ((*#line 85.14 "dve.lex"*)if inComment() then lex() else Tokens.LPAREN     (!line, !line)(*#line 338.1 "dve.lex.sml"*)
)
| 16 => ((*#line 86.14 "dve.lex"*)if inComment() then lex() else Tokens.RPAREN     (!line, !line)(*#line 340.1 "dve.lex.sml"*)
)
| 18 => ((*#line 87.14 "dve.lex"*)if inComment() then lex() else Tokens.LBRACE     (!line, !line)(*#line 342.1 "dve.lex.sml"*)
)
| 20 => ((*#line 88.14 "dve.lex"*)if inComment() then lex() else Tokens.RBRACE     (!line, !line)(*#line 344.1 "dve.lex.sml"*)
)
| 22 => ((*#line 89.14 "dve.lex"*)if inComment() then lex() else Tokens.LARRAY     (!line, !line)(*#line 346.1 "dve.lex.sml"*)
)
| 24 => ((*#line 90.14 "dve.lex"*)if inComment() then lex() else Tokens.RARRAY     (!line, !line)(*#line 348.1 "dve.lex.sml"*)
)
| 27 => ((*#line 91.14 "dve.lex"*)if inComment() then lex() else Tokens.ARROW      (!line, !line)(*#line 350.1 "dve.lex.sml"*)
)
| 29 => ((*#line 92.14 "dve.lex"*)if inComment() then lex() else Tokens.DOT        (!line, !line)(*#line 352.1 "dve.lex.sml"*)
)
| 31 => ((*#line 93.14 "dve.lex"*)if inComment() then lex() else Tokens.COLON      (!line, !line)(*#line 354.1 "dve.lex.sml"*)
)
| 33 => ((*#line 94.14 "dve.lex"*)if inComment() then lex() else Tokens.SEMICOLON  (!line, !line)(*#line 356.1 "dve.lex.sml"*)
)
| 35 => ((*#line 95.14 "dve.lex"*)if inComment() then lex() else Tokens.COMMA      (!line, !line)(*#line 358.1 "dve.lex.sml"*)
)
| 37 => ((*#line 96.14 "dve.lex"*)if inComment() then lex() else Tokens.MINUS      (!line, !line)(*#line 360.1 "dve.lex.sml"*)
)
| 39 => ((*#line 97.14 "dve.lex"*)if inComment() then lex() else Tokens.PLUS       (!line, !line)(*#line 362.1 "dve.lex.sml"*)
)
| 4 => ((*#line 77.14 "dve.lex"*)lex()(*#line 364.1 "dve.lex.sml"*)
)
| 41 => ((*#line 98.14 "dve.lex"*)if inComment() then lex() else Tokens.DIV        (!line, !line)(*#line 366.1 "dve.lex.sml"*)
)
| 43 => ((*#line 99.14 "dve.lex"*)if inComment() then lex() else Tokens.TIMES      (!line, !line)(*#line 368.1 "dve.lex.sml"*)
)
| 45 => ((*#line 100.14 "dve.lex"*)if inComment() then lex() else Tokens.MOD        (!line, !line)(*#line 370.1 "dve.lex.sml"*)
)
| 48 => ((*#line 101.14 "dve.lex"*)if inComment() then lex() else Tokens.EQ         (!line, !line)(*#line 372.1 "dve.lex.sml"*)
)
| 51 => ((*#line 102.14 "dve.lex"*)if inComment() then lex() else Tokens.NEQ        (!line, !line)(*#line 374.1 "dve.lex.sml"*)
)
| 53 => ((*#line 103.14 "dve.lex"*)if inComment() then lex() else Tokens.INF        (!line, !line)(*#line 376.1 "dve.lex.sml"*)
)
| 55 => ((*#line 104.14 "dve.lex"*)if inComment() then lex() else Tokens.SUP        (!line, !line)(*#line 378.1 "dve.lex.sml"*)
)
| 58 => ((*#line 105.14 "dve.lex"*)if inComment() then lex() else Tokens.INF_EQ     (!line, !line)(*#line 380.1 "dve.lex.sml"*)
)
| 61 => ((*#line 106.14 "dve.lex"*)if inComment() then lex() else Tokens.SUP_EQ     (!line, !line)(*#line 382.1 "dve.lex.sml"*)
)
| 63 => ((*#line 107.14 "dve.lex"*)if inComment() then lex() else Tokens.NEG        (!line, !line)(*#line 384.1 "dve.lex.sml"*)
)
| 66 => ((*#line 108.14 "dve.lex"*)if inComment() then lex() else Tokens.LSHIFT     (!line, !line)(*#line 386.1 "dve.lex.sml"*)
)
| 69 => ((*#line 109.14 "dve.lex"*)if inComment() then lex() else Tokens.RSHIFT     (!line, !line)(*#line 388.1 "dve.lex.sml"*)
)
| 7 => let val yytext=yymktext() in (*#line 78.14 "dve.lex"*)if inComment() then lex() else getKeyword yytext (!line, !line)
	     handle NotAKeyword => Tokens.IDENT (yytext, !line, !line)(*#line 391.1 "dve.lex.sml"*)
 end
| 71 => ((*#line 110.14 "dve.lex"*)if inComment() then lex() else Tokens.QUESTION   (!line, !line)(*#line 393.1 "dve.lex.sml"*)
)
| 73 => ((*#line 111.14 "dve.lex"*)if inComment() then lex() else Tokens.EXCLAMATION(!line, !line)(*#line 395.1 "dve.lex.sml"*)
)
| 76 => ((*#line 112.14 "dve.lex"*)if inComment() then lex() else Tokens.AND        (!line, !line)(*#line 397.1 "dve.lex.sml"*)
)
| 79 => ((*#line 113.14 "dve.lex"*)if inComment() then lex() else Tokens.OR         (!line, !line)(*#line 399.1 "dve.lex.sml"*)
)
| 81 => ((*#line 114.14 "dve.lex"*)if inComment() then lex() else Tokens.AND_BIT    (!line, !line)(*#line 401.1 "dve.lex.sml"*)
)
| 83 => ((*#line 115.14 "dve.lex"*)if inComment() then lex() else Tokens.OR_BIT     (!line, !line)(*#line 403.1 "dve.lex.sml"*)
)
| 85 => ((*#line 116.14 "dve.lex"*)if inComment() then lex() else Tokens.XOR        (!line, !line)(*#line 405.1 "dve.lex.sml"*)
)
| 88 => ((*#line 117.14 "dve.lex"*)(if not (inComment()) then inMlc := true else ()); lex()(*#line 407.1 "dve.lex.sml"*)
)
| 91 => ((*#line 118.14 "dve.lex"*)(if inComment() then inMlc := false
	      else raise Errors.LexError (!line, "unmatched close comment"));
	     lex()(*#line 411.1 "dve.lex.sml"*)
)
| 94 => ((*#line 121.14 "dve.lex"*)(if not (inComment()) then inSlc := true else ()); lex()(*#line 413.1 "dve.lex.sml"*)
)
| 96 => ((*#line 122.14 "dve.lex"*)if inComment() then lex()
	     else raise Errors.LexError (!line, "invalid character")(*#line 416.1 "dve.lex.sml"*)
)
| _ => raise Internal.LexerError

		) end )

	val {fin,trans} = Vector.sub(Internal.tab, s)
	val NewAcceptingLeaves = fin::AcceptingLeaves
	in if l = !yybl then
	     if trans = #trans(Vector.sub(Internal.tab,0))
	       then action(l,NewAcceptingLeaves
) else	    let val newchars= if !yydone then "" else yyinput 1024
	    in if (size newchars)=0
		  then (yydone := true;
		        if (l=i0) then UserDeclarations.eof ()
		                  else action(l,NewAcceptingLeaves))
		  else (if i0=l then yyb := newchars
		     else yyb := substring(!yyb,i0,l-i0)^newchars;
		     yygone := YYPosInt.+(!yygone, YYPosInt.fromInt i0);
		     yybl := size (!yyb);
		     scan (s,AcceptingLeaves,l-i0,0))
	    end
	  else let val NewChar = Char.ord(CharVector.sub(!yyb,l))
		val NewChar = if NewChar<128 then NewChar else 128
		val NewState = Char.ord(CharVector.sub(trans,NewChar))
		in if NewState=0 then action(l,NewAcceptingLeaves)
		else scan(NewState,NewAcceptingLeaves,l+1,i0)
	end
	end
(*
	val start= if substring(!yyb,!yybufpos-1,1)="\n"
then !yybegin+1 else !yybegin
*)
	in scan(!yybegin (* start *),nil,!yybufpos,!yybufpos)
    end
end
  in lex
  end
end
