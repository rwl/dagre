import 'package:unittest/unittest.dart';

//var assert = require("./chai").assert,
//    CDigraph = require("graphlib").CDigraph,
//    order = require("../lib/order"),
//    crossCount = require("../lib/order/crossCount");

orderTest() {
  group("order", () {
    var g;

    beforeEach(() {
      g = new CDigraph();
      g.graph({});
    });

    test("sets order = 0 for a single node", () {
      g.addNode(1, { rank: 0 });
      order(g);
      expect(g.node(1).order, equals(0));
    });

    test("sets order = 0 for 2 connected nodes on different ranks", () {
      g.addNode(1, { rank: 0 });
      g.addNode(2, { rank: 1 });
      g.addEdge(null, 1, 2);

      order(g);

      expect(g.node(1).order, equals(0));
      expect(g.node(2).order, equals(0));
    });

    test("sets order = 0 for 2 unconnected nodes on different ranks", () {
      g.addNode(1, { rank: 0 });
      g.addNode(2, { rank: 1 });

      order(g);

      expect(g.node(1).order, equals(0));
      expect(g.node(2).order, equals(0));
    });

    test("sets order = 0, 1 for 2 nodes on the same rank", () {
      g.addNode(1, { rank: 0 });
      g.addNode(2, { rank: 0 });

      order(g);

      expect(g.nodes().map((u) { return g.node(u).order; }), same([0, 1]));
    });

    test("does not assign an order to a subgraph itself", () {
      g.addNode(1, {rank: 0});
      g.addNode(2, {rank: 1});
      g.addNode("sg1", {});
      g.parent(2, "sg1");

      order(g);

      expect(g.node("sg1"), notProperty("order"));
    });

    /*
    test("keeps nodes in a subgraph adjacent in a single layer", () {
      // To test, we set up a total order for the top rank which will cause us to
      // yield suboptimal crossing reduction if we keep the subgraph together in
      // the bottom rank.
      g.addNode(1, {rank: 0});
      g.addNode(2, {rank: 0});
      g.addNode(3, {rank: 0});
      g.addNode(4, {rank: 1});
      g.addNode(5, {rank: 1});
      g.addNode(6, {rank: 1});
      g.addNode("sg1", {minRank: 1, maxRank: 1});
      g.parent(4, "sg1");
      g.parent(5, "sg1");
      g.addEdge(null, 1, 4);
      g.addEdge(null, 1, 6);
      g.addEdge(null, 2, 6);
      g.addEdge(null, 3, 5);
      g.addEdge(null, 3, 6);

      // Now set up the total order
      var cg = new Digraph();
      cg.addNode(1);
      cg.addNode(2);
      cg.addNode(3);
      cg.addEdge(null, 1, 2);
      cg.addEdge(null, 2, 3);

      order().run(g);

      // Node 4 and 5 should be adjacent since they are both in sg1
      assert.closeTo(g.node(4).order, g.node(5).order, 1.0,
        "Node 4 and 5 should have been adjacent. order(4): " + g.node(4).order +
        " order(5): " + g.node(5).order);

      // Now check that we found an optimal solution
      expect(crossCount(g), 2);
    });
    */

    group("finds minimial crossings", () {
      test("graph1", () {
        g.addNode(1, { rank: 0 });
        g.addNode(2, { rank: 0 });
        g.addNode(3, { rank: 1 });
        g.addNode(4, { rank: 1 });
        g.addEdge(null, 1, 4);
        g.addEdge(null, 2, 3);

        order(g);

        expect(crossCount(g), equals(0));
      });

      test("graph2", () {
        g.addNode(1, { rank: 0 });
        g.addNode(2, { rank: 0 });
        g.addNode(3, { rank: 0 });
        g.addNode(4, { rank: 1 });
        g.addNode(5, { rank: 1 });
        g.addEdge(null, 1, 4);
        g.addEdge(null, 2, 4);
        g.addEdge(null, 2, 5);
        g.addEdge(null, 3, 4);
        g.addEdge(null, 3, 5);

        order(g);

        expect(crossCount(g), equals(1));
      });

      test("graph3", () {
        g.addNode(1, { rank: 0 });
        g.addNode(2, { rank: 0 });
        g.addNode(3, { rank: 0 });
        g.addNode(4, { rank: 1 });
        g.addNode(5, { rank: 1 });
        g.addNode(6, { rank: 1 });
        g.addNode(7, { rank: 2 });
        g.addNode(8, { rank: 2 });
        g.addNode(9, { rank: 2 });
        g.addEdge(null, 1, 5);
        g.addEdge(null, 2, 4);
        g.addEdge(null, 3, 6);
        g.addEdge(null, 4, 9);
        g.addEdge(null, 5, 8);
        g.addEdge(null, 6, 7);

        order(g);

        expect(crossCount(g), equals(0));
      });
    });
  });
}