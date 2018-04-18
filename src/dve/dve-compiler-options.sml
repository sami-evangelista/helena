(*
 *  File:
 *     dve-compiler-options.sml
 *)


structure
DveCompilerOptions:
sig
    
    datatype opt = COMPRESSION_MIN_MAX of int * int

    val getOpt: opt -> opt

    val setOpts: string list -> unit

    val getCompressionMinMax: unit -> int * int
                           
end = struct

datatype opt = COMPRESSION_MIN_MAX of int * int

val opts = ref [
        COMPRESSION_MIN_MAX (8, 16)
    ]

fun getOpt opt = let
    val res = List.find (fn opt' =>
                            case (opt, opt')
                             of (COMPRESSION_MIN_MAX (_, _),
                                 COMPRESSION_MIN_MAX (_, _)) => true)
                        (!opts)
in
    valOf res
end

fun setOpts optsStr = let
    fun handleOpt s =
      if String.size s >= 25
         andalso String.extract (s, 0, SOME 25) = "--compression-comp-sizes="
      then let val range = String.extract (s, 25, NONE)
               val range = String.tokens (fn #"-" => true | _ => false) range
               val range = List.map Int.fromString range
               val range = List.map valOf range
               val low = List.nth (range, 0)
               val high = List.nth (range, 1)
               val opt = COMPRESSION_MIN_MAX (low, high)
           in
               print ("LOW = " ^ (Int.toString low) ^ "\n")
             ; print ("HIGH = " ^ (Int.toString high) ^ "\n")
             ; opts := opt :: (!opts)
           end
           (*handle Errors.InternalError => ()*)
      else ()
in
    List.app handleOpt optsStr
end

fun getCompressionMinMax () =
  case getOpt (COMPRESSION_MIN_MAX (0, 0))
   of COMPRESSION_MIN_MAX (min, max) => (min, max)

end
