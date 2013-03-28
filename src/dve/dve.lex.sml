type int = Int.int
functor DveLexFun(structure Tokens: Dve_TOKENS)=
   struct
    structure UserDeclarations =
      struct
exception NotAKeyword

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
  | "progress" => Tokens.PROGRESS
  | "state"    => Tokens.STATE
  | "sync"     => Tokens.SYNC
  | "system"   => Tokens.SYSTEM
  | "trans"    => Tokens.TRANS
  | "true"     => Tokens.TRUE
  | "use"      => Tokens.USE
  | _          => raise NotAKeyword


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
fun look ((j,x)::r, i) = if i = j then x else look(r, i) 
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

type int = Int.int
fun makeLexer (yyinput: int -> string) =
let	val yygone0:int= ~1
	val yyb = ref "\n" 		(* buffer *)
	val yybl: int ref = ref 1		(*buffer length *)
	val yybufpos: int ref = ref 1		(* location of next character to use *)
	val yygone: int ref = ref yygone0	(* position in file of beginning of buffer *)
	val yydone = ref false		(* eof found yet? *)
	val yybegin: int ref = ref 1		(*Current 'start state' for lexer *)

	val YYBEGIN = fn (Internal.StartStates.STARTSTATE x) =>
		 yybegin := x

fun lex () : Internal.result =
let fun continue() = lex() in
  let fun scan (s,AcceptingLeaves : Internal.yyfinstate list list,l,i0: int) =
	let fun action (i: int,nil) = raise LexError
	| action (i,nil::l) = action (i-1,l)
	| action (i,(node::acts)::l) =
		case node of
		    Internal.N yyk => 
			(let fun yymktext() = String.substring(!yyb,i0,i-i0)
			     val yypos: int = i0+ !yygone
			open UserDeclarations Internal.StartStates
 in (yybufpos := i; case yyk of 

			(* Application actions *)

  1 => (line := !line + 1; inSlc := false; lex())
| 10 => let val yytext=yymktext() in if inComment() then lex() else 
	     case LargeInt.fromString yytext of
  	     NONE     => raise Errors.LexError (!line, "int value too large")
	     | SOME i => Tokens.NUM (i, !line, !line) end
| 12 => (if inComment() then lex() else Tokens.ASSIGN     (!line, !line))
| 14 => (if inComment() then lex() else Tokens.LPAREN     (!line, !line))
| 16 => (if inComment() then lex() else Tokens.RPAREN     (!line, !line))
| 18 => (if inComment() then lex() else Tokens.LBRACE     (!line, !line))
| 20 => (if inComment() then lex() else Tokens.RBRACE     (!line, !line))
| 22 => (if inComment() then lex() else Tokens.LARRAY     (!line, !line))
| 24 => (if inComment() then lex() else Tokens.RARRAY     (!line, !line))
| 27 => (if inComment() then lex() else Tokens.ARROW      (!line, !line))
| 29 => (if inComment() then lex() else Tokens.DOT        (!line, !line))
| 31 => (if inComment() then lex() else Tokens.COLON      (!line, !line))
| 33 => (if inComment() then lex() else Tokens.SEMICOLON  (!line, !line))
| 35 => (if inComment() then lex() else Tokens.COMMA      (!line, !line))
| 37 => (if inComment() then lex() else Tokens.MINUS      (!line, !line))
| 39 => (if inComment() then lex() else Tokens.PLUS       (!line, !line))
| 4 => (lex())
| 41 => (if inComment() then lex() else Tokens.DIV        (!line, !line))
| 43 => (if inComment() then lex() else Tokens.TIMES      (!line, !line))
| 45 => (if inComment() then lex() else Tokens.MOD        (!line, !line))
| 48 => (if inComment() then lex() else Tokens.EQ         (!line, !line))
| 51 => (if inComment() then lex() else Tokens.NEQ        (!line, !line))
| 53 => (if inComment() then lex() else Tokens.INF        (!line, !line))
| 55 => (if inComment() then lex() else Tokens.SUP        (!line, !line))
| 58 => (if inComment() then lex() else Tokens.INF_EQ     (!line, !line))
| 61 => (if inComment() then lex() else Tokens.SUP_EQ     (!line, !line))
| 63 => (if inComment() then lex() else Tokens.NEG        (!line, !line))
| 66 => (if inComment() then lex() else Tokens.LSHIFT     (!line, !line))
| 69 => (if inComment() then lex() else Tokens.RSHIFT     (!line, !line))
| 7 => let val yytext=yymktext() in if inComment() then lex() else getKeyword yytext (!line, !line)
	     handle NotAKeyword => Tokens.IDENT (yytext, !line, !line) end
| 71 => (if inComment() then lex() else Tokens.QUESTION   (!line, !line))
| 73 => (if inComment() then lex() else Tokens.EXCLAMATION(!line, !line))
| 76 => (if inComment() then lex() else Tokens.AND        (!line, !line))
| 79 => (if inComment() then lex() else Tokens.OR         (!line, !line))
| 81 => (if inComment() then lex() else Tokens.AND_BIT    (!line, !line))
| 83 => (if inComment() then lex() else Tokens.OR_BIT     (!line, !line))
| 85 => (if inComment() then lex() else Tokens.XOR        (!line, !line))
| 88 => ((if not (inComment()) then inMlc := true else ()); lex())
| 91 => ((if inComment() then inMlc := false
	      else raise Errors.LexError (!line, "unmatched close comment"));
	     lex())
| 94 => ((if not (inComment()) then inSlc := true else ()); lex())
| 96 => (if inComment() then lex()
	     else raise Errors.LexError (!line, "invalid character"))
| _ => raise Internal.LexerError

		) end )

	val {fin,trans} = Vector.sub (Internal.tab, s)
	val NewAcceptingLeaves = fin::AcceptingLeaves
	in if l = !yybl then
	     if trans = #trans(Vector.sub(Internal.tab,0))
	       then action(l,NewAcceptingLeaves
) else	    let val newchars= if !yydone then "" else yyinput 1024
	    in if (String.size newchars)=0
		  then (yydone := true;
		        if (l=i0) then UserDeclarations.eof ()
		                  else action(l,NewAcceptingLeaves))
		  else (if i0=l then yyb := newchars
		     else yyb := String.substring(!yyb,i0,l-i0)^newchars;
		     yygone := !yygone+i0;
		     yybl := String.size (!yyb);
		     scan (s,AcceptingLeaves,l-i0,0))
	    end
	  else let val NewChar = Char.ord (CharVector.sub (!yyb,l))
		val NewChar = if NewChar<128 then NewChar else 128
		val NewState = Char.ord (CharVector.sub (trans,NewChar))
		in if NewState=0 then action(l,NewAcceptingLeaves)
		else scan(NewState,NewAcceptingLeaves,l+1,i0)
	end
	end
(*
	val start= if String.substring(!yyb,!yybufpos-1,1)="\n"
then !yybegin+1 else !yybegin
*)
	in scan(!yybegin (* start *),nil,!yybufpos,!yybufpos)
    end
end
  in lex
  end
end
