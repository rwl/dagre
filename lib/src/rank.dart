part of dagre;

//import 'package:graphlib/graphlib.dart' show BaseGraph, components, nodesFromList;
//
//import 'util.dart' as util;
//import 'rank/constraints.dart' as constraints;
//import 'rank/rank.dart';

//"use strict";
//
//var util = require("./util"),
//    acyclic = require("./rank/acyclic"),
//    initRank = require("./rank/initRank"),
//    feasibleTree = require("./rank/feasibleTree"),
//    constraints = require("./rank/constraints"),
//    simplex = require("./rank/simplex"),
//    components = require("graphlib").alg.components,
//    filter = require("graphlib").filter;
//
//exports.run = run;
//exports.restoreEdges = restoreEdges;

/**
 * Heuristic function that assigns a rank to each node of the input graph with
 * the intent of minimizing edge lengths, while respecting the `minLen`
 * attribute of incident edges.
 *
 * Prerequisites:
 *
 *  * Each edge in the input graph must have an assigned "minLen" attribute
 */
runRank(BaseGraph g, bool useSimplex) {
  expandSelfLoops(g);

  // If there are rank constraints on nodes, then build a new graph that
  // encodes the constraints.
  util.time("constraints.apply", () => rank.applyConstraints(g));

  expandSidewaysEdges(g);

  // Reverse edges to get an acyclic graph, we keep the graph in an acyclic
  // state until the very end.
  util.time("acyclic", () => rank.acyclic(g));

  // Convert the graph into a flat graph for ranking
  var flatGraph = g.filterNodes(util.filterNonSubgraphs(g));

  // Assign an initial ranking using DFS.
  rank.initRank(flatGraph);

  // For each component improve the assigned ranks.
  components(flatGraph).forEach((cmpt) {
    var subgraph = flatGraph.filterNodes(nodesFromList(cmpt));
    rankComponent(subgraph, useSimplex);
  });

  // Relax original constraints
  util.time("constraints.relax", () => rank.relax(g));

  // When handling nodes with constrained ranks it is possible to end up with
  // edges that point to previous ranks. Most of the subsequent algorithms assume
  // that edges are pointing to successive ranks only. Here we reverse any "back
  // edges" and mark them as such. The acyclic algorithm will reverse them as a
  // post processing step.
  util.time("reorientEdges", () => reorientEdges(g));
}

restoreEdges(g) {
  rank.undo(g);
}

/**
 * Expand self loops into three dummy nodes. One will sit above the incident
 * node, one will be at the same level, and one below. The result looks like:
 *
 *         /--<--x--->--\
 *     node              y
 *         \--<--z--->--/
 *
 * Dummy nodes x, y, z give us the shape of a loop and node y is where we place
 * the label.
 *
 * TODO: consolidate knowledge of dummy node construction.
 * TODO: support minLen = 2
 */
expandSelfLoops(BaseGraph g) {
  g.eachEdge((e, u, v, a) {
    if (u == v) {
      var x = addDummyNode(g, e, u, v, a, 0, false),
          y = addDummyNode(g, e, u, v, a, 1, true),
          z = addDummyNode(g, e, u, v, a, 2, false);
      g.addEdge(null, x, u, {'minLen': 1, 'selfLoop': true});
      g.addEdge(null, x, y, {'minLen': 1, 'selfLoop': true});
      g.addEdge(null, u, z, {'minLen': 1, 'selfLoop': true});
      g.addEdge(null, y, z, {'minLen': 1, 'selfLoop': true});
      g.delEdge(e);
    }
  });
}

expandSidewaysEdges(BaseGraph g) {
  g.eachEdge((e, u, v, a) {
    if (u == v) {
      Map origEdge = a['originalEdge'];
      var dummy = addDummyNode(g, origEdge['e'], origEdge['u'], origEdge['v'], origEdge['value'], 0, true);
      g.addEdge(null, u, dummy, {'minLen': 1});
      g.addEdge(null, dummy, v, {'minLen': 1});
      g.delEdge(e);
    }
  });
}

addDummyNode(BaseGraph g, e, u, v, Map a, index, bool isLabel) {
  return g.addNode(null, {
    'width': isLabel ? a['width'] : 0,
    'height': isLabel ? a['height'] : 0,
    'edge': { 'id': e, 'source': u, 'target': v, 'attrs': a },
    'dummy': true,
    'index': index
  });
}

reorientEdges(BaseGraph g) {
  g.eachEdge((e, u, v, Map value) {
    if (g.node(u)['rank'] > g.node(v)['rank']) {
      g.delEdge(e);
      value['reversed'] = true;
      g.addEdge(e, v, u, value);
    }
  });
}

rankComponent(subgraph, bool useSimplex) {
  var spanningTree = rank.feasibleTree(subgraph);

  if (useSimplex) {
    util.log(1, "Using network simplex for ranking");
    rank.simplex(subgraph, spanningTree);
  }
  normalize(subgraph);
}

normalize(BaseGraph g) {
  var m = util.min(g.nodes().map((u) { return g.node(u)['rank']; }));
  g.eachNode((u, node) { node['rank'] -= m; });
}
