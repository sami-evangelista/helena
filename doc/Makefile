ug :
	pdflatex helena-ug
	makeindex helena-ug.idx
	pdflatex helena-ug

syntax :
	pdflatex helena-syntax

examples :
	pdflatex helena-dbm
	pdflatex helena-load_balancer
	pdflatex helena-hanoi

all : ug syntax examples

clean :
	rm *.log *~ *.aux *.dvi *.toc *.bak *.flc *.out *.idx *.ind *.ilg *.ind

clean-all :
	rm *.log *~ *.aux *.dvi *.toc *.bak *.flc *.out *.idx *.ind *.ilg helena-*.pdf helena-*.ps helena-*.dvi
