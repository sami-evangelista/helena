(*
 *  File:
 *     dve-compiler-main.sml
 *)


structure
DveCompilerMain:
sig

    val go: unit -> unit

end = struct

fun go () = let
    val args = CommandLine.arguments ()
in
    if List.length args <> 2
    then (print "usage: helena-compile-dve my-model.dve out-dir\n";
	  OS.Process.exit OS.Process.success)
    else let val inFile = List.nth (args, 0)
	     val path   = List.nth (args, 1)
	 in
	     if 0 = (DveCompiler.compile
			 (inFile, path, false, SOME TextIO.stdOut))
	     then OS.Process.exit OS.Process.success
	     else OS.Process.exit OS.Process.failure
	 end
end

end

val _ = DveCompilerMain.go ()
