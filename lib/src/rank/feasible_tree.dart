part of dagre.rank;
///* jshint -W079 */
//var Set = require("cp-data").Set,
///* jshint +W079 */
//    Digraph = require("graphlib").Digraph,
//    util = require("../util");

//module.exports = feasibleTree;

/**
 * Given an acyclic graph with each node assigned a `rank` attribute, this
 * function constructs and returns a spanning tree. This function may reduce
 * the length of some edges from the initial rank assignment while maintaining
 * the `minLen` specified by each edge.
 *
 * Prerequisites:
 *
 * * The input graph is acyclic
 * * Each node in the input graph has an assigned `rank` attribute
 * * Each edge in the input graph has an assigned `minLen` attribute
 *
 * Outputs:
 *
 * A feasible spanning tree for the input graph (i.e. a spanning tree that
 * respects each graph edge"s `minLen` attribute) represented as a Digraph with
 * a `root` attribute on graph.
 *
 * Nodes have the same id and value as that in the input graph.
 *
 * Edges in the tree have arbitrarily assigned ids. The attributes for edges
 * include `reversed`. `reversed` indicates that the edge is a
 * back edge in the input graph.
 */
feasibleTree(g) {
  final remaining = new Set.from(g.nodes()),
      tree = new Digraph();

  if (remaining.length == 1) {
    var root = g.nodes()[0];
    tree.addNode(root, {});
    tree.graph({ 'root': root });
    return tree;
  }

  addTightEdges(v) {
    var continueToScan = true;
    g.predecessors(v).forEach((u) {
      if (remaining.contains(u) && slack(g, u, v) == 0) {
        if (remaining.contains(v)) {
          tree.addNode(v, {});
          remaining.remove(v);
          tree.graph({ 'root': v });
        }

        tree.addNode(u, {});
        tree.addEdge(null, u, v, { 'reversed': true });
        remaining.remove(u);
        addTightEdges(u);
        continueToScan = false;
      }
    });

    g.successors(v).forEach((w)  {
      if (remaining.contains(w) && slack(g, v, w) == 0) {
        if (remaining.contains(v)) {
          tree.addNode(v, {});
          remaining.remove(v);
          tree.graph({ 'root': v });
        }

        tree.addNode(w, {});
        tree.addEdge(null, v, w, {});
        remaining.remove(w);
        addTightEdges(w);
        continueToScan = false;
      }
    });
    return continueToScan;
  }

  createTightEdge() {
    var minSlack = double.MAX_FINITE;
    remaining.forEach((v) {
      g.predecessors(v).forEach((u) {
        if (!remaining.contains(u)) {
          var edgeSlack = slack(g, u, v);
          if (edgeSlack.abs() < minSlack.abs()) {
            minSlack = -edgeSlack;
          }
        }
      });

      g.successors(v).forEach((w) {
        if (!remaining.contains(w)) {
          var edgeSlack = slack(g, v, w);
          if (edgeSlack.abs() < minSlack.abs()) {
            minSlack = edgeSlack;
          }
        }
      });
    });

    tree.eachNode((u, _) { g.node(u)['rank'] -= minSlack; });
  }

  while (remaining.length != 0) {
    var nodesToSearch = tree.order() == 0 ? remaining.toList() : tree.nodes();
    for (var i = 0, il = nodesToSearch.length;
         i < il && addTightEdges(nodesToSearch[i]);
         ++i);
    if (remaining.length != 0) {
      createTightEdge();
    }
  }

  return tree;
}

slack(g, u, v) {
  var rankDiff = g.node(v)['rank'] - g.node(u)['rank'];
  var maxMinLen = util.max(g.outEdges(u, v)
                            .map((e) { return g.edge(e)['minLen']; }));
  return rankDiff - maxMinLen;
}
