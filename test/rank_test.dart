part of dagre.test;

//var assert = require("./chai").assert,
//    dot = require("graphlib-dot"),
//    rank = require("../lib/rank");

rankTest() {
  group("rank", () {
    group("default", () {
      rankTests(false);
    });

    /*group("network simplex", () {
      rankTests(true);

      test("shortens two edges rather than one", () {
        // An example where the network simplex algorithm makes a difference.
        // The node "mover" could be in rank 1 or 2, but rank 2 minimizes the
        // weighted edge length sum because it shrinks 2 out-edges while lengthening
        // 1 in-edge.
        // Note that non-network simplex ranking doesn"t have to get this
        // one wrong, but it happens to do so because of the initial feasible
        // tree it builds.  That"s true in general.  Network simplex ranking
        // may provide a better answer because it repeatedly builds feasible
        // trees until it finds one without negative cut values.
        var g = parse("digraph { n1 -> n2 -> n3 -> n4;  n1 -> n5 -> n6 -> n7; " +
                                "n1 -> mover;  mover -> n4;  mover -> n7; }");

        runRank(g, true);

        expect(g.node("mover")['rank'], equals(2));
      });
    });*/
  });
}

rankTests(withSimplex) {
  test("assigns rank 0 to a node in a singleton graph", () {
    var g = parse("digraph { A }");

    runRank(g, withSimplex);

    expect(g.node("A")['rank'], equals(0));
  });

  test("assigns successive ranks to succesors", () {
    var g = parse("digraph { A -> B }");

    runRank(g, withSimplex);

    expect(g.node("A")['rank'], equals(0));
    expect(g.node("B")['rank'], equals(1));
  });

  test("assigns the minimum rank that satisfies all in-edges", () {
    // Note that C has in-edges from A and B, so it should be placed at a rank
    // below both of them.
    var g = parse("digraph { A -> B; B -> C; A -> C }");

    runRank(g, withSimplex);

    expect(g.node("A")['rank'], equals(0));
    expect(g.node("B")['rank'], equals(1));
    expect(g.node("C")['rank'], equals(2));
  });

  test("uses an edge\"s minLen attribute to determine rank", () {
    var g = parse("digraph { A -> B [minLen=2] }");

    runRank(g, withSimplex);

    expect(g.node("A")['rank'], equals(0));
    expect(g.node("B")['rank'], equals(2));
  });

  test("does not assign a rank to a subgraph node", () {
    var g = parse("digraph { subgraph sg1 { A } }");

    runRank(g, withSimplex);

    expect(g.node("A")['rank'], equals(0));
    expect(g.node("sg1"), isNot(contains("rank")));
  });

  test("ranks the \"min\" node before any adjacent nodes", () {
    var g = parse("digraph { A; B [prefRank=min]; C; A -> B -> C }");

    runRank(g, withSimplex);

    expect(g.node("B")['rank'] < g.node("A")['rank'], isTrue, reason: "rank of B not less than rank of A");
    expect(g.node("B")['rank'] < g.node("C")['rank'], isTrue, reason: "rank of B not less than rank of C");
  });

  test("ranks an unconnected \"min\" node at the level of source nodes", () {
    var g = parse("digraph { A; B [prefRank=min]; C; A -> C }");

    runRank(g, withSimplex);

    expect(g.node("B")['rank'], equals(g.node("A")['rank']));
    expect(g.node("B")['rank'] < g.node("C")['rank'], isTrue, reason: "rank of B not less than rank of C");
  });

  test("ensures that minLen is respected for nodes added to the min rank", () {
    var minLen = 2;
    var g = parse("digraph { B [prefRank=min]; A -> B [minLen=$minLen] }");

    runRank(g, withSimplex);

    expect(g.node("A")['rank'] - minLen >= g.node("B")['rank'], isTrue);
  });

  test("ranks the \"max\" node before any adjacent nodes", () {
    var g = parse("digraph { A; B [prefRank=max]; A -> B -> C }");

    runRank(g, withSimplex);

    expect(g.node("B")['rank'] > g.node("A")['rank'], isTrue, reason: "rank of B not greater than rank of A");
    expect(g.node("B")['rank'] > g.node("C")['rank'], isTrue, reason: "rank of B not greater than rank of C");
  });

  test("ranks an unconnected \"max\" node at the level of sinks nodes", () {
    var g = parse("digraph { A; B [prefRank=max]; A -> C }");

    runRank(g, withSimplex);

    expect(g.node("B")['rank'] > g.node("A")['rank'], isTrue, reason: "rank of B not greater than rank of A");
    expect(g.node("B")['rank'], equals(g.node("C")['rank']));
  });

  test("ensures that minLen is respected for nodes added to the max rank", () {
    var minLen = 2;
    var g = parse("digraph { A [prefRank=max]; A -> B [minLen=$minLen] }");

    runRank(g, withSimplex);

    expect(g.node("A")['rank'] - minLen >= g.node("B")['rank'], isTrue);
  });

  test("ensures that \"aax\" nodes are on the unorderedEquals rank as source nodes", () {
    var g = parse("digraph { A [prefRank=max]; B }");

    runRank(g, withSimplex);

    expect(g.node("A")['rank'], equals(g.node("B")['rank']));
  });

  test("gives the unorderedEquals rank to nodes with the unorderedEquals preference", () {
    var g = parse("digraph {" +
                    "A [prefRank=same_1]; B [prefRank=same_1];" +
                    "C [prefRank=same_2]; D [prefRank=same_2];" +
                    "A -> B; D -> C;" +
                  "}");

    runRank(g, withSimplex);

    expect(g.node("A")['rank'], equals(g.node("B")['rank']));
    expect(g.node("C")['rank'], equals(g.node("D")['rank']));
  });

//  test("does not apply rank constraints that are not min, max, same_*", () {
//    var g = parse("digraph { A [prefRank=foo]; B [prefRank=foo]; A -> B }");
//
//    // Disable console.error since we"re intentionally triggering it
//    var oldError = console.error;
//    var errors = [];
//    try {
//      console.error = (x) { errors.push(x); };
//      runRank(g, withSimplex);
//      expect(g.node("A")['rank'], equals(0));
//      expect(g.node("B")['rank'], equals(1));
//      expect(errors.length >= 1, isTrue);
//      expect(errors[0], equals("Unsupported rank type: foo"));
//    } finally {
//      console.error = oldError;
//    }
//  });

  test("does not introduce cycles when constraining ranks", () {
    var g = parse("digraph { A; B [prefRank=same_1]; C [prefRank=same_1]; A -> B; C -> A; }");

    // This will throw an error if a cycle is formed
    runRank(g, withSimplex);

    expect(g.node("B")['rank'], equals(g.node("C")['rank']));
  });

  test("returns a graph with edges all pointing to the unorderedEquals or successive ranks", () {
    // This should put B above A and without any other action would leave the
    // out edge from B point to an earlier rank.
    var g = parse("digraph { A -> B; B [prefRank=min]; }");

    runRank(g, withSimplex);

    expect(g.node("B")['rank'] < g.node("A")['rank'], isTrue);
    expect(g.successors("B"), unorderedEquals(["A"]));
    expect(g.successors("A"), unorderedEquals([]));
  });

  test("properly maintains the reversed edge state when reorienting edges", () {
    // Here we construct a cyclic graph and ensure that the edges are oriented
    // correctly after undoing the acyclic phase.
    var g = parse("digraph { A -> B -> C -> A; C [prefRank=min]; }");

    runRank(g, withSimplex);

    expect(g.node("C")['rank'] < g.node("A")['rank'], isTrue);
    expect(g.node("C")['rank'] < g.node("B")['rank'], isTrue);

    restoreEdges(g);

    expect(g.successors("A"), unorderedEquals(["B"]));
    expect(g.successors("B"), unorderedEquals(["C"]));
    expect(g.successors("C"), unorderedEquals(["A"]));
  });

  test("handles edge reversal correctly when collapsing nodes yields a cycle", () {
    // A and A2 get collapsed into a single node and the unorderedEquals happens for B and
    // B2. This yields a cycle between the A rank and the B rank and one of the
    // edges must be reversed. However, we want to be sure that the edge is
    // correct oriented when it comes out of the rank function.
    var g = parse("digraph {" +
                    "{ node [prefRank=same_A] A A2 }" +
                    "{ node [prefRank=same_B] B B2 }" +
                    "A -> B; B2 -> A2" +
                  "}");

    runRank(g, withSimplex);
    restoreEdges(g);

    expect(g.successors("A"), unorderedEquals(["B"]));
    expect(g.successors("A2"), unorderedEquals([]));
    expect(g.successors("B"), unorderedEquals([]));
    expect(g.successors("B2"), unorderedEquals(["A2"]));
  });

  test("yields unorderedEquals result with network simplex and without", () {
    // The primary purpose of this test is to exercise more of the network
    // simplex code resulting in better code coverage.
    var g = parse("digraph { n1 -> n3; n1 -> n4; n1 -> n5; n1 -> n6; n1 -> n7; " +
                  "n2 -> n3; n2 -> n4; n2 -> n5; n2 -> n6; n2 -> n7; }");

    runRank(g, withSimplex);

    expect(g.node("n1")['rank'], equals(0));
    expect(g.node("n2")['rank'], equals(0));
    expect(g.node("n3")['rank'], equals(1));
    expect(g.node("n4")['rank'], equals(1));
    expect(g.node("n5")['rank'], equals(1));
    expect(g.node("n6")['rank'], equals(1));
    expect(g.node("n7")['rank'], equals(1));
  });
}

/**
 * Parses the given DOT string into a graph and performs some intialization
 * required for using the rank algorithm.
 */
Digraph parse(String str) {
  var g = dot.parse(str);

  // The rank algorithm requires that edges have a `minLen` attribute
  g.eachEdge((e, u, v, value) {
    if (!(value.containsKey("minLen"))) {
      value['minLen'] = 1;
    }
  });

  return g;
}
