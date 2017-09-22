/**
 * @file graph.h
 * @brief Implementation of graph routines to generate a graph report in a CPN
 *        Tools style.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_GRAPH
#define LIB_GRAPH

#include "heap.h"

#define GT_NODE 1
#define GT_EDGE 2

typedef uint8_t edge_num_t;
typedef uint32_t node_t;

void graph_make_report
(char * in_file,
 char * out_file,
 char * dot_file);

#endif
