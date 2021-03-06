part of dagre;
//"use strict";
//
//var util = require("./util"),
//    crossCount = require("./order/crossCount"),
//    initLayerGraphs = require("./order/initLayerGraphs"),
//    initOrder = require("./order/initOrder"),
//    sortLayer = require("./order/sortLayer");
//
//module.exports = order;

// The maximum number of sweeps to perform before finishing the order phase.
const DEFAULT_MAX_SWEEPS = 24;
//order.DEFAULT_MAX_SWEEPS = DEFAULT_MAX_SWEEPS;

/**
 * Runs the order phase with the specified `graph`, [maxSweeps], and
 * `debugLevel`. If [maxSweeps] is not specified we use [DEFAULT_MAX_SWEEPS].
 * If `debugLevel` is not set we assume 0.
 */
order(Digraph g, [maxSweeps=DEFAULT_MAX_SWEEPS]) {
//  if (arguments.length < 2) {
//    maxSweeps = DEFAULT_MAX_SWEEPS;
//  }

  final restarts = g.graph().containsKey('orderRestarts') &&
      g.graph()['orderRestarts'] != null ? g.graph()['orderRestarts'] : 0;

  final layerGraphs = initLayerGraphs(g);
  // TODO: remove this when we add back support for ordering clusters
  layerGraphs.forEach((lg) {
    lg = lg.filterNodes((u) { return g.children(u).length == 0; });
  });

  var iters = 0,
      currentBestCC,
      allTimeBestCC = double.MAX_FINITE,
      allTimeBest = {};

  saveAllTimeBest() {
    g.eachNode((u, Map value) { allTimeBest[u] = value['order']; });
  }

  for (var j = 0; j < restarts.toDouble() + 1 && allTimeBestCC != 0; ++j) {
    currentBestCC = double.MAX_FINITE;
    initOrder(g, restarts > 0);

    util.log(2, "Order phase start cross count: ${g.graph()['orderInitCC']}");

    var i = 0, lastBest, cc;
    for (lastBest = 0;
         lastBest < 4 && i < maxSweeps && currentBestCC > 0;
         ++i, ++lastBest, ++iters) {
      sweep(g, layerGraphs, i);
      cc = crossCount(g);
      if (cc < currentBestCC) {
        lastBest = 0;
        currentBestCC = cc;
        if (cc < allTimeBestCC) {
          saveAllTimeBest();
          allTimeBestCC = cc;
        }
      }
      util.log(3, "Order phase start $j iter $i cross count: $cc");
    }
  }

  allTimeBest.keys.forEach((u) {
    if (/*!g.children || */g.children(u).length == 0) {
      g.node(u)['order'] = allTimeBest[u];
    }
  });
  g.graph()['orderCC'] = allTimeBestCC;

  util.log(2, "Order iterations: $iters");
  util.log(2, "Order phase best cross count: ${g.graph()['orderCC']}");
}

predecessorWeights(g, nodes) {
  var weights = {};
  nodes.forEach((u) {
    weights[u] = g.inEdges(u).map((e) {
      return g.node(g.source(e))['order'];
    });
  });
  return weights;
}

successorWeights(Digraph g, nodes) {
  var weights = {};
  nodes.forEach((u) {
    weights[u] = g.outEdges(u).map((e) {
      return g.node(g.target(e))['order'];
    });
  });
  return weights;
}

sweep(Digraph g, List layerGraphs, iter) {
  if (iter % 2 == 0) {
    sweepDown(g, layerGraphs);//, iter);
  } else {
    sweepUp(g, layerGraphs);//, iter);
  }
}

sweepDown(Digraph g, List layerGraphs) {
  var cg;
  for (var i = 1; i < layerGraphs.length; ++i) {
    cg = sortLayer(layerGraphs[i], cg, predecessorWeights(g, layerGraphs[i].nodes()));
  }
}

sweepUp(Digraph g, List layerGraphs) {
  var cg;
  for (var i = layerGraphs.length - 2; i >= 0; --i) {
    sortLayer(layerGraphs[i], cg, successorWeights(g, layerGraphs[i].nodes()));
  }
}
