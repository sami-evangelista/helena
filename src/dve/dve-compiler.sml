(*
 *  File:
 *     dve-compiler.sml
 *)


structure
DveCompiler:
sig
    
    val compile:
        string * string * bool * TextIO.outstream option
        -> int

end = struct

open DveCompilerUtils

fun compile (inFile, path, checks, errStream) = let
    fun out file str = TextIO.output (file, str)
    fun createFile fileName includes = let
	val file = TextIO.openOut (OS.Path.concat (path, fileName))
	val out = out file
	val dateStr = Date.toString (Date.fromTimeUniv (Time.now ()))
    in
	out ("/*\n");
	out (" * File:            " ^ fileName ^ "\n");
	out (" * Generation date: " ^ dateStr ^ "\n");
	out (" *\n");
	out (" * Run-time checks: " ^ (Bool.toString checks) ^ "\n");
	out (" */\n\n");
	List.app (fn f => out ("#include \"" ^ f ^ "\"\n")) includes;
	file
    end
    fun compileBuchi sys = let
	val cFile = createFile "buchi.c" [ "buchi.h" ]
    in
	DveBuchiCompiler.gen (sys, checks, cFile)
    end
    fun compile sys = let
	val hFile = createFile "model.h" [ "includes.h",
					   "common.h",
					   "heap.h",
					   "config.h" ]
	val cFile = createFile "model.c" [ "model.h" ]
	val sys = DveSimplifier.simplify sys
	fun printComment comment = let
	    fun print file = (
		out file "\n\n\n";
		out file ("/* " ^ comment ^ " */\n"))
	in
	    print hFile;
	    print cFile
	end
	val head = [
	    "#ifndef LIB_MODEL",
	    "#define LIB_MODEL",
	    "" ]
    in
	out hFile (concatLines head);
	printComment ("type definitions");
	DveDefinitionsCompiler.gen (sys, hFile, cFile);
	printComment ("configuration");
	DveConfigCompiler.gen (sys, hFile, cFile);
	printComment ("enabling test");
	DveEnablingTestCompiler.gen (sys, checks, hFile, cFile);
	printComment ("event execution");
 	DveEventExecutionCompiler.gen (sys, checks, hFile, cFile);
	printComment ("initial state");
 	DveInitialStateCompiler.gen (sys, checks, hFile, cFile);
	printComment ("hash functions");
 	DveHashFunctionCompiler.gen (sys, hFile, cFile);
	printComment ("serialisation/unserialisation");
 	DveSerializerCompiler.gen (sys, hFile, cFile);
	printComment ("xml serialisation/unserialisation");
 	DveXmlCompiler.gen (sys, hFile, cFile);
	out hFile "#endif\n";
	TextIO.closeOut (hFile);
	TextIO.closeOut (cFile)
    end
in
    let
        val f = TextIO.openOut (OS.Path.concat (path, "SRC_FILES"))
    in
	TextIO.output (f, "model\n");
	TextIO.closeOut (f)
    end;
    case DveParser.parse (inFile, errStream)
     of NONE => 1
      | SOME sys =>
        (compile sys;
         case System.getProp sys
          of NONE => ()
          |  SOME prop => compileBuchi sys;
         0)
        handle Errors.CompilerError (lineNo, msg) =>
	       (Errors.outputErrorMsg (errStream,
                                       inFile, SOME lineNo, msg);
                1)
end

end
