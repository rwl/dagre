part of dagre.order.test;

initLayerGraphsTest() {
  group("initLayerGraphs", () {
    var g;

    setUp(() {
      g = new CDigraph();
      g.graph({});
    });

    test("constructs a 1-level graph for a flat graph", () {
      g.addNode(1, { 'rank': 0 });
      g.addNode(2, { 'rank': 0 });
      g.addNode(3, { 'rank': 0 });

      var layerGraphs = initLayerGraphs(g);

      expect(layerGraphs, isNull);
      expect(layerGraphs.length, equals(1));
      expect(layerGraphs[0].nodes(), same([1, 2, 3]));
      expect(layerGraphs[0].children(null), same([1, 2, 3]));
    });

    test("constructs a 2-level graph for a single layer", () {
      g.addNode(1, { 'rank': 0 });
      g.addNode(2, { 'rank': 0 });
      g.addNode(3, { 'rank': 0 });
      g.addNode("sg1", {});
      g.parent(2, "sg1");

      var layerGraphs = initLayerGraphs(g);

      expect(layerGraphs, isNull);
      expect(layerGraphs.length, equals(1));
      expect(layerGraphs[0].nodes(), same([1, 2, 3, "sg1"]));
      expect(layerGraphs[0].children(null), same([1, 3, "sg1"]));
      expect(layerGraphs[0].children("sg1"), same([2]));
    });

    test("constructs 2 layers for a 2-layer graph", () {
      g.addNode(1, { 'rank': 0 });
      g.addNode(2, { 'rank': 0 });
      g.addNode(3, { 'rank': 0 });
      g.addNode(4, { 'rank': 1 });
      g.addNode(5, { 'rank': 1 });
      g.addNode("sg1", {});
      g.parent(2, "sg1");
      g.parent(5, "sg1");

      var layerGraphs = initLayerGraphs(g);

      expect(layerGraphs, isNull);
      expect(layerGraphs.length, equals(2));

      expect(layerGraphs[0].nodes(), same([1, 2, 3, "sg1"]));
      expect(layerGraphs[0].children(null), same([1, 3, "sg1"]));
      expect(layerGraphs[0].children("sg1"), same([2]));

      expect(layerGraphs[1].nodes(), same([4, 5, "sg1"]));
      expect(layerGraphs[1].children(null), same([4, "sg1"]));
      expect(layerGraphs[1].children("sg1"), same([5]));
    });

    test("handles multiple nestings", () {
      g.addNode(1, { 'rank': 0 });
      g.addNode(2, { 'rank': 0 });
      g.addNode(3, { 'rank': 0 });
      g.addNode(4, { 'rank': 1 });
      g.addNode(5, { 'rank': 1 });
      g.addNode(6, { 'rank': 1 });
      g.addNode("sg1", {});
      g.addNode("sg2", {});
      g.parent(1, "sg2");
      g.parent(4, "sg2");
      g.parent(2, "sg1");
      g.parent(5, "sg1");
      g.parent("sg2", "sg1");

      var layerGraphs = initLayerGraphs(g);

      expect(layerGraphs, isNull);
      expect(layerGraphs.length, equals(2));

      expect(layerGraphs[0].nodes(), same([1, 2, 3, "sg1", "sg2"]));
      expect(layerGraphs[0].children(null), same([3, "sg1"]));
      expect(layerGraphs[0].children("sg1"), same([2, "sg2"]));
      expect(layerGraphs[0].children("sg2"), same([1]));

      expect(layerGraphs[1].nodes(), same([4, 5, 6, "sg1", "sg2"]));
      expect(layerGraphs[1].children(null), same([6, "sg1"]));
      expect(layerGraphs[1].children("sg1"), same([5, "sg2"]));
      expect(layerGraphs[1].children("sg2"), same([4]));
    });

    test("does not include subgraphs in layers where it has no nodes", () {
      // In this example sg1 is the parent of nodes 2 and 5, which are on ranks
      // 0 and 2 respectively. sg1 should not be included in rank 1 where it has
      // no nodes.
      g.addNode(1, { 'rank': 0 });
      g.addNode(2, { 'rank': 0 });
      g.addNode(3, { 'rank': 1 });
      g.addNode(4, { 'rank': 2 });
      g.addNode(5, { 'rank': 2 });
      g.addNode("sg1", {});
      g.parent(2, "sg1");
      g.parent(5, "sg1");

      var layerGraphs = initLayerGraphs(g);

      expect(layerGraphs, isNull);
      expect(layerGraphs.length, equals(3));

      expect(layerGraphs[0].nodes(), same(["sg1", 1, 2]));
      expect(layerGraphs[1].nodes(), same([3]));
      expect(layerGraphs[2].nodes(), same(["sg1", 4, 5]));
    });
  });
}