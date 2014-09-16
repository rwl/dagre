part of dagre.rank.test;

//var assert = require("../chai").assert,
//    dot = require("graphlib-dot"),
//    acyclic = require("../../lib/rank/acyclic"),
//    isAcyclic = require("graphlib").alg.isAcyclic,
//    findCycles = require("graphlib").alg.findCycles;

acyclicTest() {
  group("acyclic", () {
    test("does not change acyclic graphs", () {
      var g = dot.parse("digraph { A -> B; C }");
      acyclic(g);
      expect(g.nodes().sort(), equals(["A", "B", "C"]));
      expect(g.successors("A"), equals(["B"]));
      assertAcyclic(g);
    });

    test("reverses edges to make the graph acyclic", () {
      var g = dot.parse("digraph { A -> B [id=AB]; B -> A [id=BA] }");
      expect(isAcyclic(g), isFalse);
      acyclic(g);
      expect(g.nodes().sort(), equals(["A", "B"]));
      expect(g.source("AB"), not(equals(g.target("AB"))));
      expect(g.target("AB"), equals(g.target("BA")));
      expect(g.source("AB"), equals(g.source("BA")));
      assertAcyclic(g);
    });

    test("warns if there are self loops", () {
      var g = dot.parse("digraph { A -> A [id=AA]; }");

      // Disable console.error since we"re intentionally triggering it
      var oldError = console.error;
      var errors = [];
      try {
        console.error = (x) { errors.push(x); };
        acyclic(g);
        expect(errors.length >= 1, isTrue);
        expect(errors[0], equals("Warning: found self loop 'AA' for node 'A'"));
      } finally {
        console.error = oldError;
      }
    });

    test("is a reversible process", () {
      var g = dot.parse("digraph { A -> B [id=AB]; B -> A [id=BA] }");
      g.graph({});
      acyclic(g);
      acyclic.undo(g);
      expect(g.nodes().sort(), equals(["A", "B"]));
      expect(g.source("AB"), equals("A"));
      expect(g.target("AB"), equals("B"));
      expect(g.source("BA"), equals("B"));
      expect(g.target("BA"), equals("A"));
    });

    test("works for multiple cycles", () {
      var g = dot.parse("digraph {" +
                          "A -> B -> A;" +
                          "B -> C -> D -> E -> C;" +
                          "G -> C;" +
                          "G -> H -> G;" +
                          "H -> I -> J }");
      expect(isAcyclic(g), isFalse);
      acyclic(g);
      assertAcyclic(g);
    });
  });
}

assertAcyclic(g) {
  expect(findCycles(g), equals([]), reason: "Found one or more cycles in the actual graph");
}
