part of dagre.rank;
//"use strict";
//
//var util = require("../util"),
//    topsort = require("graphlib").alg.topsort;
//
//module.exports = initRank;

/**
 * Assigns a `rank` attribute to each node in the input graph and ensures that
 * this rank respects the `minLen` attribute of incident edges.
 *
 * Prerequisites:
 *
 *  * The input graph must be acyclic
 *  * Each edge in the input graph must have an assigned "minLen" attribute
 */
initRank(Digraph g) {
  var sorted = topsort(g);

  sorted.forEach((u) {
    var inEdges = g.inEdges(u);
    if (inEdges.length == 0) {
      g.node(u)['rank'] = 0;
      return;
    }

    var minLens = inEdges.map((e) {
      var r = g.node(g.source(e))['rank'];
      var ml = g.edge(e)['minLen'];
      return r + ml;
    });
    g.node(u)['rank'] = util.max(minLens);
  });
}
