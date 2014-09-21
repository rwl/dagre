part of dagre;
//"use strict";
//
//var util = require("./util");

/*
 * The algorithms here are based on Brandes and Köpf, "Fast and Simple
 * Horizontal Coordinate Assignment".
 */
//module.exports = function() {
class Position {
  // External configuration
  /*var config = {
    'nodeSep': 50,
    'edgeSep': 10,
    'universalSep': null,
    'rankSep': 30
  };*/
  num nodeSep = 50;
  num edgeSep = 10;
  num universalSep = null;
  num rankSep = 30;

//  var self = {};

//  self.nodeSep = util.propertyAccessor(self, config, "nodeSep");
//  self.edgeSep = util.propertyAccessor(self, config, "edgeSep");
  //num get nodeSep => config['nodeSep'];
  //num get edgeSep => config['edgeSep'];

  // If not null this separation value is used for all nodes and edges
  // regardless of their widths. `nodeSep` and `edgeSep` are ignored with this
  // option.
//  self.universalSep = util.propertyAccessor(self, config, "universalSep");
//  self.rankSep = util.propertyAccessor(self, config, "rankSep");
//  self.debugLevel = util.propertyAccessor(self, config, "debugLevel");
  //num get universalSep => config['universalSep'];
  //num get rankSep => config['rankSep'];
  //num get debugLevel => config['debugLevel'];
  int debugLevel = 0;

//  self.run = run;

//  return self;

  run(BaseGraph g) {
    g = g.filterNodes(util.filterNonSubgraphs(g));

    List layering = util.ordering(g);

    final conflicts = findConflicts(g, layering);

    final xss = {};
    ["u", "d"].forEach((vertDir) {
      if (vertDir == "d") {
        //layering.reverse();
//        print(layering);
        layering.setAll(0, layering.reversed.toList());
//        print(layering);
      }

      ["l", "r"].forEach((horizDir) {
        if (horizDir == "r") reverseInnerOrder(layering);

        var dir = vertDir + horizDir;
//        print(layering);
//        print(conflicts);
        Map align = verticalAlignment(g, layering, conflicts,
                                      vertDir == "u" ? "predecessors" : "successors");
//        print(align);
        xss[dir] = horizontalCompaction(g, layering, align['pos'], align['root'], align['align']);
//        print(xss[dir]);

        if (debugLevel >= 3) {
          debugPositioning(vertDir + horizDir, g, layering, xss[dir]);
        }

        if (horizDir == "r") flipHorizontally(xss[dir]);

        if (horizDir == "r") reverseInnerOrder(layering);
      });

      if (vertDir == "d") {
        //layering.reverse();
        layering.setAll(0, layering.reversed.toList());
      }
    });

    balance(g, layering, xss);

    g.eachNode((v, _) {
      var xs = [];
      for (var alignment in xss.keys) {
        var alignmentX = xss[alignment][v];
        posXDebug(alignment, g, v, alignmentX);
        xs.add(alignmentX);
      }
      xs.sort((x, y) { return x - y; });
      posX(g, v, (xs[1] + xs[2]) / 2);
    });

    // Align y coordinates with ranks
    var y = 0, reverseY = g.graph()['rankDir'] == "BT" || g.graph()['rankDir'] == "RL";
    layering.forEach((layer) {
      num maxHeight = util.max(layer.map((u) { return height(g, u); }));
      if (maxHeight == null) maxHeight = double.NAN;
      y += maxHeight / 2;
      layer.forEach((u) {
        posY(g, u, reverseY ? -y : y);
      });
      y += maxHeight / 2 + this.rankSep;
    });

    // Translate layout so that top left corner of bounding rectangle has
    // coordinate (0, 0).
    var minX = util.min(g.nodes().map((u) { return posX(g, u) - width(g, u) / 2; }));
    var minY = util.min(g.nodes().map((u) { return posY(g, u) - height(g, u) / 2; }));
    g.eachNode((u, _) {
      posX(g, u, posX(g, u) - minX);
      posY(g, u, posY(g, u) - minY);
    });
  }

  /**
   * Generate an ID that can be used to represent any undirected edge that is
   * incident on `u` and `v`.
   */
  undirEdgeId(u, v) {
    //return u < v
    return u.toString().compareTo(v.toString()) < 0
      ? "${u.toString().length}:$u-$v"
      : "${v.toString().length}:$v-$u";
  }

  Map findConflicts(g, layering) {
    var conflicts = {}, // Set of conflicting edge ids
        pos = {},       // Position of node in its layer
        prevLayer,
        currLayer,
        k0,     // Position of the last inner segment in the previous layer
        l,      // Current position in the current layer (for iteration up to `l1`)
        k1;     // Position of the next inner segment in the previous layer or
                // the position of the last element in the previous layer

    if (layering.length <= 2) return conflicts;

    updateConflicts(v) {
      var k = pos[v];
      if (k < k0 || k > k1) {
        conflicts[undirEdgeId(currLayer[l], v)] = true;
      }
    }

    int i = 0;
    layering[1].forEach((u) {
      pos[u] = i;
      i++;
    });
    for (var i = 1; i < layering.length - 1; ++i) {
      prevLayer = layering[i];
      currLayer = layering[i+1];
      k0 = 0;
      l = 0;

      // Scan current layer for next node that is incident to an inner segement
      // between layering[i+1] and layering[i].
      for (var l1 = 0; l1 < currLayer.length; ++l1) {
        var u = currLayer[l1]; // Next inner segment in the current layer or
                               // last node in the current layer
        pos[u] = l1;
        k1 = null;

        if (g.node(u).containsKey('dummy') && g.node(u)['dummy']) {
          var uPred = g.predecessors(u).length > 0 ? g.predecessors(u)[0] : null;
          // Note: In the case of self loops and sideways edges it is possible
          // for a dummy not to have a predecessor.
          if (uPred != null && g.node(uPred).containsKey('dummy') && g.node(uPred)['dummy'])
            k1 = pos[uPred];
        }
        if (k1 == null && l1 == currLayer.length - 1)
          k1 = prevLayer.length - 1;

        if (k1 != null) {
          for (; l <= l1; ++l) {
            g.predecessors(currLayer[l]).forEach(updateConflicts);
          }
          k0 = k1;
        }
      }
    }

    return conflicts;
  }

  Map verticalAlignment(Digraph g, List layering, Map conflicts, String relationship) {
    Map pos = {},   // Position for a node in its layer
        root = {},  // Root of the block that the node participates in
        align = {}; // Points to the next node in the block or, if the last
                    // element in the block, points to the first block"s root

    layering.forEach((layer) {
      int i = 0;
      layer.forEach((u) {
        root[u] = u;
        align[u] = u;
        pos[u] = i;
        i++;
      });
    });

    layering.forEach((layer) {
      int prevIdx = -1;
      layer.forEach((v) {
        var related,// = g[relationship](v), // Adjacent nodes from the previous layer
            mid;                          // The mid point in the related array
        if (relationship == "predecessors") related = g.predecessors(v);
        else if (relationship == "successors") related = g.successors(v);

        if (related.length > 0) {
          related.sort((x, y) { return pos[x] - pos[y]; });
          mid = (related.length - 1) / 2;
          related.sublist(mid.floor(), mid.floor() + mid.ceil() + 1).forEach((u) {
            if (align[v] == v) {
              if (conflicts[undirEdgeId(u, v)] == null && prevIdx < pos[u]) {
                align[u] = v;
                align[v] = root[v] = root[u];
                prevIdx = pos[u];
              }
            }
          });
        }
      });
    });

    return { 'pos': pos, 'root': root, 'align': align };
  }

  // This function deviates from the standard BK algorithm in two ways. First
  // it takes into account the size of the nodes. Second it includes a fix to
  // the original algorithm that is described in Carstens, "Node and Label
  // Placement in a Layered Layout Algorithm".
  horizontalCompaction(BaseGraph g, List layering, pos, root, align) {
    var sink = {},       // Mapping of node id -> sink node id for class
        maybeShift = {}, // Mapping of sink node id -> { class node id, min shift }
        shift = {},      // Mapping of sink node id -> shift
        pred = {},       // Mapping of node id -> predecessor node (or null)
        xs = {};         // Calculated X positions

    layering.forEach((layer) {
      int i = 0;
      layer.forEach((u) {
        sink[u] = u;
        maybeShift[u] = {};
        if (i > 0) {
          pred[u] = layer[i - 1];
        }
        i++;
      });
    });

    updateShift(toShift, neighbor, delta) {
      if (!(maybeShift[toShift].containsKey(neighbor))) {
        maybeShift[toShift][neighbor] = delta;
      } else {
        maybeShift[toShift][neighbor] = Math.min(maybeShift[toShift][neighbor], delta);
      }
    }

    placeBlock(v) {
      if (!(xs.containsKey(v))) {
        xs[v] = 0;
        var w = v;
        do {
          if (pos[w] > 0) {
            var u = root[pred[w]];
            placeBlock(u);
            if (sink[v] == v) {
              sink[v] = sink[u];
            }
            var delta = sep(g, pred[w]) + sep(g, w);
            if (sink[v] != sink[u]) {
              updateShift(sink[u], sink[v], xs[v] - xs[u] - delta);
            } else {
              xs[v] = Math.max(xs[v], xs[u] + delta);
            }
          }
          w = align[w];
        } while (w != v);
      }
    }

    // Root coordinates relative to sink
    root.values.forEach((v) {
      placeBlock(v);
    });

    // Absolute coordinates
    // There is an assumption here that we"ve resolved shifts for any classes
    // that begin at an earlier layer. We guarantee this by visiting layers in
    // order.
    layering.forEach((layer) {
      layer.forEach((v) {
        xs[v] = xs[root[v]];
        if (v == root[v] && v == sink[v]) {
          var minShift = 0;
          if (maybeShift.containsKey(v) && maybeShift[v].keys.length > 0) {
            minShift = util.min(maybeShift[v].keys
                                 .map((u) {
                                      return maybeShift[v][u] + (shift.containsKey(u) ? shift[u] : 0);
                                      }
                                 ));
          }
          shift[v] = minShift;
        }
      });
    });

    layering.forEach((layer) {
      layer.forEach((v) {
        xs[v] += (shift[sink[root[v]]] != null ? shift[sink[root[v]]] : 0);
      });
    });

    return xs;
  }

  findMinCoord(BaseGraph g, List layering, Map xs) {
    return util.min(layering.map((layer) {
      var u = layer[0];
      return xs[u];
    }));
  }

  findMaxCoord(BaseGraph g, List layering, xs) {
    return util.max(layering.map((layer) {
      var u = layer[layer.length - 1];
      return xs[u];
    }));
  }

  balance(BaseGraph g, List layering, Map xss) {
    var min = {},                            // Min coordinate for the alignment
        max = {},                            // Max coordinate for the alginment
        smallestAlignment,
        shift = {},                          // Amount to shift a given alignment
        alignment;

    updateAlignment(v, _) {
//      print(xss[alignment][v]);
//      if (xss[alignment][v] == null) {
//        print(xss);
//        print(alignment);
//        print(v);
//      }
      xss[alignment][v] += shift[alignment];
    }

    var smallest = double.INFINITY;
    for (alignment in xss.keys) {
      Map xs = xss[alignment];
      min[alignment] = findMinCoord(g, layering, xs);
      max[alignment] = findMaxCoord(g, layering, xs);
      var w = max[alignment] - min[alignment];
      if (w < smallest) {
        smallest = w;
        smallestAlignment = alignment;
      }
    }

    // Determine how much to adjust positioning for each alignment
    ["u", "d"].forEach((vertDir) {
      ["l", "r"].forEach((horizDir) {
        var alignment = vertDir + horizDir;
        shift[alignment] = horizDir == "l"
            ? min[smallestAlignment] - min[alignment]
            : max[smallestAlignment] - max[alignment];
      });
    });

    // Find average of medians for xss array
    for (alignment in xss.keys) {
      g.eachNode(updateAlignment);
    }
  }

  flipHorizontally(Map xs) {
    for (var u in xs.keys) {
      xs[u] = -xs[u];
    }
  }

  reverseInnerOrder(layering) {
    layering.forEach((List layer) {
      layer.setAll(0, layer.reversed.toList());
    });
  }

  width(BaseGraph g, u) {
    num r;
    switch (g.graph()['rankDir']) {
      case "LR": r = g.node(u)['height']; break;
      case "RL": r = g.node(u)['height']; break;
      default:   r = g.node(u)['width'];
    }
    if (r == null) r = double.NAN;
    return r;
  }

  height(BaseGraph g, u) {
    num r;
    switch(g.graph()['rankDir']) {
      case "LR": r = g.node(u)['width']; break;
      case "RL": r = g.node(u)['width']; break;
      default:   r = g.node(u)['height'];
    }
    if (r == null) r = double.NAN;
    return r;
  }

  sep(BaseGraph g, u) {
    if (universalSep != null) {
      return universalSep;
    }
    var w = width(g, u);
    var s = g.node(u).containsKey('dummy') && g.node(u)['dummy'] ? edgeSep : nodeSep;
    return (w + s) / 2;
  }

  posX(BaseGraph g, u, [x=null]) {
    if (g.graph()['rankDir'] == "LR" || g.graph()['rankDir'] == "RL") {
      if (x == null) {
        return g.node(u)['y'];
      } else {
        g.node(u)['y'] = x;
      }
    } else {
      if (x == null) {
        return g.node(u)['x'];
      } else {
        g.node(u)['x'] = x;
      }
    }
  }

  posXDebug(name, BaseGraph g, u, [x=null]) {
    if (g.graph()['rankDir'] == "LR" || g.graph()['rankDir'] == "RL") {
      if (x == null) {
        return g.node(u)[name];
      } else {
        g.node(u)[name] = x;
      }
    } else {
      if (x == null) {
        return g.node(u)[name];
      } else {
        g.node(u)[name] = x;
      }
    }
  }

  posY(BaseGraph g, u, [y=null]) {
    if (g.graph()['rankDir'] == "LR" || g.graph()['rankDir'] == "RL") {
      if (y == null) {
        return g.node(u)['x'];
      } else {
        g.node(u)['x'] = y;
      }
    } else {
      if (y == null) {
        return g.node(u)['y'];
      } else {
        g.node(u)['y'] = y;
      }
    }
  }

  debugPositioning(align, BaseGraph g, layering, xs) {
    layering.forEach((l, li) {
      var u, xU;
      l.forEach((v) {
        var xV = xs[v];
        if (u) {
          var s = sep(g, u) + sep(g, v);
          if (xV - xU < s)
            print("Position phase: sep violation. Align: $align. Layer: $li. " +
              "U: $u V: $v. Actual sep: ${xV - xU} Expected sep: $s");
        }
        u = v;
        xU = xV;
      });
    });
  }
}
