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


%%


%header (functor DveLexFun(structure Tokens: Dve_TOKENS));

a     = [A-Za-z];
id    = [A-Za-z0-9_];
digit = [0-9];
w    = [\ \t];


%%


\n       => (line := !line + 1; inSlc := false; lex());
{w}+     => (lex());
{a}{id}* => (if inComment() then lex() else getKeyword yytext (!line, !line)
	     handle NotAKeyword => Tokens.IDENT (yytext, !line, !line));
{digit}+ => (if inComment() then lex() else 
	     case LargeInt.fromString yytext of
  	     NONE     => raise Errors.LexError (!line, "int value too large")
	     | SOME i => Tokens.NUM (i, !line, !line));
"="      => (if inComment() then lex() else Tokens.ASSIGN     (!line, !line));
"("      => (if inComment() then lex() else Tokens.LPAREN     (!line, !line));
")"      => (if inComment() then lex() else Tokens.RPAREN     (!line, !line));
"{"      => (if inComment() then lex() else Tokens.LBRACE     (!line, !line));
"}"      => (if inComment() then lex() else Tokens.RBRACE     (!line, !line));
"["      => (if inComment() then lex() else Tokens.LARRAY     (!line, !line));
"]"      => (if inComment() then lex() else Tokens.RARRAY     (!line, !line));
"->"     => (if inComment() then lex() else Tokens.ARROW      (!line, !line));
"."      => (if inComment() then lex() else Tokens.DOT        (!line, !line));
":"      => (if inComment() then lex() else Tokens.COLON      (!line, !line));
";"      => (if inComment() then lex() else Tokens.SEMICOLON  (!line, !line));
","      => (if inComment() then lex() else Tokens.COMMA      (!line, !line));
"-"      => (if inComment() then lex() else Tokens.MINUS      (!line, !line));
"+"      => (if inComment() then lex() else Tokens.PLUS       (!line, !line));
"/"      => (if inComment() then lex() else Tokens.DIV        (!line, !line));
"*"      => (if inComment() then lex() else Tokens.TIMES      (!line, !line));
"%"      => (if inComment() then lex() else Tokens.MOD        (!line, !line));
"=="     => (if inComment() then lex() else Tokens.EQ         (!line, !line));
"!="     => (if inComment() then lex() else Tokens.NEQ        (!line, !line));
"<"      => (if inComment() then lex() else Tokens.INF        (!line, !line));
">"      => (if inComment() then lex() else Tokens.SUP        (!line, !line));
"<="     => (if inComment() then lex() else Tokens.INF_EQ     (!line, !line));
">="     => (if inComment() then lex() else Tokens.SUP_EQ     (!line, !line));
"~"      => (if inComment() then lex() else Tokens.NEG        (!line, !line));
"<<"     => (if inComment() then lex() else Tokens.LSHIFT     (!line, !line));
">>"     => (if inComment() then lex() else Tokens.RSHIFT     (!line, !line));
"?"      => (if inComment() then lex() else Tokens.QUESTION   (!line, !line));
"!"      => (if inComment() then lex() else Tokens.EXCLAMATION(!line, !line));
"&&"     => (if inComment() then lex() else Tokens.AND        (!line, !line));
"||"     => (if inComment() then lex() else Tokens.OR         (!line, !line));
"&"      => (if inComment() then lex() else Tokens.AND_BIT    (!line, !line));
"|"      => (if inComment() then lex() else Tokens.OR_BIT     (!line, !line));
"^"      => (if inComment() then lex() else Tokens.XOR        (!line, !line));
"/*"     => ((if not (inComment()) then inMlc := true else ()); lex());
"*/"     => ((if inComment() then inMlc := false
	      else raise Errors.LexError (!line, "unmatched close comment"));
	     lex());
"//"     => ((if not (inComment()) then inSlc := true else ()); lex());
.        => (if inComment() then lex()
	     else raise Errors.LexError (!line, "invalid character"));
