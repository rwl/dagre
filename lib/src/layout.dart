part of dagre;
//"use strict";
//
//var util = require("./util"),
//    rank = require("./rank"),
//    order = require("./order"),
//    CGraph = require("graphlib").CGraph,
//    CDigraph = require("graphlib").CDigraph;

//module.exports = function() {
class Layout {
  // External configuration
//  var config = {
//    // How much debug information to include?
//    'debugLevel': 0,
//    // Max number of sweeps to perform in order phase
//    'orderMaxSweeps': order.DEFAULT_MAX_SWEEPS,
//    // Use network simplex algorithm in ranking
//    'rankSimplex': false,
//    // Rank direction. Valid values are (TB, LR)
//    'rankDir': "TB"
//  };


  // How much debug information to include?
  int _debugLevel = 0;
  // Max number of sweeps to perform in order phase
  int orderMaxSweeps = DEFAULT_MAX_SWEEPS;
  // Use network simplex algorithm in ranking
  bool rankSimplex = false;
  // Rank direction. Valid values are (TB, LR)
  String rankDir = "TB";

  // Phase functions
  final position = new Position();

  // This layout object
//  var self = {};

//  self.orderIters = util.propertyAccessor(self, config, "orderMaxSweeps");
  //Object get orderIters => config['orderMaxSweeps'];

//  self.rankSimplex = util.propertyAccessor(self, config, "rankSimplex");
  //Object get rankSimplex => config['rankSimplex'];

//  self.nodeSep = delegateProperty(position.nodeSep);
  Object get nodeSep => position.nodeSep;
  void set nodeSep(num val) { position.nodeSep = val; }
//  self.edgeSep = delegateProperty(position.edgeSep);
  Object get edgeSep => position.edgeSep;
//  self.universalSep = delegateProperty(position.universalSep);
  Object get universalSep => position.universalSep;
//  self.rankSep = delegateProperty(position.rankSep);
  num get rankSep => position.rankSep;
  void set rankSep(num val) { position.rankSep = val; }
//  self.rankDir = util.propertyAccessor(self, config, "rankDir");
  //Object get rankDir => config.rankDir;
  //void set rankDir(val) { config.rankDir = val; }
//  self.debugAlignment = delegateProperty(position.debugAlignment);
  //Object get debugAlignment => position.debugAlignment;

  int get debugLevel => _debugLevel;
  void set debugLevel(int x) {
    _debugLevel = x;
    util.log_level = x;
    position.debugLevel = x;
  }

//  var run = util.time("Total layout", run);

//  var _normalize = normalize;

//  return self;

  /**
   * Constructs an adjacency graph using the nodes and edges specified through
   * config. For each node and edge we add a property `dagre` that contains an
   * object that will hold intermediate and final layout information. Some of
   * the contents include:
   *
   *  1) A generated ID that uniquely identifies the object.
   *  2) Dimension information for nodes (copied from the source node).
   *  3) Optional dimension information for edges.
   *
   * After the adjacency graph is constructed the code no longer needs to use
   * the original nodes and edges passed in via config.
   */
  CDigraph initLayoutGraph(BaseGraph inputGraph) {
    final g = new CDigraph();

    inputGraph.eachNode((u, value) {
      if (value == null) value = {};
      g.addNode(u, {
        'width': value['width'],
        'height': value['height']
      });
      if (value.containsKey("rank")) {
        g.node(u)['prefRank'] = value['rank'];
      }
    });

    // Set up subgraphs
    if (inputGraph.isCompound()) {
      inputGraph.nodes().forEach((u) {
        g.parent(u, inputGraph.parent(u));
      });
    }

    inputGraph.eachEdge((e, u, v, value) {
      if (value == null) value = {};
      var newValue = {
        'e': e,
        'minLen': value.containsKey('minLen') ? value['minLen'] : 1,
        'width': value.containsKey('width') ? value['width'] : 0,
        'height': value.containsKey('height') ? value['height'] : 0,
        'points': []
      };

      g.addEdge(null, u, v, newValue);
    });

    // Initial graph attributes
    var graphValue = inputGraph.graph() != null ? inputGraph.graph() : {};
    g.graph({
      'rankDir': graphValue.containsKey('rankDir') ? graphValue['rankDir'] : rankDir,
      'orderRestarts': graphValue['orderRestarts']
    });

    return g;
  }

  BaseGraph run(BaseGraph inputGraph) {
    var rankSep = this.rankSep;
    CDigraph g;
    try {
      // Build internal graph
      g = util.time("initLayoutGraph", () => initLayoutGraph(inputGraph));

      if (g.order() == 0) {
        return g;
      }

      // Make space for edge labels
      g.eachEdge((e, s, t, a) {
        a['minLen'] *= 2;
      });
      this.rankSep = rankSep / 2;

      // Determine the rank for each node. Nodes with a lower rank will appear
      // above nodes of higher rank.
      util.time("rank.run", () => runRank(g, this.rankSimplex));

      // Normalize the graph by ensuring that every edge is proper (each edge has
      // a length of 1). We achieve this by adding dummy nodes to long edges,
      // thus shortening them.
      util.time("normalize", () => normalize(g));

      // Order the nodes so that edge crossings are minimized.
      util.time("order", () => order(g, this.orderMaxSweeps));

      // Find the x and y coordinates for every node in the graph.
      util.time("position", () => position.run(g));

      // De-normalize the graph by removing dummy nodes and augmenting the
      // original long edges with coordinate information.
      util.time("undoNormalize", () => undoNormalize(g));

      // Reverses points for edges that are in a reversed state.
      util.time("fixupEdgePoints", () => fixupEdgePoints(g));

      // Restore delete edges and reverse edges that were reversed in the rank
      // phase.
      util.time("rank.restoreEdges", () => restoreEdges(g));

      // Construct final result graph and return it
      return util.time("createFinalGraph", () => createFinalGraph(g, inputGraph.isDirected()));
    } finally {
      this.rankSep = rankSep;
    }
  }

  /**
   * This function is responsible for "normalizing" the graph. The process of
   * normalization ensures that no edge in the graph has spans more than one
   * rank. To do this it inserts dummy nodes as needed and links them by adding
   * dummy edges. This function keeps enough information in the dummy nodes and
   * edges to ensure that the original graph can be reconstructed later.
   *
   * This method assumes that the input graph is cycle free.
   */
  normalize(g) {
    var dummyCount = 0;
    g.eachEdge((e, s, t, a) {
      var sourceRank = g.node(s)['rank'];
      var targetRank = g.node(t)['rank'];
      if (sourceRank + 1 < targetRank) {
        var u = s;
        for (var rank = sourceRank + 1, i = 0; rank < targetRank; ++rank, ++i) {
          var v = "_D${++dummyCount}";
          var node = {
            'width': a['width'],
            'height': a['height'],
            'edge': { 'id': e, 'source': s, 'target': t, 'attrs': a },
            'rank': rank,
            'dummy': true
          };

          // If this node represents a bend then we will use it as a control
          // point. For edges with 2 segments this will be the center dummy
          // node. For edges with more than two segments, this will be the
          // first and last dummy node.
          if (i == 0) node['index'] = 0;
          else if (rank + 1 == targetRank) node['index'] = 1;

          g.addNode(v, node);
          g.addEdge(null, u, v, {});
          u = v;
        }
        g.addEdge(null, u, t, {});
        g.delEdge(e);
      }
    });
  }

  /**
   * Reconstructs the graph as it was before normalization. The positions of
   * dummy nodes are used to build an array of points for the original "long"
   * edge. Dummy nodes and edges are removed.
   */
  undoNormalize(g) {
    g.eachNode((u, a) {
      if (a.containsKey('dummy') && a['dummy']) {
        if (a.containsKey("index")) {
          Map edge = a['edge'];
          if (!g.hasEdge(edge['id'])) {
            g.addEdge(edge['id'], edge['source'], edge['target'], edge['attrs']);
          }
          List points = g.edge(edge['id'])['points'];
          int i = a['index'];
          if (i >= points.length) {
            points = new List(i + 1)..setAll(0, points.toList());
            g.edge(edge['id'])['points'] = points;
          }
          points[a['index']] = { 'x': a['x'], 'y': a['y'],
                                 'ul': a['ul'], 'ur': a['ur'],
                                 'dl': a['dl'], 'dr': a['dr'] };
        }
        g.delNode(u);
      }
    });
  }

  /**
   * For each edge that was reversed during the `acyclic` step, reverse its
   * array of points.
   */
  fixupEdgePoints(BaseGraph g) {
    g.eachEdge((e, s, t, Map a) {
      if (a['reversed'] != null && a['reversed']) {
//        a['points'].reverse();
        a['points'].setAll(0, a['points'].reversed.toList());
      }
    });
  }

  BaseGraph createFinalGraph(BaseGraph g, isDirected) {
    var out = isDirected ? new CDigraph() : new CGraph();
    out.graph(g.graph());
    g.eachNode((u, value) { out.addNode(u, value); });
    g.eachNode((u, _) { out.parent(u, g.parent(u)); });
    g.eachEdge((e, u, v, Map value) {
      out.addEdge(value['e'], u, v, value);
    });

    // Attach bounding box information
    var maxX = 0, maxY = 0;
    g.eachNode((u, Map value) {
      if (g.children(u).length == 0) {
        final w = value['width'] != null ? value['width'] : double.NAN;
        final h = value['height'] != null ? value['height'] : double.NAN;
        maxX = Math.max(maxX, value['x'] + w / 2);
        maxY = Math.max(maxY, value['y'] + h / 2);
      }
    });
    g.eachEdge((e, u, v, Map value) {
      var maxXPoints = value['points'].map((p) { return p['x']; }).reduce(Math.max);
      var maxYPoints = value['points'].map((p) { return p['y']; }).reduce(Math.max);
      maxX = Math.max(maxX, maxXPoints + value['width'] / 2);
      maxY = Math.max(maxY, maxYPoints + value['height'] / 2);
    });
    out.graph()['width'] = maxX;
    out.graph()['height'] = maxY;

    return out;
  }

  /*
   * Given a function, a new function is returned that invokes the given
   * function. The return value from the function is always the `self` object.
   */
//  delegateProperty(f) {
//    return () {
//      if (!arguments.length) return f();
//      f.apply(null, arguments);
//      return self;
//    };
//  }
}

