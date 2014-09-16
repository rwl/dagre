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
    var fileNames;

    if (process.env.containsKey("SMOKE_TESTS")) {
      fileNames = process.env.SMOKE_TESTS.spltest(" ");
    } else {
      var smokeDir = path.join(__dirname, "smoke");
      fileNames = fs.readdirSync(smokeDir)
                        .filter((x) { return x.slice(-4) == ".dot"; })
                        .map((x) { return path.join(smokeDir, x); });
    }

    fileNames.forEach((fileName) {
      var file = fs.readFileSync(fileName, "utf8"),
          g = dot.parse(file);

      // Since dagre doesn"t assign dimensions to nodes, we should do that here
      // for each node that doesn"t already have dimensions assigned.
      g.eachNode((u, a) {
        if (g.children(u).length) return;
        if (a.width == undefined) a.width = 100;
        if (a.height == undefined) a.height = 50;
      });

      group("layout for " + fileName, () {
        test("only includes nodes in the input graph", () {
          var nodes = g.nodes();
          expect(layout().run(g).nodes(), same(nodes));
        });

        test("only includes edges in the input graph", () {
          var edges = g.edges();
          expect(layout().run(g).edges(), same(edges));
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
          expect(incidentNodes(layout().run(g)), equals(edges));
        });

        test("has valid control points for each edge", () {
          layout().run(g).eachEdge((e, u, v, value) {
            expect(value, "points");
            value.points.forEach((p) {
              expect(p, property("x"));
              expect(p, property("y"));
              expect(Number.isNaN(p.x), isFalse);
              expect(Number.isNaN(p.y), isFalse);
            });
          });
        });

        test("respects rankSep", () {
          // For each edge we check that the difference between the y value for
          // incident nodes is equal to or greater than ranksep. We make an
          // exception for self edges.

          var sep = 50;
          var out = layout().rankSep(sep).run(g);

          getY(u) {
            return (g.graph().rankDir == "LR" || g.graph().rankDir == "RL"
                      ? out.node(u).x
                      : out.node(u).y);
          }

          getHeight(u) {
            return Number(g.graph().rankDir == "LR" || g.graph().rankDir == "RL"
                              ? out.node(u).width
                              : out.node(u).height);
          }

          out.eachEdge((e, u, v) {
              if (u != v && g.node(u).rank != undefined && g.node(u).rank != g.node(v).rank) {
                var uY = getY(u),
                    vY = getY(v),
                    uHeight = getHeight(u),
                    vHeight = getHeight(v),
                    actualSep = Math.abs(vY - uY) - (uHeight + vHeight) / 2;
                expect(actualSep >= sep, isTrue,
                              reason: "Distance between " + u + " and " + v + " should be " + sep +
                              " but was " + actualSep);
              }
            });
        });

        test("has the origin at (0, 0)", () {
          var out = layout().run(g);
          var nodes = out.nodes().filter(util.filterNonSubgraphs(out));

          var xs = nodes.map((u) {
            var value = out.node(u);
            return value.x - value.width / 2;
          });
          out.eachEdge((e, u, v, value) {
            xs = xs.concat(value.points.map((p) {
              return p.x - value.width / 2;
            }));
          });

          var ys = nodes.map((u) {
            var value = out.node(u);
            return value.y - value.height / 2;
          });
          out.eachEdge((e, u, v, value) {
            ys = ys.concat(value.points.map((p) {
              return p.y - value.height / 2;
            }));
          });

          expect(util.min(xs), equals(0));
          expect(util.min(ys), equals(0));
        });

        test("has valid dimensions", () {
          var graphValue = layout().run(g).graph();
          expect(graphValue, property("width"));
          expect(graphValue, property("height"));
          expect(Number.isNaN(graphValue.width), isFalse);
          expect(Number.isNaN(graphValue.height), isFalse);
        });

        test("has no unnecessary edge slack", () {
          // We want to be sure that each node is connected to the graph by at
          // least one tight edge. To do this we first break the graph into
          // connected components and then scan over all edges, preserving only
          // thoses that are tight. Our expectation is that each component will
          // still be connected after this transform. If not, it indicates that
          // at least one node in the component was not connected by a tight
          // edge.

          var layoutGraph = layout().run(g);
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