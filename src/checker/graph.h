/**
 * @file graph.h
 * @author Sami Evangelista
 * @date 12 sep 2017
 * @brief Implementation of graph routines to generate a graph report in a CPN
 *        Tools style.
 */

#ifndef LIB_GRAPH
#define LIB_GRAPH

#include "heap.h"

#define GT_NODE 1
#define GT_EDGE 2

typedef uint8_t edge_num_t;
typedef uint32_t node_t;

typedef struct {
  edge_num_t num;
  node_t     dest;
} edge_data_t;

typedef struct {
  uint8_t       no_succs;
  edge_data_t * out;
} node_data_t;

typedef struct {
  unsigned int  no_nodes;
  unsigned int  no_edges;
  node_data_t * data;
  node_t        root;
  heap_t        heap;
} struct_graph_t;

typedef struct_graph_t * graph_t;

void graph_make_report
(char * in_file,
 char * out_file,
 char * dot_file);

#endif
