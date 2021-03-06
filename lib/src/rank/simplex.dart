part of dagre.rank;

simplex(BaseGraph graph, BaseGraph spanningTree) {
  // The network simplex algorithm repeatedly replaces edges of
  // the spanning tree with negative cut values until no such
  // edge exists.
  initCutValues(graph, spanningTree);
  while (true) {
    var e = leaveEdge(spanningTree);
    if (e == null) break;
    var f = enterEdge(graph, spanningTree, e);
    exchange(graph, spanningTree, e, f);
  }
}

/**
 * Set the cut values of edges in the spanning tree by a depth-first
 * postorder traversal.  The cut value corresponds to the cost, in
 * terms of a ranking"s edge length sum, of lengthening an edge.
 * Negative cut values typically indicate edges that would yield a
 * smaller edge length sum if they were lengthened.
 */
initCutValues(BaseGraph graph, Digraph spanningTree) {
  computeLowLim(spanningTree);

  spanningTree.eachEdge((id, u, v, Map treeValue) {
    treeValue['cutValue'] = 0;
  });

  // Propagate cut values up the tree.
  dfs(n) {
    var children = spanningTree.successors(n);
    for (var c in children) {
      var child = c;//TODO children[c];
      dfs(child);
    }
    if (n != spanningTree.graph()['root']) {
      setCutValue(graph, spanningTree, n);
    }
  }
  dfs(spanningTree.graph()['root']);
}

/**
 * Perform a DFS postorder traversal, labeling each node v with
 * its traversal order "lim(v)" and the minimum traversal number
 * of any of its descendants "low(v)".  This provides an efficient
 * way to test whether u is an ancestor of v since
 * low(u) <= lim(v) <= lim(u) if and only if u is an ancestor.
 */
computeLowLim(Digraph tree) {
  int postOrderNum = 0;

  dfs(n) {
    var children = tree.successors(n);
    var low = postOrderNum;
    for (var c in children) {
      var child = c;//TODO children[c];
      dfs(child);
      low = Math.min(low, tree.node(child)['low']);
    }
    tree.node(n)['low'] = low;
    tree.node(n)['lim'] = postOrderNum++;
  }

  dfs(tree.graph()['root']);
}

/**
 * To compute the cut value of the edge parent -> child, we consider
 * it and any other graph edges to or from the child.
 *          parent
 *             |
 *           child
 *          /      \
 *         u        v
 */
setCutValue(Digraph graph, Digraph tree, child) {
  var parentEdge = tree.inEdges(child)[0];

  // List of child"s children in the spanning tree.
  final grandchildren = [];
  var grandchildEdges = tree.outEdges(child);
  for (var gce in grandchildEdges) {
    grandchildren.add(tree.target(gce));//TODO grandchildEdges[gce]));
  }

  int cutValue = 0;

  // TODO: Replace unit increment/decrement with edge weights.
  int E = 0;    // Edges from child to grandchild"s subtree.
  int F = 0;    // Edges to child from grandchild"s subtree.
  int G = 0;    // Edges from child to nodes outside of child"s subtree.
  int H = 0;    // Edges from nodes outside of child"s subtree to child.

  // Consider all graph edges from child.
  var outEdges = graph.outEdges(child);
  var gc;
  for (var oe in outEdges) {
    var succ = graph.target(oe);//TODO outEdges[oe]);
    for (gc in grandchildren) {
      if (inSubtree(tree, succ, gc/*TODO grandchildren[gc]*/)) {
        E++;
      }
    }
    if (!inSubtree(tree, succ, child)) {
      G++;
    }
  }

  // Consider all graph edges to child.
  var inEdges = graph.inEdges(child);
  for (var ie in inEdges) {
    var pred = graph.source(ie);//TODO inEdges[ie]);
    for (gc in grandchildren) {
      if (inSubtree(tree, pred, gc/*TODO grandchildren[gc]*/)) {
        F++;
      }
    }
    if (!inSubtree(tree, pred, child)) {
      H++;
    }
  }

  // Contributions depend on the alignment of the parent -> child edge
  // and the child -> u or v edges.
  int grandchildCutSum = 0;
  for (gc in grandchildren) {
    var cv = tree.edge(gc/*TODO grandchildEdges[gc]*/)['cutValue'];
    if (!tree.edge(gc/*TODO grandchildEdges[gc]*/)['reversed']) {
      grandchildCutSum += cv;
    } else {
      grandchildCutSum -= cv;
    }
  }

  if (tree.edge(parentEdge)['reversed'] == null || !tree.edge(parentEdge)['reversed']) {
    cutValue += grandchildCutSum - E + F - G + H;
  } else {
    cutValue -= grandchildCutSum - E + F - G + H;
  }

  tree.edge(parentEdge)['cutValue'] = cutValue;
}

/**
 * Return whether n is a node in the subtree with the given
 * root.
 */
inSubtree(tree, n, root) {
  return (tree.node(root)['low'] <= tree.node(n)['lim'] &&
          tree.node(n)['lim'] <= tree.node(root)['lim']);
}

/**
 * Return an edge from the tree with a negative cut value, or null if there
 * is none.
 */
leaveEdge(tree) {
  var edges = tree.edges();
  for (var n in edges) {
    var e = n;//TODO edges[n];
    Map treeValue = tree.edge(e);
    if (treeValue['cutValue'] < 0) {
      return e;
    }
  }
  return null;
}

/**
 * The edge e should be an edge in the tree, with an underlying edge
 * in the graph, with a negative cut value.  Of the two nodes incident
 * on the edge, take the lower one.  enterEdge returns an edge with
 * minimum slack going from outside of that node"s subtree to inside
 * of that node"s subtree.
 */
enterEdge(BaseGraph graph, Digraph tree, e) {
  var source = tree.source(e);
  var target = tree.target(e);
  var lower = tree.node(target)['lim'] < tree.node(source)['lim'] ? target : source;

  // Is the tree edge aligned with the graph edge?
  var aligned = !tree.edge(e)['reversed'];

  var minSlack = double.INFINITY;
  var minSlackEdge = null;
  if (aligned) {
    graph.eachEdge((id, u, v, Map value) {
      if (id != e && inSubtree(tree, u, lower) && !inSubtree(tree, v, lower)) {
        var slack = rankUtil.slack(graph, u, v, value['minLen']);
        if (slack < minSlack) {
          minSlack = slack;
          minSlackEdge = id;
        }
      }
    });
  } else {
    graph.eachEdge((id, u, v, Map value) {
      if (id != e && !inSubtree(tree, u, lower) && inSubtree(tree, v, lower)) {
        var slack = rankUtil.slack(graph, u, v, value['minLen']);
        if (slack < minSlack) {
          minSlack = slack;
          minSlackEdge = id;
        }
      }
    });
  }

  if (minSlackEdge == null) {
    var outside = [];
    var inside = [];
    graph.eachNode((id, _) {
      if (!inSubtree(tree, id, lower)) {
        outside.add(id);
      } else {
        inside.add(id);
      }
    });
    throw new Exception("No edge found from outside of tree to inside");
  }

  return minSlackEdge;
}

/**
 * Replace edge e with edge f in the tree, recalculating the tree root,
 * the nodes" low and lim properties and the edges" cut values.
 */
exchange(Digraph graph, tree, e, f) {
  tree.delEdge(e);
  var source = graph.source(f);
  var target = graph.target(f);

  // Redirect edges so that target is the root of its subtree.
  redirect(v) {
    var edges = tree.inEdges(v);
    for (var i in edges) {
      var e = edges[i];
      var u = tree.source(e);
      var value = tree.edge(e);
      redirect(u);
      tree.delEdge(e);
      value['reversed'] = !value['reversed'];
      tree.addEdge(e, v, u, value);
    }
  }

  redirect(target);

  var root = source;
  var edges = tree.inEdges(root);
  while (edges.length > 0) {
    root = tree.source(edges[0]);
    edges = tree.inEdges(root);
  }

  tree.graph()['root'] = root;

  tree.addEdge(null, source, target, {'cutValue': 0});

  initCutValues(graph, tree);

  adjustRanks(graph, tree);
}

/**
 * Reset the ranks of all nodes based on the current spanning tree.
 * The rank of the tree"s root remains unchanged, while all other
 * nodes are set to the sum of minimum length constraints along
 * the path from the root.
 */
adjustRanks(BaseGraph graph, Digraph tree) {
  dfs(p) {
    var children = tree.successors(p);
    children.forEach((c) {
      var minLen = minimumLength(graph, p, c);
      graph.node(c)['rank'] = graph.node(p)['rank'] + minLen;
      dfs(c);
    });
  }

  dfs(tree.graph()['root']);
}

/**
 * If u and v are connected by some edges in the graph, return the
 * minimum length of those edges, as a positive number if v succeeds
 * u and as a negative number if v precedes u.
 */
minimumLength(Digraph graph, u, v) {
  var outEdges = graph.outEdges(u, v);
  if (outEdges.length > 0) {
    return util.max(outEdges.map((e) {
      return graph.edge(e)['minLen'];
    }));
  }

  var inEdges = graph.inEdges(u, v);
  if (inEdges.length > 0) {
    return -util.max(inEdges.map((e) {
      return graph.edge(e)['minLen'];
    }));
  }
}
