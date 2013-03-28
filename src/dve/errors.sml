(*
 *  File:
 *     errors.sml
 *
 *  Created:
 *     Nov. 13, 2007
 *
 *  Description:
 *     Error management.
 *)


structure Errors = struct

exception ParseError of Pos.pos * string

exception LexError of Pos.pos * string

exception SemError of (Pos.pos * string) list

exception CompilerError of Pos.pos * string

exception InternalError


fun sortErrors l = ListMergeSort.sort (fn ((p1, _), (p2, _)) => p1 > p2) l
									
val errors: ((Pos.pos * string) list) ref = ref []

fun initErrors () = errors := []
						
fun addError e = errors := e :: !errors

fun raiseSemErrorsIfAny () =
    if !errors <> []
    then raise SemError (sortErrors (!errors))
    else ()

fun outputErrorMsg (output, fileName, lineNo, msg) =
    case output
     of NONE   => ()
      | SOME s => let val line = fileName ^
				 (case lineNo
				   of NONE   => ""
				    | SOME i => ":" ^ (Int.toString i)) ^
				 ": " ^ msg ^ "\n"
		  in
		      TextIO.output (s, line)
		  end
		 
end
