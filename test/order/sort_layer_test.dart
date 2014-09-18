part of dagre.order.test;

sortLayerTest() {
  group("sortLayer", () {
    var g;

    setUp(() {
      g = new CDigraph();
      g.graph({});
    });

    test("sorts based on barycenters", () {
      // We set the initial order of the movable layer [1, 2, 3] in reverse order
      // and expect the ordering algorithm to put them in the correct order
      // using the barycenter algorithm.

      g.addNode(1, { 'rank': 0, 'order': 2 });
      g.addNode(2, { 'rank': 0, 'order': 1 });
      g.addNode(3, { 'rank': 0, 'order': 0 });

      var layerGraphs = initLayerGraphs(g);

      sortLayer(layerGraphs[0],
                null,
                { 1: [0], 2: [1], 3: [2] });

      expect(g.node(1)['order'], equals(0));
      expect(g.node(2)['order'], equals(1));
      expect(g.node(3)['order'], equals(2));
    });

    test("handles multiple weights", () {
      // We expect that multiple edges from the fixed layer to influence the
      // barycenters for the movable nodes. In this test we add multiple weights
      // to node 3 so that it should come before node 2.

      g.addNode(1, { 'rank': 0, 'order': 2 });
      g.addNode(2, { 'rank': 0, 'order': 1 });
      g.addNode(3, { 'rank': 0, 'order': 0 });

      var layerGraphs = initLayerGraphs(g);

      sortLayer(layerGraphs[0],
                null,
                { 1: [0], 2: [2], 3: [0, 1, 2] });

      expect(g.node(1)['order'], equals(0));
      expect(g.node(2)['order'], equals(2));
      expect(g.node(3)['order'], equals(1));
    });

    test("handles a single subgraph", () {
      // We expect that nodes 1 and 2 will be adjacent since they are in the
      // same subgraph, even though they"d otherwise be at opposite ends of the
      // layer. The subgraph gets a weight of 1, which means it should come
      // before node 3.

      g.addNode(1, { 'rank': 0, 'order': 0 });
      g.addNode(2, { 'rank': 0, 'order': 1 });
      g.addNode(3, { 'rank': 0, 'order': 2 });
      g.addNode("sg1", {});
      g.parent(1, "sg1");
      g.parent(2, "sg1");

      var layerGraphs = initLayerGraphs(g);

      sortLayer(layerGraphs[0],
                null,
                { 1: [0, 0], 2: [2, 2], 3: [1, 2] });

      expect(g.node(1)['order'], equals(0));
      expect(g.node(2)['order'], equals(1));
      expect(g.node(3)['order'], equals(2));
      expect(g.node("sg1"), isNot(contains("order")));
    });

    test("handles nested subgraphs", () {
      g.addNode(1, { 'rank': 0 });
      g.addNode(2, { 'rank': 0 });
      g.addNode(3, { 'rank': 0 });
      g.addNode(4, { 'rank': 0 });
      g.addNode(5, { 'rank': 0 });
      g.addNode("sg2", {});
      g.parent(2, "sg2");
      g.parent(3, "sg2");
      g.addNode("sg1", {});
      g.parent(1, "sg1");
      g.parent("sg2", "sg1");
      g.parent(4, "sg1");

      var layerGraphs = initLayerGraphs(g);

      sortLayer(layerGraphs[0],
                null,
                { 1: [4], 2: [3], 3: [7], 4: [6], 5: [6] });

      expect(g.node(1)['order'], equals(0));
      expect(g.node(2)['order'], equals(1));
      expect(g.node(3)['order'], equals(2));
      expect(g.node(4)['order'], equals(3));
      expect(g.node(5)['order'], equals(4));
      expect(g.node("sg1"), isNot(contains("order")));
      expect(g.node("sg2"), isNot(contains("order")));
    });

    test("returns a constraint graph for the next layer", () {
      g.addNode(1, { 'rank': 0 });
      g.addNode(2, { 'rank': 0 });
      g.addNode(3, { 'rank': 0 });
      g.addNode(4, { 'rank': 0 });
      g.addNode("sg1", {});
      g.addNode("sg2", {});
      g.addNode("sg3", {});
      g.parent(1, "sg1");
      g.parent(2, "sg2");
      g.parent(3, "sg3");
      g.parent(4, "sg3");

      var cg = sortLayer(initLayerGraphs(g)[0],
                         null,
                         { 1 : [1], 2: [2], 3: [3], 4: [4] });

      // Ordering should have sg1 < sg2 < sg3. The constraint graph should thus
      // have sg1 -> sg2 -> sg3;
      expect(g.node(1)['order'], equals(0));
      expect(g.node(2)['order'], equals(1));
      expect(g.node(3)['order'], equals(2));
      expect(g.node(4)['order'], equals(3));
      expect(cg.nodes(), unorderedEquals(["sg1", "sg2", "sg3"]));
      expect(cg.successors("sg1"), unorderedEquals(["sg2"]));
      expect(cg.successors("sg2"), unorderedEquals(["sg3"]));
      expect(cg.successors("sg3"), unorderedEquals([]));
    });

    test("returns a constraint graph a layer with nested subgraphs", () {
      g.addNode(1, { 'rank': 0 });
      g.addNode(2, { 'rank': 0 });
      g.addNode(3, { 'rank': 0 });
      g.addNode("sg1", {});
      g.addNode("sg2", {});
      g.addNode("sg3", {});
      g.addNode("sg4", {});
      g.parent("sg3", "sg1");
      g.parent("sg4", "sg1");
      g.parent(1, "sg3");
      g.parent(2, "sg4");
      g.parent(3, "sg2");

      var cg = sortLayer(initLayerGraphs(g)[0],
                         null,
                         { 1: [1], 2: [2], 3: [3] });

      // Ordering will have sg3 < sg4 and sg1 < sg2. The constraint graph should
      // thus have sg3 -> sg4 and sg1 -> sg2.
      expect(g.node(1)['order'], equals(0));
      expect(g.node(2)['order'], equals(1));
      expect(g.node(3)['order'], equals(2));
      expect(cg.nodes(), unorderedEquals(["sg1", "sg2", "sg3", "sg4"]));
      expect(cg.successors("sg1"), unorderedEquals(["sg2"]));
      expect(cg.successors("sg2"), unorderedEquals([]));
      expect(cg.successors("sg3"), unorderedEquals(["sg4"]));
      expect(cg.successors("sg4"), unorderedEquals([]));
    });

    test("respects the constraint graph", () {
      g.addNode(1, { 'rank': 0 });
      g.addNode(2, { 'rank': 0 });
      g.addNode("sg1", {});
      g.parent(1, "sg1");
      g.addNode("sg2", {});
      g.parent(2, "sg2");

      var layerGraphs = initLayerGraphs(g);

      var cg = new Digraph();
      cg.addNode("sg1");
      cg.addNode("sg2");
      cg.addEdge(null, "sg1", "sg2");

      sortLayer(layerGraphs[0],
                cg,
                { 1: [2], 2: [1] });

      expect(g.node(1)['order'], equals(0));
      expect(g.node(2)['order'], equals(1));
    });
  });
}