part of dagre.order;
//"use strict";
//
//var util = require("../util"),
//    Digraph = require("graphlib").Digraph,
//    topsort = require("graphlib").alg.topsort,
//    nodesFromList = require("graphlib").filter.nodesFromList;
//
//module.exports = sortLayer;

sortLayer(g, cg, weights) {
  weights = adjustWeights(g, weights);
  final result = sortLayerSubgraph(g, null, cg, weights);

  int i = 0;
  result['list'].forEach((u) {
    g.node(u)['order'] = i;
    i++;
  });
  return result['constraintGraph'];
}

Map sortLayerSubgraph(g, sg, cg, weights) {
  cg = cg != null ? cg.filterNodes(nodesFromList(g.children(sg))) : new Digraph();

  final nodeData = {};
  g.children(sg).forEach((u) {
    if (g.children(u).length != 0) {
      nodeData[u] = sortLayerSubgraph(g, u, cg, weights);
      nodeData[u]['firstSG'] = u;
      nodeData[u]['lastSG'] = u;
    } else {
      var ws = weights[u];
      nodeData[u] = {
        'degree': ws.length,
        'barycenter': util.sum(ws) / ws.length,
        'order': g.node(u)['order'],
        'orderCount': 1,
        'list': [u]
      };
    }
  });

  resolveViolatedConstraints(g, cg, nodeData);

  final keys = nodeData.keys.toList();
  keys.sort((x, y) {
    final bc = nodeData[x]['barycenter'] - nodeData[y]['barycenter'];
    return bc != 0 ? bc : nodeData[x]['order'] - nodeData[y]['order'];
  });

  final result = keys.map((u) { return nodeData[u]; })
                    .reduce((lhs, rhs) { return mergeNodeData(g, lhs, rhs); });
  return result;
}

Map mergeNodeData(BaseGraph g, Map lhs, Map rhs) {
  var cg = mergeDigraphs(lhs['constraintGraph'], rhs['constraintGraph']);

  if (lhs['lastSG'] != null && rhs['firstSG'] != null) {
    if (cg == null) {
      cg = new Digraph();
    }
    if (!cg.hasNode(lhs['lastSG'])) { cg.addNode(lhs['lastSG']); }
    cg.addNode(rhs['firstSG']);
    cg.addEdge(null, lhs['lastSG'], rhs['firstSG']);
  }

  return {
    'degree': lhs['degree'] + rhs['degree'],
    'barycenter': (lhs['barycenter'] * lhs['degree'] + rhs['barycenter'] * rhs['degree']) /
                (lhs['degree'] + rhs['degree']),
    'order': (lhs['order'] * lhs['orderCount'] + rhs['order'] * rhs['orderCount']) /
           (lhs['orderCount'] + rhs['orderCount']),
    'orderCount': lhs['orderCount'] + rhs['orderCount'],
    'list': concat([lhs['list'], (rhs['list'])]).toList(),
    'firstSG': lhs['firstSG'] != null ? lhs['firstSG'] : rhs['firstSG'],
    'lastSG': rhs['lastSG'] != null ? rhs['lastSG'] : lhs['lastSG'],
    'constraintGraph': cg
  };
}

BaseGraph mergeDigraphs(BaseGraph lhs, BaseGraph rhs) {
  if (lhs == null) return rhs;
  if (rhs == null) return lhs;

  lhs = lhs.copy();
  rhs.nodes().forEach((u) { lhs.addNode(u); });
  //rhs.edges().forEach((e, u, v) { lhs.addEdge(null, u, v); });
  rhs.eachEdge((e, u, v, _) { lhs.addEdge(null, u, v); });
  return lhs;
}

resolveViolatedConstraints(BaseGraph g, Digraph cg, nodeData) {
  // Removes nodes `u` and `v` from `cg` and makes any edges incident on them
  // incident on `w` instead.
  collapseNodes(u, v, w) {
    // TODO original paper removes self loops, but it is not obvious when this would happen
    cg.inEdges(u).forEach((e) {
      cg.delEdge(e);
      cg.addEdge(null, cg.source(e), w);
    });

    cg.outEdges(v).forEach((e) {
      cg.delEdge(e);
      cg.addEdge(null, w, cg.target(e));
    });

    cg.delNode(u);
    cg.delNode(v);
  }

  var violated;
  while ((violated = findViolatedConstraint(cg, nodeData)) != null) {
    var source = cg.source(violated),
        target = cg.target(violated);

    var v;
    while ((v = cg.addNode(null)) != null && g.hasNode(v)) {
      cg.delNode(v);
    }

    // Collapse barycenter and list
    nodeData[v] = mergeNodeData(g, nodeData[source], nodeData[target]);
    nodeData.remove(source);
    nodeData.remove(target);

    collapseNodes(source, target, v);
    if (cg.incidentEdges(v).length == 0) { cg.delNode(v); }
  }
}

findViolatedConstraint(Digraph cg, nodeData) {
  var us = topsort(cg);
  for (var i = 0; i < us.length; ++i) {
    var u = us[i];
    var inEdges = cg.inEdges(u);
    for (var j = 0; j < inEdges.length; ++j) {
      var e = inEdges[j];
      if (nodeData[cg.source(e)]['barycenter'] >= nodeData[u]['barycenter']) {
        return e;
      }
    }
  }
}

// Adjust weights so that they fall in the range of 0..|N|-1. If a node has no
// weight assigned then set its adjusted weight to its current position. This
// allows us to better retain the origiinal position of nodes without neighbors.
adjustWeights(BaseGraph g, weights) {
  var minW = double.MAX_FINITE,
      maxW = 0,
      adjusted = {};
  g.eachNode((u, _) {
    if (g.children(u).length != 0) return;

    var ws = weights[u];
    if (ws.length != 0) {
      minW = Math.min(minW, util.min(ws));
      maxW = Math.max(maxW, util.max(ws));
    }
  });

  var rangeW = (maxW - minW);
  g.eachNode((u, _) {
    if (g.children(u).length != 0) return;

    var ws = weights[u];
    if (ws.length == 0) {
      adjusted[u] = [g.node(u)['order']];
    } else {
      adjusted[u] = ws.map((w) {
        if (rangeW != 0) {
          return (w - minW) * (g.order() - 1) / rangeW;
        } else {
          return g.order() - 1 / 2;
        }
      });
    }
  });

  return adjusted;
}
