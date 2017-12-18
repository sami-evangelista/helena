(*
 *  File:
 *     dve-parser.sml
 *
 *  Created:
 *     Nov. 13, 2007
 *
 *  Description:
 *     Parser for dve specifications.
 *)


structure DveParser: sig

    val parse: string * TextIO.outstream option -> System.system option

end = struct

structure DveLrVals = DveLrValsFun(
structure Token = LrParser.Token)

structure Lex = DveLexFun(
structure Tokens = DveLrVals.Tokens)

structure Parser = Join(
structure ParserData = DveLrVals.ParserData
structure Lex        = Lex
structure LrParser   = LrParser)

exception SyntaxError of int
			 
fun invoke lexstream = let
    fun print_error (s,i:int,_) = raise SyntaxError i
in
    Parser.parse(0, lexstream, print_error, ())
end

fun parse (fileName, errStream) = let
    val _ = Errors.initErrors ()
    val _ = Lex.UserDeclarations.initLexer ()
    val f = TextIO.openIn fileName
    fun read n = if TextIO.endOfStream f then "" else TextIO.inputN (f, n)
    val lexer = Parser.makeLexer read		 
    val (result, lexer) = invoke lexer
    val (nextToken, lexer) = Parser.Stream.get lexer
    val _ = DveSemAnalyzer.checkSystem result
    val _ = Errors.raiseSemErrorsIfAny ()
    val _ = TextIO.closeIn f
in SOME result end
handle SyntaxError lineNo => (
    Errors.outputErrorMsg
	(errStream, fileName, SOME lineNo, "syntax error")
  ; NONE)
     | Errors.LexError (lineNo, msg) => (
         Errors.outputErrorMsg (errStream, fileName, SOME lineNo, msg)
       ; NONE)
     | Errors.ParseError (lineNo, msg) => (
         Errors.outputErrorMsg (errStream, fileName, SOME lineNo, msg)
       ; NONE)
     | Errors.SemError l =>
       let
	   fun printError (pos, msg) =
	     Errors.outputErrorMsg (errStream, fileName, SOME pos, msg)
       in
	   List.app printError l
         ; NONE
       end
     | IO.Io _ => (
         Errors.outputErrorMsg
	     (errStream, fileName, NONE, "could not open file")
       ; NONE)
	              

fun parse' fileName = parse (fileName, SOME TextIO.stdOut)	       
	       
fun parseTests dir = let
    val stream = OS.FileSys.openDir dir
    val file = ref (SOME "")
in
    while (file := OS.FileSys.readDir stream; !file <> NONE) do
	case !file
	 of NONE => ()
	  | SOME f => let val full = OS.Path.concat (dir, f)
		      in
			  TextIO.print ("(*" ^ full ^ "*)\n")
                        ; parse (full, SOME TextIO.stdOut)
                        ; ()
		      end
end

end
