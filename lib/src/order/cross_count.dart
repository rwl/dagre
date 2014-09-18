part of dagre.order;
//"use strict";
//
//var util = require("../util");
//
//module.exports = crossCount;

/**
 * Returns the cross count for the given graph.
 */
int crossCount(Digraph g) {
  var cc = 0;
  var ordering = util.ordering(g);
  for (var i = 1; i < ordering.length; ++i) {
    cc += twoLayerCrossCount(g, ordering[i-1], ordering[i]);
  }
  return cc;
}

/**
 * This function searches through a ranked and ordered graph and counts the
 * number of edges that cross. This algorithm is derived from:
 *
 *     W. Barth et al., Bilayer Cross Counting, JGAA, 8(2) 179–194 (2004)
 */
int twoLayerCrossCount(Digraph g, layer1, layer2) {
  var indices = [];
  layer1.forEach((u) {
    var nodeIndices = [];
    g.outEdges(u).forEach((e) {
      nodeIndices.add(g.node(g.target(e))['order']);
    });
    nodeIndices.sort((x, y) { return x - y; });
    indices.addAll(nodeIndices);
  });

  int firstIndex = 1;
  while (firstIndex < layer2.length) firstIndex <<= 1;

  int treeSize = 2 * firstIndex - 1;
  firstIndex -= 1;

  final tree = new Int32List(treeSize);
  //for (var i = 0; i < treeSize; ++i) { tree[i] = 0; }

  int cc = 0;
  indices.forEach((i) {
    var treeIndex = i + firstIndex;
    ++tree[treeIndex];
    while (treeIndex > 0) {
      if ((treeIndex % 2) != 0) {
        cc += tree[treeIndex + 1];
      }
      treeIndex = (treeIndex - 1) >> 1;
      ++tree[treeIndex];
    }
  });

  return cc;
}
