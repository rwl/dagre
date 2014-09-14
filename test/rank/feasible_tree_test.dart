import 'package:unittest/unittest.dart';

//var assert = require("../chai").assert,
//    Digraph = require("graphlib").Digraph,
//    feasibleTree = require("../../lib/rank/feasibleTree");

feasibleTreeTest() {
  group("feasibleTree", () {
    test("creates a tree for a trivial input graph", () {
      var g = new Digraph();
      g.addNode("a", { rank: 0 });
      g.addNode("b", { rank: 1 });
      g.addEdge(null, "a", "b", { minLen: 1 });
      feasibleTree(g);
      expect(g.node("b").rank, equals(g.node("a").rank + 1));
    });

    test("respects multiple minLens for a pair of nodes", () {
      var g = new Digraph();
      g.addNode("a", { rank: 0 });
      g.addNode("b", { rank: 6 });
      g.addEdge(null, "a", "b", { minLen: 1 });
      g.addEdge(null, "a", "b", { minLen: 2 });
      g.addEdge(null, "a", "b", { minLen: 6 });
      feasibleTree(g);
      expect(g.node("b").rank, equals(g.node("a").rank + 6));
    });

    test("tightens edges with slack", () {
      var g = new Digraph();
      g.addNode("a", { rank: 0 });
      g.addNode("b", { rank: 12 });
      g.addNode("c", { rank: 1 });
      g.addEdge(null, "a", "b", { minLen: 6 });
      g.addEdge(null, "a", "c", { minLen: 1 });
      feasibleTree(g);
      expect(g.node("b").rank, equals(g.node("a").rank + 6));
      // This wasn"t tightened, but should not have changed either
      expect(g.node("c").rank, equals(g.node("a").rank + 1));
    });

    test("correctly constructs a feasible tree", () {
      // This example came from marcello3d. The previous feasibleTree
      // implementation incorrectly shifted just the the node being added to
      // the tree, which broke the scan for edges with minimum slack.
      var g = new Digraph();
      g.addNode("a", { rank: 0 });
      g.addNode("b", { rank: 6 });
      g.addNode("c", { rank: 0 });
      g.addNode("d", { rank: 2 });
      g.addNode("e", { rank: 4 });
      g.addEdge(null, "a", "b", { minLen: 2 });
      g.addEdge(null, "c", "b", { minLen: 2 });
      g.addEdge(null, "c", "d", { minLen: 2 });
      g.addEdge(null, "d", "e", { minLen: 2 });
      g.addEdge(null, "e", "b", { minLen: 2 });
      feasibleTree(g);

      expect(g.node("d").rank, equals(g.node("c").rank + 2));
      expect(g.node("e").rank, equals(g.node("c").rank + 4));
      expect(g.node("b").rank, equals(g.node("c").rank + 6));
    });
  });
}