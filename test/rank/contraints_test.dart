part of dagre.rank.test;

//var assert = require("../chai").assert;
//
//var constraints = require("../../lib/rank/constraints");
//
//var CDigraph = require("graphlib").CDigraph;

constraintsTest() {
  group("constraints", () {
    var g;

    setUp(() {
      g = new CDigraph();
      g.graph({});
    });

    group("apply", () {
      test("does not change unconstrained nodes", () {
        g.addNode(1, {});
        constraints.apply(g);
        expect(g.nodes(), equals([1]));
      });

      test("collapses nodes with prefRank=min", () {
        g.addNode(1, {});
        g.addNode(2, { ['prefRank']: "min" });
        g.addNode(3, { ['prefRank']: "min" });
        g.addNode(4, {});
        g.addEdge("A", 1, 2, { ['minLen']: 2 });
        g.addEdge("B", 3, 4, { ['minLen']: 4 });

        constraints.apply(g);
        expect(g.nodes().length, equals(3));
        expect(g.nodes(), contains([1, 4]));

        // We should end up with a collapsed min node pointing at 1 and 4 with
        // correct minLen and reversed flags.
        var min = g.nodes().filter((u) { return u != 1 && u != 4; })[0];
        expect(g.inEdges(min).length, equals(0), reason: "there should be no in-edges to the min node");

        expect(g.outEdges(min, 1).length, equals(1));
        var eMin1 = g.outEdges(min, 1);
        expect(g.edge(eMin1), containsPair("minLen", 2));
        expect(g.edge(eMin1), containsPair("reversed", true));

        expect(g.outEdges(min, 4).length, equals(1));
        var eMin4 = g.outEdges(min, 4);
        expect(g.edge(eMin4), containsPair("minLen", 4));
        expect(g.edge(eMin4), isNot(contains("reversed")));
      });

      test("collapses nodes with prefRank=max", () {
        g.addNode(1, {});
        g.addNode(2, { ['prefRank']: "max" });
        g.addNode(3, { ['prefRank']: "max"});
        g.addNode(4, {});
        g.addEdge("A", 1, 2, { ['minLen']: 2 });
        g.addEdge("B", 3, 4, { ['minLen']: 4 });

        constraints.apply(g);
        expect(g.nodes().length, equals(3));
        expect(g.nodes(), contains([1, 4]));

        // We should end up with a collapsed nax node pointed at by 1 and 4 with
        // correct minLen and reversed flags.
        var max = g.nodes().filter((u) { return u != 1 && u != 4; })[0];
        expect(g.outEdges(max).length, equals(0), reason: "there should be no out-edges from the max node");

        expect(g.outEdges(1, max).length, equals(1));
        var eMax1 = g.outEdges(1, max);
        expect(g.edge(eMax1), containsPair("minLen", 2));
        expect(g.edge(eMax1), isNot(contains("reversed")));

        expect(g.outEdges(4, max).length, equals(1));
        var eMax4 = g.outEdges(4, max);
        expect(g.edge(eMax4), containsPair("minLen", 4));
        expect(g.edge(eMax4), containsPair("reversed", true));
      });

      test("collapses nodes with prefRank=same_x", () {
        g.addNode(1, {});
        g.addNode(2, { ['prefRank']: "same_x" });
        g.addNode(3, { ['prefRank']: "same_x"});
        g.addNode(4, {});
        g.addEdge("A", 1, 2, { ['minLen']: 2 });
        g.addEdge("B", 3, 4, { ['minLen']: 4 });

        constraints.apply(g);
        expect(g.nodes().length, equals(3));
        expect(g.nodes(), contains([1, 4]));

        var x = g.nodes().filter((u) { return u != 1 && u != 4; })[0];

        expect(g.outEdges(1, x).length, equals(1));
        var eSame1 = g.outEdges(1, x);
        expect(g.edge(eSame1), containsPair("minLen", 2));

        expect(g.outEdges(x, 4).length, equals(1));
        var eSame4 = g.outEdges(x, 4);
        expect(g.edge(eSame4), containsPair("minLen", 4));
      });

      test("does not apply rank constraints that are not min, max, same_*", () {
        g.addNode(1, {});
        g.addNode(2, { ['prefRank']: "foo" });
        g.addNode(3, { ['prefRank']: "foo"});
        g.addNode(4, {});
        g.addEdge("A", 1, 2, { ['minLen']: 2 });
        g.addEdge("B", 3, 4, { ['minLen']: 4 });

        // Disable console.error since we"re intentionally triggering it
//        var oldError = console.error;
//        var errors = [];
//        try {
//          console.error = (x) { errors.push(x); };
//          constraints.apply(g);
//          expect(g.nodes(), unorderedEquals([1, 2, 3, 4]));
//          expect(errors.length >= 1, isTrue);
//          expect(errors[0], equals("Unsupported rank type: foo"));
//        } finally {
//          console.error = oldError;
//        }
      });

      test("applies rank constraints to each subgraph separately", () {
        g.addNode("sg1", {});
        g.addNode("sg2", {});

        g.parent(g.addNode(1, {}), "sg1");
        g.parent(g.addNode(2, { ['prefRank']: "min" }), "sg1");
        g.parent(g.addNode(3, { ['prefRank']: "min"}), "sg1");
        g.addEdge("A", 1, 2, { ['minLen']: 1 });

        g.parent(g.addNode(4, {}), "sg2");
        g.parent(g.addNode(5, { ['prefRank']: "min" }), "sg2");
        g.parent(g.addNode(6, { ['prefRank']: "min" }), "sg2");
        g.addEdge("B", 4, 5, { ['minLen']: 1 });

        constraints.apply(g);
        expect(g.nodes().length, equals(6)); // 2 SGs + 2 nodes / SG
        expect(g.nodes(), contains([1, 4]));

        // Collapsed min node should be different for sg1 and sg2
        expect(g.children("sg1").length, equals(2));
        expect(g.children("sg2").length, equals(2));
      });
    });

    group("relax", () {
      test("restores expands collapsed nodes and sets the rank on expanded nodes", () {
        g.addNode(1, {});
        g.addNode(2, { ['prefRank']: "same_x" });
        g.addNode(3, { ['prefRank']: "same_x"});
        g.addNode(4, {});
        g.addEdge("A", 1, 2, { ['minLen']: 2 });
        g.addEdge("B", 3, 4, { ['minLen']: 4 });

        constraints.apply(g);

        var x = g.nodes().where((u) { return u != 1 && u != 4; }).toList()[0];
        g.node(1)['rank'] = 0;
        g.node(x)['rank'] = 2;
        g.node(4)['rank'] = 6;

        constraints.relax(g);

        expect(g.nodes(), unorderedEquals([1, 2, 3, 4]));
        expect(g.node(1), containsPair("rank", 0));
        expect(g.node(2), containsPair("rank", 2));
        expect(g.node(3), containsPair("rank", 2));
        expect(g.node(4), containsPair("rank", 6));
        expect(g.edges(), unorderedEquals(["A", "B"]));
        expect(g.target("A"), equals(2));
        expect(g.source("B"), equals(3));
      });

      test("correctly restores edge endpoints for edges pointing at two collapsed nodes", () {
        g.addNode(1, { ['prefRank']: "min" });
        g.addNode(2, { ['prefRank']: "max" });
        g.addEdge("A", 1, 2, { ['minLen']: 1 });
        g.addEdge("B", 2, 1, { ['minLen']: 1 });

        constraints.apply(g);

        expect(g.nodes().length, equals(2));
        g.node(g.nodes()[0])['rank'] = 0;
        g.node(g.nodes()[1])['rank'] = 1;

        constraints.relax(g);

        expect(g.edges(), unorderedEquals(["A", "B"]));
        expect(g.source("A"), equals(1));
        expect(g.target("A"), equals(2));
        expect(g.source("B"), equals(2));
        expect(g.target("B"), equals(1));
      });

      test("restores expanded nodes to their original subgraph", () {
        g.addNode("sg1", {});
        g.addNode("sg2", {});

        g.parent(g.addNode(1, {}), "sg1");
        g.parent(g.addNode(2, { ['prefRank']: "min" }), "sg1");
        g.parent(g.addNode(3, { ['prefRank']: "min"}), "sg1");
        g.addEdge("A", 1, 2, { ['minLen']: 1 });

        g.parent(g.addNode(4, {}), "sg2");
        g.parent(g.addNode(5, { ['prefRank']: "min" }), "sg2");
        g.parent(g.addNode(6, { ['prefRank']: "min" }), "sg2");
        g.addEdge("B", 4, 5, { ['minLen']: 1 });

        constraints.apply(g);

        g.node(1)['rank'] = 0;
        g.node(g.children("sg1").where((u) { return u != 1; }).toList()[0])['rank'] = 2;
        g.node(4)['rank'] = 0;
        g.node(g.children("sg2").where((u) { return u != 4; }).toList()[0])['rank'] = 2;

        constraints.relax(g);

        expect(g.children("sg1"), unorderedEquals([1, 2, 3]));
        expect(g.children("sg2"), unorderedEquals([4, 5, 6]));
      });
    });
  });
}