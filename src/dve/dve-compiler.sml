(*
 *  File:
 *     dve-compiler.sml
 *)


structure DveCompiler: sig

val compile:
    string * string * bool * TextIO.outstream option
    -> int

val compileDir:
    string * string * bool * TextIO.outstream option
    -> unit

end = struct

open DveCompilerUtils

fun compile (inFile, path, checks, errStream) = let
    fun compile sys = let
	val exported: string list ref = ref []
	val files: string list ref = ref []
	val dateStr = Date.toString (Date.fromTimeUniv (Time.now ()))
	fun out file str = TextIO.output (file, str)
	fun createFile fileName includes = let
	    val file = TextIO.openOut (OS.Path.concat (path, fileName))
	    val out = out file
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
	val hFile = createFile "model.h" [ "includes.h",
					   "common.h",
					   "heap.h" ]
	val cFile = createFile "model.c" [ "model.h" ]
	val sys = DveSimplifier.simplify sys
	fun printComment comment = let
	    fun print file = (
		TextIO.output (file, "\n\n\n");
		TextIO.output (file, "/*****\n");
		TextIO.output (file, " *\n");
		TextIO.output (file, " *  " ^ comment ^ "\n");
		TextIO.output (file, " *\n");
		TextIO.output (file, " *****/\n"))
	in
	    print hFile;
	    print cFile
	end
	val head = [
	    "#ifndef LIB_MODEL",
	    "#define LIB_MODEL",
	    "" ]
    in
	TextIO.output (hFile, concatLines head);
	printComment ("configuration");
	DveConfigCompiler.gen (sys, hFile, cFile);
	printComment ("type definitions");
	DveDefinitionsCompiler.gen (sys, hFile, cFile);
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
	printComment ("xml serialisation");
 	DveXmlCompiler.gen (sys, hFile, cFile);
	TextIO.output (
	hFile,
	concatLines [ "#endif",
		      "" ]);
	TextIO.closeOut (hFile);
	TextIO.closeOut (cFile)
	
    (*
     createFile "order.sml"
		[ "DveStateOrder",
		  "DveEventOrder" ]
		[ DveOrderCompiler.genState,
		  DveOrderCompiler.genEvent ] sys;
     createFile "hash-function.sml"
		[ "DveHashFunction",
		  "DveComponentsHashFunction",
		  "DveLargeComponentsHashFunction" ]
		[ DveHashFunctionCompiler.gen,
		  DveHashFunctionCompiler.genHashComponents,
		  DveHashFunctionCompiler.genHashLargeComponents ] sys;
     createFile "components.sml"
		[ "DveComponents",
		  "DveLargeComponents" ]
		[ DveComponentsCompiler.gen ] sys;
     case System.getProg sys
      of NONE => ()
       | SOME _ => createFile "progress.sml"
			      [ "DveProgress" ]
			      [ DveProgressCompiler.gen ] (sys, checks);
     createCM "all-no-ind.cm";
     createFile "independence-relation.sml"
		[ "DveIndependenceRelation" ]
		[ DveIndependenceRelationCompiler.gen ] sys;
     *)
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
      | SOME sys => (compile sys; 0)
        handle Errors.CompilerError (lineNo, msg) =>
	       (Errors.outputErrorMsg (errStream, inFile, SOME lineNo, msg);
		1)
end

fun compileDir (inDir, outDir, checks, errStream) = let
    val stream = OS.FileSys.openDir inDir
    fun loop NONE = ()
      | loop (SOME f) = let
            val full   = OS.Path.concat (inDir, f)
            val split  = OS.Path.splitBaseExt (f)
            val model  = #base split
            val ext    = #ext split
            val outDir = OS.Path.concat (outDir, model)
        in
            if not (isSome ext) orelse valOf ext <> "dve"
	    then ()
            else (TextIO.print ("(*  model " ^ model ^ "  *)\n");
                  (Posix.FileSys.mkdir (outDir, Posix.FileSys.S.irwxu)
                   handle SysErr => ());
                  compile (full, outDir, checks, errStream);
		  ())
                 handle Errors.CompilerError (lineNo, msg) =>
			Errors.outputErrorMsg
                            (errStream, full, SOME lineNo, msg);
	    loop (OS.FileSys.readDir stream)
        end
in
    loop (OS.FileSys.readDir stream)
end

end
