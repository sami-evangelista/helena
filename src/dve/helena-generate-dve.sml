(*
 *  File:
 *     dve-compiler-main.sml
 *)


structure
DveCompilerMain:
sig

    val go: unit -> unit

end = struct

fun usage err = (
    case err
     of NONE => ()
     |  SOME err => print (err ^ "\n")
  ; print "usage: helena-generate-dve [options] my-model.dve out-dir\n"
  ; OS.Process.exit OS.Process.failure)

fun go () = let
    val args = CommandLine.arguments ()
in
    if List.length args < 2
    then usage NONE
    else let val inFile = List.nth (args, List.length args - 2)
	     val path   = List.nth (args, List.length args - 1)
             val opts   = List.take (args, List.length args - 2)
         in
             DveCompilerOptions.setOpts opts
	   ; if 0 = (DveCompiler.compile
                         (inFile, path, false, SOME TextIO.stdOut))
	     then OS.Process.exit OS.Process.success
	     else OS.Process.exit OS.Process.failure
         end
end

end

val _ = DveCompilerMain.go ()
