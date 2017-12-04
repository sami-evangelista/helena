#!/bin/bash

aflex helena_lex.l
ayacc helena_yacc.y
for i in \
    helena_lex.a \
    helena_lex_dfa.a \
    helena_lex_io.a \
    helena_yacc.a; do
  gnatchop -w $i
  rm $i
done
exit
for i in *.ad?
  do
  gnatpp -gnat05 -I../../utils -I../../pn $i
  mv $i.pp $i
done
rm -rf GNAT*
