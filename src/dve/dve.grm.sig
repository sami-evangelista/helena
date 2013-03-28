signature Dve_TOKENS =
sig
type ('a,'b) token
type svalue
val EOF:  'a * 'a -> (svalue,'a) token
val QUESTION:  'a * 'a -> (svalue,'a) token
val EXCLAMATION:  'a * 'a -> (svalue,'a) token
val COMMA:  'a * 'a -> (svalue,'a) token
val SEMICOLON:  'a * 'a -> (svalue,'a) token
val COLON:  'a * 'a -> (svalue,'a) token
val DOT:  'a * 'a -> (svalue,'a) token
val ARROW:  'a * 'a -> (svalue,'a) token
val RARRAY:  'a * 'a -> (svalue,'a) token
val LARRAY:  'a * 'a -> (svalue,'a) token
val RBRACE:  'a * 'a -> (svalue,'a) token
val LBRACE:  'a * 'a -> (svalue,'a) token
val RPAREN:  'a * 'a -> (svalue,'a) token
val LPAREN:  'a * 'a -> (svalue,'a) token
val ASSIGN:  'a * 'a -> (svalue,'a) token
val XOR:  'a * 'a -> (svalue,'a) token
val OR_BIT:  'a * 'a -> (svalue,'a) token
val AND_BIT:  'a * 'a -> (svalue,'a) token
val RSHIFT:  'a * 'a -> (svalue,'a) token
val LSHIFT:  'a * 'a -> (svalue,'a) token
val NEG:  'a * 'a -> (svalue,'a) token
val SUP_EQ:  'a * 'a -> (svalue,'a) token
val INF_EQ:  'a * 'a -> (svalue,'a) token
val SUP:  'a * 'a -> (svalue,'a) token
val INF:  'a * 'a -> (svalue,'a) token
val NEQ:  'a * 'a -> (svalue,'a) token
val EQ:  'a * 'a -> (svalue,'a) token
val MOD:  'a * 'a -> (svalue,'a) token
val TIMES:  'a * 'a -> (svalue,'a) token
val DIV:  'a * 'a -> (svalue,'a) token
val PLUS:  'a * 'a -> (svalue,'a) token
val MINUS:  'a * 'a -> (svalue,'a) token
val USE:  'a * 'a -> (svalue,'a) token
val TRUE:  'a * 'a -> (svalue,'a) token
val TRANS:  'a * 'a -> (svalue,'a) token
val SYSTEM:  'a * 'a -> (svalue,'a) token
val SYNC:  'a * 'a -> (svalue,'a) token
val STATE:  'a * 'a -> (svalue,'a) token
val PROGRESS:  'a * 'a -> (svalue,'a) token
val PROCESS:  'a * 'a -> (svalue,'a) token
val NOT:  'a * 'a -> (svalue,'a) token
val OR:  'a * 'a -> (svalue,'a) token
val INT:  'a * 'a -> (svalue,'a) token
val INIT:  'a * 'a -> (svalue,'a) token
val IMPLY:  'a * 'a -> (svalue,'a) token
val GUARD:  'a * 'a -> (svalue,'a) token
val FALSE:  'a * 'a -> (svalue,'a) token
val EFFECT:  'a * 'a -> (svalue,'a) token
val CONST:  'a * 'a -> (svalue,'a) token
val COMMIT:  'a * 'a -> (svalue,'a) token
val CHANNEL:  'a * 'a -> (svalue,'a) token
val BYTE:  'a * 'a -> (svalue,'a) token
val ASYNC:  'a * 'a -> (svalue,'a) token
val ASSERT:  'a * 'a -> (svalue,'a) token
val AND:  'a * 'a -> (svalue,'a) token
val ACCEPT:  'a * 'a -> (svalue,'a) token
val NUM: (LargeInt.int) *  'a * 'a -> (svalue,'a) token
val IDENT: (string) *  'a * 'a -> (svalue,'a) token
end
signature Dve_LRVALS=
sig
structure Tokens : Dve_TOKENS
structure ParserData:PARSER_DATA
sharing type ParserData.Token.token = Tokens.token
sharing type ParserData.svalue = Tokens.svalue
end
