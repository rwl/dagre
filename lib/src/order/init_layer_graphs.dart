part of dagre.order;
//"use strict";
//
//var nodesFromList = require("graphlib").filter.nodesFromList,
//    /* jshint -W079 */
//    Set = require("cp-data").Set;
//
//module.exports = initLayerGraphs;

/*
 * This function takes a compound layered graph, g, and produces an array of
 * layer graphs. Each entry in the array represents a subgraph of nodes
 * relevant for performing crossing reduction on that layer.
 */
initLayerGraphs(g) {
  var ranks = [];

  dfs(u) {
    if (u == null) {
      g.children(u).forEach((v) { dfs(v); });
      return;
    }

    var value = g.node(u);
    value.minRank = (value.containsKey("rank")) ? value.rank : Number.MAX_VALUE;
    value.maxRank = (value.containsKey("rank")) ? value.rank : Number.MIN_VALUE;
    var uRanks = new Set();
    g.children(u).forEach((v) {
      var rs = dfs(v);
      uRanks = Set.union([uRanks, rs]);
      value.minRank = Math.min(value.minRank, g.node(v).minRank);
      value.maxRank = Math.max(value.maxRank, g.node(v).maxRank);
    });

    if (value.containsKey("rank")) uRanks.add(value.rank);

    uRanks.keys().forEach((r) {
      if (!(ranks.containsKey(r))) ranks[r] = [];
      ranks[r].push(u);
    });

    return uRanks;
  }
  dfs(null);

  var layerGraphs = [];
  ranks.forEach((us, rank) {
    layerGraphs[rank] = g.filterNodes(nodesFromList(us));
  });

  return layerGraphs;
}
