(*
 *  File:
 *     utils.sml
 *
 *  Created:
 *     Nov. 13, 2007
 *
 *  Description:
 *     Some utility functions.
 *)


structure Utils = struct

fun toLower str =
    String.implode (List.map Char.toLower (String.explode str))

fun toUpper str =
    String.implode (List.map Char.toUpper (String.explode str))

fun zipPartial pred l = let
    fun zip ([], _) = []
      | zip (a :: al, bl) = let
	    fun map b = if pred (a, b) then SOME (a, b) else NONE
	in
	    (List.mapPartial map bl) @ zip (al, bl)
      end
in
    zip (l, l)
end

fun constructList (item, 0) = []
  | constructList (item, n) = item :: constructList (item, n - 1)

fun fmt {init  : string,
	 sep   : string,
	 final : string,
	 fmt   : 'a -> string option} list = let
    fun fmt' [] = NONE
      | fmt' (item :: list) = let
	  val itemStr = fmt item
	  val listStr = fmt' list
      in
	  case itemStr of
	      NONE     =>
	      listStr
	    | SOME str =>
	      SOME (str ^
		    (case listStr of NONE      => ""
				   | SOME str' => sep ^ str'))
      end
    val fmtList = fmt' list
    val fmtList = case fmtList of NONE => "" | SOME str => str
in
    init ^ fmtList ^ final
end

val mergeStringList = 
    ListMergeSort.uniqueSort
	(fn (v1: string, v2) => if v1 = v2 then EQUAL
				else if v1 > v2 then GREATER
				else LESS)
	
end
