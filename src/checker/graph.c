#include "graph.h"
#include "model.h"
#include "config.h"

#if CFG_MODEL_HAS_GRAPH_ROUTINES == 1
#include "model_graph.h"
#else
typedef int model_graph_data_t;
void model_graph_data_init(model_graph_data_t * mdata, uint32_t states) {}
void model_graph_data_free(model_graph_data_t * mdata) {}
void model_graph_data_output(model_graph_data_t mdata, FILE * out) {}
void model_graph_dfs_start(model_graph_data_t mdata) {}
void model_graph_dfs_stop(model_graph_data_t mdata) {}
void model_graph_dfs_push(model_graph_data_t mdata, edge_num_t num,
                          bool_t new_succ) {}
void model_graph_dfs_pop(model_graph_data_t mdata) {}
void model_graph_scc_dfs_start(model_graph_data_t mdata) {}
void model_graph_scc_dfs_stop(model_graph_data_t mdata) {}
void model_graph_scc_dfs_push(model_graph_data_t mdata, edge_num_t num) {}
void model_graph_scc_dfs_pop(model_graph_data_t mdata) {}
void model_graph_scc_enter(model_graph_data_t mdata, bool_t terminal) {}
void model_graph_scc_exit(model_graph_data_t mdata) {}
#endif

typedef struct {
  edge_num_t num;
  node_t dest;
} edge_data_t;

typedef struct {
  uint8_t no_succs;
  edge_data_t * out;
} node_data_t;

typedef struct {
  unsigned int no_nodes;
  unsigned int no_edges;
  node_data_t * data;
  node_t root;
  heap_t heap;
} struct_graph_t;

typedef struct_graph_t * graph_t;

void graph_free
(graph_t graph) {
  unsigned int i;
  for(i = 0; i < graph->no_nodes; i ++) {
    mem_free(graph->heap, graph->data[i].out);
  }
  mem_free(graph->heap, graph->data);
  mem_free(graph->heap, graph);
}

graph_t graph_load_main
(char * in_file,
 heap_t heap,
 unsigned int max) {
  unsigned int i;
  char t;
  uint8_t no_succs;
  node_t n, o;
  FILE * f = fopen(in_file, "r");
  graph_t result = NULL;
  edge_data_t * out;
  edge_num_t num;

  if(f) {
    result = mem_alloc(heap, sizeof(struct_graph_t));
    result->heap = heap;
    result->no_nodes = 0;
    result->no_edges = 0;
    result->root = 0;
    result->data = mem_alloc(heap, sizeof(node_data_t) * max);
    for(i = 0; i < max; i ++) {
      result->data[i].no_succs = 0;
      result->data[i].out = NULL;
    }
    while(fread(&t, 1, 1, f)) {
      switch(t) {
      case GT_NODE: {
	fread(&n, sizeof(node_t), 1, f);
	if(n >= max) {
	  graph_free(result);
	  fclose(f);
	  return NULL;
	}
	fread(&no_succs, sizeof(uint8_t), 1, f);
	if(!no_succs) {
	  out = NULL;
	} else {
	  out = mem_alloc(heap, sizeof(node_t) * no_succs);
	  for(i = 0; i < no_succs; i ++) {
	    fread(&(out[i].num),  sizeof(edge_num_t), 1, f);
	    fread(&(out[i].dest), sizeof(node_t), 1, f);
	  }
	}
	result->data[n].out = out;
	result->data[n].no_succs = no_succs;
	result->no_nodes ++;
	result->no_edges += no_succs;
	break;
      }
      case GT_EDGE: {
	fread(&n, sizeof(node_t), 1, f);
        if(n >= max) {
          graph_free(result);
          fclose(f);
          return NULL;
        }
	fread(&num, sizeof(edge_num_t), 1, f);
	fread(&o, sizeof(node_t), 1, f);
	out = mem_alloc(heap,
                        sizeof(edge_data_t) * (result->data[n].no_succs + 1));
	for(i = 0; i < result->data[n].no_succs; i ++) {
          out[i] = result->data[n].out[i];
        }
	out[i].dest = o;
	out[i].num = num;
	if(result->data[n].out) {
	  mem_free(heap, result->data[n].out);
	}
	result->data[n].out = out;
	result->data[n].no_succs ++;
	result->no_edges ++;
	break;
      }
      default: {
	printf("error: graph_load read an incorrect GT: %d\n", t);
      }
      }
    }
    fclose(f);
  }
  return result;
}

graph_t graph_load
(char *  in_file,
 heap_t  heap) {
  unsigned int max = 4;
  graph_t result = NULL;
  while(NULL == result) {
    result = graph_load_main(in_file, heap, max);
    max = max * 2;
  }
  return result;
}



/*
 *  DFS exploration data
 */
typedef struct {
  uint32_t scc_count;
  uint32_t scc_trivial;
  uint32_t scc_terminal;
  uint32_t scc_largest;
  uint32_t front_edges;
  uint32_t cross_edges;
  uint32_t back_edges;
  uint32_t max_stack;
  uint32_t shortest_cycle;
  uint32_t samples;
  uint32_t * stack_samples_id;
  uint32_t * stack_samples_size;
} dfs_data_t;

/*
 *  degree data
 */
typedef struct {
  float avg;
  uint32_t max_in;
  uint32_t max_out;
  uint32_t degs;
  uint32_t * nodes_per_in;
  uint32_t * nodes_per_out;
} degree_data_t;

/*
 *  BFS exploration data
 */
typedef struct {
  uint32_t levels;
  uint32_t max_level;
  uint32_t ble;
  uint32_t max_ble;
  float avg_ble;
  uint32_t * states;
  uint32_t * edges;
  uint32_t * ble_lengths;
} bfs_data_t;



/*
 *  Function: graph_degree
 */
void graph_degree 
(graph_t graph,
 degree_data_t * data,
 model_graph_data_t mdata) {
  node_data_t * N = graph->data;
  node_t * in_deg;
  int i, j;

  in_deg = mem_alloc(SYSTEM_HEAP, sizeof(node_t) * graph->no_nodes);
  for(i = 0; i < graph->no_nodes; i ++) {
    in_deg[i] = 0;
  }

  data->avg = (float) graph->no_edges / (float) graph->no_nodes;
  data->max_in = 0;
  data->max_out = N[graph->root].no_succs;
  for(i = 0; i < graph->no_nodes; i ++) {
    if(data->max_out < N[i].no_succs) {
      data->max_out = N[i].no_succs;
    }
    for(j = 0; j < N[i].no_succs; j ++) {
      if((++ in_deg[N[i].out[j].dest]) > data->max_in) {
	data->max_in = in_deg[N[i].out[j].dest];
      }
    }
  }
  data->degs = data->max_in;
  if(data->max_out > data->degs) {
    data->degs = data->max_out;
  }
  data->nodes_per_in = mem_alloc(SYSTEM_HEAP,
                                 sizeof(uint32_t) * (data->degs + 1));
  data->nodes_per_out = mem_alloc(SYSTEM_HEAP, 
                                  sizeof(uint32_t) * (data->degs + 1));
  for(i = 0; i <= data->degs; i ++) {
    data->nodes_per_in[i] = 0;
    data->nodes_per_out[i] = 0;
  }
  for(i = 0; i < graph->no_nodes; i ++) {
    data->nodes_per_in[in_deg[i]] ++;
    data->nodes_per_out[N[i].no_succs] ++;
  }

  mem_free(SYSTEM_HEAP, in_deg);
}



/*
 *  Function: graph_bfs
 */
void graph_bfs
(graph_t graph,
 bfs_data_t * data,
 model_graph_data_t mdata) {
  uint32_t fst = 0;
  uint32_t last = 0;
  uint32_t old = 1;
  uint32_t current = 1;
  uint32_t next = 0;
  uint32_t edges = 0;
  uint32_t lg;
  uint32_t * depth;
  uint64_t ble_length_sum = 0;
  int i;
  node_t * queue;
  bool_t * visited;
  node_data_t * N = graph->data;
  node_t now, succ;

  data->levels = 0;
  data->max_level = 1;
  data->ble = 0;
  data->max_ble = 0;
  data->avg_ble = 0.0;
  data->states = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * 65536);
  data->edges = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * 65536);
  data->ble_lengths = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * 65536);
  for(i = 0; i < 65536; i ++) {
    data->ble_lengths[i] = 0;
  }

  queue = mem_alloc(SYSTEM_HEAP, sizeof(node_t) * graph->no_nodes);
  depth = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * graph->no_nodes);
  visited = mem_alloc(SYSTEM_HEAP, sizeof(bool_t) * graph->no_nodes);

  for(i = 0; i < graph->no_nodes; i ++) {
    visited[i] = 0;
  }
  queue[0] = graph->root;
  depth[graph->root] = 0;
  visited[graph->root] = TRUE;

  while(fst <= last) {
    now = queue[fst];
    for(i = 0; i < N[now].no_succs; i ++) {
      edges ++;
      succ = N[now].out[i].dest;
      if(visited[succ]) {
	if(depth[succ] != data->levels + 1) {
	  data->ble ++;
	  lg = data->levels - depth[succ];
	  ble_length_sum += lg;
	  data->ble_lengths[lg] ++;
	  if(lg > data->max_ble) { data->max_ble = lg; }
	}	
      } else {
	visited[succ] = TRUE;
	depth[succ] = data->levels + 1;
	queue[++ last] = succ;
	next ++;
      }
    }
    fst ++;
    current --;
    if(0 == current) {  /*  BFS level terminated  */
      if(next > data->max_level) { data->max_level = next; }
      data->states[data->levels] = old;
      data->edges[data->levels] = edges;
      data->levels ++;
      old = next;
      current = next;
      next = 0;
      edges = 0;
    }
  }
  data->avg_ble = (float) ble_length_sum / (float) data->ble;

  mem_free(SYSTEM_HEAP, depth);
  mem_free(SYSTEM_HEAP, queue);
  mem_free(SYSTEM_HEAP, visited);
}



/*
 *  Function: graph_dfs
 */
void graph_dfs
(graph_t graph,
 dfs_data_t * data,
 model_graph_data_t mdata) {
  uint8_t * scc;
  uint8_t * visited;
  uint8_t * next;
  uint32_t * depth;
  uint32_t * index;
  uint32_t * low_link;
  bool_t * scc_terminal;
  uint32_t idx = 0;
  uint32_t scc_size = 1;
  int top = 0, scc_top = 0, i;
  node_data_t * N = graph->data;
  node_t * stack;
  node_t * scc_stack;
  node_t now, succ;
  bool_t loop;
  unsigned int sampling_period = graph->no_nodes / 1000;
  
  if(sampling_period == 0) {
    sampling_period = 1;
  }

  data->scc_count = 0;
  data->scc_trivial = 0;
  data->scc_terminal = 0;
  data->scc_largest = 0;
  data->shortest_cycle = 0;
  data->front_edges = 0;
  data->cross_edges = 0;
  data->back_edges = 0;
  data->max_stack = 0;
  data->samples = 0;
  data->stack_samples_id =
    mem_alloc(SYSTEM_HEAP,
              sizeof(uint32_t) * graph->no_nodes / sampling_period);
  data->stack_samples_size =
    mem_alloc(SYSTEM_HEAP,
              sizeof(uint32_t) * graph->no_nodes / sampling_period);

  scc_terminal = mem_alloc(SYSTEM_HEAP, sizeof(bool_t) * graph->no_nodes);
  visited = mem_alloc(SYSTEM_HEAP, sizeof(uint8_t) * graph->no_nodes);
  next = mem_alloc(SYSTEM_HEAP, sizeof(uint8_t) * graph->no_nodes);
  scc = mem_alloc(SYSTEM_HEAP, sizeof(uint8_t) * graph->no_nodes);
  stack = mem_alloc(SYSTEM_HEAP, sizeof(node_t) * graph->no_nodes);
  scc_stack = mem_alloc(SYSTEM_HEAP, sizeof(node_t) * graph->no_nodes);
  depth = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * graph->no_nodes);
  index = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * graph->no_nodes);
  low_link = mem_alloc(SYSTEM_HEAP, sizeof(uint32_t) * graph->no_nodes);

  data->front_edges = 0;
  data->cross_edges = 0;
  data->back_edges = 0;
  data->max_stack = 0;

  loop = TRUE;
  for(top = 0; top < graph->no_nodes; top ++) {
    visited[top] = 0;
  }
  top = 0;
  scc_top = 0;
  stack[0] = graph->root;
  next[0] = 0;
  scc_stack[0] = graph->root;
  scc_terminal[0] = TRUE;
  scc[graph->root] = TRUE;
  depth[graph->root] = 0;
  visited[graph->root] = 1;
  index[graph->root] = idx;
  low_link[graph->root] = idx;
  idx ++;

  /*
   *  main DFS loop
   */
  model_graph_dfs_start(mdata);
  while(loop) {
    now = stack[top];
    if(next[top] >= N[now].no_succs) {  /*  backtrack  */
      visited[now] ++;
      if(index[now] == low_link[now]) {  /*  pop the root of an SCC  */
	scc_size = 0;
	do {
	  now = scc_stack[scc_top];
	  scc[now] = FALSE;
	  scc_top --;
	  scc_size ++;
	} while(scc_top >= 0 && now != stack[top]);
	if(scc_terminal[now]) {
	  data->scc_terminal ++;
	  for(i = top - 1; i >= 0 && scc_terminal[stack[i]]; i --) {
	    scc_terminal[stack[i]] = FALSE;
	  }
	}
	data->scc_count ++;
	if(scc_size == 1) { data->scc_trivial ++; }
	if(scc_size > data->scc_largest) { data->scc_largest = scc_size; }
      }
      if(0 == top) {
	loop = FALSE;
      } else {
	model_graph_dfs_pop(mdata);
	top --;
	if(low_link[stack[top]] > low_link[now]) {
	  low_link[stack[top]] = low_link[now];
	}
      }
    } else {  /*  visit a successor  */
      succ = N[now].out[next[top]].dest;
      next[top] ++;
      model_graph_dfs_push(mdata, N[now].out[next[top] - 1].num,
			   (0 == visited[succ]) ? TRUE : FALSE);
      if(0 == visited[succ]) {  /*  successor is new  */
	top ++;
	scc_top ++;
	next[top] = 0;
	stack[top] = succ;
	scc_stack[scc_top] = succ;
	scc_terminal[succ] = TRUE;
	scc[succ] = TRUE;
	depth[succ] = top;
	visited[succ] ++;
	index[succ] = idx;
	low_link[succ] = idx;
	idx ++;
	if(top + 1 > data->max_stack) { data->max_stack = top + 1; }
	if(0 == idx % sampling_period) {
	  data->stack_samples_id[data->samples] = idx;
	  data->stack_samples_size[data->samples] = top + 1;
	  data->samples ++;
	}
	data->front_edges ++;
      } else {  /*  successor is not new  */
	if(scc[succ]) {
	  if(low_link[now] > index[succ]) {
	    low_link[now] = index[succ];
	  }
	} else {
	  for(i = top; i >= 0 && scc_terminal[stack[i]]; i --) {
	    scc_terminal[stack[i]] = FALSE;
	  }	  
	}
	if(1 == visited[succ]) {  /*  successor is on stack  */
	  data->back_edges ++;
	  if(data->shortest_cycle == 0 ||
             top - depth[succ] + 1 < data->shortest_cycle) {
	    data->shortest_cycle = top - depth[succ] + 1;
	  }
	} else {  /*  successor has left stack  */
	  data->cross_edges ++;
	}
      }
    }
  }
  model_graph_dfs_stop(mdata);

  /*
   *  main SCC-DFS loop
   */
  loop = TRUE;
  for(top = 0; top < graph->no_nodes; top ++) {
    visited[top] = 0;
  }
  top = 0;
  stack[0] = graph->root;
  next[0] = 0;
  visited[graph->root] = 1;
  model_graph_scc_dfs_start(mdata);
  while(loop) {
    now = stack[top];
    if(index[now] == low_link[now] && next[top] == 0) {
      model_graph_scc_enter(mdata, scc_terminal[now]);
    }
    if(next[top] >= N[now].no_succs) {  /*  backtrack  */
      if(index[now] == low_link[now]) {  /*  pop the root of an SCC  */
	model_graph_scc_exit(mdata);
      }
      if(0 == top) {
	loop = FALSE;
      } else {
	model_graph_scc_dfs_pop(mdata);
	top --;
      }
    } else {  /*  visit a successor  */
      succ = N[now].out[next[top]].dest;
      next[top] ++;
      model_graph_scc_dfs_push(mdata, N[now].out[next[top] - 1].num);
      if(visited[succ]) {  /*  successor is not new  */
	model_graph_scc_dfs_pop(mdata);
      } else {
	top ++;
	next[top] = 0;
	stack[top] = succ;
	visited[succ] = 1;
      }
    }
  }
  model_graph_scc_dfs_stop(mdata);

  mem_free(SYSTEM_HEAP, depth);
  mem_free(SYSTEM_HEAP, next);
  mem_free(SYSTEM_HEAP, visited);
  mem_free(SYSTEM_HEAP, stack);
  mem_free(SYSTEM_HEAP, index);
  mem_free(SYSTEM_HEAP, low_link);
  mem_free(SYSTEM_HEAP, scc);
  mem_free(SYSTEM_HEAP, scc_stack);
  mem_free(SYSTEM_HEAP, scc_terminal);
}



/*
 *  Function: graph_make_statistics
 */
void graph_make_statistics
(graph_t graph,
 char * out_file) {

  FILE * f = fopen(out_file, "w");
  bfs_data_t B;
  dfs_data_t D;
  degree_data_t E;
  int i;
  model_graph_data_t mdata;

  model_graph_data_init(&mdata, graph->no_nodes);

  fprintf(f, "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n");
  fprintf(f, "<state-space-info>\n\n");

  fprintf(f, "<model>%s</model>\n", model_name());
  fprintf(f, "<language>%s</language>\n", CFG_LANGUAGE);
  fprintf(f, "<date>%s</date>\n", CFG_DATE);
  fprintf(f, "<filePath>%s</filePath>\n", CFG_FILE_PATH);
  model_xml_parameters(f);

  fprintf(f, "<states>%d</states>\n", graph->no_nodes);
  fprintf(f, "<edges>%d</edges>\n\n", graph->no_edges);

  /*
   *  BFS statistics
   */
  graph_bfs(graph, &B, mdata);
  fprintf(f, "<bfs-info>\n");
  fprintf(f, "<levels>%d</levels>\n", B.levels);
  fprintf(f, "<max-level>%d</max-level>\n", B.max_level);
  fprintf(f, "<back-level-edges>%d</back-level-edges>\n", B.ble);
  fprintf(f, "<max-back-level-edge>%d</max-back-level-edge>\n", B.max_ble);
  fprintf(f, "<avg-back-level-edge>%.2f</avg-back-level-edge>\n", B.avg_ble);
  fprintf(f, "<bfs-levels>\n");
  for(i = 0; i < B.levels; i ++) {
    fprintf(f, "<level id=\"%d\">", i);
    fprintf(f, "<states>%d</states>", B.states[i]);
    fprintf(f, "<edges>%d</edges>", B.edges[i]);
    fprintf(f, "</level>\n");
  }
  fprintf(f, "</bfs-levels>\n");
  fprintf(f, "<back-level-lengths>\n");
  if(B.ble > 0) {
    for(i = 0; i <= B.max_ble; i ++) {
      fprintf(f, "<length id=\"%d\">%.4f</length>\n", i,
              100.0 *(float) B.ble_lengths[i] /(float) B.ble);
    }
  }
  fprintf(f, "</back-level-lengths>\n");
  fprintf(f, "</bfs-info>\n\n");
  mem_free(SYSTEM_HEAP, B.states);
  mem_free(SYSTEM_HEAP, B.edges);
  mem_free(SYSTEM_HEAP, B.ble_lengths);

  /*
   *  degress statistics
   */
  graph_degree(graph, &E, mdata);
  fprintf(f, "<degrees>\n");
  fprintf(f, "<avg>%.4f</avg>\n", E.avg);
  fprintf(f, "<max-in>%d</max-in>\n", E.max_in);
  fprintf(f, "<max-out>%d</max-out>\n", E.max_out);
  for(i = 0; i <= E.degs; i ++) {
    fprintf(f, "<degree id=\"%d\"><in>%d</in><out>%d</out></degree>\n",
            i, E.nodes_per_in[i], E.nodes_per_out[i]);
  }
  fprintf(f, "</degrees>\n\n");
  mem_free(SYSTEM_HEAP, E.nodes_per_in);
  mem_free(SYSTEM_HEAP, E.nodes_per_out);

  /*
   *  SCC statistics
   */
  graph_dfs(graph, &D, mdata);
  fprintf(f, "<scc-info>\n");
  fprintf(f, "<count>%d</count>\n", D.scc_count);
  fprintf(f, "<trivial>%d</trivial>\n", D.scc_trivial);
  fprintf(f, "<terminal>%d</terminal>\n", D.scc_terminal);
  fprintf(f, "<largest>%d</largest>\n", D.scc_largest);
  fprintf(f, "</scc-info>\n\n");

  /*
   *  DFS statistics
   */
  fprintf(f, "<dfs-info>\n");
  for(i = 0; i < D.samples; i ++) {
    fprintf(f, "<stack-size id=\"%d\">%.4f</stack-size>\n",
            D.stack_samples_id[i],
            100.0 *
	    (float) D.stack_samples_size[i] /(float) graph->no_nodes);

  }
  fprintf(f, "<max-stack>%d</max-stack>\n", D.max_stack);
  fprintf(f, "<front-edges>%d</front-edges>\n", D.front_edges);
  fprintf(f, "<back-edges>%d</back-edges>\n", D.back_edges);
  fprintf(f, "<cross-edges>%d</cross-edges>\n", D.cross_edges);
  fprintf(f, "<shortest-cycle>%d</shortest-cycle>\n", D.shortest_cycle);
  fprintf(f, "</dfs-info>\n\n");
  mem_free(SYSTEM_HEAP, D.stack_samples_id);
  mem_free(SYSTEM_HEAP, D.stack_samples_size);

  /*
   *  model specific data
   */
  model_graph_data_output(mdata, f);
  model_graph_data_free(&mdata);
  
  fprintf(f, "</state-space-info>\n");
  fclose(f);
}



void graph_make_report
(char * in_file,
 char * out_file) {
  graph_t g = graph_load(in_file, SYSTEM_HEAP);
  graph_make_statistics(g, out_file);
  graph_free(g);
}
