part of dagre.rank;

applyConstraints(Digraph g) {
  dfs(sg) {
    var rankSets = {};
    g.children(sg).forEach((u) {
      if (g.children(u).length != 0) {
        dfs(u);
        return;
      }

      var value = g.node(u),
          prefRank = value['prefRank'];
      if (prefRank != null) {
        if (!checkSupportedPrefRank(prefRank)) { return; }

        if (!(rankSets.containsKey(prefRank))) {
          rankSets['prefRank'] = [u];
        } else {
          rankSets['prefRank'].add(u);
        }

        var newU = rankSets[prefRank];
        if (newU == null) {
          newU = rankSets[prefRank] = g.addNode(null, { 'originalNodes': [] });
          g.parent(newU, sg);
        }

        redirectInEdges(g, u, newU, prefRank == "min");
        redirectOutEdges(g, u, newU, prefRank == "max");

        // Save original node and remove it from reduced graph
        g.node(newU)['originalNodes'].add({ 'u': u, 'value': value, 'parent': sg });
        g.delNode(u);
      }
    });

    addLightEdgesFromMinNode(g, sg, rankSets['min']);
    addLightEdgesToMaxNode(g, sg, rankSets['max']);
  }

  dfs(null);
}

checkSupportedPrefRank(prefRank) {
  if (prefRank != "min" && prefRank != "max" && prefRank.indexOf("same_") != 0) {
    /*console.error*/print("Unsupported rank type: " + prefRank);
    return false;
  }
  return true;
}

redirectInEdges(g, u, newU, reverse) {
  g.inEdges(u).forEach((e) {
    var origValue = g.edge(e),
        value;
    if (origValue['originalEdge'] != null) {
      value = origValue;
    } else {
      value =  {
        'originalEdge': { 'e': e, 'u': g.source(e), 'v': g.target(e), 'value': origValue },
        'minLen': g.edge(e)['minLen']
      };
    }

    // Do not reverse edges for self-loops.
    if (origValue['selfLoop'] != null) {
      reverse = false;
    }

    if (reverse) {
      // Ensure that all edges to min are reversed
      g.addEdge(null, newU, g.source(e), value);
      value['reversed'] = true;
    } else {
      g.addEdge(null, g.source(e), newU, value);
    }
  });
}

redirectOutEdges(g, u, newU, reverse) {
  g.outEdges(u).forEach((e) {
    Map origValue = g.edge(e),
        value;
    if (origValue['originalEdge'] != null) {
      value = origValue;
    } else {
      value =  {
        'originalEdge': { 'e': e, 'u': g.source(e), 'v': g.target(e), 'value': origValue },
        'minLen': g.edge(e)['minLen']
      };
    }

    // Do not reverse edges for self-loops.
    if (origValue['selfLoop'] != null) {
      reverse = false;
    }

    if (reverse) {
      // Ensure that all edges from max are reversed
      g.addEdge(null, g.target(e), newU, value);
      value['reversed'] = true;
    } else {
      g.addEdge(null, newU, g.target(e), value);
    }
  });
}

addLightEdgesFromMinNode(Digraph g, sg, minNode) {
  if (minNode != null) {
    g.children(sg).forEach((u) {
      // The dummy check ensures we don"t add an edge if the node is involved
      // in a self loop or sideways edge.
      if (u != minNode && g.outEdges(minNode, u).length == 0 && !g.node(u)['dummy']) {
        g.addEdge(null, minNode, u, { 'minLen': 0 });
      }
    });
  }
}

addLightEdgesToMaxNode(Digraph g, sg, maxNode) {
  if (maxNode != null) {
    g.children(sg).forEach((u) {
      // The dummy check ensures we don"t add an edge if the node is involved
      // in a self loop or sideways edge.
      if (u != maxNode && g.outEdges(u, maxNode).length == 0 && !g.node(u)['dummy']) {
        g.addEdge(null, u, maxNode, { 'minLen': 0 });
      }
    });
  }
}

/*
 * This function "relaxes" the constraints applied previously by the "apply"
 * function. It expands any nodes that were collapsed and assigns the rank of
 * the collapsed node to each of the expanded nodes. It also restores the
 * original edges and removes any dummy edges pointing at the collapsed nodes.
 *
 * Note that the process of removing collapsed nodes also removes dummy edges
 * automatically.
 */
relax(g) {
  // Save original edges
  var originalEdges = [];
  g.eachEdge((e, u, v, Map value) {
    var originalEdge = value['originalEdge'];
    if (originalEdge != null) {
      originalEdges.add(originalEdge);
    }
  });

  // Expand collapsed nodes
  g.eachNode((u, Map value) {
    var originalNodes = value['originalNodes'];
    if (originalNodes != null) {
      originalNodes.forEach((Map originalNode) {
        originalNode['value']['rank'] = value['rank'];
        g.addNode(originalNode['u'], originalNode['value']);
        g.parent(originalNode['u'], originalNode['parent']);
      });
      g.delNode(u);
    }
  });

  // Restore original edges
  originalEdges.forEach((Map edge) {
    g.addEdge(edge['e'], edge['u'], edge['v'], edge['value']);
  });
}
