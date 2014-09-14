part of dagre.rank;
//"use strict";
//
//var util = require("../util");
//
//module.exports = acyclic;
//module.exports.undo = undo;

/*
 * This function takes a directed graph that may have cycles and reverses edges
 * as appropriate to break these cycles. Each reversed edge is assigned a
 * `reversed` attribute with the value `true`.
 *
 * There should be no self loops in the graph.
 */
acyclic(g) {
  var onStack = {},
      visited = {},
      reverseCount = 0;

  dfs(u) {
    if (visited.containsKey(u)) return;
    visited[u] = onStack[u] = true;
    g.outEdges(u).forEach((e) {
      var t = g.target(e),
          value;

      if (u == t) {
        console.error("Warning: found self loop '" + e + "' for node '" + u + "'");
      } else if (onStack.containsKey(t)) {
        value = g.edge(e);
        g.delEdge(e);
        value.reversed = true;
        ++reverseCount;
        g.addEdge(e, t, u, value);
      } else {
        dfs(t);
      }
    });

    onStack.remove(u);
  }

  g.eachNode((u) { dfs(u); });

  util.log(2, "Acyclic Phase: reversed " + reverseCount + " edge(s)");

  return reverseCount;
}

/*
 * Given a graph that has had the acyclic operation applied, this function
 * undoes that operation. More specifically, any edge with the `reversed`
 * attribute is again reversed to restore the original direction of the edge.
 */
undo(g) {
  g.eachEdge((e, s, t, a) {
    if (a.reversed) {
      a.remove(reversed);
      g.delEdge(e);
      g.addEdge(e, t, s, a);
    }
  });
}
