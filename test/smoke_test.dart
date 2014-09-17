part of dagre.test;

//var assert = require("./chai").assert,
//    util = require("../lib/util"),
//    dot = require("graphlib-dot"),
//    layout = require("..").layout,
//    components = require("graphlib").alg.components,
//    nodesFromList = require("graphlib").filter.nodesFromList,
//    path = require("path"),
//    fs = require("fs");

smokeTest() {
  group("smoke tests", () {
    List<String> fileNames;

    if (Platform.environment.containsKey("SMOKE_TESTS")) {
      fileNames = Platform.environment['SMOKE_TESTS'].split(" ");
    } else {
      final smokeDir = new Directory(path.join(Uri.base.toFilePath(), "smoke"));
      fileNames = smokeDir.listSync(followLinks: false)
                        .where((x) { return FileSystemEntity.isFileSync(x.path); })
                        .map((x) { return x.path; })
                        .where((x) { return x.slice(-4) == ".dot"; })
                        .map((x) { return path.join(smokeDir.path, x); });
    }

    fileNames.forEach((fileName) {
      final file = new File(fileName);
      Digraph g;
      try {
        final contents = file.readAsStringSync();
        g = dot.parse(contents);
      } on FileSystemException catch (e) {
        fail(e.message);
        return null;
      }

      // Since dagre doesn"t assign dimensions to nodes, we should do that here
      // for each node that doesn"t already have dimensions assigned.
      g.eachNode((u, Map a) {
        if (g.children(u).length != 0) return;
        if (a['width'] == null) a['width'] = 100;
        if (a['height'] == null) a['height'] = 50;
      });

      group("layout for " + fileName, () {
        test("only includes nodes in the input graph", () {
          var nodes = g.nodes();
          expect(new Layout().run(g).nodes(), same(nodes));
        });

        test("only includes edges in the input graph", () {
          var edges = g.edges();
          expect(new Layout().run(g).edges(), same(edges));
        });

        test("has the same incident nodes for each edge", () {
          incidentNodes(g) {
            var edges = {};
            g.edges().forEach((e) {
              edges[e] = g.incidentNodes(e);
            });
            return edges;
          }

          var edges = incidentNodes(g);
          expect(incidentNodes(new Layout().run(g)), equals(edges));
        });

        test("has valid control points for each edge", () {
          new Layout().run(g).eachEdge((e, u, v, value) {
            expect(value, "points");
            value.points.forEach((p) {
              expect(p, contains("x"));
              expect(p, contains("y"));
              expect(p['x'].isNaN, isFalse);
              expect(p['y'].isNaN, isFalse);
            });
          });
        });

        test("respects rankSep", () {
          // For each edge we check that the difference between the y value for
          // incident nodes is equal to or greater than ranksep. We make an
          // exception for self edges.

          var sep = 50;
          var out = (new Layout()..rankSep = sep).run(g);

          getY(u) {
            return (g.graph().rankDir == "LR" || g.graph().rankDir == "RL"
                      ? out.node(u).x
                      : out.node(u).y);
          }

          getHeight(u) {
            return (g.graph().rankDir == "LR" || g.graph().rankDir == "RL"
                              ? out.node(u)['width']
                              : out.node(u)['height']).toDouble();
          }

          out.eachEdge((e, u, v, _) {
              if (u != v && g.node(u)['rank'] != null && g.node(u)['rank'] != g.node(v)['rank']) {
                var uY = getY(u),
                    vY = getY(v),
                    uHeight = getHeight(u),
                    vHeight = getHeight(v),
                    actualSep = (vY - uY).abs() - (uHeight + vHeight) / 2;
                expect(actualSep >= sep, isTrue,
                              reason: "Distance between $u and $v should be $sep but was $actualSep");
              }
            });
        });

        test("has the origin at (0, 0)", () {
          BaseGraph out = new Layout().run(g);
          final nodes = out.nodes().where(util.filterNonSubgraphs(out));

          final xs = nodes.map((u) {
            var value = out.node(u);
            return value.x - value.width / 2;
          });
          out.eachEdge((e, u, v, Map value) {
            xs.addAll(value['points'].map((p) {
              return p.x - value['width'] / 2;
            }));
          });

          final ys = nodes.map((u) {
            var value = out.node(u);
            return value.y - value.height / 2;
          });
          out.eachEdge((e, u, v, value) {
            ys.addAll(value.points.map((p) {
              return p.y - value.height / 2;
            }));
          });

          expect(util.min(xs), equals(0));
          expect(util.min(ys), equals(0));
        });

        test("has valid dimensions", () {
          Map graphValue = new Layout().run(g).graph();
          expect(graphValue, contains("width"));
          expect(graphValue, contains("height"));
          expect(graphValue['width'].isNaN, isFalse);
          expect(graphValue['height'].isNaN, isFalse);
        });

        test("has no unnecessary edge slack", () {
          // We want to be sure that each node is connected to the graph by at
          // least one tight edge. To do this we first break the graph into
          // connected components and then scan over all edges, preserving only
          // thoses that are tight. Our expectation is that each component will
          // still be connected after this transform. If not, it indicates that
          // at least one node in the component was not connected by a tight
          // edge.

          var layoutGraph = new Layout().run(g);
          components(layoutGraph).forEach((cmpt) {
            var subgraph = layoutGraph.filterNodes(nodesFromList(cmpt));
            subgraph.eachEdge((e, u, v, value) {
              if (value.minLen != (layoutGraph.node(u).rank - layoutGraph.node(v).rank).abs() &&
                  layoutGraph.node(u).prefRank != layoutGraph.node(v).prefRank) {
                subgraph.delEdge(e);
              }
            });

            expect(components(subgraph).length, equals(1));
          });
        });
      });
    });
  });
}