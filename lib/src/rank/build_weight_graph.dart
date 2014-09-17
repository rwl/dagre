part of dagre.rank;

/**
 * This function takes a directed acyclic multi-graph and produces a
 * simple directed graph. Nodes are simply copied from the input graph to the
 * output graph.Edges are collapsed and assigned `weight` and `minLen`
 * attributes.
 *
 * The weight of an edge consists of a sign and a magnitude. The sign is
 * negative if the edge has a truthy `reversed` attribute; otherwise it is
 * positive. Because the input graph is acyclic multi-edges between a pair of
 * nodes must be in the same direction, so there is no difficulty in
 * determining the sign. The magnitude represents the number of edges between
 * the pair of nodes. This entire value is represented as a single attribute
 * called `weight`.
 *
 * The `minLen` of an edge in the output graph is the max value for `minLen`
 * between the adjacent nodes in the input graph. If the edge in the input
 * graph is reversed then `minLen` will be a negative value (or 0 in the case
 * of a sideways edge).
 */
Digraph buildWeightGraph(BaseGraph g) {
  var result = new Digraph();
  g.eachNode((u, value) { result.addNode(u, value); });
  g.eachEdge((e, u, v, Map value) {
    final id = incidenceId(u, v);
    if (!result.hasEdge(id)) {
      result.addEdge(id, u, v, { 'weight': 0, 'minLen': 0 });
    }
    Map resultEdge = result.edge(id);
    final rev = value.containsKey('reversed') && value['reversed'] ? -1 : 1;
    resultEdge['weight'] += rev;
    resultEdge['minLen'] = rev * Math.max(
        resultEdge.containsKey('minLen') ? resultEdge['minLen'].abs() : double.NAN,
        value.containsKey('minLen') ? value['minLen'].abs() : double.NAN);
  });
  return result;
}

/**
 * This id can be used to group (in an undirected manner) multi-edges
 * incident on the same two nodes.
 */
String incidenceId(u, v) {
  //return u < v ? "${u.length}:$u-$v" : "${v.length}:$v-$u";
  return u < v ? ":$u-$v" : ":$v-$u";
}
