#!/bin/bash

aflex prop_lexer.l
ayacc prop_parser.y
for i in prop_lexer.a prop_lexer_dfa.a prop_lexer_io.a prop_parser.a
do
    gnatchop -w $i
    rm $i
done
