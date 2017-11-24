# Helena help

This document describes Helena options.

General usage is:
```
helena [options] my-net.lna
```

## General options

### -h[=opt], --help[=opt]

Prints help and exit.  If an option is provided, a specific help
message for this option is printed.  If opt=FULL a detailed help for
all options is printed.

### -V, --version

Prints the version number and exit.

### -v, --verbose

Be verbose.

### -N=ACTION, --action=ACTION

Indicate the action performed on the model.  ACTION must have one of
the following values:
* EXPLORE - Explore the state space of the model and then prints some
   statistics.  This is the default.
* SIMULATE - Start interactive simulation mode.  You can then navigate
   through the reachability graph of the model. A simple command
   language is provided.  Once the simulation is started, type help to
   see the list of commands.
* BUILD-GRAPH - Build the reachability graph of the model using
   algorithm DELTA-DDD (see option algo) and store it on disk.  This
   graph can then be analyzed using the helena-graph tool.
* CHECK-prop - Check whether or not property prop (which must be a
   property defined in the model file) is verified.

### -g=LEVEL, --progress=LEVEL

LEVEL can take one of these three values:
* no-compile - Helena stops after the generation of source files.
* no-check - Helena launches compilation but does not launches the
  search.
* no-report - Helena launches the search but does not print any
  report.

### -b[={0|1}], --observer[={0|1}]

Activate/deactivate the observer thread that prints some progression
informations during the search.  It is turned on by default.

### -p=FILE, --property-file=FILE

File FILE contains the definition of the property to check (specified
with option --action=CHECK-prop).  By default, if the input file of
the model is model.lna, Helena will look into model.prop.lna for the
property definition.

### -md=DIRECTORY, --model-directory=DIRECTORY

All generated files such as source files are put in directory
DIRECTORY (instead of ~/.helena/models/lna/my-net).

### -wp[={0|1}], --with-papi[={0|1}]

Activate/deactivate the use of the PAPI (Performance Application
Programming Interface, see http://icl.utk.edu/papi/) to print
additional statistics at the end of the search.

## Search and storage options

### -A=ALGO, --algo=ALGO

Sets search algorithm used to explore the state space.  Available
algorithms are:

* DFS - The state space is explored using a depth-first search.  This
   is the default.
* BFS - The state space is explored using a breadth-first search.
* DELTA-DDD - The state space is explored using a parallel
   breadth-first search based on state compression.
* RWALK - A random walk is used.  The principle is to randomly select
   at each state an enabled transition, execute it and reiterate this
   process.  The walk is reinitiated each time a deadlock state is
   met.  If no limit is specified (e.g., option --state-limit) the
   search will last forever.

### -t=N, --hash-size=N

Set to 2^N the size of the hash table which stores the set of
reachable states.  The default value is 22.  

### -W=N, --workers=N

Set to N the number of working threads that will perform the
search.

### -R[={0|1}], --random-succs[={0|1}]

Activate/deactivate randomised successor selection.  This is only
valid if algorithm DFS is used.  This option is useful if the
counter-example produced is too long.  Using randomisation can often
produce a smaller counter-example.

### -cs=N, --candidate-set-size=N

Set the candidate set size of algorithm DELTA-DDD.  100000 is the
default value.  Increasing it may consume more memory but can fasten
the search.

## Reduction techniques

### -H[={0|1}], --hash-compaction[={0|1}]

Activate/deactivate hash compaction.  Its principle is to only store a
hash signature of each visited state.  In case of hash conflict,
Helena will not necessarily explore the whole state space and may
report that no error has been found whereas one could exist.

### -P[={0|1}], --partial-order[={0|1}]}

Activate/deactivate partial-order reduction.  This reduction limits
the exploration of multiple paths that are redundant with respect to
the desired property.  This causes some states to be never explored
during the search.  The reductions done depend on the property
verified.  If there is no property checked, the reduction done only
preserves the existence of deadlock states.

## Limit options

### -ml=N, --memory-limit=N

The memory used by Helena is limited to N megabytes.  When this limit
is reached the search stops as soon as possible.

### -tl=N, --time-limit=N

The search time is limited to N seconds.  When this limit is reached
the search stops as soon as possible.

### -sl=N, --state-limit=N

As soon as N states have been processed the search is stopped as soon
as possible.

## Model options

### -d=SYMBOL-NAME, --define=SYMBOL-NAME

Define preprocessor symbol SYMBOL-NAME in the net.

### -a=N, --capacity=N

The default capacity of places is set to N.

### -r[={0|1}], --run-time-checks[={0|1}]

Activate/deactivate run time checks such as: division by 0,
expressions out of range, capacity of places exceeded, ...  If this
option is not activated, and such an error occurs during the analysis,
Helena may either crash, either produce wrong results.

### -L=OBJECT-FILE, --link=OBJECT-FILE

Add file OBJECT-FILE to the files linked by Helena when compiling the
net.  Please consult user guide for further help on this option.

### -m=PARAM=VAL, --parameter=PARAM=VAL

This gives value VAL (an integer) to net parameter PARAM.

## Output options

### -o=FILE, --report-file=FILE

An XML report file is created by Helena once the search terminated.
It contains some informations such as the result of the search, or
some statistics.

### -tr=TYPE, --trace-type=TYPE

Specify the type of trace (i.e., counter-example) displayed.  TYPE
must take on e of these three values:
* FULL - The full trace is displayed.
* EVENTS - Only the sequence of events, the initial and the final
   faulty states are displayed.  Intermediary states are not
   displayed.
* STATE - Only the faulty state reached is displayed.  No information
   on how this state can be reached is therefore available.
