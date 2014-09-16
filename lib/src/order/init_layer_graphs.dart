part of dagre.order;

/**
 * This function takes a compound layered graph, [g], and produces an array
 * of layer graphs. Each entry in the array represents a subgraph of nodes
 * relevant for performing crossing reduction on that layer.
 */
List initLayerGraphs(BaseGraph g) {
  final ranks = new SplayTreeMap<int, List>();

  Set dfs(u) {
    if (u == null) {
      g.children(u).forEach((v) { dfs(v); });
      return null;
    }

    Map value = g.node(u);
    value['minRank'] = (value.containsKey("rank")) ? value['rank'] : double.MAX_FINITE;
    value['maxRank'] = (value.containsKey("rank")) ? value['rank'] : double.MIN_POSITIVE;
    var uRanks = new Set();
    g.children(u).forEach((v) {
      final rs = dfs(v);
      uRanks = util.union([uRanks, rs]);
      value['minRank'] = Math.min(value['minRank'], g.node(v)['minRank']);
      value['maxRank'] = Math.max(value['maxRank'], g.node(v)['maxRank']);
    });

    if (value.containsKey("rank")) uRanks.add(value['rank']);

    uRanks.forEach((r) {
      if (!(ranks.containsKey(r))) ranks[r] = [];
      ranks[r].add(u);
    });

    return uRanks;
  }
  dfs(null);

  final layerGraphs = new SplayTreeMap<int, BaseGraph>();
  //ranks.forEach((us, rank) {
  ranks.forEach((int rank, List us) {
    layerGraphs[rank] = g.filterNodes(nodesFromList(us));
  });

  return layerGraphs.values.toList();
}
