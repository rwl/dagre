part of dagre.rank.test;

buildWeightGraphTest() {
  group("buildWeightGraph", () {
    Digraph g;

    setUp(() {
      g = new Digraph();
    });

    test("returns an directed graph", () {
      g.addNode(1);

      var result = buildWeightGraph(g);
      expect(result.isDirected(), isTrue);
    });

    test("returns a singleton graph for a singleton input graph", () {
      g.addNode(1);

      var result = buildWeightGraph(g);
      expect(result.nodes(), same(g.nodes()));
    });

    test("returns a weight of 1 for a single forward edge", () {
      g.addNode(1);
      g.addNode(2);
      g.addEdge(null, 1, 2, {});

      var result = buildWeightGraph(g);
      expect(result.edges().length, equals(1));
      expect(result.edge(result.edges().first)['weight'], equals(1));
    });

    test("returns a weight of -1 for a single back edge", () {
      g.addNode(1);
      g.addNode(2);
      g.addEdge(null, 1, 2, { 'reversed': true });

      var result = buildWeightGraph(g);
      expect(result.edges().length, equals(1));
      expect(result.edge(result.edges().first)['weight'], equals(-1));
    });

    test("returns a weight of n for an n count forward multi-edge", () {
      g.addNode(1);
      g.addNode(2);

      var n = 3;
      for (var i = 0; i < 3; ++i) {
        g.addEdge(null, 1, 2, {});
      }

      var result = buildWeightGraph(g);
      expect(result.edges().length, equals(1));
      expect(result.edge(result.edges().first)['weight'], equals(n));
    });

    test("returns a weight of -n for an n count back multi-edge", () {
      g.addNode(1);
      g.addNode(2);

      var n = 3;
      for (var i = 0; i < 3; ++i) {
        g.addEdge(null, 1, 2, { 'reversed': true });
      }

      var result = buildWeightGraph(g);
      expect(result.edges().length, equals(1));
      expect(result.edge(result.edges().first)['weight'], equals(-n));
    });

    test("sets the minLen to the max minLen of edges in the original graph", () {
      g.addNode(1);
      g.addNode(2);
      g.addEdge(null, 1, 2, { 'minLen': 1 });
      g.addEdge(null, 1, 2, { 'minLen': 2 });
      g.addEdge(null, 1, 2, { 'minLen': 5 });

      var result = buildWeightGraph(g);
      expect(result.edges().length, equals(1));
      expect(result.edge(result.edges().first)['minLen'], equals(5));
    });

    test("sets the minLen to a negative value if the edge is reversed", () {
      g.addNode(1);
      g.addNode(2);
      g.addEdge(null, 1, 2, { 'minLen': 1, 'reversed': true });
      g.addEdge(null, 1, 2, { 'minLen': 3, 'reversed': true });

      var result = buildWeightGraph(g);
      expect(result.edges().length, equals(1));
      expect(result.edge(result.edges().first)['minLen'], equals(-3));
    });

    test("handles multiple edges across nodes", () {
      g.addNode(1);
      g.addNode(2);
      g.addNode(3);

      g.addEdge(null, 1, 2, { 'minLen': 2, 'reversed': true });
      g.addEdge(null, 1, 3, { 'minLen': 4 });
      g.addEdge(null, 1, 3, { 'minLen': 6 });

      var result = buildWeightGraph(g);
      expect(result.edges().length, equals(2));

      var e12, e13;
      var firstTarget = result.incidentNodes(result.edges()[0])[1];
      if (firstTarget == 2) {
        e12 = result.edges()[0];
        e13 = result.edges()[1];
      } else {
        e12 = result.edges()[1];
        e13 = result.edges()[0];
      }

      expect(result.edge(e12)['weight'], equals(-1));
      expect(result.edge(e13)['weight'], equals(2));
      expect(result.edge(e12)['minLen'], equals(-2));
      expect(result.edge(e13)['minLen'], equals(6));
    });
  });
}