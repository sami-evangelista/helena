# Helena

Helena is a High Level Nets Analyzer under the GPL license (see file
LICENSE).  It can be used to model check high level Petri nets.

Download the latest version of the tool at the following url:
   http://www.lipn.univ-paris13.fr/~evangelista/helena/

## Prerequisites

To compile Helena you will need:

* GCC
* [http://libre.adacore.com] The GNAT ada compiler.
* [http://mlton.org] The mlton compiler.  It is required if you want
to analyse DVE models (option --with-dve).

## Compilation

To compile helena, go to directory src and execute script compile-helena.
The script can be passed with the following options:
* option *--with-ltl* => This is required if you want to analyse LTL
  properties.
* option *--with-dve* => This is required if you want to analyse DVE
  models (beta version).

Once the compilation is finished make sure that you PATH variable
points to the bin directory.  You may change the value of some
variables in script bin/helena:
* gcc - path of the gcc compiler used by helena to translate a model in C code
* helenaDir - path of the directory in which helena will store specific files
  for a model
  
## Acknowledgements

LTL properties are translated to Buchi automata using the LTL2BA tool by Oddoux
and Gastin.  See http://www.lsv.ens-cachan.fr/~gastin/ltl2ba for more
information on this tool.
